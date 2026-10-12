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

from katakana import DATA, REPERTOIRE, STUDIES, build, export_svg, load_library
from stroke_model import Brush, Stroke, centerline, pressure_at, svg_path, union_strokes, validate_profile
import vector


class StrokeModelTests(unittest.TestCase):
    def test_complete_alphabet_has_calibrated_connected_strokes_and_correct_topology(self):
        _, brush, entries = load_library()
        detached = {'ア': 2, 'シ': 3, 'ソ': 2, 'ツ': 3, 'テ': 2, 'ニ': 2,
                    'ネ': 3, 'ハ': 2, 'ホ': 3, 'ミ': 3, 'ラ': 2, 'リ': 2,
                    'ル': 2, 'ロ': 2, 'ヲ': 2, 'ン': 2}
        for glyph, strokes in entries:
            with self.subTest(character=glyph['character']):
                self.assertTrue(all('path_override' in s and 'pressure' in s for s in glyph['strokes']))
                for stroke in strokes:
                    self.assertNotEqual(stroke.terminal, 'unspecified')
                    self.assertEqual(len(list(stroke.outline(brush).contours)), 1)
                outline = union_strokes(strokes, brush)
                self.assertEqual(len(list(outline.contours)), detached.get(glyph['character'], 1))
                self.assertTrue(all(0 <= value <= 109 for value in outline.bounds))
                self.assertGreater(outline.area, 0)
                if glyph['character'] == 'ロ':
                    self.assertFalse(outline.contains((54, 55)))
                    for point in ((31, 55), (79, 55), (54, 34), (54, 77)):
                        self.assertTrue(outline.contains(point))

    def test_study_groups_cover_the_alphabet_exactly_once(self):
        characters = ''.join(chars for _, chars, _ in STUDIES)
        self.assertCountEqual(characters, REPERTOIRE)
        self.assertEqual(len({slug for slug, _, _ in STUDIES}), len(STUDIES))

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

    def test_calibrated_studies_keep_their_intended_connections(self):
        _, brush, entries = load_library()
        for glyph, strokes in entries:
            if glyph['character'] not in 'ネマスセ':
                continue
            with self.subTest(character=glyph['character']):
                for stroke in strokes:
                    self.assertEqual(len(list(stroke.outline(brush).contours)), 1)
                outline = union_strokes(strokes, brush)
                # ネ retains two detached short marks; the other studies meet.
                self.assertEqual(len(list(outline.contours)), 3 if glyph['character'] == 'ネ' else 1)
                reflected = outline.transform(-1, 0, 0, 1, 109, 0)
                self.assertAlmostEqual(outline.area, reflected.area, delta=.01)

    def test_interior_knots_do_not_pause_thickness_change(self):
        knots = ((0, .1), (.2, .3), (.7, .8), (1, 1))
        epsilon = 1e-6
        for s, p in knots[1:-1]:
            left = (p - pressure_at(knots, s - epsilon)) / epsilon
            right = (pressure_at(knots, s + epsilon) - p) / epsilon
            self.assertGreater(left, .5)
            self.assertAlmostEqual(left, right, delta=1e-4)

    def test_crossbar_studies_keep_joins_filled_and_side_marks_detached(self):
        _, brush, entries = load_library()
        joins = {'オ': [(62, 34), (59, 40)], 'キ': [(54, 34), (58, 56)],
                 'ホ': [(56, 38)], 'モ': [(47, 26), (47, 52)]}
        for glyph, strokes in entries:
            character = glyph['character']
            if character not in joins:
                continue
            with self.subTest(character=character):
                for stroke in strokes:
                    self.assertEqual(len(list(stroke.outline(brush).contours)), 1)
                outline = union_strokes(strokes, brush)
                self.assertEqual(len(list(outline.contours)), 3 if character == 'ホ' else 1)
                for point in joins[character]:
                    self.assertTrue(outline.contains(point), f'empty join at {point}')
                self.assertAlmostEqual(outline.area, outline.transform(-1, 0, 0, 1, 109, 0).area, delta=.01)

    def test_hooks_release_up_left_while_full_endings_keep_weight(self):
        _, _, entries = load_library()
        by_character = {glyph['character']: strokes for glyph, strokes in entries}
        for character in 'オホ':
            stroke = by_character[character][1]
            samples = stroke.samples()
            bottom = max(samples, key=lambda sample: sample[1])
            self.assertLess(samples[-1][0], bottom[0])
            self.assertLess(samples[-1][1], bottom[1])
            self.assertEqual(samples[-1][3], 0)
            self.assertGreater(pressure_at(stroke.pressure, .82), .9)
        for character in 'キモ':
            stroke = by_character[character][-1]
            self.assertGreater(stroke.pressure[-1][1], .7)
        for stroke in by_character['ホ'][2:]:
            self.assertEqual(stroke.pressure[0][1], 0)
            self.assertGreater(pressure_at(stroke.pressure, .75), .9)

    def test_turn_studies_preserve_open_counters_and_detached_parts(self):
        _, brush, entries = load_library()
        components = {'ア': 2, 'ウ': 1, 'ワ': 1, 'ヲ': 2}
        for glyph, strokes in entries:
            character = glyph['character']
            if character not in components:
                continue
            with self.subTest(character=character):
                for stroke in strokes:
                    self.assertEqual(len(list(stroke.outline(brush).contours)), 1)
                outline = union_strokes(strokes, brush)
                self.assertEqual(len(list(outline.contours)), components[character])
                # The central opening must not be filled by a whole-glyph convex hull.
                self.assertFalse(outline.contains((63, 55)))
                self.assertAlmostEqual(outline.area, outline.transform(-1, 0, 0, 1, 109, 0).area, delta=.01)

    def test_long_releases_reach_the_tip_and_continuously_lose_pressure(self):
        _, brush, entries = load_library()
        for glyph, strokes in entries:
            if glyph['character'] not in 'アウワヲ':
                continue
            with self.subTest(character=glyph['character']):
                stroke = strokes[-1]
                samples = stroke.samples()
                # ウ/ワ first travel right across the top before descending left.
                turn = max(samples, key=lambda sample: sample[0])
                self.assertLess(samples[-1][0], turn[0])
                self.assertGreater(samples[-1][1], turn[1])
                self.assertEqual(samples[-1][3], 0)
                release = [pressure_at(stroke.pressure, .6 + .4 * i / 100) for i in range(101)]
                self.assertTrue(all(a > b for a, b in zip(release, release[1:])))
                outline = stroke.outline(brush)
                for x, y, s, pressure in samples:
                    if .65 < s < .99 and pressure > 0:
                        self.assertTrue(outline.contains((x, y)))
                self.assertAlmostEqual(outline.bounds[3], samples[-1][1], delta=.01)

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

    def test_calibrated_pairs_preserve_detached_marks_and_tip_direction(self):
        _, brush, entries = load_library()
        for glyph, strokes in entries:
            if glyph['character'] not in 'シツソン':
                continue
            with self.subTest(character=glyph['character']):
                self.assertEqual(len(list(union_strokes(strokes, brush).contours)), len(strokes))
                for stroke in strokes:
                    self.assertEqual(len(list(stroke.outline(brush).contours)), 1)
                for mark in strokes[:-1]:
                    self.assertEqual(mark.pressure[0][1], 0)
                    self.assertGreater(pressure_at(mark.pressure, .7), .8)
                    samples = mark.samples()
                    dx = samples[-1][0] - samples[0][0]
                    dy = samples[-1][1] - samples[0][1]
                    self.assertGreater(dx, dy) if glyph['character'] in 'シン' else self.assertGreater(dy, dx)
                self.assertEqual(strokes[-1].pressure[-1][1], 0)
                self.assertGreater(pressure_at(strokes[-1].pressure, .15),
                                   pressure_at(strokes[-1].pressure, .85))

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
        for glyph, strokes in entries:
            for mirrored in (False, True):
                with self.subTest(character=glyph['character'], mirrored=mirrored):
                    text = export_svg(strokes, brush, font, mirrored)
                    vector.check_viewbox(text, font, 'test')
                    parsed = vector.clean(vector.read_svg(text))
                    sx = -7 if mirrored else 7
                    expected = union_strokes(strokes, brush).transform(sx, 0, 0, 8, 478 - sx * 54.5, 74)
                    self.assertAlmostEqual(parsed.area, expected.area, delta=5)
                    self.assertEqual(len(list(parsed.contours)), len(list(expected.contours)))
                    self.assertIn('CC BY-SA', text)
                    # The ordinary glyph-pipeline loader can consume each SVG as an override.
                    recording = vector.read_svg(text, Transform(1, 0, 0, -1, 0, 900))[0][0]
                    path = pathops.Path()
                    recording.replay(TransformPen(path.getPen(), Transform()))
                    self.assertTrue(svg_path(path))

    def test_build_is_reproducible(self):
        with tempfile.TemporaryDirectory() as tmp:
            a, b = Path(tmp) / 'a', Path(tmp) / 'b'
            build(a)
            b.mkdir()
            unrelated = {'.DS_Store': b'finder metadata', 'manual-edit.svg': b'<svg/>',
                         'old-study.html': b'previous experiment'}
            for name, content in unrelated.items():
                (b / name).write_bytes(content)
            (b / 'manifest.json').write_text('{"stale": "manifest"}')
            build(b)
            def hashes(root):
                return {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                        for p in root.iterdir() if p.name not in unrelated}
            self.assertEqual(hashes(a), hashes(b))
            manifest = json.loads((b / 'manifest.json').read_text())
            self.assertEqual(manifest, {name: digest for name, digest in hashes(a).items()
                                       if name != 'manifest.json'})
            for name, content in unrelated.items():
                self.assertEqual((b / name).read_bytes(), content)
            self.assertEqual(len(list(a.glob('*.svg'))), 92)
            for slug, characters, _ in STUDIES:
                page = (a / f'{slug}.html').read_text()
                self.assertEqual(page.count('<article>'), len(characters) * 2)
            self.assertEqual((a / 'alphabet.html').read_text().count('<article>'), 92)
            # Compare the actual browser interpolation with Python export values.
            library, _, _ = load_library()
            overrides = [stroke['pressure'] for glyph in library['glyphs']
                         for stroke in glyph['strokes'] if 'pressure' in stroke]
            profiles = list(library['profiles'].values()) + overrides + [
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
