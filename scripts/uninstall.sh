#!/bin/zsh
# Removes Dreams from this Mac.
#   scripts/uninstall.sh              quit Dreams, remove its hooks and the app
#   scripts/uninstall.sh --purge      also remove settings, the keyword mailbox, caches and hook backups
#   scripts/uninstall.sh --dry-run    only list what would be done (combine with --purge)
# Installed with Homebrew? Use: brew uninstall --cask --zap dreams
set -uo pipefail
setopt null_glob

purge=0
dry=0
for arg in "$@"; do
  case "$arg" in
    --purge) purge=1 ;;
    --dry-run) dry=1 ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) print -u2 "Unknown option: $arg"; exit 2 ;;
  esac
done

home="${HOME:?}"
apps_dirs=("${DREAMS_APPLICATIONS:-/Applications}" "$home/Applications")
prefs_domains=(${=DREAMS_PREFS_DOMAINS:-ru.egormerkushev.dreams local.dreams.app})
root="${0:A:h:h}"

run() {  # run a command, or only print it with --dry-run
  if (( dry )); then print "  would: $*"; else "$@"; fi
}

print "== Quit Dreams"
if pgrep -x Dreams > /dev/null; then run pkill -x Dreams; else print "  not running"; fi

print "== Agent hooks (Codex, Claude Code)"
binary=""
for candidate in "${apps_dirs[@]}" "$root/dist/release" "$root/dist"; do
  if [[ -x "$candidate/Dreams.app/Contents/MacOS/Dreams" ]]; then binary="$candidate/Dreams.app/Contents/MacOS/Dreams"; break; fi
done
if [[ -z "$binary" ]]; then
  print "  Dreams.app not found, so its hooks cannot be removed automatically."
  print "  Remove the entries that run '.../Dreams.app/Contents/MacOS/Dreams --hook ...' from"
  print "  ~/.codex/hooks.json and ~/.claude/settings.json by hand."
elif (( dry )); then
  HOME="$home" "$binary" --uninstall-hooks --dry-run | sed 's/^/  /'
else
  HOME="$home" "$binary" --uninstall-hooks | sed 's/^/  /'
fi

print "== Application"
removed_app=0
for dir in "${apps_dirs[@]}"; do
  if [[ -d "$dir/Dreams.app" ]]; then run rm -rf "$dir/Dreams.app"; print "  $dir/Dreams.app"; removed_app=1; fi
done
(( removed_app )) || print "  no Dreams.app in ${apps_dirs[*]}"
if command -v brew > /dev/null && brew list --cask dreams > /dev/null 2>&1; then
  print "  Installed through Homebrew: also run  brew uninstall --cask dreams"
fi

if (( purge )); then
  print "== Settings, mailbox, caches"
  for domain in "${prefs_domains[@]}"; do
    if defaults read "$domain" > /dev/null 2>&1; then run defaults delete "$domain"; print "  preferences $domain"; fi
    if [[ -e "$home/Library/Preferences/$domain.plist" ]]; then run rm -f "$home/Library/Preferences/$domain.plist"; print "  $home/Library/Preferences/$domain.plist"; fi
    for item in "$home/Library/Caches/$domain" "$home/Library/Saved Application State/$domain.savedState" \
                "$home/Library/HTTPStorages/$domain" "$home/Library/WebKit/$domain"; do
      if [[ -e "$item" ]]; then run rm -rf "$item"; print "  $item"; fi
    done
  done
  for item in "$home/Library/Application Support/Dreams"; do
    if [[ -e "$item" ]]; then run rm -rf "$item"; print "  $item"; fi
  done
  print "== Hook config backups"
  for backup in "$home"/.codex/hooks.json.dreams-backup-* "$home"/.claude/settings.json.dreams-backup-*; do
    [[ -e "$backup" ]] && { run rm -f "$backup"; print "  $backup"; }
  done
fi

print "== Left for you to check"
for config in "$home/.codex/config.toml" "$home/.claude.json" "$home/.claude/settings.json"; do
  if [[ -f "$config" ]] && grep -qi 'dreams' "$config" 2>/dev/null; then
    print "  $config still mentions Dreams (an MCP server entry?): check it by hand"
  fi
done
(( purge )) || print "  settings and the keyword mailbox were kept; use --purge to remove them too"
(( dry )) && print "(dry run: nothing was changed)"
exit 0
