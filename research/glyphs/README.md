# Dreams — glyph catalogue

Open [`catalog.html`](catalog.html). It is a self-contained local HTML file that works offline: search by ID / character / Unicode / observation, a confidence filter, and the source next to the latest restored shape. For G17 a separate sharp reference from the user is used.

- [`PIPELINE.md`](PIPELINE.md) — the reproducible pipeline: reconstruction sheet and manual edits → SVG → TTF → checks → proof.
- [`PLAN.md`](PLAN.md) — stages and acceptance criteria.
- [`identifications.json`](identifications.json) — the editable source of identifications, 28 stable IDs.
- [`IDENTIFICATIONS.md`](IDENTIFICATIONS.md) — the detailed analysis by the Sol 6.1 / Medium subagent.
- [`references/sources.json`](references/sources.json) — origin of the saved images.
- [`references/provenance.json`](references/provenance.json) — coordinates and timestamps of the source crops from the video.

After changing the JSON, rebuild the HTML from the Dreams root:

```sh
python3 scripts/build-glyph-catalog.py
```

## Catalogue rules

1. A glyph ID does not depend on a hypothesis about Unicode. Do not rename G01–G28.
2. Confidence describes the identification, not the readiness of the image for release. `confirmed_by_user` is an explicit confirmation by the user; `high`, `medium`, `low` are the degree of support for the hypothesis; `unidentified` means no suitable hypothesis yet.
3. Keep the observed geometry, the hypothesis and the alternatives separately. A reflection and a rotation must be explicit.
4. Light intersections are solid strokes. The old method `G − (R+B)/2` created false holes; the corrected extractor uses G without subtracting neutral highlights.
5. `restored-v5.png` is the current version of the reconstruction; the original frames take priority over its shapes. GPT Image can change contours or neighbouring glyphs: check every iteration.
6. The catalogue does not assign a cmap and does not change the app's font. Those actions belong to the later stages of the plan.
7. Specify a new processing batch as a list of IDs, a concrete goal, references and acceptance criteria. The result is an image version, the prompt and a record of the visual check.

## Brief for the next iteration

First check the geometrically unambiguous matches on a small set, then the disputed glyphs. For every comparison: the source frame, the standard character, the proposed transformation, and the restored contour at the same size. Keep the confirmed G01/G02 and the fixed intersections. Do not regenerate the whole sheet for a local edit without checking the other 19 glyphs.
