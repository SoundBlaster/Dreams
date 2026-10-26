# Dreams TV store metadata

Scope: Dreams TV app 6826786729, tvOS version 1.0. The Russian description was
approved by the owner on 2026-10-26; English and Mexican Spanish follow its tone.
The app name remains Dreams TV in every locale.

## Sources

- [Russian description](descriptions/ru.txt)
- [English description](descriptions/en-US.txt)
- [Mexican Spanish description](descriptions/es-MX.txt)
- `metadata/app-info/*.json`: name, subtitle and privacy URL.
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
