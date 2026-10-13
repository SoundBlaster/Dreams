#!/bin/zsh
set -euo pipefail
dreams_root="${0:A:h:h}"
cd "$dreams_root"
dreams_fsd_ref="$(<.fsd-version)"
dreams_fsd_dir="${DREAMS_FSD_TOOLING_DIR:-$dreams_root/.fsd-ios-tooling}"
if [[ ! -d "$dreams_fsd_dir/.git" ]]; then
    git init --quiet "$dreams_fsd_dir"
    git -C "$dreams_fsd_dir" remote add origin https://github.com/SoundBlaster/FSD.git
    git -C "$dreams_fsd_dir" fetch --quiet --depth 1 origin "$dreams_fsd_ref"
    git -C "$dreams_fsd_dir" checkout --quiet --detach FETCH_HEAD
fi
if [[ "$(git -C "$dreams_fsd_dir" rev-parse HEAD)" != "$dreams_fsd_ref" ]] || \
   [[ -n "$(git -C "$dreams_fsd_dir" status --porcelain --untracked-files=no)" ]]; then
    print -u2 "FSD tooling must be clean at $dreams_fsd_ref. Use a separate checkout or remove .fsd-ios-tooling and retry."
    exit 1
fi
swift "$dreams_fsd_dir/tools/fsd-ios.swift" lint --config "$dreams_root/.fsd-ios.yml" "$@"
