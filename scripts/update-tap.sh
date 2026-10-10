#!/bin/zsh
# Updates the Dreams cask in SoundBlaster/homebrew-tap to the version in VERSION and opens a PR.
#   scripts/update-tap.sh             after `make release` and `make github-release`
#   scripts/update-tap.sh --dry-run   show the change, push nothing
set -euo pipefail
dreams_root="${0:A:h:h}"
cd "$dreams_root"

dry=0
[[ "${1:-}" == "--dry-run" ]] && dry=1
version="${DREAMS_VERSION:-$(<VERSION)}"
dmg="${DREAMS_DMG:-dist/release/Dreams-$version.dmg}"
tap_repo="${DREAMS_TAP_REPO:-SoundBlaster/homebrew-tap}"

[[ -f "$dmg" ]] || { print -u2 "$dmg not found: run make release first"; exit 1; }
sha="$(shasum -a 256 "$dmg" | cut -d' ' -f1)"

if [[ -z "${DREAMS_TAP_SKIP_RELEASE_CHECK:-}" ]]; then
  # The cask downloads this exact file: the published asset must match the local DMG.
  gh release view "v$version" > /dev/null 2>&1 || { print -u2 "No GitHub release v$version: run make github-release first"; exit 1; }
  published="$(mktemp -d)"
  gh release download "v$version" -p "Dreams-$version.dmg" -D "$published" > /dev/null
  [[ "$(shasum -a 256 "$published/Dreams-$version.dmg" | cut -d' ' -f1)" == "$sha" ]] \
    || { print -u2 "The published DMG differs from $dmg"; exit 1; }
fi

work="$(mktemp -d)"
gh repo clone "$tap_repo" "$work/tap" -- --quiet --branch "${DREAMS_TAP_REF:-main}"
cd "$work/tap"
cask="Casks/dreams.rb"
[[ -f "$cask" ]] || { print -u2 "$cask is not on ${DREAMS_TAP_REF:-main} of $tap_repo yet: merge the PR that adds the cask first"; exit 1; }
current="$(sed -n 's/^  version "\(.*\)"/\1/p' "$cask")"
if [[ "$current" == "$version" ]]; then print "Cask is already at $version: nothing to do."; exit 0; fi

branch="cask-dreams-$version"
git switch -q -c "$branch"
sed -i '' -e "s/^  version \".*\"/  version \"$version\"/" -e "s/^  sha256 \".*\"/  sha256 \"$sha\"/" "$cask"
ruby -c "$cask" > /dev/null
git --no-pager diff

if (( dry )); then print "(dry run: $current -> $version, nothing pushed; clone in $work/tap)"; exit 0; fi
print -n "Open a PR in $tap_repo: dreams $current -> $version? [y/N] "
read answer
[[ "$answer" == "y" ]] || { print "Cancelled."; exit 1; }
git add "$cask"
git commit -q -m "dreams $version" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
git push -q -u origin "$branch"
gh pr create --repo "$tap_repo" --base main --head "$branch" --title "dreams $version" \
  --body "Updates the Dreams cask to [$version](https://github.com/SoundBlaster/Dreams/releases/tag/v$version).

sha256 \`$sha\`, checked against the published DMG.

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
