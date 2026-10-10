"""Rendering helpers and the review proof sheet."""
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFont

LABEL_FONT = '/System/Library/Fonts/Supplemental/Arial.ttf'


def render(ttf_path, codepoint, size):
    """Rasterise one glyph from the built TTF through FreeType (end-to-end check of the file)."""
    font = ImageFont.truetype(str(ttf_path), size)
    text = chr(codepoint)
    x0, y0, x1, y1 = font.getbbox(text)
    image = Image.new('L', (x1 - x0 + 8, y1 - y0 + 8), 0)
    ImageDraw.Draw(image).text((4 - x0, 4 - y0), text, font=font, fill=255)
    return np.asarray(image) >= 128


def _tile(mask, height, color=(225, 240, 228), background=(8, 12, 10)):
    ys, xs = np.nonzero(mask)
    if ys.size:
        mask = mask[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    rgb = np.empty(mask.shape + (3,), dtype=np.uint8)
    rgb[...] = background
    rgb[mask] = color
    image = Image.fromarray(rgb)
    width = max(1, round(image.width * height / max(1, image.height)))
    return image.resize((width, height), Image.Resampling.LANCZOS)


def _overlay(source, final, height):
    """Green = both, red = only in the sheet raster, blue = only in the outline."""
    from raster import crop_to_ink
    a, b = crop_to_ink(source), crop_to_ink(final)
    h, w = max(a.shape[0], b.shape[0]), max(a.shape[1], b.shape[1])
    pa = np.zeros((h, w), bool); pa[:a.shape[0], :a.shape[1]] = a
    pb = np.zeros((h, w), bool); pb[:b.shape[0], :b.shape[1]] = b
    rgb = np.zeros((h, w, 3), np.uint8); rgb[...] = (8, 12, 10)
    rgb[pa & pb] = (60, 170, 95)
    rgb[pa & ~pb] = (235, 70, 60)
    rgb[~pa & pb] = (70, 140, 255)
    image = Image.fromarray(rgb)
    return image.resize((max(1, round(w * height / h)), height), Image.Resampling.NEAREST)


def sheet(records, ttf_path, film_dir, references_dir, out_path, title):
    columns, card_w, card_h, tile_h = 4, 520, 280, 124
    rows = (len(records) + columns - 1) // columns
    width, height = 24 + columns * (card_w + 14), 110 + rows * (card_h + 14) + 200
    image = Image.new('RGB', (width, height), '#0b0f0d')
    draw = ImageDraw.Draw(image)
    big, font, small = (ImageFont.truetype(LABEL_FONT, s) for s in (28, 16, 13))
    draw.text((24, 20), title, font=big, fill='#e1ebe3')
    draw.text((24, 62), 'film frame · film mask · sheet raster · outline from TTF · overlay '
              '(green both, red sheet only, blue outline only)', font=small, fill='#93a69a')
    for index, record in enumerate(records):
        x = 24 + index % columns * (card_w + 14)
        y = 100 + index // columns * (card_h + 14)
        ok = not record['failures']
        draw.rounded_rectangle((x, y, x + card_w, y + card_h), radius=9, fill='#121a16',
                               outline='#2f5a3c' if ok and not record['warnings'] else '#8a6d1f' if ok else '#a33a2c', width=2)
        draw.text((x + 12, y + 10), f"{record['id']}  {record['source']}  {record['cmap']}", font=font, fill='#d6e6da')
        px = x + 12
        frame_path = references_dir / f"{record['id'].lower()}-source.png"
        tiles = []
        if frame_path.exists():
            tiles.append(Image.open(frame_path).convert('RGB').resize((round(tile_h * 40 / 59), tile_h), Image.Resampling.NEAREST))
        film = film_dir / f"{record['id']}.png"
        if film.exists():
            tiles.append(_tile(np.asarray(Image.open(film).convert('L')) >= 128, tile_h))
        tiles += [_tile(record['_source'], tile_h), _tile(record['_final'], tile_h),
                  _overlay(record['_source'], record['_final'], tile_h)]
        for tile in tiles:
            if px + tile.width > x + card_w - 8:
                break
            image.paste(tile, (px, y + 40))
            px += tile.width + 8
        topo = record['topology']
        compact = lambda t: f"{t.get('components', '?')}c/{t.get('holes', '?')}h"
        lines = [f"topology {compact(topo['final'])} (expected {compact(topo['expected'])}, sheet {compact(topo['sheet'])})",
                 f"IoU sheet {record['iou_sheet']:.3f}   film {record['film_iou']} / mirrored {record['film_iou_mirrored']}"]
        lines += [f'FAIL {m}' for m in record['failures']] + [f'WARN {m}' for m in record['warnings']]
        for line_index, line in enumerate(lines[:6]):
            color = '#ff8a7a' if line.startswith('FAIL') else '#e7c66b' if line.startswith('WARN') else '#a9bdb0'
            draw.text((x + 12, y + 176 + line_index * 17), line[:80], font=small, fill=color)

    # A deterministic rain strip rendered with the built font.
    rain_font = ImageFont.truetype(str(ttf_path), 30)
    codes = [record['pua'] for record in records]
    rng = random.Random(7)
    top = height - 190
    draw.text((24, top - 4), 'rain sample (built font, 30 px)', font=small, fill='#93a69a')
    for column in range((width - 48) // 22):
        for row in range(6):
            shade = 255 if row == 5 and rng.random() < 0.4 else int(90 + 120 * rng.random())
            draw.text((24 + column * 22, top + 18 + row * 27), chr(rng.choice(codes)), font=rain_font,
                      fill=(int(shade * 0.35), shade, int(shade * 0.55)) if shade < 255 else (230, 255, 236))
    image.save(out_path, optimize=False)


def latin_sheet(records, ttf_path, latin, out_path, title, sample='Hxgbk 08', texts=None):
    """Designed glyphs on the metric lines, next to the specimen they were drawn from."""
    lines = [('ascender', latin['ascender']), ('cap height', latin['cap_height']),
             ('x-height', latin['x_height']), ('baseline', 0), ('descender', latin['descender'])]
    columns, cell_w, cell_h, em = 13, 160, 300, 170
    rows = (len(records) + columns - 1) // columns
    width = 40 + columns * cell_w
    header, samples = 470, 330
    image = Image.new('RGB', (width, header + rows * cell_h + samples), '#0b0f0d')
    draw = ImageDraw.Draw(image)
    big, font, small = (ImageFont.truetype(LABEL_FONT, s) for s in (28, 16, 13))
    draw.text((24, 20), title, font=big, fill='#e1ebe3')
    draw.text((24, 60), 'one system for every glyph: metric lines, broad-nib weight (vertical heavier than '
              'horizontal), rounded joins, square ends, tapered sweeps', font=small, fill='#93a69a')

    # Metric diagram, rendered from the built font.
    size, base = 300, 380
    glyph_font = ImageFont.truetype(str(ttf_path), size)
    unit = size / 1024
    for name, y in lines:
        yy = base - y * unit
        draw.line((24, yy, width - 24, yy), fill='#2f5a3c' if name != 'baseline' else '#5f9f72', width=1)
        # Close lines (ascender / cap height) get their labels on opposite sides of the line.
        anchor, dy = ('rb', -3) if name == 'ascender' else ('rt', 3)
        draw.text((width - 24, yy + dy), f'{name} {y}', font=small, fill='#93a69a', anchor=anchor)
    draw.text((40, base), sample, font=glyph_font, fill='#5dff9a', anchor='ls')

    label_font = ImageFont.truetype(str(ttf_path), em)
    unit = em / 1024
    for index, record in enumerate(records):
        x = 20 + index % columns * cell_w
        y = header + index // columns * cell_h
        ok = not record['failures']
        draw.rounded_rectangle((x, y, x + cell_w - 8, y + cell_h - 8), radius=8, fill='#121a16',
                               outline='#2f5a3c' if ok else '#a33a2c', width=2)
        reference = record.get('_reference')
        box = record.get('_reference_box')
        if reference and box:
            crop = Image.open(reference).convert('RGB').crop(tuple(box))
            crop = crop.resize((round(crop.width * 60 / crop.height), 60), Image.Resampling.LANCZOS)
            image.paste(crop, (x + cell_w - 14 - crop.width, y + 8))
        draw.text((x + 10, y + 8), f"{chr(int(record['unicode'][2:], 16))}  {record['id']}", font=font, fill='#d6e6da')
        draw.text((x + 10, y + 30), record['unicode'], font=small, fill='#93a69a')
        baseline = y + 225
        for _, value in lines:
            yy = baseline - value * unit
            draw.line((x + 6, yy, x + cell_w - 14, yy), fill='#20372a')
        draw.text((x + (cell_w - 8) / 2, baseline), chr(int(record['unicode'][2:], 16)), font=label_font,
                  fill='#e8f5ec', anchor='ms')
        topo = record['topology']['final']
        status = 'ok' if ok else 'FAIL'
        draw.text((x + 10, y + cell_h - 30), f"{topo['components']}c/{topo['holes']}h  {status}", font=small,
                  fill='#a9bdb0' if ok else '#ff8a7a')

    text_font = ImageFont.truetype(str(ttf_path), 64)
    top = header + rows * cell_h + 20
    for i, line in enumerate(texts or ['WAKE UP NEO', 'THE MATRIX HAS YOU', 'follow the white rabbit', 'knock knock 0123456789']):
        draw.text((24, top + 40 + i * 72), line, font=text_font, fill='#5dff9a', anchor='ls')
    image.save(out_path, optimize=False)
