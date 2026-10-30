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

## Distribution model

Owner decision (2026-10-25): the first tvOS release is a paid-upfront app — one
purchase at download gives access to all included features. No subscription or
in-app purchases are planned for this release.

The approved base price is **US$0.99 for the application itself**, using USA as
the pricing base territory. Other storefront prices follow Apple's automatic
equalization. See [Apple's app pricing guide](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price/).
Owner decision (2026-10-26): enable all 148 current Apple territories outside the
EU and exclude all 27 EU members; automatic availability in future territories is
disabled. The exact selection and API read-back are recorded in the
[availability record](app-store/availability.json). Confirm the account's paid-app
agreements and commercial details before release. This price configuration does
not publish the app or create any In-App Purchase products.
ASC read-back on 2026-10-25 confirmed app6826786729, base/territory USA,
currency USD, customerPrice0.99 and isFree=false.

## Store descriptions

The Russian description was approved by the owner on 2026-10-26;
the English version follows the same content and tone:

- [Russian](app-store/descriptions/ru.txt)
- [English (US)](app-store/descriptions/en-US.txt)
- [Spanish (Mexico)](app-store/descriptions/es-MX.txt)

These plain-text sources are for the App Store Description field. Editing them
does not upload metadata to App Store Connect. All three describe the current TV
rain, optional clock, remote settings and foreground-only application scope.
Canonical [metadata sources](app-store/README.md) include the subtitles, keywords
and URLs for each locale; descriptions match the plain-text files exactly.

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

- The owner closed the internal DreamsMatrix pre-release rights-review gate on
  2026-10-27 and authorized proceeding with the self-created font. Retain the
  [decision and complaint-response plan](app-store/release-decisions.md),
  [provenance](../research/glyphs/PIPELINE.md) and existing third-party notices.
  This owner decision does not record outside clearance or establish film fidelity.
- Confirm the installed Xcode/SDK is accepted for App Store submission.
- Verify Release on the owner's older Apple TV and a current Apple TV 4K:
  remote focus/swipes/Select/Back/PlayPause, paused/live preview, clock, errors,
  persisted tuning, frame cadence and a sustained-memory run.
- The owner-authorized 1.0/build1 IPA upload completed on 2026-10-27; Apple
  reports it VALID. See [upload record](app-store/README.md). Attaching a build
  to version1.0 and internal TestFlight group assignment were subsequently
  verified. The owner tester is INVITED; acceptance and device installation
  remain unverified. App Review submission remains a separate action.
- Publish/verify the separate App Privacy declaration and complete export
  compliance for the eventual build. EN/RU/es-MX metadata, localized screenshot
  sets, privacy text, age rating4+, category, copyright and review contacts were
  verified through the API on 2026-10-26; see [store field record](app-store/README.md).
  Launch availability was verified as 148 non-EU territories; confirm applicable
  agreements, any required trader-status declaration and content rights. Do not
  infer those answers solely from a passing build.
- Retain manual release for version1.0: changed from the initially observed
  AFTER_APPROVAL to MANUAL and verified on 2026-10-26.
- After attaching the intended build, run `asc release stage --dry-run`,
  `asc validate` and `asc review doctor` with `--platform TV_OS` where supported.
  Review submission and public release remain separate authorized actions.

See the [TV specification record](../specs/tvos/README.md) for current checks and
their scope. Simulator builds and local signing do not prove physical-device
performance, Apple processing or review acceptance.
