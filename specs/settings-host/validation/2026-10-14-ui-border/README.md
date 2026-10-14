# PR #22 local UI border correction — 2026-10-14

Review found that the host baseline omitted its consumed local UI library. The
host now requires `dreams.settings.ui` (the library capability from the existing
catalog package), and its border names both the local Package.swift and
SettingsSliderRow.swift. A new source identity includes their full-file digests
and snapshots. App implementation source stays at `f0b7f0f`; original identities,
validation records and claim IDs are retained as historical evidence.

Fresh checks: HC profiles legacy/native, all SpecPM packages, relative docs links,
and current snapshot/hash consistency. A bounded negative check mutates each UI
input in a temporary copy and rejects the stale digest for each, without touching
the application/library checkout. Local capability availability remains an
unresolved requirement when the host package is validated on its own; its concrete
provider is explicitly linked and exported by the catalog package contract.

No app code, font, fixture or saved settings changed. No app launch, build, new
runtime/UI claim or CI monitoring was performed for this specification-only fix.

Reproduce the source/dependency check without modifying the checkout:

```sh
rtk proxy python3 specs/settings-host/validation/2026-10-14-ui-border/check-identity.py
```
