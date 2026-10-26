# Dreams TV store metadata

Scope: Dreams TV app 6826786729, tvOS version 1.0. The Russian description was
approved by the owner on 2026-10-26; English and Mexican Spanish follow its tone.
The app name remains Dreams TV in every locale.

## Sources

- [Russian description](descriptions/ru.txt)
- [English description](descriptions/en-US.txt)
- [Mexican Spanish description](descriptions/es-MX.txt)
- `metadata/app-info/*.json`: name, subtitle, privacy URL and Apple TV privacy policy text.
- `metadata/version/1.0/*.json`: description, keywords and support/marketing URLs.

The JSON descriptions must exactly match the corresponding plain-text files,
excluding the final newline. Keep both representations current when editing.

The owner chose to retain matrix/матрица in Keywords after discussing the review
risk. Those terms and green/зеленый are not added to visible names, subtitles or
descriptions. RU uses Russian keywords without repeating the English strings.
The es-MX keyword field supplements en-US with different English search terms;
its visible description and subtitle are Mexican Spanish. Keyword relevance is
source-reviewed, not search-volume measured. Cross-localization behavior on
tvOS remains unverified; no search-ranking outcome is promised.

The website currently supports EN/RU. es-MX support, marketing and privacy URLs
therefore open its English pages. This is store-listing localization only; it
does not add a Spanish interface to the tvOS application.

## Validate and preview

```sh
asc metadata validate --dir tvOS/app-store/metadata --check-urls
asc metadata push --app 6826786729 --version 1.0 --platform TV_OS \
  --dir tvOS/app-store/metadata --dry-run
```

Always pull current remote metadata into a separate directory before applying,
inspect the field-level plan and preserve unrelated fields/locales. Omitted
fields are no-ops; do not use --allow-deletes for this update. Remote application
of translations follows the explicit reviewed-text approval step.

Historical evidence remains separate from later uploads. This source addition
does not itself prove metadata has been applied, screenshots copied, TestFlight
uploaded or the store version submitted.

## Remote verification on 2026-10-26

After the owner approved the reviewed three-locale text, canonical metadata was
applied to app 6826786729, TV_OS version 1.0. A fresh metadata pull confirmed
all seven supplied fields per locale (three app-info, four version fields)
exactly match these files for en-US, ru and es-MX.

The first apply succeeded for app-info records and en-US version fields, then
reported existing-locale conflicts for ru/es-MX version records automatically
created by Apple. A fresh dry-run targeted two version-localization updates;
the second apply succeeded. Existing screenshots were not changed by this
metadata update. No build upload, review submission or public release occurred.

## Localized screenshots verified on 2026-10-26

[Upload manifest](screenshots.json) records asset IDs, order, dimensions and
checksums read back from App Store Connect. RU contains rain, clock and a newly
captured Russian menu; es-MX contains the same language-independent rain and clock
frames without a menu. No Spanish app interface is implied. All five assets
reached COMPLETE at 1920×1080 and their MD5 checksums match the supplied files.
The initial es-MX clock processing wait timed out, but a later read-back confirmed
completion for that same asset without reuploading or creating a duplicate.

The original captures remain on the local build volume; retrieve the uploaded
assets with `asc screenshots download` using the corresponding version
localization ID. No app source changed during screenshot preparation.

## API field verification on 2026-10-26

- Apple calculated the global age rating FOUR_PLUS (4+) after the questionnaire
  was completed with all content/capability answers NONE/false. The accepted
  [answers](age-rating-answers.json) do not opt into the Kids category or impose
  an age override.
- Primary category: ENTERTAINMENT.
- Copyright: 2026 Egor Merkushev.
- Version 1.0 release type: MANUAL.
- Apple TV privacy policy text is populated in en-US, ru and es-MX. Sources:
  [English](privacy/en-US.txt) and [Russian](privacy/ru.txt). es-MX intentionally
  uses English policy text, matching its English privacy URL. This does not
  publish or confirm the separate App Privacy data-collection declaration.
- App Review contact fields use the owner's supplied details and were read back
  exactly. Private contact/phone receipts stay outside the repository. The
  [review instructions](review-notes.txt) require no demo account.
- Fresh metadata pull matches every supplied field. The readiness check no
  longer reports missing age rating, category, review details or copyright.
- No build was uploaded or attached; version 1.0 remains PREPARE_FOR_SUBMISSION.

Content-rights declaration remains unset pending the documented font-rights
review. Launch territories require the owner's choice. App Privacy publication
and agreement readiness still require a working Apple web session or manual
verification. These remain separate from the completed API fields.

## App Privacy preparation on 2026-10-26

[App Privacy declaration](app-privacy.json) is the prepared desired declaration
for the TV-only app: DATA_NOT_COLLECTED. It follows the installed asc5.17.0
canonical privacy JSON schema and the reviewed TV target, which stores preferences
locally and has no network integration or analytics SDK. It is separate from the
already populated Apple TV policy text and from PrivacyInfo.xcprivacy.

This draft has not been applied or published. The current CLI reports no usable
web session, so remote privacy state, live catalog validation and publication
remain unverified. Once authentication works, run a fresh privacy pull and plan
before applying; never infer live state from this file. Launch availability also
remains unchanged while the owner considers EU distribution requirements.
