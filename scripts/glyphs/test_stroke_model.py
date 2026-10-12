"""Behavioral checks for the research stroke library; no app/Metal required."""
import hashlib
import json
import math
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from fontTools.misc.transform import Transform
from fontTools.pens.transformPen import TransformPen
import pathops

from katakana import DATA, build, export_svg, load_library
from stroke_model import Brush, Stroke, centerline, pressure_at, svg_path, union_strokes, validate_profile
import vector


class StrokeModelTests(unittest.TestCase):
    def test_pressure_is_not_inferred_from_movement_direction(self):
        constant = ((0, .6), (1, .6))
        for path in ('M10 10L90 10', 'M90 10L10 10', 'M10 10L10 90'):
            samples = Stroke(path, constant).samples()
            self.assertEqual(samples[0][3], samples[-1][3])

    def test_stop_can_finish_thicker_than_it_starts(self):
        stroke = Stroke('M10 50L90 50', ((0, .3), (.6, .7), (1, .9)), 'tome')
        brush = Brush()
        self.assertGreater(brush.radius(stroke.samples()[-1][3]), brush.radius(stroke.samples()[0][3]))

    def test_nonmonotonic_pressure_and_exact_knots(self):
        knots = ((0, .2), (.2, .9), (.5, .3), (.8, 1), (1, .75))
        for s, p in knots:
            self.assertAlmostEqual(pressure_at(knots, s), p)
        for i in range(101):
            self.assertTrue(.2 <= pressure_at(knots, i / 100) <= 1)

    def test_zero_pressure_lifts_brush(self):
        self.assertEqual(Brush().radius(0), 0)
        self.assertEqual(Stroke('M10 50L90 50', ((0, 0), (1, 0))).outline(Brush()).area, 0)

    def test_thin_sweep_remains_connected_and_reaches_both_tips(self):
        stroke = Stroke('M10 50L90 50', ((0, 0), (.5, .005), (1, 0)))
        outline = stroke.outline(Brush())
        self.assertEqual(len(list(outline.contours)), 1)
        self.assertAlmostEqual(outline.bounds[0], 10, places=4)
        self.assertAlmostEqual(outline.bounds[2], 90, places=4)
        for i in range(1, 800):
            self.assertTrue(outline.contains((10 + i / 10, 50)))

    def test_ne_calligraphic_strokes_are_connected_and_directional(self):
        _, brush, entries = load_library()
        glyph, strokes = next(entry for entry in entries if entry[0]['character'] == 'ネ')
        self.assertEqual(glyph['review'], 'draft')
        for stroke in strokes:
            self.assertEqual(len(list(stroke.outline(brush).contours)), 1)
        for i in (0, 3):
            self.assertEqual(strokes[i].pressure[0][1], 0)
            self.assertGreater(pressure_at(strokes[i].pressure, .7), .8)
        self.assertEqual(strokes[1].pressure[-1][1], 0)
        self.assertGreater(pressure_at(strokes[2].pressure, .9), pressure_at(strokes[2].pressure, .3))

    def test_interior_knots_do_not_pause_thickness_change(self):
        knots = ((0, .1), (.2, .3), (.7, .8), (1, 1))
        epsilon = 1e-6
        for s, p in knots[1:-1]:
            left = (p - pressure_at(knots, s - epsilon)) / epsilon
            right = (pressure_at(knots, s + epsilon) - p) / epsilon
            self.assertGreater(left, .5)
            self.assertAlmostEqual(left, right, delta=1e-4)

    def test_profiles_preserve_local_bounds_and_plateaus(self):
        profiles = [((0, .1), (.01, .9), (.7, .9), (.9, 0), (1, .8)),
                    ((0, 1), (.6, .8), (1, .75)), ((0, 0), (1, 1))]
        for knots in profiles:
            for (a, p), (b, q) in zip(knots, knots[1:]):
                samples = [pressure_at(knots, a + (b - a) * i / 100) for i in range(101)]
                self.assertTrue(all(min(p, q) <= v <= max(p, q) for v in samples))
                self.assertEqual(samples, sorted(samples, reverse=q < p))

    def test_harai_releases_throughout_the_stroke(self):
        library, _, _ = load_library()
        profile = library['profiles']['harai']
        values = [pressure_at(profile, i / 100) for i in range(101)]
        self.assertTrue(all(a > b for a, b in zip(values, values[1:])))
        self.assertEqual(values[-1], 0)

    def test_width_depends_on_nib_orientation_as_well_as_pressure(self):
        brush = Brush(width=10, angle=0, aspect=.5, gamma=1)
        self.assertAlmostEqual(brush.width_across((1, 0), 1), 5)
        self.assertAlmostEqual(brush.width_across((0, 1), 1), 10)
        self.assertAlmostEqual(brush.width_across((0, -1), .5), 5)

    def test_arc_fraction_is_not_bezier_parameter(self):
        samples = centerline('M10 10C10 10 10 10 90 10')
        middle = samples[len(samples) // 2]
        self.assertAlmostEqual(middle[0], 10 + 80 * middle[2], places=5)
        self.assertAlmostEqual(samples[-1][2], 1)

    def test_distinct_strokes_must_have_pen_lifts(self):
        for bad in ('M1 1L1 1', 'M1 1L10 10Z', 'M1 1L10 10M20 20L30 30'):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                centerline(bad)

    def test_bad_profiles_fail_closed(self):
        for bad in ((), ((0, .5),), ((.1, .5), (1, .5)), ((0, .5), (0, .6), (1, .7)),
                    ((0, .5), (1, 2)), ((0, math.nan), (1, .5))):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                validate_profile(bad)
        for bad in (0, -1, math.nan):
            with self.assertRaises(ValueError):
                Brush(width=bad)

    def test_intersections_are_union_not_xor_holes(self):
        strokes = [Stroke(p, ((0, 1), (1, 1))) for p in ('M10 50L90 50', 'M50 10L50 90')]
        outline = union_strokes(strokes, Brush())
        self.assertTrue(outline.contains((50, 50)))
        self.assertEqual(len(list(outline.contours)), 1)

    def test_mirror_preserves_trace_and_thick_terminal(self):
        stroke = Stroke('M10 50L90 50', ((0, .2), (1, 1)))
        outline = stroke.outline(Brush())
        mirrored = outline.transform(-1, 0, 0, 1, 109, 0)
        self.assertAlmostEqual(outline.area, mirrored.area, delta=.01)
        # Thick end moves left; it is not re-generated with a reversed pressure curve.
        self.assertTrue(mirrored.contains((19, 52)))
        self.assertFalse(mirrored.contains((99, 52)))
        self.assertEqual(stroke.path, 'M10 50L90 50')

    def test_source_directions_disambiguate_similar_kana(self):
        _, _, entries = load_library()
        glyphs = {g['character']: strokes for g, strokes in entries}
        for char, count in [('シ', 3), ('ツ', 3), ('ソ', 2), ('ン', 2)]:
            self.assertEqual(len(glyphs[char]), count)
            sample = glyphs[char][-1].samples()
            dy = sample[-1][1] - sample[0][1]
            self.assertLess(dy, 0) if char in 'シン' else self.assertGreater(dy, 0)

    def test_source_tampering_and_reordered_strokes_are_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp) / 'library'
            shutil.copytree(DATA, directory)
            source = directory / 'sources/030a2.svg'
            original = source.read_bytes()
            source.write_bytes(original + b'\n')
            with self.assertRaisesRegex(ValueError, 'hash mismatch'):
                load_library(directory)
            source.write_bytes(original)
            file = directory / 'library.json'
            data = json.loads(file.read_text())
            data['glyphs'][0]['strokes'].reverse()
            file.write_text(json.dumps(data))
            with self.assertRaisesRegex(ValueError, 'stroke order'):
                load_library(directory)

    def test_editable_svg_round_trip_preserves_outline(self):
        _, brush, entries = load_library()
        font = dict(advance=956, ascent=900, descent=124, body_bottom=0, body_top=780)
        strokes = entries[4][1]  # オ: crossings and a hooked second stroke
        text = export_svg(strokes, brush, font)
        vector.check_viewbox(text, font, 'test')
        parsed = vector.clean(vector.read_svg(text))
        expected = union_strokes(strokes, brush).transform(7, 0, 0, 8, 96.5, 74)
        self.assertAlmostEqual(parsed.area, expected.area, delta=5)
        self.assertIn('CC BY-SA', text)
        # The ordinary glyph-pipeline loader can consume this SVG as an override.
        recording = vector.read_svg(text, Transform(1, 0, 0, -1, 0, 900))[0][0]
        path = pathops.Path()
        recording.replay(TransformPen(path.getPen(), Transform()))
        self.assertTrue(svg_path(path))

    def test_build_is_reproducible(self):
        with tempfile.TemporaryDirectory() as tmp:
            a, b = Path(tmp) / 'a', Path(tmp) / 'b'
            build(a)
            build(b)
            def hashes(root):
                return {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in root.iterdir()}
            self.assertEqual(hashes(a), hashes(b))
            self.assertEqual(len(list(a.glob('*.svg'))), 92)
            # Compare the actual browser interpolation with Python export values.
            library, _, _ = load_library()
            profiles = list(library['profiles'].values()) + [
                [[0, .1], [.01, .9], [.7, .9], [.9, 0], [1, .8]]]
            fixture = Path(tmp) / 'pressure-parity.json'
            fixture.write_text(json.dumps([
                {'knots': knots, 'samples': [[i / 100, pressure_at(knots, i / 100)]
                                            for i in range(101)]}
                for knots in profiles]))
            subprocess.run(['node', str(Path(__file__).with_name('test-katakana-catalog.mjs')),
                            str(a / 'catalog.html'), str(fixture)], check=True)


if __name__ == '__main__':
    unittest.main(verbosity=2)
