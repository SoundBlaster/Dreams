"""Reproducible Matrix glyph pipeline.

sheet raster -> per-glyph slice -> potrace (or hand-edited override SVG) -> cleaned outline
-> TTF -> checks (topology, IoU, winding, film orientation) -> proof sheet + manifest.

Run from the Dreams root with the project venv:
  .venv/bin/python scripts/glyphs/pipeline.py build     # build research/glyphs/build/
  .venv/bin/python scripts/glyphs/pipeline.py verify    # rebuild in a temp dir, compare hashes
  .venv/bin/python scripts/glyphs/pipeline.py adopt G04 # copy an outline to overrides/ for hand editing
  .venv/bin/python scripts/glyphs/pipeline.py lock      # accept intentional changes of frozen inputs
"""
import argparse
import hashlib
import json
import platform
import shutil
import subprocess
import sys
import tempfile
import tomllib
from importlib.metadata import version
from pathlib import Path

import numpy as np
from PIL import Image
from fontTools.misc.transform import Transform

import font as fontlib
import proof
import raster
import vector

ROOT = Path(__file__).resolve().parents[2]
RESEARCH = ROOT / 'research/glyphs'
CONFIG = RESEARCH / 'pipeline.toml'
LOCK = RESEARCH / 'inputs.lock.json'
DEFAULT_OUT = RESEARCH / 'build'
FILM = RESEARCH / 'sources/film-masks'
OVERRIDES = RESEARCH / 'overrides'
TTF_NAME = 'DreamsMatrix.ttf'


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def rel(path):
    path = Path(path).resolve()
    if path.is_relative_to(ROOT):
        return path.relative_to(ROOT).as_posix()
    return '/'.join(path.parts[-2:])  # inputs outside the repository (self-test copies)


def load_config():
    config = tomllib.loads(CONFIG.read_text())
    config.setdefault('glyph', {})
    return config


def frozen_inputs(config):
    files = [RESEARCH / sheet['path'] for sheet in config['sheet']]
    files += sorted(FILM.glob('G*.png'))
    files += [RESEARCH / design['reference'] for design in config.get('design', []) if 'reference' in design]
    return {rel(path): sha256(path) for path in files}


LINE_NAMES = {'cap': 'cap_height', 'x': 'x_height', 'asc': 'ascender', 'desc': 'descender', 'tail': 'tail'}
LINE_LABELS = {'cap': 'cap height', 'x': 'x-height', 'asc': 'ascender', 'base': 'baseline', 'desc': 'descender',
               'tail': 'tail line'}


def load_designs(config, root=None):
    """Designed glyph sets: name -> entry with its SVG, codepoint and contracts, plus
    aliases (name -> entry) that give an existing designed glyph a second codepoint."""
    entries, aliases = {}, {}
    for design in config.get('design', []):
        index = (root or RESEARCH) / design['index']
        data = tomllib.loads(index.read_text())
        for name, entry in data.get('glyph', {}).items():
            if name in entries:
                raise SystemExit(f'designed glyph {name} appears in two sets')
            entries[name] = {**entry, 'name': name, 'set': design['id'], 'svg': index.parent / entry['file'],
                             'reference': RESEARCH / design['reference'] if 'reference' in design else None}
        for name, alias in data.get('alias', {}).items():
            aliases[name] = {**alias, 'name': name, 'set': design['id']}
    for name, alias in aliases.items():
        if alias['glyph'] not in entries:
            raise SystemExit(f'alias {name} points to unknown designed glyph {alias["glyph"]}')
    codes = [e['unicode'] for e in entries.values()] + [a['unicode'] for a in aliases.values()]
    if len(codes) != len(set(codes)):
        raise SystemExit('two designed glyphs claim the same codepoint')
    return entries, aliases


def atlas_overflow(glyph, font, app):
    """Pixels by which a glyph leaves the app's sampling window (0 if it fits)."""
    if not hasattr(glyph, 'yMax'):
        return 0.0
    k = app['font_size'] / font['upm']
    margin = (app['cell'] - app['window']) / 2
    baseline = (app['cell'] - (font['ascent'] + font['descent']) * k) / 2 + font['descent'] * k
    left = (app['cell'] - font['advance'] * k) / 2
    return round(max(0.0, baseline + glyph.yMax * k - (app['cell'] - margin), margin - (baseline + glyph.yMin * k),
                     margin - (left + glyph.xMin * k), left + glyph.xMax * k - (app['cell'] - margin)), 2)


def used_by_app(code):
    """The app draws every codepoint: rain PUA, keywords and verbatim tool call lines."""
    return True


def settle(path, font, glyph_id, svg_to_font):
    """The outline exactly as it reads back from its own SVG (rounding and pen
    normalisation settle in a pass or two), so an adopted file is a fixed point."""
    for _ in range(5):
        svg = vector.write_svg(path, font, glyph_id, 'outline')
        path = vector.clean(vector.read_svg(svg, svg_to_font))
        if vector.write_svg(path, font, glyph_id, 'outline') == svg:
            return path
    raise SystemExit(f'{glyph_id}: outline does not settle under SVG round-trips')


def tools():
    potrace = subprocess.run(['potrace', '--version'], capture_output=True, text=True, check=True)
    return {'python': platform.python_version(), 'potrace': potrace.stdout.split()[1],
            **{name: version(name) for name in ('fonttools', 'numpy', 'pillow', 'scipy', 'skia-pathops')}}


def check_lock(config, allow_changed):
    if not LOCK.exists():
        sys.exit(f'{rel(LOCK)} missing: review the inputs, then run `pipeline.py lock`')
    lock = json.loads(LOCK.read_text())
    current = frozen_inputs(config)
    changed = sorted(k for k in set(current) | set(lock['files']) if current.get(k) != lock['files'].get(k))
    if changed and not allow_changed:
        sys.exit('Frozen inputs differ from inputs.lock.json:\n  ' + '\n  '.join(changed) +
                 '\nGenerated sheets and film masks must not change silently. Add a new sheet '
                 'instead, or run `pipeline.py lock` after an intentional change.')
    drift = {k: (lock['tools'].get(k), v) for k, v in tools().items() if lock['tools'].get(k) != v}
    return changed, drift


def glyph_plan(config):
    """Ordered glyph ids and the sheet each one is taken from."""
    sheets = {sheet['id']: sheet for sheet in config['sheet']}
    order, source = [], {}
    for sheet in config['sheet']:
        for glyph_id in sheet['glyphs']:
            if glyph_id not in source:
                order.append(glyph_id)
                source[glyph_id] = sheet['id']
    for glyph_id, settings in config['glyph'].items():
        if glyph_id not in source:
            raise SystemExit(f'[glyph.{glyph_id}] is configured but no sheet contains it')
        if 'sheet' in settings:
            if glyph_id not in sheets.get(settings['sheet'], {}).get('glyphs', []):
                raise SystemExit(f'{glyph_id}: sheet {settings["sheet"]!r} does not contain it')
            source[glyph_id] = settings['sheet']
    return order, source


def build(out, allow_changed=False, overrides=OVERRIDES, designs_root=None):
    config = load_config()
    font, trace, checks = config['font'], config['trace'], config['checks']
    app = config.get('app')
    changed, drift = check_lock(config, allow_changed)
    identifications = {g['id']: g for g in json.loads((RESEARCH / 'identifications.json').read_text())['glyphs']}
    order, source = glyph_plan(config)

    slices, scales = {}, {}
    for sheet in config['sheet']:
        cut = raster.segment_sheet(RESEARCH / sheet['path'], sheet, trace['threshold'], trace['min_area'])
        cap = float(np.median(list({s.row: s.row_bottom - s.row_top for s in cut}.values())))
        scales[sheet['id']] = (font['body_top'] - font['body_bottom']) / cap
        for s in cut:
            slices[(sheet['id'], s.glyph_id)] = s

    if out.exists():
        shutil.rmtree(out)
    for sub in ('glyphs', 'raster'):
        (out / sub).mkdir(parents=True)

    outlines, records = {}, {}
    svg_to_font = Transform(1, 0, 0, -1, 0, font['ascent'])
    for glyph_id in order:
        settings = config['glyph'].get(glyph_id, {})
        piece, scale = slices[(source[glyph_id], glyph_id)], scales[source[glyph_id]]
        x0, y0 = piece.origin
        center = (piece.ink_box[0] + piece.ink_box[2]) / 2
        # Sheet pixels (y down) -> font units (y up), ink centred in the advance.
        placement = Transform(scale, 0, 0, -scale,
                              font['advance'] / 2 + (x0 - center) * scale,
                              font['body_bottom'] + (piece.row_bottom - y0) * scale + settings.get('dy', 0))
        override = overrides / f'{glyph_id}.svg'
        if override.exists():
            text = override.read_text()
            vector.check_viewbox(text, font, override.name)
            shapes = vector.read_svg(text, svg_to_font)
            kind = 'override'
        else:
            shapes = vector.read_svg(vector.trace(piece.gray, trace), placement.scale(1 / trace['upscale']))
            kind = 'traced'
        path = vector.clean(shapes)
        if not shapes or not path.contours:
            raise SystemExit(f'{glyph_id}: no filled outline ({kind})')
        path = settle(path, font, glyph_id, svg_to_font)
        outlines[glyph_id] = path
        note = f'{kind} from sheet {source[glyph_id]}' if kind == 'traced' else 'hand-edited override'
        (out / 'glyphs' / f'{glyph_id}.svg').write_text(vector.write_svg(path, font, glyph_id, note))
        Image.fromarray(np.uint8(np.clip(piece.gray, 0, 1) * 255)).save(out / 'raster' / f'{glyph_id}.png')
        records[glyph_id] = {'id': glyph_id, 'source': kind, 'sheet': source[glyph_id],
                             'sheet_ink_box': list(piece.ink_box), 'scale_units_per_px': round(scale, 6),
                             'dy': settings.get('dy', 0)}

    designs, aliases = load_designs(config, designs_root)
    for name, entry in designs.items():
        text = entry['svg'].read_text()
        vector.check_viewbox(text, font, rel(entry['svg']))
        shapes = vector.read_svg(text, svg_to_font)
        path = vector.clean(shapes)
        if not shapes or not path.contours:
            raise SystemExit(f'{name}: no filled outline in {rel(entry["svg"])}')
        outlines[name] = settle(path, font, name, svg_to_font)
        (out / 'glyphs' / entry['file']).write_text(
            vector.write_svg(outlines[name], font, name, f'designed glyph, set {entry["set"]}'))

    reserved = {entry['unicode']: name for name, entry in designs.items()}
    reserved.update({alias['unicode']: alias['glyph'] for alias in aliases.values()})
    cmap, notes = fontlib.assign_cmap(order, identifications, font, config['cmap']['unicode_min_confidence'], reserved)
    latin = config.get('latin', {})
    metrics = {**font, **({'cap_height': latin['cap_height'], 'x_height': latin['x_height']} if latin else {})}
    ttfont = fontlib.build(outlines, cmap, metrics, trace)
    ttf_path = out / TTF_NAME
    ttfont.save(ttf_path)
    winding = set(fontlib.winding_errors(ttfont))

    reverse = {}
    for code, name in cmap.items():
        reverse.setdefault(name, []).append(code)
    for glyph_id in order:
        record, piece = records[glyph_id], slices[(source[glyph_id], glyph_id)]
        settings = config['glyph'].get(glyph_id, {})
        em_at_sheet = round(font['upm'] / scales[source[glyph_id]])
        pua = font['pua_base'] + int(glyph_id[1:])
        final = proof.render(ttf_path, pua, em_at_sheet)
        source_topology = raster.topology(piece.mask, trace['min_area'])
        expected = {**source_topology, **settings.get('expect', {})}
        final_topology = raster.topology(final, trace['min_area'])
        iou = raster.iou_aligned(piece.mask, final)
        failures, warnings = [], []
        if final_topology != expected:
            failures.append(f'topology {final_topology} != expected {expected}')
        if record['source'] == 'traced' and iou < checks['min_iou_traced']:
            failures.append(f'trace IoU {iou:.3f} < {checks["min_iou_traced"]}')
        if record['source'] == 'override' and iou < checks['override_warn_iou']:
            warnings.append(f'override departs from the sheet raster (IoU {iou:.3f})')
        if glyph_id in winding:
            failures.append('contour winding does not match TrueType nesting')
        if app and (overflow := atlas_overflow(ttfont['glyf'][glyph_id], font, app)):
            failures.append(f'leaves the app atlas window by {overflow}px')
        film_iou = film_mirror = None
        film = FILM / f'{glyph_id}.png'
        if film.exists():
            film_mask = np.asarray(Image.open(film).convert('L')) >= 128
            film_iou, film_mirror = raster.film_scores(final, film_mask)
            if film_mirror - film_iou > checks['mirror_margin']:
                warnings.append(f'mirrored shape matches the film better ({film_mirror} vs {film_iou})')
        info = identifications.get(glyph_id, {})
        record.update({
            'unicode_hypothesis': info.get('unicode'), 'confidence': info.get('confidence'),
            'transform_hypothesis': info.get('transform'),
            'cmap': notes[glyph_id], 'codepoints': [f'U+{c:04X}' for c in sorted(reverse[glyph_id])],
            'pua': pua,
            'topology': {'sheet': source_topology, 'expected': expected, 'final': final_topology},
            'iou_sheet': round(iou, 4), 'film_iou': film_iou, 'film_iou_mirrored': film_mirror,
            'failures': failures, 'warnings': warnings,
            '_source': piece.mask, '_final': final})

    design_records = []
    glyf = ttfont['glyf']
    for name, entry in designs.items():
        final = proof.render(ttf_path, entry['unicode'], 256)
        topology = raster.topology(final, trace['min_area'])
        expected = entry['expect']
        failures, warnings = [], []
        if topology != expected:
            failures.append(f'topology {topology} != expected {expected}')
        if name in winding:
            failures.append('contour winding does not match TrueType nesting')
        if app and (overflow := atlas_overflow(glyf[name], font, app)):
            codes = [entry['unicode']] + [a['unicode'] for a in aliases.values() if a['glyph'] == name]
            message = f'leaves the app atlas window by {overflow}px'
            (failures if any(used_by_app(c) for c in codes) else warnings).append(message)
        extent = {'top': glyf[name].yMax, 'bottom': glyf[name].yMin}
        for side, line in entry['lines'].items():
            if line == 'free':
                continue
            target = 0 if line == 'base' else latin[LINE_NAMES[line]]
            if abs(extent[side] - target) > latin['line_tolerance']:
                failures.append(f'{side} {extent[side]} is off the {LINE_LABELS[line]} ({target} ± {latin["line_tolerance"]})')
        design_records.append({'id': name, 'source': 'designed', 'set': entry['set'],
                               'unicode': f"U+{entry['unicode']:04X}", 'file': entry['file'],
                               'extent': extent, 'lines': entry['lines'],
                               'topology': {'expected': expected, 'final': topology},
                               'failures': failures, 'warnings': warnings,
                               '_final': final, '_reference': entry['reference'],
                               '_reference_box': entry.get('reference_box')})
    by_name = {r['id']: r for r in design_records}
    for design in config.get('design', []):
        # One proof per set, by codepoint: aliases show the shared outline they map to.
        items = [r for r in design_records if r['set'] == design['id']]
        items += [{**by_name[a['glyph']], 'id': f"{name} → {a['glyph']}", 'unicode': f"U+{a['unicode']:04X}",
                   '_reference': None} for name, a in aliases.items() if a['set'] == design['id']]
        # Alphabetical order: Ё/ё follow Е/е instead of sitting outside the А…я block.
        alphabetical = lambda code: {0x401: 0x415 + 0.5, 0x451: 0x435 + 0.5}.get(code, code)
        items.sort(key=lambda r: alphabetical(int(r["unicode"][2:], 16)))
        if items:
            proof.latin_sheet(items, ttf_path, latin, out / f"proof-{design['id']}.png",
                              f"{font['family']} {font['version']} — {design['id']}",
                              **design.get('proof', {}))

    public = [{k: v for k, v in r.items() if not k.startswith('_')} for r in records.values()]
    public_designs = [{k: v for k, v in r.items() if not k.startswith('_')} for r in design_records]
    (out / 'glyphs.json').write_text(json.dumps({'font': TTF_NAME, 'glyphs': public, 'designed': public_designs,
                                                'aliases': {n: {'unicode': f"U+{a['unicode']:04X}", 'glyph': a['glyph'], 'set': a['set']}
                                                            for n, a in aliases.items()}},
                                                ensure_ascii=False, indent=2) + '\n')
    proof.sheet([records[g] for g in order], ttf_path, FILM, RESEARCH / 'references',
                out / 'proof.png', f"{font['family']} {font['version']} — glyph pipeline proof")
    failed = [r for r in public + public_designs if r['failures']]
    warned = [r for r in public + public_designs if r['warnings']]
    report = [f"# Glyph build — {font['family']} {font['version']}", '',
              f"{len(public)} glyphs · {sum(r['source'] == 'override' for r in public)} overrides · "
              f"{len(public_designs)} designed · {len(failed)} failed · {len(warned)} with warnings", '']
    if changed:
        report += ['**Frozen inputs changed (built with --allow-changed-inputs):** ' + ', '.join(changed), '']
    if drift:
        report += ['**Tool versions differ from inputs.lock.json:** ' +
                   ', '.join(f'{k} {a} → {b}' for k, (a, b) in drift.items()), '']
    report += ['| ID | source | cmap | topology (final) | IoU sheet | film / mirrored | status |',
               '|---|---|---|---|---|---|---|']
    for r in public:
        status = '; '.join(['FAIL ' + m for m in r['failures']] + ['WARN ' + m for m in r['warnings']]) or 'ok'
        topo = r['topology']['final']
        report.append(f"| {r['id']} | {r['source']} | {r['cmap']} | {topo['components']}c/{topo['holes']}h | "
                      f"{r['iou_sheet']:.3f} | {r['film_iou']} / {r['film_iou_mirrored']} | {status} |")
    if public_designs:
        report += ['', f'## Designed glyphs ({len(public_designs)})', '',
                   '| glyph | code | topology | top / bottom | status |', '|---|---|---|---|---|']
        for r in public_designs:
            topo = r['topology']['final']
            status = '; '.join(['FAIL ' + m for m in r['failures']] + ['WARN ' + m for m in r['warnings']]) or 'ok'
            report.append(f"| {r['id']} | {r['unicode']} | {topo['components']}c/{topo['holes']}h | "
                          f"{r['extent']['top']} / {r['extent']['bottom']} | {status} |")
    (out / 'report.md').write_text('\n'.join(report) + '\n')

    inputs = {rel(CONFIG): sha256(CONFIG), rel(RESEARCH / 'identifications.json'): sha256(RESEARCH / 'identifications.json'),
              **frozen_inputs(config), **{f'overrides/{p.name}': sha256(p) for p in sorted(overrides.glob('*.svg'))},
              **{rel(p): sha256(p) for p in sorted(Path(__file__).parent.glob('*.py'))},
              **{rel(p): sha256(p) for d in config.get('design', [])
                 for p in sorted(((designs_root or RESEARCH) / d['index']).parent.glob('*')) if p.suffix in ('.svg', '.toml')}}
    strict = [TTF_NAME, 'glyphs.json', *(f'glyphs/{g}.svg' for g in order),
              *(f"glyphs/{e['file']}" for e in designs.values())]
    manifest = {'inputs': inputs, 'tools': tools(),
                'outputs': {name: sha256(out / name) for name in strict},
                'review_outputs': ['proof.png', *(f"proof-{d['id']}.png" for d in config.get('design', [])),
                                   'report.md', 'raster/'],
                'result': {'glyphs': len(public), 'designed': len(public_designs), 'failed': [r['id'] for r in failed],
                           'warnings': [r['id'] for r in warned]}}
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest='command', required=True)
    run = commands.add_parser('build')
    run.add_argument('--out', type=Path, default=DEFAULT_OUT)
    run.add_argument('--allow-changed-inputs', action='store_true')
    commands.add_parser('verify')
    commands.add_parser('lock')
    adopt = commands.add_parser('adopt')
    adopt.add_argument('glyphs', nargs='+')
    adopt.add_argument('--force', action='store_true')
    args = parser.parse_args()

    if args.command == 'lock':
        config = load_config()
        LOCK.write_text(json.dumps({'files': frozen_inputs(config), 'tools': tools()}, indent=2) + '\n')
        print(f'Locked {len(frozen_inputs(config))} frozen inputs in {rel(LOCK)}')
    elif args.command == 'build':
        manifest = build(args.out.resolve(), args.allow_changed_inputs)
        result = manifest['result']
        print(f"Built {result['glyphs']} film + {result.get('designed', 0)} designed glyphs into {args.out}: "
              f"failed {result['failed'] or 'none'}, "
              f"warnings {result['warnings'] or 'none'}")
        print(f"See {args.out / 'report.md'} and {args.out / 'proof.png'}")
        sys.exit(1 if result['failed'] else 0)
    elif args.command == 'verify':
        reference = DEFAULT_OUT / 'manifest.json'
        if not reference.exists():
            sys.exit('No build to verify; run `pipeline.py build` first')
        expected = json.loads(reference.read_text())
        with tempfile.TemporaryDirectory() as tmp:
            actual = build(Path(tmp) / 'build')
        problems = [f'input changed since build: {k}' for k in sorted(set(expected['inputs']) | set(actual['inputs']))
                    if expected['inputs'].get(k) != actual['inputs'].get(k)]
        problems += [f'output differs: {k}' for k in sorted(set(expected['outputs']) | set(actual['outputs']))
                     if expected['outputs'].get(k) != actual['outputs'].get(k)]
        if problems:
            sys.exit('NOT reproducible:\n  ' + '\n  '.join(problems))
        print(f"Reproducible: {len(actual['outputs'])} strict outputs byte-identical")
    elif args.command == 'adopt':
        OVERRIDES.mkdir(exist_ok=True)
        for glyph_id in args.glyphs:
            target, built = OVERRIDES / f'{glyph_id}.svg', DEFAULT_OUT / 'glyphs' / f'{glyph_id}.svg'
            if not built.exists():
                sys.exit(f'{rel(built)} missing; run build first')
            if target.exists() and not args.force:
                sys.exit(f'{rel(target)} exists; pass --force to replace your edits')
            shutil.copyfile(built, target)
            print(f'{glyph_id}: edit {rel(target)}, then rebuild')


if __name__ == '__main__':
    main()
