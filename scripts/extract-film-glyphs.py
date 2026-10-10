"""Reconstruct a small bitmap repertoire from user-supplied film reference crops.

Requires numpy and Pillow. No OCR, generated shapes, or Unicode guesses.
Candidate rectangles are reviewed manually in glyph-candidates.png.
"""
import argparse
import json
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont


SELECTED = [0, 1, 2, 3, 5, 6, 7, 10, 15, 23, 31, 39, 46, 65, 78, 110, 112, 147, 170, 182]


def normalized(rgb):
    rgb = np.asarray(rgb, dtype=np.float32)
    # Retain neutral bright intersections. Subtracting R/B from G turns
    # desaturated white stroke junctions into artificial holes.
    signal = rgb[..., 1]
    return np.clip(signal / max(1, np.percentile(signal, 98)), 0, 1)


def aligned(sample, reference):
    best = (-1, None, None)
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            padded = np.pad(sample, 2)
            shifted = padded[2 + dy:2 + dy + sample.shape[0], 2 + dx:2 + dx + sample.shape[1]]
            a, b = shifted[3:-3, 3:-3].ravel(), reference[3:-3, 3:-3].ravel()
            score = float(np.corrcoef(a, b)[0, 1]) if a.std() > 0 else -1
            if score > best[0]:
                best = (score, shifted, [dx, dy])
    return best


def blur(signal, sigma=1.25):
    kernel = np.exp(-np.arange(-4, 5, dtype=float) ** 2 / (2 * sigma ** 2))
    kernel /= kernel.sum()
    padded = np.pad(signal, ((0, 0), (4, 4)))
    result = sum(weight * padded[:, i:i + signal.shape[1]] for i, weight in enumerate(kernel))
    padded = np.pad(result, ((4, 4), (0, 0)))
    return sum(weight * padded[i:i + signal.shape[0]] for i, weight in enumerate(kernel))


def recover_strokes(observed):
    # A conservative fixed-PSF Richardson–Lucy estimate. It sharpens recorded
    # edges but cannot recover unavailable detail or prove the original outline.
    observed = np.maximum(0, observed - 0.07)
    estimate = observed.copy() + 0.001
    for _ in range(8):
        estimate *= blur(observed / np.maximum(blur(estimate), 0.015))
    estimate = np.clip(estimate / max(0.01, np.percentile(estimate, 98)), 0, 1)
    return np.clip((estimate - 0.38) / 0.52, 0, 1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('video', type=Path)
    parser.add_argument('--candidates', type=Path, default=Path('artifacts/glyph-candidates.json'))
    parser.add_argument('--output', type=Path, default=Path('artifacts/film-glyphs'))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    candidates = json.loads(args.candidates.read_text())
    boxes = [candidates[i]['box'] for i in SELECTED]
    width, height = 3024, 1900
    start, fps, count, anchor = 1.9, 60, 13, 6
    proc = subprocess.Popen(['ffmpeg', '-loglevel', 'error', '-ss', str(start), '-i', str(args.video),
        '-frames:v', str(count), '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'], stdout=subprocess.PIPE)
    samples = [[] for _ in boxes]
    for frame in range(count):
        data = proc.stdout.read(width * height * 3)
        if len(data) != width * height * 3:
            raise RuntimeError(f'Incomplete source frame {frame}')
        image = Image.frombytes('RGB', (width, height), data)
        for group, box in zip(samples, boxes):
            group.append(image.crop(box))
    if proc.wait() != 0:
        raise RuntimeError('ffmpeg decode failed')

    font_path = '/System/Library/Fonts/Supplemental/Arial.ttf'
    font = ImageFont.truetype(font_path, 17)
    title = ImageFont.truetype(font_path, 32)
    small = ImageFont.truetype(font_path, 14)
    sheet = Image.new('RGB', (1680, 1530), '#0b0f0d')
    draw = ImageDraw.Draw(sheet)
    draw.text((28, 22), 'MATRIX / глифы из видео — проба 01', font=title, fill='#e1ebe3')
    draw.text((28, 68), '20 форм · исходник / маска штрихов / пробный glow · без дорисовки и векторизации', font=font, fill='#a2b5a9')
    atlas = Image.new('L', (5 * 64, 4 * 80))
    metadata = []
    for index, (source_id, box, group) in enumerate(zip(SELECTED, boxes, samples)):
        reference = normalized(group[anchor])
        accepted, observations = [], []
        for frame, crop in enumerate(group):
            rgb = np.asarray(crop, dtype=float)
            bright = rgb[..., 1] > max(20, np.percentile(rgb[..., 1], 85))
            neutral = float(np.mean(rgb[..., 0][bright] / np.maximum(1, rgb[..., 1][bright])))
            score, shifted, offset = aligned(normalized(crop), reference)
            # Never average a replacement glyph or a white head flash into this shape.
            if score >= 0.92 and neutral < 0.5:
                accepted.append(shifted)
                observations.append({'time': round(start + frame / fps, 5), 'correlation': round(score, 4), 'offset': offset})
        if not accepted:
            raise RuntimeError(f'No trustworthy observations for glyph {source_id}')
        median = np.median(accepted, axis=0)
        alpha = recover_strokes(median)
        mask = Image.fromarray(np.uint8(alpha * 255))
        name = f'g{index + 1:02d}'
        mask.save(args.output / f'{name}-mask.png')
        group[anchor].save(args.output / f'{name}-source.png')
        slot = ((index % 5) * 64 + 12, (index // 5) * 80 + 11)
        atlas.paste(mask, slot)
        rgba = Image.new('RGBA', mask.size, (255, 255, 255, 0))
        rgba.putalpha(mask)
        rgba.save(args.output / f'{name}.png')
        glow = np.asarray(mask.filter(ImageFilter.GaussianBlur(2.2)), dtype=float) / 255
        result = np.stack([alpha * 0.04 + glow * 0.03, alpha * 0.63 + glow * 0.30, alpha * 0.36 + glow * 0.16], axis=-1)
        rendered = Image.fromarray(np.uint8(np.clip(result, 0, 1) * 255))
        x, y = 24 + index % 4 * 414, 116 + index // 4 * 278
        draw.rounded_rectangle((x, y, x + 402, y + 266), radius=9, fill='#121a16', outline='#263a2d')
        draw.text((x + 13, y + 9), f'{name.upper()}   ·   {len(accepted)} кадров', font=font, fill='#c4d6c9')
        for j, (label, im) in enumerate([('ИСХОДНИК', group[anchor]), ('МАСКА', mask.convert('RGB')), ('RENDER', rendered)]):
            px = x + 13 + j * 129
            draw.text((px, y + 40), label, font=small, fill='#849e8e')
            enlarged = im.resize((im.width * 3, im.height * 3), Image.Resampling.NEAREST)
            sheet.paste(enlarged, (px, y + 66))
        metadata.append({'id': name, 'candidate': source_id, 'source_box': box, 'source_time': 2.0,
            'atlas_box': [*slot, slot[0] + mask.width, slot[1] + mask.height],
            'ink_box': mask.getbbox(), 'observations': observations})
        print(name, 'candidate', source_id, 'frames', len(accepted), 'ink', mask.getbbox(), flush=True)
    draw.text((28, 1510), 'Увеличение 3×. Маска — оценка формы из записи; мелкие детали ограничены разрешением и компрессией видео.', font=small, fill='#8ca395')
    atlas.save(args.output / 'atlas.png')
    sheet.save(args.output / 'comparison.png')
    (args.output / 'manifest.json').write_text(json.dumps({'source': str(args.video), 'source_resolution': [width, height],
        'method': 'Registered temporal median, green channel retaining neutral highlights, 8-step Richardson-Lucy with assumed sigma 1.25px, soft threshold. No Unicode assignment.',
        'atlas_size': list(atlas.size), 'glyphs': metadata}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
