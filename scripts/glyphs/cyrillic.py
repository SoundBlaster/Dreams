"""Generator of the basic Russian Cyrillic set on the same system as latin.py.

Forms shared with Latin (А В Е К М Н О Р С Т Х, а е о р с у х, п = n) are aliases:
the same outline under the Cyrillic codepoint, so the two scripts cannot drift apart.
Every other letter is built here from the same rules ([latin] in pipeline.toml).
Lowercase Cyrillic is mostly small-cap (в г к л м н т), so one builder draws a letter
for both cases: the System decides heights, weights and the bar positions.

  .venv/bin/python scripts/glyphs/cyrillic.py              # write missing / unedited SVGs
  .venv/bin/python scripts/glyphs/cyrillic.py --force Ж    # regenerate even if edited
"""
import argparse
import tomllib
from pathlib import Path

from latin import CONFIG, ROOT, Q, System, glyphs as latin_glyphs, write_set

ALIASES = {
    'А': 'A', 'В': 'B', 'Е': 'E', 'К': 'K', 'М': 'M', 'Н': 'H', 'О': 'O', 'Р': 'P', 'С': 'C', 'Т': 'T', 'Х': 'X',
    'а': 'a', 'е': 'e', 'о': 'o', 'п': 'n', 'р': 'p', 'с': 'c', 'у': 'y', 'х': 'x',
}


def qpoint(p0, c, p1, t):
    return ((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t * t * p1[0],
            (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t * t * p1[1])


def mirror(x, xc):
    return 2 * xc - x


# --- builders: one function per letter, both cases -----------------------------------

def soft_bowl(s, left, right, bottom, top, start='v', end='v'):
    """Bowl open to the left with rounded right corners (Б Ь Ъ Ы З Э)."""
    r = min(130, 0.42 * (top - bottom))
    return s.stroke((left, top), (right - r, top), Q((right, top), (right, top - r)), (right, bottom + r),
                    Q((right, bottom), (right - r, bottom)), (left, bottom), start=start, end=end)


def be(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return [s.stroke((xl, 0), (xl, s.top), start='h', end='h'),
            s.stroke((xl, s.yt), (R, s.yt), end='v'),
            soft_bowl(s, L, xr, s.yb, s.ym)]


def ge(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return [s.stroke((xl, 0), (xl, s.yt), (R, s.yt), start='h', end='v')]


def de(s, key):
    L, R, xl, xr, xc = s.frame(key)
    foot_l, foot_r = L - 40 + s.stem / 2, R + 40 - s.stem / 2
    return [s.stroke((xl + 20, s.yt), (xr, s.yt), (xr, s.yb), start='v'),
            s.stroke((xl + 50, s.yt), Q((xl + 40, 0.3 * s.top), (L + 10, s.yb))),
            s.stroke((foot_l, s.tail), (foot_l, s.yb), (foot_r, s.yb), (foot_r, s.tail), start='h', end='h')]


def zhe(s, key):
    L, R, xl, xr, xc = s.frame(key)
    T, half = s.top, R - xc
    arm = ((xc, 0.42 * T), (xc + 0.45 * half, 0.67 * T), (R - 15, T - s.tip / 2 + s.o))
    leg = ((xc + 0.12 * half, 0.6 * T), (xc + 0.6 * half, 0.28 * T), (R + 5, s.tip_low))
    strokes = [s.stroke((xc, 0), (xc, T), start='h', end='h')]
    for side in (1, -1):
        fx = (lambda x: x) if side == 1 else (lambda x: mirror(x, xc))
        a0, a1, a2 = [(fx(x), y) for x, y in arm]
        l0, l1, l2 = [(fx(x), y) for x, y in leg]
        strokes += [s.stroke(a0, Q(a1, a2), start='v', end='taper', taper=0.6),
                    s.stroke(l0, Q(l1, l2), end='taper', taper=0.6)]
    return strokes


def ze(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return [soft_bowl(s, L + 10, xr - 30, s.ym, s.yt, start='v', end='cut'),
            soft_bowl(s, xc - 60, xr, s.yb, s.ym, start='cut', end='v')]


def i(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return [s.stroke((xl, 0), (xl, s.top), start='h', end='h'), s.stroke((xr, 0), (xr, s.top), start='h', end='h'),
            s.stroke((xl + 10, 0), (xr - 10, s.top), start='h', end='h')]


def breve(s, key):
    L, R, xl, xr, xc = s.frame(key)
    # Capitals get a flatter, lower accent: the app samples a 28px window around a 26px font.
    y = s.top + (135 if s.top == s.C else 150)
    return [s.stroke((xc - 120, y), Q((xc, y - 110), (xc + 120, y)), start='taper', end='taper', taper=0.45)]


def el(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return [s.stroke((xl + 20, s.yt), (xr, s.yt), (xr, 0), start='v', end='h'),
            s.stroke((xl + 50, s.yt), Q((xl + 40, 0.25 * s.top), (L - 10, s.tip_low)), end='taper', taper=0.5)]


def pe(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return [s.stroke((xl, 0), (xl, s.yt), (xr, s.yt), (xr, 0), start='h', end='h')]


def u(s, key):
    L, R, xl, xr, xc = s.frame(key)
    p0, c, p1 = (R - 20, s.top), (R - 60, 0.44 * s.top), (L + 40, s.tip_low)
    return [s.stroke(p0, Q(c, p1), start='h', end='taper', taper=0.55),
            s.stroke((L + 20, s.top), qpoint(p0, c, p1, 0.5), start='h')]


def ef(s, key, low, high):
    L, R, xl, xr, xc = s.frame(key)
    return [s.stroke((xc, low), (xc, high), start='h', end='h'),
            s.loop(xl, 0.18 * s.top, xr, 0.8 * s.top, r=110)]


def tse(s, key):
    L, R, xl, xr, xc = s.frame(key)
    xt = xr + 60
    return [s.stroke((xl, s.top), (xl, s.yb), (xt, s.yb), (xt, s.tail), start='h', end='h'),
            s.stroke((xr, s.top), (xr, s.yb), start='h')]


def che(s, key):
    L, R, xl, xr, xc = s.frame(key)
    y = s.ym - 20
    return [s.stroke((xl, s.top), (xl, y + 120), Q((xl, y), (xl + 130, y)), (xr, y), start='h'),
            s.stroke((xr, 0), (xr, s.top), start='h', end='h')]


def sha(s, key, tail=False):
    L, R, xl, xr, xc = s.frame(key)
    xt = xr + 60
    base = ([(xl, s.top), (xl, s.yb), (xt, s.yb), (xt, s.tail)] if tail
            else [(xl, s.top), (xl, s.yb), (xr, s.yb), (xr, s.top)])
    strokes = [s.stroke(*base, start='h', end='h'), s.stroke((xc, s.top), (xc, s.yb), start='h')]
    if tail:
        strokes.append(s.stroke((xr, s.top), (xr, s.yb), start='h'))
    return strokes


def soft_sign(s, key, flag=False, bowl_right=None):
    L, R, xl, xr, xc = s.frame(key)
    stem = L + 170 if flag else xl
    right = bowl_right if bowl_right is not None else xr
    r = min(130, 0.42 * (s.ym - s.yb))
    path = [(stem, s.top), (stem, s.yb), (right - r, s.yb), Q((right, s.yb), (right, s.yb + r)),
            (right, s.ym - r), Q((right, s.ym), (right - r, s.ym)), (stem, s.ym)]
    strokes = [s.stroke(*path, start='h')]
    if flag:
        strokes.append(s.stroke((L, s.yt), (stem, s.yt), start='v'))
    return strokes


def yery(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return soft_sign(s, key, bowl_right=xc + 60) + [s.stroke((xr, 0), (xr, s.top), start='h', end='h')]


def e_rev(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return [soft_bowl(s, L, xr, s.yb, s.yt), s.stroke((xc - 60, s.ym), (xr, s.ym))]


def yu(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return [s.stroke((xl, 0), (xl, s.top), start='h', end='h'), s.stroke((xl, s.ym), (xc - 10, s.ym)),
            s.loop(xc - 10, s.yb, xr, s.yt, r=min(110, 0.3 * s.top))]


def ya(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return [s.stroke((xr, 0), (xr, s.top), start='h', end='h'),
            s.stroke((R, s.yt), (xl, s.yt), (xl, s.ym), (R, s.ym), start='v', end='v'),
            s.stroke((xc + 20, s.ym), Q((xc - 90, 0.25 * s.top), (L - 10, s.tip_low)), end='taper', taper=0.6)]


def ve_lower(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return [s.stroke((xl, 0), (xl, s.top), start='h', end='h'),
            s.stroke((L, s.yt), (xr - 40, s.yt), (xr - 40, s.ym), (L, s.ym), start='v', end='v'),
            s.stroke((L, s.ym), (xr, s.ym), (xr, s.yb), (L, s.yb), start='v', end='v')]


def ka_lower(s, key):
    L, R, xl, xr, xc = s.frame(key)
    X = s.top
    return [s.stroke((xl, 0), (xl, X), start='h', end='h'),
            s.stroke((xl, 0.4 * X), Q((xc + 40, 0.65 * X), (R - 20, X - s.tip / 2 + s.o)), start='v', end='taper', taper=0.6),
            s.stroke((xc - 30, 0.57 * X), Q((xc + 70, 0.27 * X), (R + 5, s.tip_low)), end='taper', taper=0.6)]


def em_lower(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return [s.stroke((xl, 0), (xl, s.yt), (xr, s.yt), (xr, 0), start='h', end='h'),
            s.stroke((xc, s.yt), (xc, 0.45 * s.top))]


def en(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return [s.stroke((xl, 0), (xl, s.top), start='h', end='h'), s.stroke((xr, 0), (xr, s.top), start='h', end='h'),
            s.stroke((xl, s.ym), (xr, s.ym))]


def te(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return [s.stroke((L - 10, s.yt), (R + 10, s.yt), start='v', end='v'), s.stroke((xc, s.yt), (xc, 0), end='h')]


def be_lower(s, key):
    L, R, xl, xr, xc = s.frame(key)
    return [s.loop(xl, s.yb, xr, s.yt),
            s.stroke((xl, s.yt), Q((xl + 20, s.A - 90), (R + 10, s.A + s.o - s.tip / 2)), end='taper', taper=0.6)]


def diaeresis(s, key):
    L, R, xl, xr, xc = s.frame(key)
    if s.top == s.C:   # compact capital dots (see breve)
        return [s.dot(xc - 105, s.top + 92, weight=0.8), s.dot(xc + 105, s.top + 92, weight=0.8)]
    return [s.dot(xc - 110, s.top + 120), s.dot(xc + 110, s.top + 120)]


# --- the set ------------------------------------------------------------------------

def glyphs(rules):
    U, l = System(rules), System(rules, lowercase=True)
    latin = latin_glyphs(rules)
    g = {}

    def add(char, topology, lines, strokes):
        g[f'uni{ord(char):04X}'] = {'char': char, 'unicode': ord(char), 'expect': topology, 'lines': lines,
                                    'strokes': strokes}

    cap, low = ('cap', 'base'), ('x', 'base')
    add('Б', (1, 1), cap, be(U, 'cap'))
    add('Г', (1, 0), cap, ge(U, 'cap'))
    add('Д', (1, 1), ('cap', 'tail'), de(U, 'cap'))
    add('Ё', (3, 0), ('free', 'base'), latin['E']['strokes'] + diaeresis(U, 'cap'))
    add('Ж', (1, 0), cap, zhe(U, 'wide'))
    add('З', (1, 0), cap, ze(U, 'cap'))
    add('И', (1, 0), cap, i(U, 'cap'))
    add('Й', (2, 0), ('free', 'base'), i(U, 'cap') + breve(U, 'cap'))
    add('Л', (1, 0), cap, el(U, 'cap'))
    add('П', (1, 0), cap, pe(U, 'cap'))
    add('У', (1, 0), cap, u(U, 'cap'))
    add('Ф', (1, 2), cap, ef(U, 'wide', 0, U.top))
    add('Ц', (1, 0), ('cap', 'tail'), tse(U, 'cap'))
    add('Ч', (1, 0), cap, che(U, 'cap'))
    add('Ш', (1, 0), cap, sha(U, 'wide'))
    add('Щ', (1, 0), ('cap', 'tail'), sha(U, 'wide', tail=True))
    add('Ъ', (1, 1), cap, soft_sign(U, 'wide', flag=True))
    add('Ы', (2, 1), cap, yery(U, 'wide'))
    add('Ь', (1, 1), cap, soft_sign(U, 'cap'))
    add('Э', (1, 0), cap, e_rev(U, 'cap'))
    add('Ю', (1, 1), cap, yu(U, 'wide'))
    add('Я', (1, 1), cap, ya(U, 'cap'))

    add('б', (1, 1), ('asc', 'base'), be_lower(l, 'lower'))
    add('в', (1, 2), low, ve_lower(l, 'lower'))
    add('г', (1, 0), low, ge(l, 'lower'))
    add('д', (1, 1), ('x', 'tail'), de(l, 'lower'))
    add('ё', (3, 1), ('free', 'base'), latin['e']['strokes'] + diaeresis(l, 'lower'))
    add('ж', (1, 0), low, zhe(l, 'lower_wide'))
    add('з', (1, 0), low, ze(l, 'lower'))
    add('и', (1, 0), low, i(l, 'lower'))
    add('й', (2, 0), ('free', 'base'), i(l, 'lower') + breve(l, 'lower'))
    add('к', (1, 0), low, ka_lower(l, 'lower'))
    add('л', (1, 0), low, el(l, 'lower'))
    add('м', (1, 0), low, em_lower(l, 'lower_wide'))
    add('н', (1, 0), low, en(l, 'lower'))
    add('т', (1, 0), low, te(l, 'lower'))
    add('ф', (1, 2), ('asc', 'desc'), ef(l, 'lower_wide', l.D, l.A))
    add('ц', (1, 0), ('x', 'tail'), tse(l, 'lower'))
    add('ч', (1, 0), low, che(l, 'lower'))
    add('ш', (1, 0), low, sha(l, 'lower_wide'))
    add('щ', (1, 0), ('x', 'tail'), sha(l, 'lower_wide', tail=True))
    add('ъ', (1, 1), low, soft_sign(l, 'lower_wide', flag=True))
    add('ы', (2, 1), low, yery(l, 'lower_wide'))
    add('ь', (1, 1), low, soft_sign(l, 'lower'))
    add('э', (1, 0), low, e_rev(l, 'lower'))
    add('ю', (1, 1), low, yu(l, 'lower_wide'))
    add('я', (1, 1), low, ya(l, 'lower'))
    return g


def generate(out_dir, force=(), only=None):
    rules = tomllib.loads(CONFIG.read_text())['latin']
    designs = glyphs(rules)
    by_char = {g['char']: name for name, g in designs.items()}
    force = [by_char.get(n, n) for n in force]
    only = None if only is None else [by_char.get(n, n) for n in only]
    aliases = {f'uni{ord(c):04X}': (ord(c), target) for c, target in ALIASES.items()}
    header = ['# Basic Russian Cyrillic, generated by scripts/glyphs/cyrillic.py from [latin] in pipeline.toml.']
    return write_set(out_dir, designs, header, force, only,
                     file_of=lambda name, glyph: f"{glyph['char']}-{name}.svg", aliases=aliases)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--force', nargs='*', default=[], help='letters or uniXXXX names to regenerate even if edited')
    parser.add_argument('--only', nargs='*', help='limit regeneration to these letters')
    parser.add_argument('--out', type=Path, default=ROOT / 'research/glyphs/cyrillic')
    args = parser.parse_args()
    written, kept = generate(args.out, args.force, args.only)
    print(f'wrote {len(written)} SVGs; kept {len(kept)} edited: {" ".join(kept) or "none"}')


if __name__ == '__main__':
    main()
