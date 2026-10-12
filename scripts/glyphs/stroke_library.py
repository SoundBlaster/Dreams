"""Content-addressed glyph projects and named checkpoints, stored as Git-friendly JSON."""
import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
import fcntl
import hashlib
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import uuid

ROOT = Path(__file__).resolve().parents[2]
DATABASE = ROOT / 'research/glyphs/stroke-library'
OUTPUT = ROOT / 'research/glyphs/build/katakana'
MAX_BYTES = 2_000_000


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2, allow_nan=False) + '\n').encode()


def validate(project):
    data = encoded(project)
    if len(data) > MAX_BYTES:
        raise ValueError('Проект больше 2 МБ')
    result = subprocess.run(['node', str(Path(__file__).with_name('validate-stroke-project.cjs'))],
                            input=data, capture_output=True, timeout=15)
    if result.returncode:
        raise ValueError(result.stderr.decode().strip() or 'Неверный проект')
    return data


def atomic_write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(suffix='.tmp', dir=path.parent)
    try:
        with os.fdopen(descriptor, 'wb') as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


class Conflict(ValueError):
    pass


class Library:
    def __init__(self, directory=DATABASE):
        self.directory = Path(directory)

    @contextmanager
    def locked(self):
        self.directory.mkdir(parents=True, exist_ok=True)
        with (self.directory / '.lock').open('a') as stream:
            fcntl.flock(stream, fcntl.LOCK_EX)
            yield

    def history(self):
        path = self.directory / 'history.json'
        if not path.exists():
            return {'schema': 'dreams.stroke-library/v1', 'head': None, 'checkpoints': []}
        history = json.loads(path.read_text())
        if not isinstance(history, dict) or history.get('schema') != 'dreams.stroke-library/v1':
            raise ValueError('Неподдерживаемая версия базы checkpoints')
        records = history.get('checkpoints')
        if not isinstance(records, list) or history.get('head') != (records[-1]['id'] if records else None):
            raise ValueError('Повреждён индекс checkpoints')
        return history

    def project(self, checkpoint_id):
        record = next((c for c in self.history()['checkpoints'] if c['id'] == checkpoint_id), None)
        if not record:
            raise ValueError('Checkpoint не найден')
        digest = record['projectHash']
        if not re.fullmatch('[0-9a-f]{64}', digest):
            raise ValueError('Неверный hash проекта')
        data = (self.directory / 'projects' / (digest + '.json')).read_bytes()
        if hashlib.sha256(data).hexdigest() != digest:
            raise ValueError('Контрольная сумма проекта не совпадает')
        return json.loads(data)

    def save(self, project, label, expected_head, parent=None):
        if not isinstance(label, str) or not label.strip() or len(label) > 120:
            raise ValueError('Название: от 1 до 120 символов')
        data = validate(project)
        digest = hashlib.sha256(data).hexdigest()
        with self.locked():
            history = self.history()
            if expected_head != history['head']:
                raise Conflict('История обновилась в другой вкладке. Обнови список и повтори сохранение.')
            parent = parent or history['head']
            previous = self.project(parent) if parent else {'glyphs': [], 'attribution': ''}
            before = {g['character']: g for g in previous['glyphs']}
            after = {g['character']: g for g in project['glyphs']}
            changed = sorted(k for k in before.keys() | after.keys() if before.get(k) != after.get(k))
            record = {'id': uuid.uuid4().hex, 'parent': parent,
                      'createdAt': datetime.now(timezone.utc).isoformat(timespec='microseconds'),
                      'label': label.strip(), 'projectHash': digest, 'changedGlyphs': changed,
                      'attributionChanged': project['attribution'] != previous['attribution']}
            path = self.directory / 'projects' / (digest + '.json')
            if path.exists():
                if path.read_bytes() != data:
                    raise ValueError('Повреждён существующий проект')
            else:
                atomic_write(path, data)
            history['checkpoints'].append(record)
            history['head'] = record['id']
            atomic_write(self.directory / 'history.json', encoded(history))
            return record


def serve(library, port=8767, directory=OUTPUT):
    class Handler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=str(directory), **kwargs)

        def reply(self, value, code=200):
            body = encoded(value)
            self.send_response(code)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            self.wfile.write(body)

        def trusted_host(self):
            return self.headers.get('Host') == f'127.0.0.1:{self.server.server_port}'

        def do_GET(self):
            if not self.trusted_host():
                return self.reply({'error': 'Localhost only'}, 403)
            try:
                if self.path == '/api/checkpoints':
                    return self.reply(library.history())
                if self.path.startswith('/api/checkpoints/'):
                    return self.reply(library.project(self.path.removeprefix('/api/checkpoints/')))
                super().do_GET()
            except (ValueError, OSError, KeyError, TypeError) as error:
                self.reply({'error': str(error)}, 400)

        def do_POST(self):
            origin = f'http://127.0.0.1:{self.server.server_port}'
            if not self.trusted_host() or self.headers.get('Origin') != origin:
                return self.reply({'error': 'Same-origin requests only'}, 403)
            if self.path != '/api/checkpoints':
                return self.reply({'error': 'Unknown endpoint'}, 404)
            try:
                size = int(self.headers.get('Content-Length', '0'))
                if not 0 < size <= MAX_BYTES or self.headers.get('Content-Type') != 'application/json':
                    raise ValueError('Ожидается JSON до 2 МБ')
                self.connection.settimeout(10)
                payload = json.loads(self.rfile.read(size))
                if not isinstance(payload, dict):
                    raise ValueError('Ожидается объект checkpoint')
                record = library.save(payload.get('project'), payload.get('label'),
                                      payload.get('expectedHead'), payload.get('parent'))
                self.reply(record, 201)
            except Conflict as error:
                self.reply({'error': str(error)}, 409)
            except (ValueError, OSError, TypeError, KeyError, subprocess.TimeoutExpired) as error:
                self.reply({'error': str(error)}, 400)

    return ThreadingHTTPServer(('127.0.0.1', port), Handler)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--database', type=Path, default=DATABASE)
    commands = parser.add_subparsers(dest='command', required=True)
    server = commands.add_parser('serve')
    server.add_argument('--port', type=int, default=8767)
    server.add_argument('--directory', type=Path, default=OUTPUT)
    save = commands.add_parser('save')
    save.add_argument('project', type=Path)
    save.add_argument('--label', required=True)
    args = parser.parse_args()
    library = Library(args.database)
    if args.command == 'save':
        print(json.dumps(library.save(json.loads(args.project.read_text()), args.label,
                                      library.history()['head']), ensure_ascii=False))
    else:
        with serve(library, args.port, args.directory) as http:
            print(f'Glyph editor: http://127.0.0.1:{http.server_port}/editor.html', flush=True)
            http.serve_forever()


if __name__ == '__main__':
    main()
