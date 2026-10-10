"""Self-test of the glyph pipeline: every check must catch the defect it exists for.

Runs in temporary directories and never touches research/glyphs/overrides or build/.
  .venv/bin/python scripts/glyphs/selftest.py
"""
import json
import re
import shutil
import sys
import tempfile
from pathlib import Path

from fontTools.pens.reverseContourPen import ReverseContourPen
from fontTools.pens.recordingPen import RecordingPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont

import font as fontlib
import pipeline

results = []


def check(name, condition, detail=''):
    results.append(condition)
    print(f"{'PASS' if condition else 'FAIL'}  {name}{'  — ' + detail if detail else ''}")


def record(out, glyph_id):
    glyphs = json.loads((out / 'glyphs.json').read_text())['glyphs']
    return next(g for g in glyphs if g['id'] == glyph_id)


def path_data(svg):
    return re.findall(r'<g id="glyph"[^>]*>(.*?)</g>\n</svg>', Path(svg).read_text(), re.S)[0]


def edit(svg, before, after):
    text = Path(svg).read_text()
    assert before in text, f'{before!r} not found in {svg}'
    Path(svg).write_text(text.replace(before, after, 1))


with tempfile.TemporaryDirectory() as tmp:
    tmp = Path(tmp)
    empty = tmp / 'no-overrides'
    empty.mkdir()
    base = pipeline.build(tmp / 'base', overrides=empty)
    ids = [g['id'] for g in json.loads((tmp / 'base/glyphs.json').read_text())['glyphs']]
    check('baseline build passes', not base['result']['failed'], f"{len(ids)} glyphs")

    # Punctuation must retain its cell metrics through sheet segmentation and TTF.
    base_font = TTFont(tmp / 'base' / pipeline.TTF_NAME)
    font = pipeline.load_config()['font']
    if 'G25' in ids:
        digit, dash = base_font['glyf']['G21'], base_font['glyf']['G25']
        colon = base_font['glyf']['G23']
        check('short punctuation is not stretched to cap height',
              dash.yMax - dash.yMin < (digit.yMax - digit.yMin) / 4
              and colon.yMax - colon.yMin < digit.yMax - digit.yMin)
        check('dash remains vertically centred in its cell',
              abs((dash.yMin + dash.yMax) / 2 - (font['body_bottom'] + font['body_top']) / 2) < 40)

    again = pipeline.build(tmp / 'again', overrides=empty)
    check('two builds are byte-identical', again['outputs'] == base['outputs'])

    overrides = tmp / 'overrides'
    overrides.mkdir()
    for glyph_id in ids:
        shutil.copy(tmp / 'base/glyphs' / f'{glyph_id}.svg', overrides)
    first = pipeline.build(tmp / 'round1', overrides=overrides)
    for glyph_id in ids:
        shutil.copy(tmp / 'round1/glyphs' / f'{glyph_id}.svg', overrides)
    pipeline.build(tmp / 'round2', overrides=overrides)
    drift = [g for g in ids if not (path_data(tmp / 'base/glyphs' / f'{g}.svg')
                                    == path_data(tmp / 'round1/glyphs' / f'{g}.svg')
                                    == path_data(tmp / 'round2/glyphs' / f'{g}.svg'))]
    check('adopted overrides survive rebuilds unchanged', not drift and not first['result']['failed'],
          f'drifting: {drift}' if drift else 'all outlines identical over two round-trips')
    ttf = pipeline.TTF_NAME
    check('font from unedited overrides equals the traced font', first['outputs'][ttf] == base['outputs'][ttf])

    def scenario(name, glyph_id, mutate, expect_fail=None, expect_warn=None, expect_topology=None):
        work = tmp / name
        work.mkdir()
        svg = work / f'{glyph_id}.svg'
        shutil.copy(tmp / 'base/glyphs' / f'{glyph_id}.svg', svg)
        mutate(svg)
        out = tmp / f'{name}-out'
        manifest = pipeline.build(out, overrides=work)
        r = record(out, glyph_id)
        ok = True
        if expect_fail is not None:
            ok &= (glyph_id in manifest['result']['failed']) == expect_fail
        if expect_warn is not None:
            ok &= any(expect_warn in w for w in r['warnings'])
        if expect_topology is not None:
            ok &= r['topology']['final'] == expect_topology
        detail = '; '.join(r['failures'] + r['warnings']) or f"topology {r['topology']['final']}"
        check(name, ok, detail)

    def drop_last_subpath(svg):
        text = Path(svg).read_text()
        d = re.search(r'<path d="([^"]+)"', text.split('<g id="glyph"')[1]).group(1)
        Path(svg).write_text(text.replace(d, ''.join(re.findall(r'M[^M]+', d)[:-1])))

    scenario('missing stroke fails topology (G10)', 'G10', drop_last_subpath, expect_fail=True)
    scenario('overlapping element is united, not punched (G11)', 'G11',
             lambda svg: edit(svg, '</g>\n</svg>', '<rect x="380" y="700" width="300" height="80"/></g>\n</svg>'),
             expect_topology={'components': 1, 'holes': 0})
    scenario('reversed element direction is still a union (G11)', 'G11',
             lambda svg: edit(svg, '</g>\n</svg>', '<path d="M380 700 V780 H680 V700 Z"/></g>\n</svg>'),
             expect_topology={'components': 1, 'holes': 0})
    scenario('even-odd overlap punches a hole as SVG renders it (G11)', 'G11',
             lambda svg: edit(svg, '</g>\n</svg>',
                              '<path fill-rule="evenodd" d="M300 650 H760 V830 H300 Z M380 700 H680 V780 H380 Z"/></g>\n</svg>'),
             expect_fail=True)
    scenario('mirrored glyph warns about orientation (G06)', 'G06',
             lambda svg: edit(svg, '<g id="glyph" fill="#000">',
                              '<g id="glyph" fill="#000" transform="translate(956 0) scale(-1 1)">'),
             expect_warn='mirrored shape matches the film better')
    scenario('guides without ids are ignored (G01)', 'G01',
             lambda svg: edit(svg, '<g id="guides"', '<g'), expect_fail=False,
             expect_topology={'components': 1, 'holes': 0})
    try:
        scenario('rescaled viewBox is refused', 'G01', lambda svg: edit(svg, 'viewBox="0 0 956 1024"', 'viewBox="0 0 478 512"'))
        check('rescaled viewBox is refused', False, 'build accepted it')
    except ValueError as error:
        check('rescaled viewBox is refused', 'viewBox' in str(error))

    ttfont = TTFont(tmp / 'base' / pipeline.TTF_NAME)
    glyphs = ttfont.getGlyphSet()
    pen = TTGlyphPen(glyphs)
    glyphs['G02'].draw(ReverseContourPen(pen))
    ttfont['glyf']['G02'] = pen.glyph()
    check('reversed TrueType contours are detected', fontlib.winding_errors(ttfont) == ['G02'])

    def flip_one_contour(glyph_id, contour_index):
        font = TTFont(tmp / 'base' / pipeline.TTF_NAME)
        glyphset = font.getGlyphSet()
        recording = RecordingPen()
        glyphset[glyph_id].draw(recording)
        contours, current = [], []
        for operation in recording.value:
            current.append(operation)
            if operation[0] in ('closePath', 'endPath'):
                contours.append(current)
                current = []
        pen = TTGlyphPen(glyphset)
        for index, contour in enumerate(contours):
            sink = ReverseContourPen(pen) if index == contour_index else pen
            for operation, arguments in contour:
                getattr(sink, operation)(*arguments)
        font['glyf'][glyph_id] = pen.glyph()
        return font

    check('one reversed hole is detected despite correct total area',
          fontlib.winding_errors(flip_one_contour('G02', 1)) == ['G02'])
    check('one reversed disconnected stroke is detected',
          fontlib.winding_errors(flip_one_contour('G10', 0)) == ['G10'])

    nested = TTFont(tmp / 'base' / pipeline.TTF_NAME)
    pen = TTGlyphPen(nested.getGlyphSet())
    # Outer shell, hole, and a filled island inside the hole.
    for a, b, clockwise in [(50, 850, True), (150, 750, False), (250, 650, True)]:
        points = [(a, a), (a, b), (b, b), (b, a)]
        if not clockwise:
            points.reverse()
        pen.moveTo(points[0])
        for point in points[1:]:
            pen.lineTo(point)
        pen.closePath()
    nested['glyf']['G02'] = pen.glyph()
    check('nested island uses alternating winding', fontlib.winding_errors(nested) == [])

    # Designed Latin: owns the ASCII codepoints, stays out of the rain's PUA repertoire,
    # and its topology and metric-line contracts catch broken edits.
    cmap = TTFont(tmp / 'base' / pipeline.TTF_NAME).getBestCmap()
    designed = json.loads((tmp / 'base/glyphs.json').read_text())['designed']
    check('designed glyphs own their codepoints, none in PUA',
          designed and all(cmap[int(d['unicode'][2:], 16)] == d['id'] for d in designed)
          and not any(not n.startswith('G') for c, n in cmap.items() if 0xE001 <= c <= 0xF8FF),
          f'{len(designed)} designed glyphs')
    check('designed glyphs pass in the baseline build', not any(d['failures'] for d in designed))
    russian = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя'
    aliases = json.loads((tmp / 'base/glyphs.json').read_text())['aliases']
    check('every Russian letter is in the font, shared forms point to their Latin outline',
          all(ord(c) in cmap for c in russian)
          and all(cmap[int(a['unicode'][2:], 16)] == a['glyph'] for a in aliases.values())
          and cmap[ord('А')] == 'A' and cmap[ord('п')] == 'n', f'{len(russian)} letters, {len(aliases)} aliases')

    def design_scenario(name, file, mutate, expect):
        root = tmp / name
        for design in pipeline.load_config().get('design', []):
            folder = Path(design['index']).parent
            shutil.copytree(pipeline.RESEARCH / folder, root / folder)
        mutate(root / 'latin' / file)
        manifest = pipeline.build(tmp / f'{name}-out', overrides=empty, designs_root=root)
        glyph = file.split('-')[1].removesuffix('.svg')
        failures = next(d for d in json.loads((tmp / f'{name}-out/glyphs.json').read_text())['designed']
                        if d['id'] == glyph)['failures']
        check(name, glyph in manifest['result']['failed'] and any(expect in f for f in failures), '; '.join(failures))

    design_scenario('filled counter of a designed O fails topology', 'upper-O.svg',
                    lambda svg: edit(svg, '</g>\n</svg>', '<rect x="250" y="200" width="460" height="600"/></g>\n</svg>'),
                    'topology')
    design_scenario('designed H lifted off the baseline fails the line check', 'upper-H.svg',
                    lambda svg: edit(svg, '<g id="glyph" fill="#000">', '<g id="glyph" fill="#000" transform="translate(0 -100)">'),
                    'baseline')

    import latin
    generated = tmp / 'latin-gen'
    latin.generate(generated, only=['A'])
    edit(generated / 'upper-A.svg', '<g id="glyph" fill="#000">', '<g id="glyph" fill="#000"><!-- edited -->')
    edited = (generated / 'upper-A.svg').read_text()
    written, kept = latin.generate(generated, only=['A'])
    check('regenerating keeps a hand-edited designed SVG', kept == ['A'] and not written
          and (generated / 'upper-A.svg').read_text() == edited)

    lock = json.loads(pipeline.LOCK.read_text())
    victim = next(iter(lock['files']))
    lock['files'][victim] = '0' * 64
    fake = tmp / 'inputs.lock.json'
    fake.write_text(json.dumps(lock))
    original, pipeline.LOCK = pipeline.LOCK, fake
    try:
        pipeline.build(tmp / 'tampered', overrides=empty)
        check('changed frozen input is refused', False, 'build accepted it')
    except SystemExit as error:
        check('changed frozen input is refused', victim in str(error.code))
    finally:
        pipeline.LOCK = original

print(f"\n{sum(results)}/{len(results)} checks passed")
sys.exit(0 if all(results) else 1)
