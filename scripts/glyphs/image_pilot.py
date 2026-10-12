#!/usr/bin/env python3
"""Trace an image-generation candidate into an editable SVG and an isolated test font.

Never writes production outlines or fonts. Existing SVGs are respected unless
--retrace is explicitly supplied; raster-to-vector fidelity is reported separately
from artistic approval and is not a measure of resemblance to the film.
"""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from fontTools.misc.transform import Transform

import font as font_builder
import proof
import raster
import vector

ROOT = Path(__file__).resolve().parents[2]


def prepare(experiment, candidate, retrace=False):
    config = json.loads((experiment / 'manifest.json').read_text())
    image_path = experiment / candidate
    gray = raster.load_gray(image_path)
    mask = gray < config['trace']['threshold']
    if not mask.any():
        raise ValueError('Candidate has no ink')
    ys, xs = np.nonzero(mask)
    box = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
    x0, y0, x1, y1 = box
    # Keep a white margin around the trace to avoid cropping away edge antialiasing.
    gray = np.pad(gray[y0:y1, x0:x1], 4, constant_values=1)
    mask = gray < config['trace']['threshold']
    name = Path(candidate).stem
    output = ROOT / 'research/glyphs/build/image-pilot' / experiment.name / name
    output.mkdir(parents=True, exist_ok=True)
    svg_path = experiment / f'{name}.svg'
    font = dict(config['font'])
    font['family'] += ' ' + name
    trace = config['trace']
    if retrace or not svg_path.exists():
        scale = (font['body_top'] - font['body_bottom']) / (y1 - y0)
        placement = Transform(scale, 0, 0, -scale,
                              font['advance'] / 2 - gray.shape[1] * scale / 2,
                              font['body_bottom'] + (gray.shape[0] - 4) * scale)
        path = vector.clean(vector.read_svg(vector.trace(gray, trace),
                            placement.scale(1 / trace['upscale'])))
        svg_path.write_text(vector.write_svg(path, font, config['glyph'],
                            f'image pilot traced from {candidate}; unapproved'))
    svg = svg_path.read_text()
    vector.check_viewbox(svg, font, svg_path.name)
    path = vector.clean(vector.read_svg(svg, Transform(1, 0, 0, -1, 0, font['ascent'])))
    ttf = font_builder.build({config['glyph']: path},
                            {config['codepoint']: config['glyph']}, font, trace)
    ttf_path = output / 'pilot.ttf'
    ttf.save(ttf_path)
    # Render the TTF at the source's ink height, preserving the source aspect ratio.
    source_height = y1 - y0
    size = round(source_height * font['upm'] / (font['body_top'] - font['body_bottom']))
    final = proof.render(ttf_path, config['codepoint'], size)
    iou = raster.iou_aligned(mask, final)
    topology = {'source': raster.topology(mask, 4), 'font': raster.topology(final, 4)}
    failures, warnings = [], []
    for stage, actual in topology.items():
        if actual != config['expected']:
            failures.append(f'{stage} topology {actual} != {config["expected"]}')
    if iou < config['minimum_trace_iou']:
        failures.append(f'Trace IoU {iou:.4f} below {config["minimum_trace_iou"]}')
    winding = font_builder.winding_errors(ttf)
    if winding:
        failures.append(f'Invalid winding: {winding}')
    if path.bounds[0] < 0 or path.bounds[2] > font['advance']:
        failures.append('Outline extends beyond the advance cell')
    sizes = {}
    for pixel_size in (20, 26, 32, 48):
        small = proof.render(ttf_path, config['codepoint'], pixel_size)
        sizes[str(pixel_size)] = raster.topology(small, 1)
        if sizes[str(pixel_size)] != config['expected']:
            messages = failures if pixel_size >= config['minimum_font_size'] else warnings
            messages.append(f'Topology lost at {pixel_size}px: {sizes[str(pixel_size)]}')
    ratio = (x1 - x0) / (y1 - y0)
    proportions = config['proportions']
    if abs(ratio - proportions['target_ink_width_over_height']) > proportions['tolerance']:
        warnings.append(f'Generated aspect ratio {ratio:.4f} needs review')
    report = {
        'candidate': candidate, 'sha256': hashlib.sha256(image_path.read_bytes()).hexdigest(),
        'svg_sha256': hashlib.sha256(svg_path.read_bytes()).hexdigest(),
        'ink_box': box, 'aspect_ratio': round((x1 - x0) / (y1 - y0), 4),
        'topology': topology, 'trace_iou': round(iou, 5),
        'font_bounds': list(path.bounds), 'contours': len(list(path.contours)),
        'segments': len(list(path.segments)), 'small_sizes': sizes,
        'failures': failures, 'warnings': warnings,
        'artistic_status': 'review required; these checks do not establish film fidelity',
    }
    (output / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    return config, ttf_path, report, output


def make_proof(config, fonts, out):
    """A static proof from actual test TTFs, not a capture of the application."""
    width, height = 1100, 870
    image = Image.new('RGB', (width, height), '#f7f6f1')
    draw = ImageDraw.Draw(image)
    label = ImageFont.truetype(proof.LABEL_FONT, 20)
    small = ImageFont.truetype(proof.LABEL_FONT, 16)
    draw.text((32, 24), 'G04 / KATAKANA O — IMAGE TO SVG TO TEST FONT', font=label, fill='#162820')
    draw.text((32, 57), 'Generated candidates; technical proof only. Film-style approval pending.', font=small, fill='#536359')
    for i, (name, font_path, report) in enumerate(fonts):
        x = 32 + i * 540
        draw.text((x, 98), name, font=label, fill='#162820')
        glyph_font = ImageFont.truetype(str(font_path), 530)
        draw.text((x + 240, 560), chr(config['codepoint']), font=glyph_font, anchor='ms', fill='#102e22')
        draw.text((x, 584), f'Trace IoU {report["trace_iou"]:.3f} | {report["contours"]} contour | {report["segments"]} segments', font=small, fill='#536359')
        for row, size in enumerate((20, 26, 32, 48)):
            y = 628 + row * 51
            draw.text((x, y), f'{size} px', font=small, fill='#536359')
            draw.rectangle((x + 72, y - 4, x + 488, y + 43), fill='#020705')
            f = ImageFont.truetype(str(font_path), size)
            for j in range(10):
                draw.text((x + 86 + j * 38, y + 34), chr(config['codepoint']), font=f,
                          anchor='ls', fill=('#1e7549', '#32c77b', '#c9ffe1')[j % 3])
    image.save(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('experiment', type=Path)
    parser.add_argument('--candidates', nargs='+', default=['candidate.png'])
    parser.add_argument('--retrace', action='store_true', help='Replace candidate SVGs; discards manual edits')
    args = parser.parse_args()
    if len(args.candidates) > 2:
        parser.error('Proof supports at most two candidates per comparison')
    fonts, failures = [], []
    for candidate in args.candidates:
        config, ttf, report, out = prepare(args.experiment, candidate, args.retrace)
        fonts.append((Path(candidate).stem, ttf, report))
        failures += report['failures']
        print(json.dumps(report, ensure_ascii=False))
    proof_path = out.parent / 'proof.png'
    make_proof(config, fonts, proof_path)
    print(f'Proof: {proof_path}')
    if failures:
        raise SystemExit('\n'.join(failures))


if __name__ == '__main__':
    main()
