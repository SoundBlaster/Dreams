"""Directed brush strokes. Geometry is evidence; pressure is an editable hypothesis.

Coordinates: 109-unit cell, x right, y down. Pressure knots use normalized arc
length, not Bezier t or time. No terminal taper is inferred from direction.
"""
from dataclasses import dataclass
import math

import pathops
from fontTools.pens.basePen import BasePen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.svgLib.path import parse_path


def finite(value, name):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
        raise ValueError(f'{name} must be a finite number')
    return value


def validate_profile(knots):
    if len(knots) < 2:
        raise ValueError('pressure needs at least two knots')
    previous = -1
    for s, p in knots:
        finite(s, 'arc fraction')
        finite(p, 'pressure')
        if not 0 <= s <= 1 or not 0 <= p <= 1 or s <= previous:
            raise ValueError('pressure knots must increase strictly in [0, 1], pressure in [0, 1]')
        previous = s
    if knots[0][0] != 0 or knots[-1][0] != 1:
        raise ValueError('pressure must cover the entire stroke: 0...1')


def pressure_slopes(knots):
    """Shape-preserving cubic Hermite tangents (PCHIP), in arc-length units.

    Interior knots retain motion through a rising/falling profile. Only actual
    extrema or explicitly flat segments require a zero tangent.
    """
    lengths = [b[0] - a[0] for a, b in zip(knots, knots[1:])]
    secants = [(b[1] - a[1]) / h for a, b, h in zip(knots, knots[1:], lengths)]
    if len(secants) == 1:
        return [secants[0], secants[0]]

    def endpoint(h, next_h, d, next_d):
        slope = ((2 * h + next_h) * d - h * next_d) / (h + next_h)
        if slope * d <= 0:
            return 0.0
        if d * next_d <= 0 and abs(slope) > abs(3 * d):
            return 3 * d
        return slope

    slopes = [endpoint(lengths[0], lengths[1], secants[0], secants[1])]
    for i in range(1, len(knots) - 1):
        left, right = secants[i - 1], secants[i]
        if left * right <= 0:
            slopes.append(0.0)
        else:
            w1, w2 = 2 * lengths[i] + lengths[i - 1], lengths[i] + 2 * lengths[i - 1]
            slopes.append((w1 + w2) / (w1 / left + w2 / right))
    slopes.append(endpoint(lengths[-1], lengths[-2], secants[-1], secants[-2]))
    return slopes


def pressure_at(knots, s):
    """C1 continuous, exact knots and no overshoot; no forced pauses at knots."""
    slopes = pressure_slopes(knots)
    for i, ((a, p), (b, q)) in enumerate(zip(knots, knots[1:])):
        if s <= b:
            t = max(0, min(1, (s - a) / (b - a)))
            value = ((2 * t**3 - 3 * t**2 + 1) * p
                     + (t**3 - 2 * t**2 + t) * (b - a) * slopes[i]
                     + (-2 * t**3 + 3 * t**2) * q
                     + (t**3 - t**2) * (b - a) * slopes[i + 1])
            return max(min(p, q), min(max(p, q), value))
    return knots[-1][1]


def convex_hull(points):
    """Envelope bridging adjacent nib footprints, including zero-width tips."""
    points = sorted(set(points))
    if len(points) < 3:
        return points

    def cross(a, b, c):
        return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])

    def half(sequence):
        result = []
        for p in sequence:
            while len(result) > 1 and cross(result[-2], result[-1], p) <= 0:
                result.pop()
            result.append(p)
        return result

    return half(points)[:-1] + half(reversed(points))[:-1]


@dataclass(frozen=True)
class Brush:
    width: float = 8
    aspect: float = 0.72
    angle: float = -35
    gamma: float = 0.7

    def __post_init__(self):
        for name in ('width', 'aspect', 'angle', 'gamma'):
            finite(getattr(self, name), name)
        if not 0 < self.width <= 20 or not 0.1 <= self.aspect <= 1 or not 0.1 <= self.gamma <= 4:
            raise ValueError('invalid brush width, aspect or gamma')

    def radius(self, pressure):
        # Zero pressure means lift-off; no artificial minimum-width hairline.
        return self.width * 0.5 * pressure ** self.gamma

    def footprint(self, x, y, pressure):
        """32-sided ellipse; adjacent footprints form a continuous brush sweep."""
        radius = self.radius(pressure)
        angle = math.radians(self.angle)
        c, s = math.cos(angle), math.sin(angle)
        return [(x + radius * (math.cos(t) * c - self.aspect * math.sin(t) * s),
                 y + radius * (math.cos(t) * s + self.aspect * math.sin(t) * c))
                for t in (2 * math.pi * i / 32 for i in range(32))]

    def width_across(self, tangent, pressure):
        """Footprint width normal to movement (not simply pressure = width)."""
        dx, dy = tangent
        norm = math.hypot(dx, dy)
        if norm == 0:
            raise ValueError('tangent must be nonzero')
        nx, ny = -dy / norm, dx / norm
        angle = math.radians(self.angle)
        major = nx * math.cos(angle) + ny * math.sin(angle)
        minor = -nx * math.sin(angle) + ny * math.cos(angle)
        return 2 * self.radius(pressure) * math.hypot(major, self.aspect * minor)


class CenterlinePen(BasePen):
    """Flatten open SVG curves adaptively; reject pen lifts inside one stroke."""
    def __init__(self):
        super().__init__(None)
        self.points = []

    def _moveTo(self, p):
        if self.points:
            raise ValueError('one stroke must have exactly one moveTo')
        self.points.append(p)

    def _lineTo(self, p):
        self.points.append(p)

    def _curveToOne(self, b, c, d):
        def split(a, b, c, d, depth=0):
            chord = math.dist(a, d)
            polygon = math.dist(a, b) + math.dist(b, c) + math.dist(c, d)
            if depth >= 16 or polygon - chord <= 0.002:
                self.points.append(d)
                return
            mid = lambda p, q: ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
            ab, bc, cd = mid(a, b), mid(b, c), mid(c, d)
            abc, bcd = mid(ab, bc), mid(bc, cd)
            center = mid(abc, bcd)
            split(a, ab, abc, center, depth + 1)
            split(center, bcd, cd, d, depth + 1)
        split(self.points[-1], b, c, d)

    def _qCurveToOne(self, control, end):
        a = self.points[-1]
        self._curveToOne(tuple(a[i] + 2 / 3 * (control[i] - a[i]) for i in range(2)),
                         tuple(end[i] + 2 / 3 * (control[i] - end[i]) for i in range(2)), end)

    def _closePath(self):
        raise ValueError('a directed brush stroke must be open')

    def _endPath(self):
        pass


def centerline(path, step=0.45):
    finite(step, 'sample step')
    if step <= 0:
        raise ValueError('sample step must be positive')
    pen = CenterlinePen()
    parse_path(path, pen)
    points = []
    for p in pen.points:
        if any(not math.isfinite(v) or not -10 <= v <= 119 for v in p):
            raise ValueError('centerline outside the 109-unit cell margin')
        if not points or math.dist(points[-1], p) > 1e-8:
            points.append(p)
    if len(points) < 2:
        raise ValueError('zero length stroke')
    distances = [0.0]
    for a, b in zip(points, points[1:]):
        distances.append(distances[-1] + math.dist(a, b))
    count = max(2, math.ceil(distances[-1] / step))
    if count > 10000:
        raise ValueError('stroke exceeds sampling budget')
    result, j = [], 0
    for i in range(count + 1):
        distance = distances[-1] * i / count
        while j + 1 < len(points) - 1 and distances[j + 1] < distance:
            j += 1
        t = (distance - distances[j]) / (distances[j + 1] - distances[j])
        result.append((points[j][0] * (1 - t) + points[j + 1][0] * t,
                       points[j][1] * (1 - t) + points[j + 1][1] * t, i / count))
    return result


@dataclass(frozen=True)
class Stroke:
    path: str
    pressure: tuple
    terminal: str = 'unspecified'
    duration: float = 0.7

    def __post_init__(self):
        validate_profile(self.pressure)
        if self.terminal not in ('unspecified', 'tome', 'harai', 'hane'):
            raise ValueError('unknown terminal')
        if not 0 < finite(self.duration, 'duration') <= 10:
            raise ValueError('duration must be in (0, 10]')
        centerline(self.path)

    def samples(self):
        return [(x, y, s, pressure_at(self.pressure, s)) for x, y, s in centerline(self.path)]

    def outline(self, brush):
        footprints = []
        previous = []
        for x, y, _, pressure in self.samples():
            current = brush.footprint(x, y, pressure) if brush.radius(pressure) >= 1e-4 else [(x, y)]
            points = convex_hull(previous + current)
            previous = current
            if len(points) < 3:
                continue  # An entirely lifted brush leaves no filled area.
            footprint = pathops.Path()
            pen = footprint.getPen()
            pen.moveTo(points[0])
            for p in points[1:]:
                pen.lineTo(p)
            pen.closePath()
            footprints.append(footprint)
        # Balanced pairwise union avoids Skia simplify's failure with hundreds of
        # mutually overlapping contours (notably ノ and the turn in ヘ).
        while len(footprints) > 1:
            merged = [pathops.op(footprints[i], footprints[i + 1], pathops.PathOp.UNION,
                                 fix_winding=True, keep_starting_points=True)
                      for i in range(0, len(footprints) - 1, 2)]
            if len(footprints) % 2:
                merged.append(footprints[-1])
            footprints = merged
        return footprints[0] if footprints else pathops.Path()


def union_strokes(strokes, brush):
    result = pathops.Path()
    for stroke in strokes:
        result = pathops.op(result, stroke.outline(brush), pathops.PathOp.UNION,
                            fix_winding=True, keep_starting_points=True)
    return result


def svg_path(outline):
    pen = SVGPathPen(None, ntos=lambda v: f'{v:.3f}'.rstrip('0').rstrip('.'))
    outline.draw(pen)
    return pen.getCommands()
