"""Vector side of the pipeline: potrace tracing, SVG I/O and outline cleanup."""
import math
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

import numpy as np
import pathops
from PIL import Image
from fontTools.misc.transform import Transform
from fontTools.pens.recordingPen import RecordingPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.svgLib.path import parse_path
from fontTools.svgLib.path.shapes import PathBuilder

SVG_NS = 'http://www.w3.org/2000/svg'
SHAPES = {'path', 'rect', 'circle', 'ellipse', 'polygon', 'polyline', 'line'}


def trace(gray, params):
    """Trace a glyph crop (0 = ink) with potrace; returns SVG text in upscaled crop pixels."""
    scale = params['upscale']
    image = Image.fromarray(np.uint8(np.clip(gray, 0, 1) * 255))
    image = image.resize((image.width * scale, image.height * scale), Image.Resampling.LANCZOS)
    bitmap = image.point(lambda v: 0 if v < params['threshold'] * 255 else 255).convert('1')
    with tempfile.TemporaryDirectory() as tmp:
        source = Path(tmp) / 'glyph.pbm'
        bitmap.save(source)
        result = subprocess.run(['potrace', '--backend', 'svg', '--output', '-',
                                 '--turdsize', str(params['turdsize']),
                                 '--alphamax', str(params['alphamax']),
                                 '--opttolerance', str(params['opttolerance']), str(source)],
                                check=True, capture_output=True, text=True)
    return result.stdout


def parse_transform(value):
    transform = Transform()
    for name, args in re.findall(r'(\w+)\s*\(([^)]*)\)', value or ''):
        v = [float(x) for x in re.split(r'[\s,]+', args.strip()) if x]
        if name == 'matrix':
            transform = transform.transform(v)
        elif name == 'translate':
            transform = transform.translate(v[0], v[1] if len(v) > 1 else 0)
        elif name == 'scale':
            transform = transform.scale(v[0], v[1] if len(v) > 1 else v[0])
        elif name == 'rotate':
            if len(v) == 3:
                transform = transform.translate(v[1], v[2])
            transform = transform.rotate(math.radians(v[0]))
            if len(v) == 3:
                transform = transform.translate(-v[1], -v[2])
        elif name == 'skewX':
            transform = transform.skew(math.radians(v[0]), 0)
        elif name == 'skewY':
            transform = transform.skew(0, math.radians(v[0]))
        else:
            raise ValueError(f'unsupported SVG transform {name}')
    return transform


def _style(element, key):
    for item in (element.get('style') or '').split(';'):
        if ':' in item and item.split(':', 1)[0].strip() == key:
            return item.split(':', 1)[1].strip()
    return element.get(key)


def read_svg(text, transform=Transform()):
    """Return the filled shapes of an SVG as [(RecordingPen, even_odd)], one per element.

    If an element with id="glyph" exists, only its subtree is used. Elements with
    id="guides", display:none or fill:none (with inheritance) are ignored, so guide
    lines survive editors that drop ids.
    """
    root = ET.fromstring(text)
    scope = next((e for e in root.iter() if e.get('id') == 'glyph'), root)
    shapes = []

    def walk(element, parent, filled, even_odd):
        tag = element.tag.split('}')[-1] if isinstance(element.tag, str) else ''
        if element.get('id') == 'guides' or _style(element, 'display') == 'none' or tag in {'defs', 'metadata', 'title', 'desc'}:
            return
        fill, rule = _style(element, 'fill'), _style(element, 'fill-rule')
        filled = filled if fill is None else fill != 'none'
        even_odd = even_odd if rule is None else rule == 'evenodd'
        current = parent.transform(parse_transform(element.get('transform')))
        if tag in SHAPES and filled:
            builder = PathBuilder()
            builder.add_path_from_element(element)
            for d in builder.paths:
                pen = RecordingPen()
                parse_path(d, TransformPen(pen, current))
                shapes.append((pen, even_odd))
        for child in element:
            walk(child, current, filled, even_odd)

    # The scope's ancestors may carry transforms too.
    chain, node = [], scope
    parents = {child: parent for parent in root.iter() for child in parent}
    while node is not root:
        node = parents[node]
        chain.append(node)
    for node in reversed(chain):
        transform = transform.transform(parse_transform(node.get('transform')))
    walk(scope, transform, True, False)
    return shapes


def _oriented_if_clean(path):
    """The same points with outer contours counter-clockwise, or None if the path overlaps."""
    simplified = pathops.Path(path)
    simplified.simplify(fix_winding=True, keep_starting_points=True)
    contours = list(path.contours)
    oriented, signed_area, reversed_any = pathops.Path(), 0.0, False
    for index, contour in enumerate(contours):
        start = next(iter(contour.segments))[1][0]
        depth = sum(1 for other_index, other in enumerate(contours)
                    if other_index != index and other.contains(start))
        hole = depth % 2 == 1
        if contour.clockwise != hole:
            contour.reverse()
            reversed_any = True
        signed_area += -contour.area if hole else contour.area
        oriented.addPath(contour)
    if (len(contours) == len(list(simplified.contours))
            and abs(signed_area - simplified.area) <= 1e-4 * max(1.0, simplified.area)):
        # Rebuilding from contours makes implicit closing lines explicit; skip it when possible.
        return oriented if reversed_any else path
    return None


def clean(shapes):
    """Union SVG shapes into an overlap-free pathops.Path with outer contours counter-clockwise.

    SVG fills each element on its own, so elements are cleaned separately (honouring
    fill-rule) and then united. A single non-zero element that is already clean keeps
    its exact points and is only re-oriented, so a hand-edited override survives any
    number of rebuilds unchanged; pathops simplify rewrites geometry on every pass.
    """
    parts = []
    for recording, even_odd in shapes:
        path = pathops.Path()
        recording.replay(path.getPen())
        if even_odd:
            path.fillType = pathops.FillType.EVEN_ODD
        parts.append(path)
    if len(parts) == 1 and not shapes[0][1]:
        oriented = _oriented_if_clean(parts[0])
        if oriented is not None:
            return oriented
    result = pathops.Path()
    for path in parts:
        path.simplify(fix_winding=True, keep_starting_points=True)
        result = pathops.op(result, path, pathops.PathOp.UNION, fix_winding=True, keep_starting_points=True)
    return result


def write_svg(path, font, glyph_id, note):
    """Editable SVG in font units with y pointing down (viewBox = one advance cell)."""
    height = font['ascent'] + font['descent']
    pen = SVGPathPen(None, ntos=lambda v: f'{round(v, 2):g}')
    path.draw(TransformPen(pen, Transform(1, 0, 0, -1, 0, font['ascent'])))
    guide = lambda y: font['ascent'] - y
    lines = [
        ('baseline', 0), ('body bottom', font['body_bottom']), ('body top', font['body_top'])]
    guides = ''.join(
        f'<line x1="0" x2="{font["advance"]}" y1="{guide(y)}" y2="{guide(y)}"><title>{name}</title></line>'
        for name, y in lines)
    return (f'<?xml version="1.0" encoding="UTF-8"?>\n'
            f'<svg xmlns="{SVG_NS}" viewBox="0 0 {font["advance"]} {height}" '
            f'width="{font["advance"]}" height="{height}">\n'
            f'<!-- {glyph_id}: {note}. Units = font units, y down from ascender. '
            f'Edit only the paths inside id="glyph"; keep the viewBox. -->\n'
            f'<g id="guides" fill="none" stroke="#00a0ff" stroke-width="2" stroke-dasharray="8 6">'
            f'<rect x="0" y="0" width="{font["advance"]}" height="{height}"/>{guides}</g>\n'
            f'<g id="glyph" fill="#000"><path d="{pen.getCommands()}"/></g>\n</svg>\n')


def check_viewbox(text, font, origin):
    root = ET.fromstring(text)
    expected = [0, 0, font['advance'], font['ascent'] + font['descent']]
    actual = [float(v) for v in re.split(r'[\s,]+', (root.get('viewBox') or '').strip()) if v]
    if actual != expected:
        raise ValueError(f'{origin}: viewBox {actual or "missing"} != {expected}; '
                         'the editor rescaled the document — export without resizing')
