"""Generator of the designed Latin + digit set in the calligraphic film style.

Skeletons follow the user's katakana-styled Latin specimen; the drawing follows the
reconstructed film glyphs. One system governs every glyph ([latin] in pipeline.toml):

* lines: baseline 0, x-height, cap height, ascender, descender, overshoot;
* weight: a broad-nib law — a stroke's width depends on its direction, from `stem`
  (vertical) to `hair` (horizontal); lowercase is `lowercase_ratio` lighter;
* joins: outer corners are rounded by an ellipse made of the two meeting widths;
* terminals: straight strokes end square (softened); strokes that descend diagonally
  sweep and taper to a rounded point, like a brush release (cf. film G03, G13, G15).

Strokes are painted at 1 px per font unit, softened and traced with potrace into a
smooth editable outline. Deterministic for fixed inputs. Regenerating never
overwrites an SVG edited after generation.

  .venv/bin/python scripts/glyphs/latin.py              # write missing / unedited SVGs
  .venv/bin/python scripts/glyphs/latin.py --force A g  # regenerate even if edited
"""
import argparse
import hashlib
import math
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from fontTools.misc.transform import Transform
from fontTools.pens.svgPathPen import SVGPathPen
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
import vector  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / 'research/glyphs/pipeline.toml'
CANVAS_TOP, CANVAS_HEIGHT = 1000, 1400   # pixel row 0 = font y 1000; rows reach y -400

# Specimen grid (references/latin-specimen-v1.png): 13 columns from x=28, ~113.9 px each.
SPECIMEN_ROWS = {'upper': [(150, 250), (318, 414)], 'lower': [(486, 592), (642, 742)], 'digit': [(822, 926)]}


class Q:
    """Quadratic segment inside a stroke path: Q(control, end)."""
    def __init__(self, control, end):
        self.control, self.end = control, end


class System:
    """Metric and weight rules from [latin]; geometry helpers derived from them."""

    def __init__(self, rules, lowercase=False):
        self.r = rules
        k = rules['lowercase_ratio'] if lowercase else 1.0
        self.stem, self.hair = rules['stem'] * k, rules['hair'] * k
        self.tip, self.soften = rules['taper_tip'], rules['soften']
        self.C, self.X = rules['cap_height'], rules['x_height']
        self.A, self.D, self.o = rules['ascender'], rules['descender'], rules['overshoot']
        self.tail = rules['tail']
        top = self.X if lowercase else self.C
        self.top = top
        self.yt, self.yb = top - self.hair / 2, self.hair / 2               # top / bottom bar centres
        self.ym = (rules['lower_crossbar'] if lowercase else rules['crossbar']) * top
        self.yd = self.D + self.hair / 2                                    # descender bar centre
        self.tip_low = self.tip / 2 - self.o                                # tapered tip on the baseline
        self.tip_desc = self.D + self.tip / 2 - self.o                      # ... on the descender

    def frame(self, width_key):
        width = self.r['widths'][width_key]
        left, right = 478 - width / 2, 478 + width / 2
        return left, right, left + self.stem / 2, right - self.stem / 2, 478.0

    def width(self, ux, uy):
        """Broad-nib law: vertical strokes get `stem`, horizontal ones `hair`."""
        sin2 = uy * uy / (ux * ux + uy * uy)
        return self.hair + (self.stem - self.hair) * sin2

    def stroke(self, *path, start='cut', end='cut', taper=0.45, weight=1.0):
        return {'path': path, 'start': start, 'end': end, 'taper': taper, 'sys': self, 'weight': weight}

    def loop(self, x0, y0, x1, y1, r=0, weight=1.0):
        """Closed rectangle-like loop between centre lines, optionally with round corners r."""
        xc = (x0 + x1) / 2
        if not r:
            return self.stroke((xc, y0), (x0, y0), (x0, y1), (x1, y1), (x1, y0), (xc - 30, y0), weight=weight)
        return self.stroke((xc, y0), (x0 + r, y0), Q((x0, y0), (x0, y0 + r)), (x0, y1 - r),
                           Q((x0, y1), (x0 + r, y1)), (x1 - r, y1), Q((x1, y1), (x1, y1 - r)),
                           (x1, y0 + r), Q((x1, y0), (x1 - r, y0)), (xc - 30, y0), weight=weight)

    def dot(self, x, y, weight=1.0):
        half = self.hair * 0.2 * weight
        return self.stroke((x, y - half), (x, y + half), start='round', end='round', weight=weight)


# --- painting -----------------------------------------------------------------------

def _runs(path):
    runs, current = [], [path[0]]
    for item in path[1:]:
        if isinstance(item, Q):
            p0, c, p1 = current[-1], item.control, item.end
            current += [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t * t * p1[0],
                         (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t * t * p1[1])
                        for t in (i / 32 for i in range(1, 33))]
            runs.append(current)
            current = [item.end]
        else:
            current.append(item)
            runs.append(current)
            current = [item]
    return runs


def _cut(spec, u):
    if spec == 'h':
        return 1.0, 0.0
    if spec == 'v':
        return 0.0, 1.0
    if isinstance(spec, (int, float)):
        a = math.radians(spec)
        return math.cos(a), math.sin(a)
    return -u[1], u[0]


def _meet(p, d, q, e):
    det = d[0] * e[1] - d[1] * e[0]
    if abs(det) < 1e-9:
        return q
    t = ((q[0] - p[0]) * e[1] - (q[1] - p[1]) * e[0]) / det
    return p[0] + t * d[0], p[1] + t * d[1]


def _direction(a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    n = math.hypot(dx, dy)
    return dx / n, dy / n


def paint(strokes, soften):
    image = Image.new('L', (956, CANVAS_HEIGHT), 0)
    draw = ImageDraw.Draw(image)
    px = lambda p: (p[0], CANVAS_TOP - p[1])

    for s in strokes:
        sys_ = s['sys']
        runs = _runs(s['path'])
        flat = [runs[0][0]] + [p for run in runs for p in run[1:]]
        lengths = [0.0]
        for a, b in zip(flat, flat[1:]):
            lengths.append(lengths[-1] + math.hypot(b[0] - a[0], b[1] - a[1]))
        total, zone = lengths[-1], s['taper'] * lengths[-1]

        def width(base, distance):
            w = base
            for kind, u in (('start', distance), ('end', total - distance)):
                if s[kind] == 'taper' and u < zone:
                    k = 1 - u / zone
                    w = min(w, sys_.tip + (base - sys_.tip) * (1 - k ** 1.7))
            return w

        index, run_widths = 0, []
        for number, run in enumerate(runs):
            dists = lengths[index:index + len(run)]
            index += len(run) - 1
            left, right = [], []
            for i, p in enumerate(run):
                u = _direction(run[max(0, i - 1)], run[min(len(run) - 1, i + 1)])
                h = width(sys_.width(*u) * s['weight'], dists[i]) / 2
                l_pt, r_pt = (p[0] - u[1] * h, p[1] + u[0] * h), (p[0] + u[1] * h, p[1] - u[0] * h)
                first, last = number == 0 and i == 0, number == len(runs) - 1 and i == len(run) - 1
                spec = s['start'] if first else s['end'] if last else None
                if spec not in (None, 'cut', 'round', 'taper'):
                    c = _cut(spec, u)
                    l_pt, r_pt = _meet(l_pt, u, p, c), _meet(r_pt, u, p, c)
                left.append(l_pt)
                right.append(r_pt)
            draw.polygon([px(p) for p in left + right[::-1]], fill=255)
            run_widths.append((_direction(run[0], run[1]), _direction(run[-2], run[-1]), dists))
        # Round joins: an ellipse built from the two meeting widths keeps the outer
        # corner radius equal to each stroke's own half-width.
        for number in range(len(runs) - 1):
            p = runs[number][-1]
            u1, u2 = run_widths[number][1], run_widths[number + 1][0]
            d = run_widths[number][2][-1]
            w1, w2 = width(sys_.width(*u1) * s['weight'], d), width(sys_.width(*u2) * s['weight'], d)
            vertical = [w for w, u in ((w1, u1), (w2, u2)) if abs(u[1]) > abs(u[0])]
            horizontal = [w for w, u in ((w1, u1), (w2, u2)) if abs(u[1]) <= abs(u[0])]
            rx = (max(vertical) if vertical and horizontal else max(w1, w2)) / 2
            ry = (max(horizontal) if vertical and horizontal else max(w1, w2)) / 2
            x, y = px(p)
            draw.ellipse((x - rx, y - ry, x + rx, y + ry), fill=255)
        for kind, p, u in (('start', flat[0], _direction(flat[0], flat[1])), ('end', flat[-1], _direction(flat[-2], flat[-1]))):
            x, y = px(p)
            if s[kind] == 'round':
                r = sys_.width(*u) * s['weight'] / 2
                draw.ellipse((x - r, y - r, x + r, y + r), fill=255)
            elif s[kind] == 'taper':
                r = sys_.tip / 2
                draw.ellipse((x - r, y - r, x + r, y + r), fill=255)
    mask = np.asarray(image) >= 128
    yy, xx = np.mgrid[-soften:soften + 1, -soften:soften + 1]
    return ndimage.binary_opening(mask, structure=xx ** 2 + yy ** 2 <= soften ** 2)


def trace(mask):
    with tempfile.TemporaryDirectory() as tmp:
        source = Path(tmp) / 'glyph.pbm'
        Image.fromarray(np.where(mask, 0, 255).astype(np.uint8)).convert('1').save(source)
        result = subprocess.run(['potrace', '--backend', 'svg', '--output', '-', '--turdsize', '4',
                                 '--alphamax', '1.0', '--opttolerance', '0.5', str(source)],
                                check=True, capture_output=True, text=True)
    return result.stdout


# --- glyphs -------------------------------------------------------------------------
# Each glyph: unicode, (components, holes), (top line, bottom line), strokes.
# Lines: 'cap', 'x', 'asc', 'base', 'desc', or 'free' (punctuation-like marks).

def glyphs(rules):
    g = {}
    U, l = System(rules), System(rules, lowercase=True)

    def add(name, code, topology, lines, *strokes):
        g[name] = {'unicode': code, 'expect': topology, 'lines': lines, 'strokes': list(strokes)}

    # ---- capitals ----
    s = U
    L, R, xl, xr, xc = s.frame('cap')
    C, yt, yb, ym = s.C, s.yt, s.yb, s.ym
    add('A', 0x41, (1, 1), ('cap', 'base'),
        s.stroke((xc + 12, C), Q((xc - 45, 300), (L - 5, s.tip_low)), start='h', end='taper', taper=0.5),
        s.stroke((xc + 12, C), (R - 35, 0), start='h', end='h'),
        s.stroke((xc - 110, 0.33 * C), (xc + 150, 0.33 * C)))
    add('B', 0x42, (1, 2), ('cap', 'base'),
        s.stroke((xl, 0), (xl, C), start='h', end='h'),
        s.stroke((L, yt), (xr - 50, yt), (xr - 50, ym), (L, ym), start='v', end='v'),
        s.stroke((L, ym), (xr, ym), (xr, yb), (L, yb), start='v', end='v'))
    add('C', 0x43, (1, 0), ('cap', 'base'),
        s.stroke((R, yt), (xl, yt), (xl, 300), Q((xl, yb + 10), (R + 15, s.tip_low + 20)), start='v', end='taper', taper=0.45))
    add('D', 0x44, (1, 1), ('cap', 'base'),
        s.stroke((xl, 0), (xl, C), start='h', end='h'),
        s.stroke((L, yt), (xr - 140, yt), Q((xr, yt), (xr, yt - 140)), (xr, yb + 140),
                 Q((xr, yb), (xr - 140, yb)), (L, yb), start='v', end='v'))
    add('E', 0x45, (1, 0), ('cap', 'base'),
        s.stroke((R, yt), (xl, yt), (xl, yb), (R, yb), start='v', end='v'),
        s.stroke((xl, ym), (R - 50, ym), end='v'))
    add('F', 0x46, (1, 0), ('cap', 'base'),
        s.stroke((R, yt), (xl + 15, yt), Q((xl + 5, 180), (xl - 40, s.tip_low)), start='v', end='taper', taper=0.4),
        s.stroke((xl, ym), (R - 70, ym), end='v'))
    add('G', 0x47, (1, 0), ('cap', 'base'),
        s.stroke((R, yt), (xl, yt), (xl, yb), (xr, yb), (xr, ym - 30), start='v', end='h'),
        s.stroke((xc, ym - 30), (R, ym - 30), end='v'))
    add('H', 0x48, (1, 0), ('cap', 'base'),
        s.stroke((xl, 0), (xl, C), start='h', end='h'), s.stroke((xr, 0), (xr, C), start='h', end='h'),
        s.stroke((xl, ym), (xr, ym)))
    add('I', 0x49, (1, 0), ('cap', 'base'),
        s.stroke((xc - 160, yt), (xc + 160, yt), start='v', end='v'), s.stroke((xc, yt), (xc, yb)),
        s.stroke((xc - 160, yb), (xc + 160, yb), start='v', end='v'))
    add('J', 0x4A, (1, 0), ('cap', 'base'),
        s.stroke((L + 80, yt), (xr, yt), (xr, 380), Q((xr, 90), (L - 5, s.tip_low)), start='v', end='taper', taper=0.5))
    add('K', 0x4B, (1, 0), ('cap', 'base'),
        s.stroke((xl, 0), (xl, C), start='h', end='h'),
        s.stroke((xl, 330), Q((xc + 40, 520), (R - 20, C - s.tip / 2 + s.o)), start='v', end='taper', taper=0.6),
        s.stroke((xc - 30, 470), Q((xc + 70, 220), (R + 5, s.tip_low)), end='taper', taper=0.6))
    add('L', 0x4C, (1, 0), ('cap', 'base'), s.stroke((xl, C), (xl, yb), (R, yb), start='h', end='v'))
    L, R, xl, xr, xc = s.frame('wide')
    add('M', 0x4D, (1, 0), ('cap', 'base'),
        s.stroke((xl, 0), (xl, yt), (xr, yt), (xr, 0), start='h', end='h'), s.stroke((xc, yt), (xc, 330)))
    L, R, xl, xr, xc = s.frame('cap')
    add('N', 0x4E, (1, 0), ('cap', 'base'),
        s.stroke((xl, 0), (xl, C), start='h', end='h'), s.stroke((xr, 0), (xr, C), start='h', end='h'),
        s.stroke((xl + 10, C), (xr - 10, 0), start='h', end='h'))
    add('O', 0x4F, (1, 1), ('cap', 'base'), s.loop(xl, yb, xr, yt))
    add('P', 0x50, (1, 1), ('cap', 'base'),
        s.stroke((xl, 0), (xl, C), start='h', end='h'),
        s.stroke((L, yt), (xr, yt), (xr, ym - 40), (L, ym - 40), start='v', end='v'))
    add('Q', 0x51, (1, 1), ('cap', 'free'),
        s.loop(xl, yb, xr, yt),
        s.stroke((xc + 30, 230), Q((xr - 10, 60), (R + 40, -80)), end='taper', taper=0.6))
    add('R', 0x52, (1, 1), ('cap', 'base'),
        s.stroke((xl, 0), (xl, C), start='h', end='h'),
        s.stroke((L, yt), (xr, yt), (xr, ym), (L, ym), start='v', end='v'),
        s.stroke((xc - 20, ym), Q((xc + 90, 200), (R + 10, s.tip_low)), end='taper', taper=0.6))
    add('S', 0x53, (1, 0), ('cap', 'base'),
        s.stroke((R, yt), (xl, yt), (xl, ym), (xr, ym), (xr, yb), (L, yb), start='v', end='v'))
    add('T', 0x54, (1, 0), ('cap', 'base'),
        s.stroke((L - 10, yt), (R + 10, yt), start='v', end='v'), s.stroke((xc, yt), (xc, 0), end='h'))
    add('U', 0x55, (1, 0), ('cap', 'base'), s.stroke((xl, C), (xl, yb), (xr, yb), (xr, C), start='h', end='h'))
    add('V', 0x56, (1, 0), ('cap', 'base'),
        s.stroke((L + 25, C), (xc - 15, 0), start='h', end='h'),
        s.stroke((R - 15, C), Q((R - 50, 300), (xc - 15, 40)), start='h', end='taper', taper=0.5))
    L, R, xl, xr, xc = s.frame('wide')
    add('W', 0x57, (1, 0), ('cap', 'base'),
        s.stroke((L + 20, C), (L + 150, 0), start='h', end='h'), s.stroke((xc + 10, C - 170), (L + 150, 0), start='h', end='h'),
        s.stroke((xc - 10, C - 170), (R - 150, 0), start='h', end='h'), s.stroke((R - 20, C), (R - 150, 0), start='h', end='h'))
    L, R, xl, xr, xc = s.frame('cap')
    add('X', 0x58, (1, 0), ('cap', 'base'),
        s.stroke((L + 20, C), (R - 15, 0), start='h', end='h'),
        s.stroke((R - 20, C), Q((xc + 20, 360), (L - 5, s.tip_low)), start='h', end='taper', taper=0.5))
    add('Y', 0x59, (2, 0), ('cap', 'base'),
        s.stroke((L + 25, C - 45), Q((L + 90, 600), (xc - 40, ym)), start='round', end='taper', taper=0.5),
        s.stroke((R - 20, C), Q((R - 60, 340), (L + 40, s.tip_low)), start='h', end='taper', taper=0.55))
    add('Z', 0x5A, (1, 0), ('cap', 'base'), s.stroke((L, yt), (xr, yt), (xl, yb), (R, yb), start='v', end='v'))

    # ---- lowercase ----
    s = l
    L, R, xl, xr, xc = s.frame('lower')
    X, A, yx, yb, xm, yd = s.X, s.A, s.yt, s.yb, s.ym, s.yd
    add('a', 0x61, (1, 1), ('x', 'base'),
        s.stroke((L, yx), (xr, yx), (xr, 0), start='v', end='h'),
        s.stroke((xr, xm), (xl, xm), (xl, yb), (xr, yb)))
    add('b', 0x62, (1, 1), ('asc', 'base'),
        s.stroke((xl, 0), (xl, A), start='h', end='h'),
        s.stroke((L, yx), (xr, yx), (xr, yb), (L, yb), start='v', end='v'))
    add('c', 0x63, (1, 0), ('x', 'base'),
        s.stroke((R, yx), (xl, yx), (xl, 200), Q((xl, yb + 5), (R + 15, s.tip_low + 15)), start='v', end='taper', taper=0.45))
    add('d', 0x64, (1, 1), ('asc', 'base'),
        s.stroke((xr, 0), (xr, A), start='h', end='h'),
        s.stroke((R, yx), (xl, yx), (xl, yb), (R, yb), start='v', end='v'))
    add('e', 0x65, (1, 1), ('x', 'base'),
        s.stroke((xl, xm), (xr, xm), (xr, yx), (xl, yx), (xl, 190), Q((xl, yb + 5), (R + 15, s.tip_low + 15)), end='taper', taper=0.4))
    add('f', 0x66, (1, 0), ('asc', 'base'),
        s.stroke((R + 10, A - s.hair / 2), (xc + 10, A - s.hair / 2), Q((xc - 10, 260), (L + 10, s.tip_low)), start='v', end='taper', taper=0.45),
        s.stroke((L, yx), (R - 40, yx), start='v'))
    add('g', 0x67, (1, 1), ('x', 'desc'),
        s.stroke((xr, 230), (xl, 230), (xl, yx), (xr, yx), (xr, 180), Q((xr, yd), (L - 5, s.tip_desc)), end='taper', taper=0.4))
    add('h', 0x68, (1, 0), ('asc', 'base'),
        s.stroke((xl, 0), (xl, A), start='h', end='h'), s.stroke((xl, yx), (xr, yx), (xr, 0), end='h'))
    add('i', 0x69, (2, 0), ('asc', 'base'), s.stroke((xc, 0), (xc, X), start='h', end='h'), s.dot(xc, A - 60))
    add('j', 0x6A, (2, 0), ('asc', 'desc'),
        s.stroke((xc + 60, X), (xc + 60, 20), Q((xc + 60, yd), (L - 10, s.tip_desc)), start='h', end='taper', taper=0.45),
        s.dot(xc + 60, A - 60))
    add('k', 0x6B, (1, 0), ('asc', 'base'),
        s.stroke((xl, 0), (xl, A), start='h', end='h'),
        s.stroke((xl, 210), Q((xc + 40, 360), (R - 20, X - s.tip / 2 + s.o)), start='v', end='taper', taper=0.6),
        s.stroke((xc - 30, 320), Q((xc + 70, 150), (R + 5, s.tip_low)), end='taper', taper=0.6))
    add('l', 0x6C, (1, 0), ('asc', 'base'),
        s.stroke((xc - 50, A), (xc - 50, 200), Q((xc - 50, yb + 5), (R + 10, s.tip_low + 15)), start='h', end='taper', taper=0.45))
    L, R, xl, xr, xc = s.frame('lower_wide')
    add('m', 0x6D, (1, 0), ('x', 'base'),
        s.stroke((xl, 0), (xl, yx), (xr, yx), (xr, 0), start='h', end='h'), s.stroke((xc, yx), (xc, 0), end='h'))
    L, R, xl, xr, xc = s.frame('lower')
    add('n', 0x6E, (1, 0), ('x', 'base'), s.stroke((xl, 0), (xl, yx), (xr, yx), (xr, 0), start='h', end='h'))
    add('o', 0x6F, (1, 1), ('x', 'base'), s.loop(xl, yb, xr, yx))
    add('p', 0x70, (1, 1), ('x', 'desc'),
        s.stroke((xl, s.D), (xl, X), start='h', end='h'),
        s.stroke((L, yx), (xr, yx), (xr, yb), (L, yb), start='v', end='v'))
    add('q', 0x71, (1, 1), ('x', 'desc'),
        s.stroke((xr, s.D), (xr, X), start='h', end='h'),
        s.stroke((R, yx), (xl, yx), (xl, yb), (R, yb), start='v', end='v'))
    add('r', 0x72, (1, 0), ('x', 'base'), s.stroke((xl, 0), (xl, yx), (R - 30, yx), start='h', end='v'))
    add('s', 0x73, (1, 0), ('x', 'base'),
        s.stroke((R, yx), (xl, yx), (xl, xm), (xr, xm), (xr, yb), (L, yb), start='v', end='v'))
    add('t', 0x74, (1, 0), ('free', 'base'),
        s.stroke((xc - 60, X + 160), (xc - 60, 200), Q((xc - 60, yb + 5), (R + 10, s.tip_low + 15)), start='h', end='taper', taper=0.45),
        s.stroke((L, yx), (R - 40, yx), start='v', end='v'))
    add('u', 0x75, (1, 0), ('x', 'base'),
        s.stroke((xl, X), (xl, yb), (xr, yb), start='h'), s.stroke((xr, X), (xr, 0), start='h', end='h'))
    add('v', 0x76, (1, 0), ('x', 'base'),
        s.stroke((L + 20, X), (xc - 15, 0), start='h', end='h'),
        s.stroke((R - 15, X), Q((R - 50, 200), (xc - 15, 30)), start='h', end='taper', taper=0.5))
    L, R, xl, xr, xc = s.frame('lower_wide')
    add('w', 0x77, (1, 0), ('x', 'base'),
        s.stroke((L + 20, X), (L + 140, 0), start='h', end='h'), s.stroke((xc + 10, X - 130), (L + 140, 0), start='h', end='h'),
        s.stroke((xc - 10, X - 130), (R - 140, 0), start='h', end='h'), s.stroke((R - 20, X), (R - 140, 0), start='h', end='h'))
    L, R, xl, xr, xc = s.frame('lower')
    add('x', 0x78, (1, 0), ('x', 'base'),
        s.stroke((L + 20, X), (R - 15, 0), start='h', end='h'),
        s.stroke((R - 20, X), Q((xc + 20, 260), (L - 5, s.tip_low)), start='h', end='taper', taper=0.5))
    add('y', 0x79, (2, 0), ('x', 'desc'),
        s.stroke((L + 25, X - 40), Q((L + 80, 400), (xc - 30, 230)), start='round', end='taper', taper=0.5),
        s.stroke((R - 20, X), Q((R - 70, 80), (L + 10, s.tip_desc)), start='h', end='taper', taper=0.5))
    add('z', 0x7A, (1, 0), ('x', 'base'), s.stroke((L, yx), (xr, yx), (xl, yb), (R, yb), start='v', end='v'))

    # ---- digits: tabular width, square-rounded like film 2/3 ----
    s = U
    L, R, xl, xr, xc = s.frame('digit')
    C, yt, yb, ym = s.C, s.yt, s.yb, s.ym
    add('zero', 0x30, (1, 2), ('cap', 'base'),
        s.loop(xl, yb, xr, yt, r=130),
        s.stroke((xl + 25, 150), (xr - 25, C - 150)))
    add('one', 0x31, (1, 0), ('cap', 'base'),
        s.stroke((xc - 140, C - 160), (xc + 35, C - 25)), s.stroke((xc + 40, C), (xc + 40, 0), start='h', end='h'))
    add('two', 0x32, (1, 0), ('cap', 'base'),
        s.stroke((L, yt), (xr, yt), (xr, ym + 30), Q((xr, 280), (xl + 60, 180)), (xl, yb), (R, yb), start='v', end='v'))
    add('three', 0x33, (1, 0), ('cap', 'base'),
        s.stroke((L, yt), (xr, yt), (xr, yb), (L, yb), start='v', end='v'), s.stroke((xc - 80, ym), (xr, ym)))
    add('four', 0x34, (1, 1), ('cap', 'base'),
        s.stroke((xr - 30, 0), (xr - 30, C), start='h', end='h'),
        s.stroke((xr - 30, C - 40), (xl - 10, 270), (R, 270), end='v'))
    add('five', 0x35, (1, 0), ('cap', 'base'),
        s.stroke((R, yt), (xl, yt), (xl, ym + 20), (xr - 50, ym + 20), Q((xr + 30, ym + 20), (xr, 220)),
                 Q((xr - 40, yb), (L, yb)), start='v', end='v'))
    add('six', 0x36, (1, 1), ('cap', 'base'),
        s.stroke((R, yt), (xl, yt), (xl, yb), (xr, yb), (xr, ym), (xl, ym), start='v'))
    add('seven', 0x37, (1, 0), ('cap', 'base'),
        s.stroke((L, yt), (xr, yt), Q((xc - 20, 380), (xc - 80, s.tip_low)), start='v', end='taper', taper=0.45))
    add('eight', 0x38, (1, 2), ('cap', 'base'),
        s.loop(xl + 30, ym, xr - 30, yt), s.loop(xl, yb, xr, ym))
    add('nine', 0x39, (1, 1), ('cap', 'base'),
        s.stroke((L, yb), (xr, yb), (xr, yt), (xl, yt), (xl, ym), (xr, ym), start='v'))
    g.update(punctuation(rules))
    return g


def punctuation(rules):
    """ASCII punctuation and the ellipsis, for tool call lines in the rain."""
    g = {}
    s, l = System(rules), System(rules, lowercase=True)
    L, R, xl, xr, xc = s.frame('cap')
    C, A, D, yt, yb = s.C, s.A, s.D, s.yt, s.yb
    bar_a, bar_d = A - s.hair / 2, D + s.hair / 2          # bracket bars on ascender / descender
    dot_y = s.hair * 0.2 + s.stem / 2                       # a dot resting on the baseline
    mid = 0.42 * C                                          # math axis: centre of + - = < >

    def add(name, code, topology, lines, *strokes):
        g[name] = {'unicode': code, 'expect': topology, 'lines': lines, 'strokes': list(strokes)}

    def comma(x, y):
        return s.stroke((x + 15, y), Q((x + 10, y - 120), (x - 70, D + s.tip / 2)), start='round', end='taper', taper=0.6)

    add('exclam', 0x21, (2, 0), ('cap', 'base'),
        s.stroke((xc, C), (xc, 250), start='h', end='taper', taper=0.6), s.dot(xc, dot_y))
    add('quotedbl', 0x22, (2, 0), ('cap', 'free'),
        s.stroke((xc - 95, C), (xc - 95, C - 230), start='h', end='taper', taper=0.7),
        s.stroke((xc + 95, C), (xc + 95, C - 230), start='h', end='taper', taper=0.7))
    add('numbersign', 0x23, (1, 1), ('cap', 'base'),
        s.stroke((xc - 40, C), (xc - 140, 0), start='h', end='h'), s.stroke((xc + 140, C), (xc + 40, 0), start='h', end='h'),
        s.stroke((L, 530), (R, 530), start='v', end='v'), s.stroke((L, 250), (R, 250), start='v', end='v'))
    add('dollar', 0x24, (1, 0), ('free', 'free'),
        s.stroke((R, yt), (xl, yt), (xl, 0.52 * C), (xr, 0.52 * C), (xr, yb), (L, yb), start='v', end='v'),
        s.stroke((xc, C + 80), (xc, yt), start='h'), s.stroke((xc, yb), (xc, -80), end='h'))
    add('percent', 0x25, (3, 2), ('cap', 'base'),
        s.stroke((R - 30, C), (L + 30, 0), start='h', end='h'),
        s.loop(L + 20, 520, L + 200, C - 50, weight=0.75), s.loop(R - 200, 50, R - 20, 260, weight=0.75))
    add('ampersand', 0x26, (1, 2), ('cap', 'base'),
        s.loop(xl + 40, 450, xc + 110, yt, r=70),
        s.stroke((xc + 110, 450), (xl, 290), (xl, yb + 60), Q((xl, yb), (xl + 80, yb)), (xc + 60, yb), (R, 300), start='cut', end='cut'),
        s.stroke((xl + 60, 450), Q((xc + 60, 300), (R + 20, s.tip_low)), end='taper', taper=0.5))
    add('quotesingle', 0x27, (1, 0), ('cap', 'free'), s.stroke((xc, C), (xc, C - 230), start='h', end='taper', taper=0.7))
    add('parenleft', 0x28, (1, 0), ('asc', 'desc'),
        s.stroke((xc + 110, A - s.tip / 2 + s.o), Q((xc - 170, 320), (xc + 110, D + s.tip / 2 - s.o)), start='taper', end='taper', taper=0.3))
    add('parenright', 0x29, (1, 0), ('asc', 'desc'),
        s.stroke((xc - 110, A - s.tip / 2 + s.o), Q((xc + 170, 320), (xc - 110, D + s.tip / 2 - s.o)), start='taper', end='taper', taper=0.3))
    arm = 175
    add('asterisk', 0x2A, (1, 0), ('free', 'free'),
        *[s.stroke((xc - arm * math.cos(a), 560 - arm * math.sin(a)), (xc + arm * math.cos(a), 560 + arm * math.sin(a)),
                   start='round', end='round', weight=0.85) for a in (math.pi / 2, math.pi / 6, -math.pi / 6)])
    add('plus', 0x2B, (1, 0), ('free', 'free'),
        s.stroke((xc - 210, mid), (xc + 210, mid)), s.stroke((xc, mid - 210), (xc, mid + 210)))
    add('comma', 0x2C, (1, 0), ('free', 'desc'), comma(xc, dot_y + 20))
    add('hyphen', 0x2D, (1, 0), ('free', 'free'), s.stroke((xc - 160, mid), (xc + 160, mid)))
    add('period', 0x2E, (1, 0), ('free', 'base'), s.dot(xc, dot_y))
    add('slash', 0x2F, (1, 0), ('asc', 'desc'), s.stroke((R - 50, A), (L + 50, D), start='h', end='h'))
    add('colon', 0x3A, (2, 0), ('free', 'base'), s.dot(xc, dot_y), s.dot(xc, 470))
    add('semicolon', 0x3B, (2, 0), ('free', 'desc'), comma(xc, dot_y + 20), s.dot(xc, 470))
    add('less', 0x3C, (1, 0), ('free', 'free'), s.stroke((R - 70, mid + 250), (L + 70, mid), (R - 70, mid - 250)))
    add('equal', 0x3D, (2, 0), ('free', 'free'),
        s.stroke((xc - 200, mid + 110), (xc + 200, mid + 110)), s.stroke((xc - 200, mid - 110), (xc + 200, mid - 110)))
    add('greater', 0x3E, (1, 0), ('free', 'free'), s.stroke((L + 70, mid + 250), (R - 70, mid), (L + 70, mid - 250)))
    add('question', 0x3F, (2, 0), ('cap', 'base'),
        s.stroke((L + 20, yt), (xr, yt), (xr, 470), (xc, 470), (xc, 250), start='v', end='taper', taper=0.4),
        s.dot(xc, dot_y))
    add('at', 0x40, (1, 1), ('cap', 'base'),
        s.stroke((R, yb), (xl, yb), (xl, yt), (xr, yt), (xr, 250), start='v'),
        s.loop(xc - 70, 250, xr, 520, weight=0.85))
    add('bracketleft', 0x5B, (1, 0), ('asc', 'desc'),
        s.stroke((xc + 140, bar_a), (xc - 80, bar_a), (xc - 80, bar_d), (xc + 140, bar_d), start='v', end='v'))
    add('backslash', 0x5C, (1, 0), ('asc', 'desc'), s.stroke((L + 50, A), (R - 50, D), start='h', end='h'))
    add('bracketright', 0x5D, (1, 0), ('asc', 'desc'),
        s.stroke((xc - 140, bar_a), (xc + 80, bar_a), (xc + 80, bar_d), (xc - 140, bar_d), start='v', end='v'))
    add('asciicircum', 0x5E, (1, 0), ('cap', 'free'), s.stroke((L + 60, 430), (xc, C - 40), (R - 60, 430), start='h', end='h'))
    add('underscore', 0x5F, (1, 0), ('free', 'desc'), s.stroke((L - 20, D + s.hair / 2), (R + 20, D + s.hair / 2), start='v', end='v'))
    add('grave', 0x60, (1, 0), ('cap', 'free'), s.stroke((xc - 70, C - s.stem / 2), (xc + 50, C - 200), start='round', end='taper', taper=0.6))
    add('braceleft', 0x7B, (1, 0), ('asc', 'desc'),
        s.stroke((xc + 140, bar_a), (xc - 10, bar_a), (xc - 10, 390), (xc - 120, 320), (xc - 10, 250), (xc - 10, bar_d),
                 (xc + 140, bar_d), start='v', end='v'))
    add('bar', 0x7C, (1, 0), ('asc', 'desc'), s.stroke((xc, A), (xc, D), start='h', end='h'))
    add('braceright', 0x7D, (1, 0), ('asc', 'desc'),
        s.stroke((xc - 140, bar_a), (xc + 10, bar_a), (xc + 10, 390), (xc + 120, 320), (xc + 10, 250), (xc + 10, bar_d),
                 (xc - 140, bar_d), start='v', end='v'))
    add('asciitilde', 0x7E, (1, 0), ('free', 'free'),
        s.stroke((L + 40, mid - 40), Q((L + 130, mid + 110), (xc, mid)), Q((R - 130, mid - 110), (R - 40, mid + 40)),
                 start='round', end='round', weight=0.9))
    add('ellipsis', 0x2026, (3, 0), ('free', 'base'), s.dot(xc - 230, dot_y), s.dot(xc, dot_y), s.dot(xc + 230, dot_y))
    return g


# --- files --------------------------------------------------------------------------

def outline_svg(name, glyph, font, rules):
    mask = paint(glyph['strokes'], rules['soften'])
    shapes = vector.read_svg(trace(mask), Transform().translate(0, font['ascent'] - CANVAS_TOP))
    path = vector.clean(shapes)
    pen = SVGPathPen(None, ntos=lambda v: f'{round(v, 2):g}')
    path.draw(pen)
    asc, adv, height = font['ascent'], font['advance'], font['ascent'] + font['descent']
    lines = (('descender', rules['descender']), ('baseline', 0), ('x-height', rules['x_height']),
             ('cap height', rules['cap_height']), ('ascender', rules['ascender']))
    guides = ''.join(f'<line x1="0" x2="{adv}" y1="{asc - y}" y2="{asc - y}"><title>{label}</title></line>'
                     for label, y in lines)
    return (f'<?xml version="1.0" encoding="UTF-8"?>\n'
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {adv} {height}" width="{adv}" height="{height}">\n'
            f'<!-- {name} U+{glyph["unicode"]:04X}: designed calligraphic glyph. Units = font units, '
            f'y down from ascender. Keep the viewBox and the guide lines. -->\n'
            f'<g id="guides" fill="none" stroke="#00a0ff" stroke-width="2" stroke-dasharray="8 6">'
            f'<rect x="0" y="0" width="{adv}" height="{height}"/>{guides}</g>\n'
            f'<g id="glyph" fill="#000"><path d="{pen.getCommands()}"/></g>\n</svg>\n')


DIGITS = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine']


def file_name(name):
    # macOS file systems are case-insensitive: A.svg and a.svg would collide.
    if len(name) == 1:
        return f'{"upper" if name.isupper() else "lower"}-{name}.svg'
    return f'{"digit" if name in DIGITS else "punct"}-{name}.svg'


def reference_box(name, order):
    group = 'upper' if len(name) == 1 and name.isupper() else 'lower' if len(name) == 1 else 'digit'
    index = order[group].index(name)
    row, column = divmod(index, 13)
    y0, y1 = SPECIMEN_ROWS[group][row]
    x0 = 28 + column * 113.9
    return [round(x0 + 4), y0, round(x0 + 110), y1]


def write_set(out_dir, designs, header, force=(), only=None, file_of=file_name, reference_of=None, aliases=None):
    """Write one designed set: an SVG per glyph plus glyphs.toml with the contracts.

    `aliases` maps alias names to (codepoint, target glyph): letters that share a
    form (Latin A / Cyrillic А) get the target's outline under a second codepoint.
    """
    config = tomllib.loads(CONFIG.read_text())
    font, rules = config['font'], config['latin']
    out_dir.mkdir(parents=True, exist_ok=True)
    index = out_dir / 'glyphs.toml'
    previous = tomllib.loads(index.read_text()).get('glyph', {}) if index.exists() else {}
    lines = header + ['# `expect` (topology) and `lines` (top/bottom metric lines) are the contract the pipeline',
                      '# enforces. Edit the SVGs freely; change these fields only when an edit intends it.', '']
    written, kept = [], []
    for name, glyph in designs.items():
        path = out_dir / file_of(name, glyph)
        generated = previous.get(name, {}).get('generated_sha256')
        edited = path.exists() and hashlib.sha256(path.read_bytes()).hexdigest() != generated
        if (only is None or name in only) and (not edited or name in force):
            text = outline_svg(name, glyph, font, rules)
            path.write_text(text)
            generated = hashlib.sha256(text.encode()).hexdigest()
            written.append(name)
        elif edited:
            kept.append(name)
        components, holes = glyph['expect']
        top, bottom = glyph['lines']
        lines += [f'[glyph.{name}]', f'unicode = 0x{glyph["unicode"]:04X}', f'file = "{path.name}"',
                  f'expect = {{ components = {components}, holes = {holes} }}',
                  f'lines = {{ top = "{top}", bottom = "{bottom}" }}']
        if reference_of and (box := reference_of(name)) is not None:
            lines.append(f'reference_box = {box}')
        lines += [f'generated_sha256 = "{generated}"', '']
    if aliases:
        lines += ['# Shared forms: the same outline under a second codepoint.', '[alias]']
        lines += [f'{name} = {{ unicode = 0x{code:04X}, glyph = "{target}" }}' for name, (code, target) in aliases.items()]
        lines.append('')
    index.write_text('\n'.join(lines))
    return written, kept


def generate(out_dir, force=(), only=None):
    rules = tomllib.loads(CONFIG.read_text())['latin']
    designs = glyphs(rules)
    order = {'upper': [n for n in designs if len(n) == 1 and n.isupper()],
             'lower': [n for n in designs if len(n) == 1 and n.islower()],
             'digit': [n for n in designs if n in DIGITS]}
    header = ['# Designed Latin, digits and ASCII punctuation, generated by scripts/glyphs/latin.py from [latin].']
    return write_set(out_dir, designs, header, force, only, file_of=lambda name, glyph: file_name(name),
                     reference_of=lambda name: reference_box(name, order) if any(name in v for v in order.values()) else None)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--force', nargs='*', default=[], help='glyph names to regenerate even if edited')
    parser.add_argument('--only', nargs='*', help='limit regeneration to these glyph names')
    parser.add_argument('--out', type=Path, default=ROOT / 'research/glyphs/latin')
    args = parser.parse_args()
    written, kept = generate(args.out, args.force, args.only)
    print(f'wrote {len(written)} SVGs; kept {len(kept)} edited: {" ".join(kept) or "none"}')


if __name__ == '__main__':
    main()
