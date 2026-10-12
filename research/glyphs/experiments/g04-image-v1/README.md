# G04 / オ — image-assisted reconstruction pilot

This is a review experiment, not an approved replacement for the production font.
The film provides visual evidence; the directed katakana library provides a
construction hypothesis. Neither image generation nor tracing proves that the
result is the original movie outline.

`stroke-study.json` is an excerpt of the katakana research data and retains its
[CC BY-SA 3.0 attribution and notices](../../katakana/NOTICE.md). The generated
candidate images are separate experiments, not a relicensing of that source data.

## Inputs and stages

1. **Construction:** `stroke-study.json` snapshots the three directed strokes,
   authored pressure profiles and attribution from the katakana study. Those
   profiles describe movement; the generated bitmap does not preserve stroke order.
2. **Appearance:** the existing G04 film crop plus two user-provided movie frames.
   `manifest.json` records reference roles and SHA-256 hashes. External frames are
   not copied into this experiment. Source licensing remains as documented in the
   katakana library and glyph research; generated contours do not erase provenance.
3. **Generation:** built-in imagegen, exact prompts saved alongside the immutable
   candidate PNGs. The tool did not expose an exact model version. Re-generation
   is nondeterministic; rebuilding the saved raster into SVG/TTF is deterministic
   within the same toolchain.
4. **Vector:** `image_pilot.py` uses the existing Potrace/pathops/fontTools pipeline.
   Black ink is segmented at 50%, traced and placed in a 956 × 1024 font cell,
   with ink height 780. Uniform scaling preserves the candidate's aspect ratio.
5. **Verification:** overlap with the generated raster, connectedness, counters,
   winding, bounds and test-TTF rendering at 20/26/32/48 px. 26 px is the pilot's
   minimum intended font size; problems below that size remain visible warnings.
   IoU measures tracing fidelity, **not resemblance to the movie**.

## Design constraints

- Tall, narrow letterforms: target ink width/height ≈ 22/30, independent of advance.
  The pilot accepts ±0.05 for visual review, reports the measured ratio, and never
  silently compresses a raster horizontally. Future Latin/Cyrillic glyphs need
  their own width classes instead of forcing every letter into this same ratio.
- Technical, mostly even-weight construction with restrained pen modulation.
- Small **curved** terminal turns and modest flares. A triangular spike is not a
  substitute for a pen turn. Inspect both the enlarged contour and screen sizes.
- Solid intersections, no glow/noise baked into the shape. Those belong to rendering.

## Rebuild and edit

From the repository root, using the project's Python environment:

```sh
.venv/bin/python scripts/glyphs/image_pilot.py \
  research/glyphs/experiments/g04-image-v1 \
  --candidates terminals.png film.png
```

The first build creates `<candidate>.svg` next to the raster. Further builds use
that SVG, preserving manual edits. Edit paths inside `id="glyph"`, keep the
viewBox and guide metrics unchanged. `--retrace` explicitly replaces those SVGs.
The immutable PNGs and prompts remain available for comparison.

Test fonts, reports and a comparison proof go under
`research/glyphs/build/image-pilot/g04-image-v1/`. This static proof is rendered
from the test TTF with FreeType; it is not a screenshot of the Metal application.
The script never installs a font or changes application resources.

Saved [comparison proof](proof.png) and `verification.json` describe this run.
The `terminals` candidate has ink ratio 0.6949, 46 outline segments, one connected
contour and no holes. Its source-to-TTF IoU is 0.98939; topology survives all four
tested sizes. The earlier `refined` candidate has a detached pixel at 20 px and
keeps that warning. All four test fonts rebuilt byte-identically in two runs.

The latest movie close-up exposed a construction/orientation mismatch: the upper
film glyph has its diagonal descending right, unlike conventional オ used in the
first three candidates. `film.png` / `film.svg` follows that photographed layout
and is mapped **only to PUA U+E004** in its test font. No Unicode identification
or production catalog assignment was changed. The new candidate has 37 segments,
IoU 0.99235 and correct topology at all four sizes, but ratio 0.5978 is outside
the target range and produces an explicit warning. Its terminals are also too
rounded/heavy. Use it for manual refinement against the film, not automatic
promotion. The clean normal オ variants remain construction studies.

## Continue the alphabet

Approve the pilot's proportions, stroke weight and terminal vocabulary first.
Then use a separate reference packet per katakana: identity/orientation, directed
strokes, film crops, shared style rules, exact prompt and selected raster. Preserve
rejected variants so later edits have a reason and a baseline. Review small-size
proofs before promoting any contour into the production glyph manifest.

Latin follows katakana, then Cyrillic. Reuse metrics, weight, terminal vocabulary
and the generation/trace/review stages; supply each script's own construction and
stroke references rather than copying katakana anatomy onto other alphabets.
