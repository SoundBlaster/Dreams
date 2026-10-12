"""Offline research catalogue of directed katakana strokes; no production font writes."""
import argparse
import hashlib
import html
import json
from pathlib import Path
import tomllib
import xml.etree.ElementTree as ET

from stroke_model import Brush, Stroke, svg_path, union_strokes, validate_profile
import vector

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'research/glyphs/katakana'
OUTPUT = ROOT / 'research/glyphs/build/katakana'
REPERTOIRE = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン'
STUDIES = (
    ('studies', 'ネマスセ', 'Четыре каллиграфических этюда'),
    ('pairs', 'シツソン', 'シ/ツ и ソ/ン: направление росчерка'),
    ('crossings', 'オキホモ', 'Перекладины, пересечения и крючки'),
    ('turns', 'アウワヲ', 'Повороты и длинные росчерки'),
    ('diagonals', 'タチテナ', 'Диагонали и перекладины'),
    ('branches', 'カクケサ', 'Разветвления и нисходящие дуги'),
    ('sweeps', 'イノハヘ', 'Наклоны и открытые росчерки'),
    ('curves', 'ヒミムメ', 'Изгибы и расширяющиеся штрихи'),
    ('verticals', 'トヤリル', 'Вертикали и боковые движения'),
    ('horizontals', 'レエニフ', 'Горизонтали и смена направления'),
    ('frames', 'コユヨロ', 'Рамки и внутренние просветы'),
    ('finals', 'ラヌ', 'Последние нисходящие дуги'),
)
ATTRIBUTION = ('Based on KanjiVG, copyright Ulrich Apel and contributors; '
               'https://kanjivg.tagaini.net/ ; CC BY-SA 3.0 '
               'https://creativecommons.org/licenses/by-sa/3.0/ . '
               'Modified by Dreams: pressure profiles, brush outlines and optional reflection.')


def load_library(directory=DATA):
    library = json.loads((directory / 'library.json').read_text())
    lock = json.loads((directory / 'sources.lock.json').read_text())
    if library['schema'] != 'dreams.katakana-strokes/v1':
        raise ValueError('unsupported library schema')
    if ''.join(g['character'] for g in library['glyphs']) != REPERTOIRE:
        raise ValueError('expected exactly the 46 basic katakana in gojuon order')
    if set(lock['sources']) != set(REPERTOIRE):
        raise ValueError('source lock repertoire mismatch')
    brush = Brush(**library['brush'])
    for profile in library['profiles'].values():
        validate_profile(profile)
    result = []
    for glyph in library['glyphs']:
        source = lock['sources'][glyph['character']]
        file = (directory / source['file']).resolve()
        if not file.is_relative_to(directory.resolve()):
            raise ValueError('source escapes library directory')
        raw = file.read_bytes()
        if hashlib.sha256(raw).hexdigest() != source['sha256']:
            raise ValueError(f'{file.name}: source hash mismatch')
        svg = ET.fromstring(raw)
        if svg.attrib['viewBox'] != '0 0 109 109':
            raise ValueError('unexpected source viewBox')
        paths = list(svg.iter('{http://www.w3.org/2000/svg}path'))
        if [p.attrib['id'] for p in paths] != [s['source_id'] for s in glyph['strokes']]:
            raise ValueError(f'{glyph["character"]}: stroke order/count differs from source')
        if glyph['review'] not in ('draft', 'reviewed'):
            raise ValueError('invalid review status')
        strokes = []
        for spec, path in zip(glyph['strokes'], paths):
            if spec['pressure_evidence'] != 'design-hypothesis':
                raise ValueError('v1 supports authored pressure only, not measured pressure')
            pressure = spec.get('pressure', library['profiles'][spec['profile']])
            strokes.append(Stroke(spec.get('path_override', path.attrib['d']), tuple(map(tuple, pressure)),
                                  spec['terminal'], spec['duration']))
        result.append((glyph, strokes))
    return library, brush, result


def export_svg(strokes, brush, font, mirrored=False):
    """Keep one common cell transform; never fit short strokes to full cap height."""
    path = union_strokes(strokes, brush)
    # Reflection occurs AFTER brush synthesis, preserving stroke chronology and nib shape.
    sx = -7.0 if mirrored else 7.0
    tx = font['advance'] / 2 - sx * 54.5
    outline = path.transform(sx, 0, 0, -8.0, tx, 826.0)
    return vector.write_svg(outline, font, 'katakana', ATTRIBUTION)


def study_sheet(records, characters='ネマスセ', title='Четыре каллиграфических этюда', directions=False):
    """Focused normal/reflected proof; optional actual long-stroke direction."""
    selected = [next(g for g in records if g['character'] == char) for char in characters]
    rows = []
    for mirrored in (False, True):
        cards = []
        for glyph in selected:
            paths = ''.join(f'<path d="{d}"/>' for d in glyph['outlines'])
            transform = 'translate(109 0) scale(-1 1)' if mirrored else ''
            label = f'{glyph["character"]} · {glyph["reading"]}'
            gesture = ''
            if directions:
                start, end = glyph['samples'][-1][0], glyph['samples'][-1][-1]
                right = (end[0] - start[0]) * (-1 if mirrored else 1) > 0
                up = end[1] < start[1]
                arrow = ('↗' if right else '↖') if up else ('↘' if right else '↙')
                direction = 'снизу вверх' if up else 'сверху вниз'
                gesture = f'<p class="gesture">{len(glyph["strokes"])}-й штрих: {arrow} {direction}</p>'
            cards.append(f'<article><h2>{label}</h2><svg viewBox="0 0 109 109" role="img" '
                         f'aria-label="{label}, {"mirrored" if mirrored else "normal"}">'
                         f'<g fill="#173b2e" transform="{transform}">{paths}</g></svg>{gesture}</article>')
        anchor = 'mirrored' if mirrored else 'normal'
        rows.append(f'<h3 id="{anchor}">{"Зеркальное отражение" if mirrored else "Обычное начертание"}</h3>'
                    f'<section>{"".join(cards)}</section>')
    alphabet = characters == REPERTOIRE
    group_links = ''.join(f'<a href="{slug}.html">{"・".join(chars)}</a>' for slug, chars, _ in STUDIES)
    index = f'<nav class="groups" aria-label="Группы этюдов">{group_links}</nav>' if alphabet else ''
    return ('<!doctype html><html lang="ru"><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width, initial-scale=1">'
            f'<title>Dreams · {html.escape(title)}</title><link rel="icon" href="data:,">'
            '<style>body{background:#f4f0e5;color:#173b2e;font:16px system-ui;'
            'max-width:1340px;margin:28px auto;padding:0 24px}h1{margin:0 0 8px}h3{margin:20px 0 8px}'
            'p{color:#52635d}section{display:grid;grid-template-columns:repeat(4,1fr);gap:16px}'
            + ('section{grid-template-columns:repeat(6,1fr)}' if alphabet else '') +
            'article{background:#fffdf6;border:1px solid #ccd1c4;border-radius:12px;padding:12px}'
            'h2{font-size:18px;margin:0}svg{display:block;width:100%}a{color:inherit}'
            '.gesture{font-size:14px;margin:0}nav{margin-bottom:12px;display:flex;flex-wrap:wrap;gap:20px}'
            '@media(max-width:640px){section{grid-template-columns:repeat(2,1fr)}}</style>'
            '<nav><a href="editor.html">Редактор штрихов</a><a href="alphabet.html">Весь алфавит и группы</a>'
            '<a href="#normal">Обычные формы</a><a href="#mirrored">Зеркальные формы</a></nav>'
            f'<h1>{html.escape(title)}</h1><p>Индивидуальные траектории и нажим · DRAFT · '
            '<a href="catalog.html">Открыть каталог</a></p>' + index + ''.join(rows)
            + '<p>Зеркальные варианты получены отражением готового следа кисти. '
            'Профили — художественная настройка по образцу, а не измеренный нажим.</p>'
            f'<small>{html.escape(ATTRIBUTION)}</small></html>')


def build(destination=OUTPUT):
    library, brush, glyphs = load_library()
    destination.mkdir(parents=True, exist_ok=True)
    generated = []

    def write(name, content):
        path = destination / name
        path.write_text(content)
        generated.append(path)

    font = tomllib.loads((ROOT / 'research/glyphs/pipeline.toml').read_text())['font']
    records, cards = [], []
    for glyph, strokes in glyphs:
        character = glyph['character']
        name = f'uni{ord(character):04X}'
        for mirrored in (False, True):
            write(f'{name}{"-mirrored" if mirrored else ""}.svg',
                export_svg(strokes, brush, font, mirrored))
        record = {**glyph, 'outlines': [], 'samples': [], 'paths': [], 'pressure': []}
        for stroke in strokes:
            record['outlines'].append(svg_path(stroke.outline(brush)))
            record['samples'].append([[round(v, 5) for v in sample] for sample in stroke.samples()])
            record['paths'].append(stroke.path)
            record['pressure'].append(stroke.pressure)
        records.append(record)
        paths = ''.join(f'<path d="{d}"/>' for d in record['outlines'])
        cards.append(f'<svg viewBox="0 0 109 128"><title>{character} {glyph["reading"]}</title>'
                     f'<g fill="#152b26">{paths}</g><text x="5" y="123" font-size="8">'
                     f'{character} · {glyph["reading"]} · DRAFT</text></svg>')
    payload = json.dumps({'brush': library['brush'], 'profiles': library['profiles'], 'glyphs': records},
                         ensure_ascii=False, separators=(',', ':')).replace('<', '\\u003c')
    template = (Path(__file__).parent / 'katakana-catalog.html').read_text()
    write('catalog.html', template.replace('__LIBRARY_JSON__', payload))
    for slug, characters, title in STUDIES:
        write(f'{slug}.html', study_sheet(records, characters, title, slug == 'pairs'))
    write('alphabet.html', study_sheet(records, REPERTOIRE, 'Катакана · 46 каллиграфических этюдов'))
    write('proof.html', '<!doctype html><meta charset="utf-8"><title>Katakana proof</title>'
        '<style>body{background:#f4f0e5;font:16px system-ui;padding:24px}main{display:grid;'
        'grid-template-columns:repeat(10,1fr);gap:12px}svg{width:100%;border:1px solid #b9c7bd}</style>'
        '<h1>Katakana · 46 construction studies</h1><p>Pressure = editable hypothesis; all glyphs DRAFT.</p>'
        f'<main>{"".join(cards)}</main><p>{html.escape(ATTRIBUTION)}</p>')
    write('ATTRIBUTION.txt', ATTRIBUTION + '\n')
    from stroke_editor import build as build_editor
    generated.extend(build_editor(destination))
    hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
              for p in sorted(generated)}
    (destination / 'manifest.json').write_text(json.dumps(hashes, indent=2) + '\n')
    print(f'{len(glyphs)} glyphs, {sum(len(s) for _, s in glyphs)} directed strokes, 92 editable SVGs')
    print(destination / 'catalog.html')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['check', 'build'], default='build', nargs='?')
    parser.add_argument('--output', type=Path, default=OUTPUT)
    args = parser.parse_args()
    if args.command == 'check':
        _, _, glyphs = load_library()
        print(f'Validated {len(glyphs)} glyphs, source hashes, stroke order and pressure profiles')
    else:
        build(args.output)
