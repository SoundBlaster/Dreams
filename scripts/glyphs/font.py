"""Deterministic TTF assembly from cleaned outlines."""
from datetime import datetime

from fontTools.fontBuilder import FontBuilder
from fontTools.misc.timeTools import timestampSinceEpoch
import pathops
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib.tables.O_S_2f_2 import Panose

CONFIDENCE = ['unidentified', 'low', 'medium', 'high', 'confirmed_by_user']


def assign_cmap(glyph_ids, identifications, font, minimum, reserved=None):
    """PUA for every film glyph; standard Unicode only for confident, non-conflicting ones.

    `reserved` maps codepoints to designed glyphs; they win over film hypotheses.
    """
    floor = CONFIDENCE.index(minimum)
    cmap, notes = dict(reserved or {}), {}
    candidates = []
    for glyph_id in glyph_ids:
        cmap[font['pua_base'] + int(glyph_id[1:])] = glyph_id
        info = identifications.get(glyph_id, {})
        code, confidence = info.get('unicode'), info.get('confidence', 'unidentified')
        rank = CONFIDENCE.index(confidence) if confidence in CONFIDENCE else 0
        if not code or not code.startswith('U+'):
            notes[glyph_id] = 'PUA only: no Unicode hypothesis'
        elif rank < floor:
            notes[glyph_id] = f'PUA only: {code} is {confidence}'
        else:
            candidates.append((-rank, glyph_id, int(code[2:], 16)))
    for _, glyph_id, code in sorted(candidates):
        if code in cmap:
            notes[glyph_id] = f'PUA only: U+{code:04X} already taken by {cmap[code]}'
        else:
            cmap[code] = glyph_id
            notes[glyph_id] = f'U+{code:04X}'
    return cmap, notes


def tt_glyph(path, max_err):
    pen = TTGlyphPen(None)
    # pathops returns counter-clockwise outer contours (PostScript order);
    # TrueType wants clockwise, so the direction is reversed during cu2qu.
    path.draw(Cu2QuPen(pen, max_err, reverse_direction=True))
    return pen.glyph()


def notdef(font):
    pen = TTGlyphPen(None)
    x0, x1, y0, y1, t = 100, font['advance'] - 100, font['body_bottom'], font['body_top'], 60
    for (a, b, c, d), clockwise in (((x0, y0, x1, y1), True), ((x0 + t, y0 + t, x1 - t, y1 - t), False)):
        points = [(a, b), (a, d), (c, d), (c, b)] if clockwise else [(a, b), (c, b), (c, d), (a, d)]
        pen.moveTo(points[0])
        for point in points[1:]:
            pen.lineTo(point)
        pen.closePath()
    return pen.glyph()


def monospace_panose():
    panose = Panose()
    panose.bFamilyType, panose.bProportion = 2, 9  # Latin text, monospaced
    return panose


def build(outlines, cmap, font, trace):
    """`outlines` maps glyph id -> pathops.Path in font units."""
    names = list(outlines)
    builder = FontBuilder(font['upm'], isTTF=True)
    stamp = int(datetime.fromisoformat(font['timestamp'].replace('Z', '+00:00')).timestamp())
    builder.updateHead(created=timestampSinceEpoch(stamp), modified=timestampSinceEpoch(stamp),
                       fontRevision=float(font['version']))
    builder.setupGlyphOrder(['.notdef', 'space', *names])
    builder.setupCharacterMap({0x20: 'space', **cmap})
    glyphs = {'.notdef': notdef(font), 'space': TTGlyphPen(None).glyph()}
    glyphs.update({name: tt_glyph(outlines[name], trace['max_quadratic_error']) for name in names})
    builder.setupGlyf(glyphs)
    glyf = builder.font['glyf']
    metrics = {}
    for name in ['.notdef', 'space', *names]:
        metrics[name] = (font['advance'], getattr(glyf[name], 'xMin', 0))
    builder.setupHorizontalMetrics(metrics)
    builder.setupHorizontalHeader(ascent=font['ascent'], descent=-font['descent'])
    # Windows clips ink outside usWin*; cover the real extremes (descenders, overshoots).
    y_max = max([font['ascent']] + [glyf[n].yMax for n in names if hasattr(glyf[n], 'yMax')])
    y_min = min([-font['descent']] + [glyf[n].yMin for n in names if hasattr(glyf[n], 'yMin')])
    postscript = font['family'].replace(' ', '') + '-' + font['style']
    builder.setupNameTable({
        'familyName': font['family'], 'styleName': font['style'],
        'uniqueFontIdentifier': f"{postscript};{font['version']}",
        'fullName': f"{font['family']} {font['style']}", 'psName': postscript,
        'version': f"Version {font['version']}",
        'description': 'Film glyph reconstruction and designed Latin for Dreams; see research/glyphs.',
    })
    builder.setupOS2(sTypoAscender=font['ascent'], sTypoDescender=-font['descent'], sTypoLineGap=0,
                     usWinAscent=y_max, usWinDescent=-y_min,
                     sCapHeight=font.get('cap_height', font['body_top']),
                     sxHeight=font.get('x_height', font['body_top']),
                     achVendID='NONE', fsType=0, panose=monospace_panose())
    builder.setupPost(isFixedPitch=1)
    return builder.font


def winding_errors(ttfont):
    """Validate each contour by nesting: clockwise shells, counter-clockwise holes.

    Inspect the raw outline, without simplify/fix_winding: repairing it here
    would hide the very errors this gate must detect. Nested islands alternate
    again, while disconnected shells are checked independently.
    """
    glyphs = ttfont.getGlyphSet()
    errors = []
    for name in ttfont.getGlyphOrder():
        path = pathops.Path()
        glyphs[name].draw(path.getPen())
        contours = list(path.contours)
        for index, contour in enumerate(contours):
            if contour.area <= 1e-8:
                errors.append(name)
                break
            start = next(iter(contour.segments))[1][0]
            depth = sum(other.contains(start) for other_index, other in enumerate(contours)
                        if other_index != index)
            if contour.clockwise != (depth % 2 == 0):
                errors.append(name)
                break
    return errors
