# Matrix glyph restoration plan

Goal: a reproducible catalogue of forms from the user's video, then a verified set for Dreams. The first 20 glyphs have permanent IDs G01–G20. Changing a hypothesis about a character does not change its ID.

## 1. Catalogue and identification — current stage

- [x] Save the references from temporary attachments into `references/`.
- [x] Freeze the latest reconstruction `restored-v5.png` and the coordinates of the source crops in `provenance.json`.
- [x] Analyse all 20 forms: character, Unicode when the match is confident, reflection/rotation, alternatives, confidence level.
- [x] Check the subagent's conclusions against the frames and the user's confirmations.
- [x] Mark the missing forms from additional frames as a separate queue, without replacing the current IDs.

Result: `identifications.json`, `IDENTIFICATIONS.md`, the local `catalog.html`. The confidence value refers to the identification of a glyph, not to the quality of the restored contour. The user's confirmations outweigh the model's assumptions.

## 2. Restoration in small batches

- [ ] Start with the high-confidence forms, then take the disputed ones one at a time.
- [ ] Give GPT Image the source frame, the real character and an explicitly stated transformation. For an unknown glyph use a geometric description.
- [ ] Edit 1–4 glyphs per iteration; keep the previous version and the exact prompt.
- [ ] Keep clean contours without glow, grain and intentional damage. A light crossing of strokes is not a hole.
- [ ] Check that nothing outside the target glyphs changed unrequested.

Result: a version of every glyph, the reason for the edit, a comparison with the reference. Generation is a visual hypothesis, not proof of the original letterform.

## 3. Editable vectors and shape control

The tool of this stage is [PIPELINE.md](PIPELINE.md): `pipeline.py build` produces `build/glyphs/Gxx.svg` (real paths in font units), `adopt` moves a contour into manual editing, and the checks of topology, agreement with the sheet and orientation against the film run on every build.

- [x] Prepare separate SVGs with real editable paths for the user's manual finishing; keep the raster reference apart. Do not pass an embedded PNG off as a vector.
- [ ] Hand over simple contours with a moderate number of nodes and one coordinate system; keep the original versions.
- [ ] Take the latest edits into account: the crossbar kink of G04, the direction of G06's foot following the film, the reflection of G15.
- [ ] Check the number of strokes, connectivity, real openings and separate accents.
- [ ] Check reflection and orientation; G01 is a mirrored 5, G02 is a slashed 0.
- [ ] Compare at the same physical size, separately with minimal glow.
- [ ] Choose a common cell pitch and baseline, keeping the natural size of short glyphs.
- [ ] Check legibility at the real rain size and the density of neighbouring columns.

Criterion to move on: no known false holes, cut-off parts or substituted glyphs; disputed forms are explicitly marked, not presented as confirmed.

## 4. Atlas and a trial in Dreams

- [ ] Build a versioned atlas and metadata, keeping the current set for comparison.
- [ ] Connect the experimental set as a separate option.
- [ ] Check printing from top to bottom, single replacements and that faded lines do not return.
- [ ] Compare a short video render with the film; only then choose the main set.

## 5. TTF/OTF and extension

- [ ] If needed, trace the verified forms and build a font.
- [ ] Assign a cmap only to verified characters; give the unknown film forms internal IDs or documented PUA codes.
- [ ] Draw a consistent Latin and Cyrillic for keywords, separate from the reconstruction of the film glyphs.
- [ ] State the origin of every contour and check the rights to the source fonts used before distribution.

## Working cycle

`reference → hypothesis → reconstruction → visual review → accepted asset`

The Sol 6.1 / Medium subagent leads the identification and prepares targeted reconstruction briefs. The main agent checks the results and integrates the catalogue and app changes. New batches can be given to the same subagent. A subagent does not keep working by itself after its assigned task is done.

The references `film-reference-*.jpg` and `g17-clear.jpg` are the user's frames. `hypothetical-table.jpg` is only an illustration of the desired catalogue: its Unicode labels and shapes are not evidence. The Unicode specifications are used to check the identity of characters, not as a source of font outlines to copy.
