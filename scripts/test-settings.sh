#!/bin/zsh
set -euo pipefail
dreams_root="${0:A:h:h}"
cd "$dreams_root"
dreams_test_feed="$(mktemp -d "${TMPDIR:-/tmp}/dreams-settings.XXXXXX")"
trap 'rm -rf "$dreams_test_feed"' EXIT
DREAMS_FEED_DIRECTORY="$dreams_test_feed" swift test -c release
