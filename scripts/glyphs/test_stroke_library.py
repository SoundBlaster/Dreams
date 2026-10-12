"""Persistence, optimistic concurrency and localhost API checks with a disposable database."""
from concurrent.futures import ThreadPoolExecutor
import copy
import hashlib
import http.client
import json
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch

from stroke_library import Conflict, Library, OUTPUT, atomic_write, serve


class Checkpoints(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.library = Library(self.temporary.name)
        self.project = json.loads((OUTPUT / 'editor-seed.json').read_text())

    def save(self, label='First', parent=None):
        return self.library.save(self.project, label, self.library.history()['head'], parent)

    def test_round_trip_dedup_and_branch_from_old_version(self):
        first = self.save()
        self.assertEqual(self.library.project(first['id']), self.project)
        self.project['glyphs'][4]['strokes'][0]['endCap'] = 'round'
        second = self.save('Round オ')
        self.assertEqual(second['changedGlyphs'], ['オ'])
        self.assertEqual(second['parent'], first['id'])
        self.assertNotEqual(self.library.project(first['id']), self.project)
        third = self.save('Same shape')
        self.assertEqual(third['changedGlyphs'], [])
        self.assertEqual(len(list(Path(self.temporary.name, 'projects').glob('*.json'))), 2)
        self.project = self.library.project(first['id'])
        branch = self.save('Return to baseline', first['id'])
        self.assertEqual(branch['parent'], first['id'])
        self.assertEqual(len(self.library.history()['checkpoints']), 4)

    def test_two_writers_cannot_overwrite_history(self):
        first = self.save()

        def writer(label):
            try:
                return self.library.save(self.project, label, first['id'])
            except Conflict:
                return None

        with ThreadPoolExecutor(max_workers=2) as executor:
            records = list(executor.map(writer, ['One', 'Two']))
        self.assertEqual(sum(r is not None for r in records), 1)
        self.assertEqual(len(self.library.history()['checkpoints']), 2)

    def test_invalid_data_and_failed_write_leave_history_intact(self):
        first = self.save()
        bad = copy.deepcopy(self.project)
        bad['glyphs'][0]['strokes'][0]['width'] = -5
        with self.assertRaises(ValueError):
            self.library.save(bad, 'Invalid', first['id'])
        with self.assertRaises(ValueError):
            self.save('Missing parent', '../outside')
        self.project['glyphs'][0]['stretch'] = .7

        def fail_history(path, data):
            if path.name == 'history.json':
                raise OSError('Simulated disk failure')
            atomic_write(path, data)

        with patch('stroke_library.atomic_write', side_effect=fail_history), self.assertRaises(OSError):
            self.save('Not committed')
        self.assertEqual(self.library.history()['head'], first['id'])
        self.library.project(first['id'])

    def test_hash_tampering_is_detected(self):
        record = self.save()
        path = Path(self.temporary.name, 'projects', record['projectHash'] + '.json')
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), record['projectHash'])
        path.write_text('{}')
        with self.assertRaises(ValueError):
            self.library.project(record['id'])

    def test_unknown_database_version_is_not_overwritten(self):
        self.save()
        path = Path(self.temporary.name, 'history.json')
        history = self.library.history()
        history['schema'] = 'future/v2'
        path.write_text(json.dumps(history))
        before = path.read_bytes()
        with self.assertRaises(ValueError):
            self.library.save(self.project, 'Unsupported', None)
        self.assertEqual(path.read_bytes(), before)

    def test_http_save_read_conflict_and_origin_guards(self):
        server = serve(self.library, port=0)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        port = server.server_port

        def request(method, path, payload=None, origin=None, host=None):
            connection = http.client.HTTPConnection('127.0.0.1', port, timeout=10)
            headers = {'Content-Type': 'application/json'}
            if origin:
                headers['Origin'] = origin
            if host:
                headers['Host'] = host
            connection.request(method, path, json.dumps(payload) if payload else None, headers)
            response = connection.getresponse()
            body = response.read()
            connection.close()
            return response.status, json.loads(body)

        payload = {'label': 'HTTP checkpoint', 'project': self.project, 'expectedHead': None}
        self.assertEqual(request('GET', '/api/checkpoints')[1]['head'], None)
        self.assertEqual(request('POST', '/api/checkpoints', payload)[0], 403)
        self.assertEqual(request('POST', '/api/checkpoints', payload, 'http://evil.example')[0], 403)
        self.assertEqual(request('GET', '/api/checkpoints', host='evil.example')[0], 403)
        origin = f'http://127.0.0.1:{port}'
        status, record = request('POST', '/api/checkpoints', payload, origin)
        self.assertEqual(status, 201)
        self.assertEqual(request('GET', '/api/checkpoints/' + record['id'])[1], self.project)
        self.assertEqual(request('POST', '/api/checkpoints', payload, origin)[0], 409)
        self.assertEqual(len(request('GET', '/api/checkpoints')[1]['checkpoints']), 1)


if __name__ == '__main__':
    unittest.main()
