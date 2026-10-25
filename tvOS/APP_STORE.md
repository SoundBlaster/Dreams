# Apple TV App Store preparation

## Identity and scope

- App Store Connect: [Dreams TV, 6826786729](https://appstoreconnect.apple.com/apps/6826786729).
- Registered Bundle ID: `ru.egormerkushev.dreams.tv`; team `P8T2366K8X`.
- Store platform: `TV_OS` only; deployment target: tvOS 18.0.
- Initial marketing version/build: `1.0` / `1`, independent of macOS `VERSION`.
- `project.yml` is authoritative; regenerate the ignored Xcode project after edits.

This identifier has its own sandbox. The previous developer installation with
`ru.egormerkushev.DreamsTV` retains its separate settings and can remain installed;
the new app cannot automatically read that app's preferences. No migration or
uninstallation of the previous app is performed.

## Resources and privacy

`Sources/shared/assets/Assets.xcassets` contains the layered TV Home Screen icon,
1280×768 App Store icon and static standard/wide Top Shelf images. Assets are
committed, so ordinary builds do not require Pillow. Regenerate from the existing
`assets/icon/source.png` with `python3 scripts/make-tv-assets.py` (requires Pillow).
The generator uses the original artwork, without the macOS tile's rounded mask
or shadow. tvOS owns the icon mask and focus treatment.

`PrivacyInfo.xcprivacy` declares no tracking or collected data, and UserDefaults
reason `CA92.1`: this app reads/writes only its own saved tuning. Current target
membership includes local rendering/settings code and Apple frameworks, with no
network service, third-party SDK, agent feed or desktop executable dependency.
Re-audit these declarations if target membership or data handling changes. The
manifest is distinct from the App Privacy answers in App Store Connect.

References: [Apple icon configuration](https://developer.apple.com/documentation/xcode/configuring-your-app-icon),
[required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api),
[approved reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons).

## Local archive and export

Use an App Store-accepted Xcode/tvOS SDK. On Egor's host run the TB5 preflight for
this checkout's `tvOS` directory before building. Set `TV_DERIVED_DATA`,
`TV_ARCHIVE_PATH` and `TV_IPA_PATH` below to absolute paths on the verified volume;
do not reuse another checkout's products or silently fall back to internal storage.

```sh
xcodegen generate --spec tvOS/project.yml
asc xcode archive --project tvOS/DreamsTV.xcodeproj --scheme DreamsTV \
  --configuration Release --archive-path "$TV_ARCHIVE_PATH" \
  --xcodebuild-flag=-destination --xcodebuild-flag=generic/platform=tvOS \
  --xcodebuild-flag=-derivedDataPath --xcodebuild-flag="$TV_DERIVED_DATA" \
  --xcodebuild-flag=-IDEBuildLocationStyle=Unique
asc xcode export --archive-path "$TV_ARCHIVE_PATH" \
  --export-options tvOS/ExportOptions-AppStore.plist --ipa-path "$TV_IPA_PATH"
```

The per-process build-location override avoids global custom Xcode locations and
lets archive retain its own intermediate-product layout beneath Derived Data.
Select the verified ASC profile explicitly. With a stored team API key, the
installed `asc-xcode-build` skill's `with_xcode_auth.py` helper can wrap `archive`
and `export` and pass temporary credentials to Xcode for automatic provisioning.
It must not expose keys in source, logs or persistent exported config. Automatic
signing can create profiles/certificates; do not revoke unrelated identities.

The checked-in export options use `destination=export` and preserve explicit
version/build numbers. These commands produce a local IPA; they do not upload or
submit it. Before an eventual upload, verify Bundle ID, version/build, tvOS device
family, privacy/icon/font/shader resources, signature, provisioning application
identifier/team, `get-task-allow=false` and absence of desktop dependencies.
After extracting the IPA to a task-scoped directory on the verified build volume,
run `python3 scripts/check-tv-app.py /path/to/Payload/DreamsTV.app --version 1.0 --build 1`.
This checks actual resources, metadata, signature and provisioning, and reports
linked libraries for review. It does not prove App Store acceptance or API behavior.

## Remaining release gates

- Resolve the reconstructed font's pending redistribution rights review documented
  in [third-party notices](../THIRD_PARTY_NOTICES.md) and [glyph provenance](../research/glyphs/PIPELINE.md).
  Packaging the existing assets does not establish permission or film fidelity.
- Confirm the installed Xcode/SDK is accepted for App Store submission.
- Verify Release on the owner's older Apple TV and a current Apple TV 4K:
  remote focus/swipes/Select/Back/PlayPause, paused/live preview, clock, errors,
  persisted tuning, frame cadence and a sustained-memory run.
- Upload the approved source/build to TestFlight under a separately authorized
  distribution step; retain its commit, version/build and device evidence.
- Complete EN/RU metadata, screenshots, support/privacy URLs, App Privacy,
  age rating, export-compliance answers, pricing/availability and applicable
  agreements. Do not infer these answers solely from a passing build.
- Switch the store version to manual release before review (the initial 1.0
  record was observed with automatic `AFTER_APPROVAL` on 2026-10-25).
- After attaching the intended build, run `asc release stage --dry-run`,
  `asc validate` and `asc review doctor` with `--platform TV_OS` where supported.
  Review submission and public release remain separate authorized actions.

See the [TV specification record](../specs/tvos/README.md) for current checks and
their scope. Simulator builds and local signing do not prove physical-device
performance, Apple processing or review acceptance.
