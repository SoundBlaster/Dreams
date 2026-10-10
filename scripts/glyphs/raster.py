"""Raster side of the pipeline: sheet segmentation, topology and shape comparison."""
from dataclasses import dataclass

import numpy as np
from PIL import Image
from scipy import ndimage

EIGHT = np.ones((3, 3), dtype=bool)


@dataclass
class Slice:
    glyph_id: str
    sheet_id: str
    row: int
    gray: np.ndarray        # cell crop, 0 = ink, 1 = paper; foreign ink painted out
    mask: np.ndarray        # boolean ink of this glyph only, same frame as gray
    origin: tuple           # (x, y) of the crop in sheet pixels
    ink_box: tuple          # (x0, y0, x1, y1) in sheet pixels, exclusive end
    row_top: float = 0.0
    row_bottom: float = 0.0


def load_gray(path):
    return np.asarray(Image.open(path).convert('L'), dtype=np.float32) / 255


def bands(profile, count, axis_name):
    """Split a projection profile into `count` ink bands at the widest empty gaps."""
    filled = np.flatnonzero(profile > 0)
    if filled.size == 0:
        raise ValueError(f'no ink along {axis_name}')
    start, end = filled[0], filled[-1] + 1
    gaps, run = [], None
    for i in range(start, end):
        if profile[i] == 0 and run is None:
            run = i
        elif profile[i] > 0 and run is not None:
            gaps.append((i - run, run, i))
            run = None
    if len(gaps) < count - 1:
        raise ValueError(f'expected {count} {axis_name} bands, found only {len(gaps) + 1}; '
                         'check columns/rows in pipeline.toml')
    cuts = sorted(gaps, key=lambda g: (-g[0], g[1]))[:count - 1]
    edges = [start] + [(a + b) // 2 for _, a, b in sorted(cuts, key=lambda g: g[1])] + [end]
    return list(zip(edges[:-1], edges[1:]))


def segment_sheet(path, sheet, threshold, min_area):
    gray = load_gray(path)
    ink = gray < threshold
    labels, count = ndimage.label(ink, structure=EIGHT)
    sizes = ndimage.sum(ink, labels, index=np.arange(1, count + 1))
    keep = np.zeros(count + 1, dtype=bool)
    keep[1:] = sizes >= min_area
    ink = keep[labels]
    rows = bands(ink.sum(axis=1), sheet['rows'], 'row')
    cols = bands(ink.sum(axis=0), sheet['columns'], 'column')
    ids = sheet['glyphs']
    if len(ids) != len(rows) * len(cols):
        raise ValueError(f"sheet {sheet['id']}: {len(ids)} ids for {len(rows)}x{len(cols)} cells")

    def band_index(value, spans):
        return min(range(len(spans)), key=lambda i: 0 if spans[i][0] <= value < spans[i][1]
                   else min(abs(value - spans[i][0]), abs(value - spans[i][1])))

    owner = {}
    for index, box in enumerate(ndimage.find_objects(labels), start=1):
        if box is None or not keep[index]:
            continue
        cy = (box[0].start + box[0].stop) / 2
        cx = (box[1].start + box[1].stop) / 2
        owner[index] = band_index(cy, rows) * len(cols) + band_index(cx, cols)

    slices = []
    pad = 6
    for cell, glyph_id in enumerate(ids):
        members = [label for label, c in owner.items() if c == cell]
        if not members:
            raise ValueError(f"sheet {sheet['id']}: cell {cell} ({glyph_id}) is empty")
        own = np.isin(labels, members)
        ys, xs = np.nonzero(own)
        x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
        cx0, cy0 = max(0, x0 - pad), max(0, y0 - pad)
        cx1, cy1 = min(gray.shape[1], x1 + pad), min(gray.shape[0], y1 + pad)
        region = own[cy0:cy1, cx0:cx1]
        # Keep anti-aliased edges of this glyph, paint out neighbours' ink.
        near = ndimage.binary_dilation(region, structure=EIGHT, iterations=2)
        crop = np.where(near, gray[cy0:cy1, cx0:cx1], 1.0)
        slices.append(Slice(glyph_id, sheet['id'], cell // len(cols), crop, region,
                            (int(cx0), int(cy0)), (int(x0), int(y0), int(x1), int(y1))))

    for row in range(len(rows)):
        members = [s for s in slices if s.row == row]
        if 'body_bounds' in sheet:
            # Explicit cell metrics keep punctuation small. Inferring cap height
            # from short marks would otherwise stretch an all-punctuation row.
            top, bottom = map(float, sheet['body_bounds'])
            cell_height = gray.shape[0] / sheet['rows']
            if not 0 <= top < bottom <= cell_height:
                raise ValueError(f"sheet {sheet['id']}: invalid body_bounds")
            top += row * cell_height
            bottom += row * cell_height
        else:
            top = float(np.median([s.ink_box[1] for s in members]))
            bottom = float(np.median([s.ink_box[3] for s in members]))
        for s in members:
            s.row_top, s.row_bottom = top, bottom
    return slices


def topology(mask, min_area):
    """Count ink components (8-connected) and enclosed holes (4-connected paper)."""
    labels, count = ndimage.label(mask, structure=EIGHT)
    sizes = ndimage.sum(mask, labels, index=np.arange(1, count + 1)) if count else []
    components = int(np.sum(np.asarray(sizes) >= min_area))
    paper = np.pad(~mask, 1, constant_values=True)
    labels, count = ndimage.label(paper)
    outside = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]])))
    sizes = ndimage.sum(paper, labels, index=np.arange(1, count + 1)) if count else []
    holes = sum(1 for i, size in enumerate(sizes, start=1) if i not in outside and size >= min_area)
    return {'components': components, 'holes': int(holes)}


def crop_to_ink(mask):
    ys, xs = np.nonzero(mask)
    if ys.size == 0:
        return mask[:0, :0]
    return mask[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def iou_aligned(a, b, search=3):
    """IoU of two ink-cropped masks at the same scale, best over small shifts."""
    a, b = crop_to_ink(a), crop_to_ink(b)
    h, w = max(a.shape[0], b.shape[0]) + 2 * search, max(a.shape[1], b.shape[1]) + 2 * search
    canvas = np.zeros((h, w), dtype=bool)
    canvas[search:search + a.shape[0], search:search + a.shape[1]] = a
    best = 0.0
    for dy in range(2 * search + 1):
        for dx in range(2 * search + 1):
            other = np.zeros((h, w), dtype=bool)
            if dy + b.shape[0] > h or dx + b.shape[1] > w:
                continue
            other[dy:dy + b.shape[0], dx:dx + b.shape[1]] = b
            union = np.logical_or(canvas, other).sum()
            if union:
                best = max(best, float(np.logical_and(canvas, other).sum() / union))
    return best


def normalized(mask, size=(36, 54)):
    """Stretch the ink box to a fixed frame so differently scaled shapes compare."""
    ink = crop_to_ink(mask)
    image = Image.fromarray(np.uint8(ink) * 255).resize(size, Image.Resampling.BILINEAR)
    return np.asarray(image) >= 128


def film_scores(final_mask, film_mask):
    ours, film = normalized(final_mask), normalized(film_mask)
    direct = iou_aligned(ours, film, search=2)
    mirrored = iou_aligned(ours[:, ::-1], film, search=2)
    return round(direct, 4), round(mirrored, 4)
