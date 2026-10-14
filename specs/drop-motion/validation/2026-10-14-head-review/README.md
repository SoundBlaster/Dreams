# PR #24 coverage-table correction — 2026-10-14

The shared coverage table now points Renderer.DropMotion to runtime `d3b962a` and the
[current head baseline](../2026-10-14-head/README.md), replacing its obsolete `3a4ad94`
reference. HeadAppearance has its own coverage row with the same current baseline and
an explicit outstanding physical compositor observation.

This is documentation only. Stable `dreams.rain.drop_motion`, `dreams.rain.head_visibility`
and `dreams.rain.search_occupancy` claim IDs, runtime source/map bytes, evidence and draft
acceptance remain unchanged. The 42 Swift/GPU and 12 tvOS Simulator results remain the
historical runtime observations of `d3b962a`; they are not new runs for this review commit.

[Fresh docs/structure checks](checks.log) and [identities](identity.json) record the
coverage repair separately. Remaining platform capability warnings do not establish
runtime behavior or formal acceptance.
