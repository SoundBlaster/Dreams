# Identification of 28 Matrix glyphs

Status: first research version, 2026-10-09. All G01–G28 are accounted for; the original G01–G20 are kept, and the first new batch is G21–G28. The IDs fix the **shape from the film**, not a Unicode character: changing a hypothesis does not change the ID. No new contours were generated in this iteration and the app was not changed. (Quotations from the user were translated from Russian.)

**Summary:** 4 identifications are confirmed by the user, 12 have high confidence, 10 medium, 2 low. G24/G25 have medium confidence in the observed geometry, but no Unicode identity is assigned. All unconfirmed assignments remain hypotheses. Confidence refers to the identity of the character, not to the accuracy of the restored contour. Even "high" here is a structural match, not proof of the original film font.

## How to read the evidence

- [Direct crops and coordinates](references/provenance.json) tie G01–G20 to `1.mov`, t=2.00 s; coordinates are `(x0,y0,x1,y1)` in the source image of 3024×1900. The video was not decoded again in this pass; the saved crops and the user's photos were studied.
- [restored-v5.png](references/restored-v5.png) is the current reconstruction, 4 columns × 5 rows, row-major. It helps to find a shape but does not confirm its identity.
- [extraction-corrected.png](references/extraction-corrected.png) — the source on the left of every card, the mask estimate in the centre. The original old mask wrongly subtracted white intersections through `G-(R+B)/2`. For G04/G05/G08/G12/G14 these intersections are **solid**, not holes.
- [g17-clear.jpg](references/g17-clear.jpg) takes priority for G17: one connected glyph, a right stem with a bump upward, a top crossbar that bends down into a free hook on the left, a lower leg to the left, the middle open on the left.
- The [Unicode Katakana chart](https://www.unicode.org/charts/PDF/U30A0.pdf) and [Hiragana chart](https://www.unicode.org/charts/PDF/U3040.pdf) were viewed to compare structure and code points. The charts themselves state that their reference glyph shapes are not prescriptive. This is not evidence of the repertoire or of the original film font and not a source of contours to copy.

The original orientation, horizontal reflection, vertical reflection and rotations by 90°/180°/270° were tried as structural variants. No rotation received enough positive features to be assigned. `mirror_horizontal` means the ordinary Unicode character reflected left to right into the observed shape. `none` is a working hypothesis without a transformation. `not_distinguishable` — the silhouette is almost symmetric; `not_determined` — not enough data. G01, confirmed by the user, is reflected independently of any guesses about a global rule of the film.

## Catalogue

| ID | Working candidate | Transform | Confidence | What to check / fix |
|---|---|---|---|---|
| G01 | 5 `U+0035` | `mirror_horizontal` | `confirmed_by_user` | Keep the identity and orientation; compare the radii of the lower arc with the film. |
| G02 | 0 `U+0030` | `not_determined` | `confirmed_by_user` | Do not open the oval; check where the diagonal touches the frame. |
| G03 | ワ `U+30EF` | `mirror_horizontal` | `medium` | Compare the length of the short right stroke across several repetitions; do not normalise it to て. |
| G04 | オ `U+30AA` | `not_determined` | `confirmed_by_user` | Keep オ and the kink/step of the crossbar; do not flatten it to a straight bar and do not add a real gap without source evidence. Check reflection separately; the intersections are solid. Prepare an editable SVG for manual finishing. |
| G05 | せ `U+305B` | `none` | `medium` | Compare the repeated forms of せ/サ: especially the short right end and the bend of the long left leg; do not treat the choice as final. |
| G06 | マ `U+30DE` | `mirror_horizontal` | `medium` | Fix only the slope of the lower "foot" towards the bottom-right corner per the film source; keep the rest of the mirrored マ topology and do not reflect the whole glyph again. The current candidate sheet is not accepted; next an editable SVG. |
| G07 | 3 `U+0033` | `none` | `low` | P1: compare the upper arc and the lower turn with several instances; do not declare 3 confirmed. |
| G08 | * `U+002A` | `not_distinguishable` | `confirmed_by_user` | Place the small six-armed asterisk above the midline; check the provisional preview offset of −0.13 of the cell height visually against the film. Do not enlarge the glyph to full height. |
| G09 | ム `U+30E0` | `mirror_horizontal` | `high` | Keep the real open upper-left gap; check the angle of the long side. |
| G10 | ツ `U+30C4` | `mirror_horizontal` | `high` | Check the three separate components and the natural slope of the accents; do not merge them through glow in the clean contour. |
| G11 | 1 `U+0031` | `not_determined` | `high` | Keep the small upper bump, do not add a wide lower serif. |
| G12 | セ `U+30BB` | `mirror_horizontal` | `medium` | P1: compare the source with a horizontally mirrored セ: the upper crossing stroke, the long right stem, the open left branch and the lower bar. Keep the solid upper node; do not substitute a standard font glyph and do not merge with G17. |
| G13 | 7 `U+0037` | `none` | `high` | Keep the simple two-part geometry, do not add a middle crossbar. |
| G14 | ≠ `U+2260` | `stylized_cross_stroke_orientation_unresolved` | `medium` | P1: compare the hypothesis of a stylised ≠ with the film: two horizontal bars and an almost vertical stroke crossing them; refine the slope while keeping the intersections solid. Do not turn it into a literal pair of ! and =. |
| G15 | ハ `U+30CF` | `mirror_horizontal` | `high` | Keep the horizontal reflection of ハ confirmed by the user: two separate diverging parts and an upper opening. For the editable SVG keep the asymmetry of the strokes; do not symmetrise. |
| G16 | エ `U+30A8` | `not_distinguishable` | `medium` | Keep the I-shaped contour; do not treat the code point as confirmed without repertoire evidence. |
| G17 | セ `U+30BB` | `mirror_horizontal` | `medium` | P0: per g17-clear.jpg compare the hypothesis of a mirrored セ with G12, keeping the separate IDs. A right stem with a short upper bump, a connected open left hook and a lower leg to the left are mandatory; identity and reflection remain hypotheses. |
| G18 | 9 `U+0039` | `mirror_horizontal` | `low` | P1: compare with the other digits and check the relation of the closed top to the free lower tail; do not turn it into a solid P. |
| G19 | ミ `U+30DF` | `mirror_horizontal` | `high` | Keep the three separate strokes, the common slope and the difference in lengths; do not straighten it into the character 三. |
| G20 | ス `U+30B9` | `mirror_horizontal` | `medium` | P1: compare the source with a horizontally mirrored ス from the user's sample: check the slope of the long stroke, the position of the lower branch and the asymmetry. Do not keep the symmetry of v5 automatically. |
| G21 | 8 `U+0038` | `not_determined` | `high` | Check two real inner cavities and a continuous outer frame; keep the manual SVG preliminary until compared with the source. |
| G22 | 4 `U+0034` | `none` | `confirmed_by_user` | An ordinary 4 without a lower bar: the user clarified that the lower stroke belongs to the neighbouring glyph. Below the middle crossbar only the right stem continues. |
| G23 | : `U+003A` | `not_determined` | `high` | Keep two separate square dots and their vertical interval, and the narrow width; do not stretch each square into a bar. |
| G24 | no Unicode assigned | `not_determined` | `medium` | Draw two separate slightly slanted bars per the source; leave candidate_character and Unicode null until equals/ニ is checked. |
| G25 | no Unicode assigned | `not_determined` | `medium` | Keep the single short bar of small height and the source width; leave Unicode null, and do not assign a baseline from a single crop. |
| G26 | < `U+003C` | `not_determined` | `high` | Keep the angle open on the right and the merged left vertex; do not substitute G27 or the triangular G09 for the separate G26. |
| G27 | > `U+003E` | `not_determined` | `high` | Keep the right vertex and the source asymmetry; do not obtain an accepted contour by automatically mirroring G26 without a visual check. |
| G28 | + `U+002B` | `not_determined` | `high` | Keep a compact four-armed cross with a solid centre; do not stretch it to full height and do not add a second bar or rays. |

## Disputed points and limits of the conclusion

- **G03:** the working version is a mirrored ワ, because it has a short right vertical and a long left arc. Hiragana て remains an alternative; the form must not be replaced with て or フ automatically.
- **G05:** せ and a mirrored サ have a similar topology. The long lower arc supports hiragana せ but does not prove it. The number and connectivity of the strokes are more reliable than this label.
- **G06:** the user clarified: "G04 is the katakana `o`. G06 is, as it were, a mirrored `ma`." The working candidate is now a horizontally mirrored マ MA (`U+30DE`), confidence medium: the words "as it were" keep the hypothetical status. The earlier mirrored タ remains an alternative. Compare the upper bar, the inner bump, the lower end and the connectivity with the film.
- **G07:** an angular 3 is a weak version. A mirrored 2 and ろ are not excluded. The upper arc and the lower angular bowl must be compared separately.
- **G12/G17:** similar forms must not be treated as duplicates. In v5, G12 has a wide lower bar with two sides, while G17 has a confirmed leg to the left; the upper bumps differ. For G17 the user suggested "G17 also looks like `se`": the main candidate is now セ (`U+30BB`), confidence medium. Horizontal reflection is a working interpretation in the context of G12 and the user did not confirm it separately; the earlier mirrored ヤ is kept as an alternative. G12/G17 may turn out to be variants of one character but remain separate IDs and contours. For G12 the user suggested: "G12 looks like a mirrored `se`" — the working candidate is a horizontally mirrored セ SE (`U+30BB`), confidence medium, not confirmed. Compare the topology with the film; the upper node is solid, the short left branch and the middle on the left are open. The earlier alternatives ウ/ヤ/す are kept in the JSON.
- **G14:** the user proposed a hypothesis: "G14 is probably != that is a crossed-out space". The working interpretation is a stylised NOT EQUAL TO ≠ (`U+2260`), written textually as `!=`; the word "space" is preserved literally, its meaning is not clarified. Confidence is medium, not confirmed_by_user. Two horizontal bars and a crossing almost vertical stroke are observed; this is no basis for declaring a rotation or for drawing a separate pair `!` and `=`. The alternatives キ and the double dagger ‡ are kept.
- **G16:** エ versus Latin I is a real semantic ambiguity of close silhouettes. The catalogue keeps the alternatives; do not fix a cmap for disputed forms yet.
- **G18:** a mirrored 9 and a lowercase e look alike. The closed upper counter is observable, the numeric value is not confirmed.
- **G04:** in the same exact quotation "G04 is the katakana `o`. G06 is, as it were, a mirrored `ma`." the user confirmed オ O (`U+30AA`), confidence confirmed_by_user. The reflection for G04 is not stated explicitly, so the transform remains not_determined. The intersections are solid; check the lower ends and the orientation against the source, and do not replace them with a standard font contour.
- **G08:** the user confirmed: "it is an asterisk, yes, but it must be drawn above the midline". This is `* U+002A`, confidence confirmed_by_user. Keep a small six-armed glyph above the middle. `metrics.vertical_anchor=above_midline`; `preview_offset_y=-0.13` is a provisional shift as a fraction of the cell height for the preview, not an exact number from the user.
- **G20:** the user asked "is this a mirrored su?" and attached a [standard ス SU](references/g20-su.png). The working hypothesis is `ス U+30B9`, horizontal reflection, confidence medium. The question is not a confirmation. Compare the long diagonal stroke and the short lower branch; v5 may have wrongly made the glyph symmetric. The alternatives are kept in the JSON.

## The user's latest contour edit

Exact quotation: "G04 has a 'broken' crossbar. The slope of G06's 'foot' goes the wrong way. And by the way G15 is in fact mirrored. I would tune the vector by hand later."

- **G04:** keep the kink/step of the crossbar; do not smooth it into a straight bar. "Broken" does not prove a disconnected gap: do not add a real gap without source evidence.
- **G06:** the user pointed out an error in the slope; the direction is our visual interpretation: in the [candidate sheet](references/kana-candidates-v1.png) the end points down-left, while in the film source and the earlier reconstruction it points down-right. Fix the local "foot" towards the bottom-right corner, keeping the rest of the shape; do not reflect the whole glyph again.
- **G15:** horizontal reflection is confirmed by the user. The identity ハ keeps high confidence: the user confirmed the orientation but did not name the character separately.

The current candidate sheet of five glyphs is **not accepted**. The next phase is separate editable SVG contours for every glyph: trace the clean base with real paths, keep the asymmetry and the separate components, and prepare them for the user's manual finishing. An SVG with a single embedded bitmap is not such a vector result.

## Queue of targeted work

1. **P0 — keep the invariants already established.** G01 = mirrored 5; G02 = closed slashed 0; G17 is one connected form open on the left. In the clean contours of G04/G05/G08/G12/G14 there are no holes from white highlights. This is a topology check, not a new generation.
2. **P1 — repeated film instances first.** G04 (orientation and bottom), G06 (mirrored マ: the inner stroke), G07 (the lower turn), G12/G17 (mirrored セ and the differences between the forms), G14 (the ≠ hypothesis and the slope of the crossing stroke), G16 (identity ambiguity), G18 (9/e), G20 (mirrored ス: the diagonal and the asymmetry). For each, compare 2–3 instances from the additional photos, then change one glyph at a time.
3. **P2 — contour finishing of recognisable forms.** G03/G05: refine the terminals without imposing a font; G09/G10/G19: keep the separate strokes and the orientation; G15: keep the confirmed horizontal reflection and the asymmetry; G08: keep it short and raise it above the cell midline. Check sizes, radii and serif proportions at the same scale as the reference.
4. **Checking the result.** Before accepting a reconstruction, compare the number of components, real counters and free ends; check that the other IDs did not change. Record the Unicode identity and the visual acceptance of the contour separately.

A ready brief for every glyph is in the `reconstruction_prompt` field of [identifications.json](identifications.json). It is an instruction for a future reconstruction, not a reason to consider it already done.

## First batch G21–G28 and the remaining queue

M01–M08 were converted into the stable G21–G28 respectively. This is the first batch of **preliminary manual reconstruction** of native SVG from the user's film references, not a claim that the contours are exactly original. The existing 20 JSON records are unchanged. M09–M11 remain a research queue and are not part of this batch. The earlier search pointers for M are kept below; the corrected primary source boxes for the new batch are given separately. The photo size is 1280×589.

| New note ID | Observed shape | Where to look | Preliminary version / caveat |
|---|---|---|---|
| M01 | Two closed counters one above the other | [film-reference-1.jpg](references/film-reference-1.jpg), around (1074, 51); also (268, 117) | G21; digit 8, high visual recognisability. |
| M02 | Open angular top, a middle crossbar, a long right stem | [film-reference-2.jpg](references/film-reference-2.jpg), around (745, 28); [film-reference-3.jpg](references/film-reference-3.jpg), around (476, 50) | G22; digit 4; no reflection assigned. Do not confuse with G04. |
| M03 | Two separate square dots, vertical | [film-reference-1.jpg](references/film-reference-1.jpg), around (691, 121) | G23; colon `:`; tell the two dots from a fragment of neighbouring lines. |
| M04 | Two short horizontal bars | [film-reference-1.jpg](references/film-reference-1.jpg), around (517, 201) | G24; `=` or ニ, no Unicode assigned. The earlier locator is unreliable: use the corrected crop below. |
| M05 | One short horizontal bar | [film-reference-1.jpg](references/film-reference-1.jpg), around (518, 165) | G25; minus / hyphen / ー, no Unicode assigned. |
| M06 | Two diagonals meeting at the left corner | [film-reference-1.jpg](references/film-reference-1.jpg), around (309, 56) | G26; `<`, two diagonals, not the closed triangular G09. |
| M07 | Two diagonals meeting at the right corner | [film-reference-1.jpg](references/film-reference-1.jpg), around (1081, 560); [film-reference-2.jpg](references/film-reference-2.jpg), around (991, 276) | G27; `>`, a separate ID, not automatically the mirrored contour of G26. |
| M08 | A cross of a vertical and one crossbar | [film-reference-2.jpg](references/film-reference-2.jpg), around (990, 496); [film-reference-3.jpg](references/film-reference-3.jpg), around (269, 189) | G28; plus `+`. The earlier locators are wrong, use the corrected crop below. |
| M09 | Two short separate upper strokes | [film-reference-1.jpg](references/film-reference-1.jpg), around (813, 118); [film-reference-3.jpg](references/film-reference-3.jpg), around (380, 516) | A quote / dakuten-like mark; do not declare it punctuation before checking whether it is a fragment of a neighbouring kana. |
| M10 | A rectangular frame with an inner crossbar | [film-reference-1.jpg](references/film-reference-1.jpg), around (817, 500); [film-reference-2.jpg](references/film-reference-2.jpg), around (620, 355) | An angular 8/B-like form; check whether it is the same glyph as M01 in another stylisation or a separate glyph. |
| M11 | A long right vertical stroke and three bars to the left | [film-reference-1.jpg](references/film-reference-1.jpg), around (818, 60); [film-reference-2.jpg](references/film-reference-2.jpg), around (601, 33) | A ヨ-like form; needs a crop, no reflection assigned by the general rule. |

Do not extend the set automatically to the full Katakana alphabet: these photos confirm the visible shapes, not the full repertoire of the film. The current batch is limited to G21–G28. The next step is to match the eight editable SVGs against the exact source crops; study M09–M11 separately after that.

## Source boxes and size of the first new batch

The windows `(x0,y0,x1,y1)` were visually checked on enlarged crops and contain small margins; they are the recommended windows for integration. The final source crops and their provenance are fixed by the main agent. The sources of G21–G28 are photos, not t=2.00 s video crops like the original G01–G20; the earlier timestamp must not be assigned to them automatically.

| ID | Photo | Recommended box | Proportions in the preview |
|---|---|---|---|
| G21 | film-reference-1.jpg | `[1050,21,1094,85]` | Full-size 8; two real counters. |
| G22 | film-reference-2.jpg | `[720,9,768,65]` | Full-size 4; keep the source slope, do not mirror automatically. |
| G23 | film-reference-1.jpg | `[675,91,706,151]` | A narrow pair of square dots; total height about 0.8 of full size, width about 0.35. |
| G24 | film-reference-2.jpg | `[90,87,133,128]` | Two bars together about 0.55 of the height, 0.8 of the width; a slight rise to the right. |
| G25 | film-reference-1.jpg | `[497,151,539,176]` | One bar about 0.12–0.18 of the height and 0.8 of the width; do not stretch vertically. |
| G26 | film-reference-1.jpg | `[287,26,326,81]` | Left vertex, opening on the right; about 0.7–0.8 of the height, 0.6–0.7 of the width. |
| G27 | film-reference-2.jpg | `[972,225,1011,269]` | Right vertex, opening on the left; compare its own asymmetry with G26. |
| G28 | film-reference-2.jpg | `[936,439,972,478]` | A compact plus, about 0.6–0.7 of the full height and width. |

The proportions are optical guides from the photos relative to full-size neighbouring glyphs, not exact font metrics. Place the short glyphs near the optical middle of the provisional cell; do not establish an exact baseline from single crops. The user's instruction "above the midline" refers to G08 and is not carried over automatically to G23–G28. No reflection/rotation is assigned for the new eight: the observed direction of `<`/`>` is stored by the character itself, and the origin through a transform is unknown. G24/G25 remain forms without a cmap identity until a separate check.

## Provenance and reproducibility

The JSON contains exactly 28 stable IDs, observations `Gxx-O1…`, evidence `REF-Gxx`, alternatives and per-glyph briefs. The sources are the user's film references; reconstruction v5 and the masks are separated from the primary visual material. Unicode is used as a structural reference; no font outlines were extracted or copied from the charts. Before distributing a new font it must be established separately whether the film-derived contours and assets may be used; this research catalogue grants no licence to them.

## Clarification of G22, 2026-10-10

The user: "g22 is a plain 4. The lower stroke is from the neighbouring glyph." The wide lower bar was removed from the reconstruction and the right stem kept. The original crop was left unretouched as evidence of the segmentation error. The corrected sheet `references/g22-v2.png` was added separately; the earlier frozen sheet was not overwritten.
