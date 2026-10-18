#!/bin/zsh
# Keep the linked SDK current without raising the package deployment target.
# Swift Build can otherwise emit LC_BUILD_VERSION with SDK == deployment target.
set -euo pipefail
dreams_command="${1:?Usage: swift-macos.sh build|test [SwiftPM options]}"
shift
[[ "$dreams_command" == build || "$dreams_command" == test ]] || exit 2

typeset -a dreams_package_options=()
dreams_product=""
for (( dreams_index = 1; dreams_index <= $#; dreams_index++ )); do
  case "${argv[dreams_index]}" in
    --package-path|--scratch-path|--cache-path|--config-path|--security-path)
      dreams_package_options+=("${argv[dreams_index]}" "${argv[dreams_index + 1]}")
      (( dreams_index += 1 ))
      ;;
    --product)
      dreams_product="${argv[dreams_index + 1]}"
      ;;
    --package-path=*|--scratch-path=*|--cache-path=*|--config-path=*|--security-path=*)
      dreams_package_options+=("${argv[dreams_index]}")
      ;;
  esac
done
dreams_manifest="$(swift package "${dreams_package_options[@]}" dump-package)"
[[ "$(print -r -- "$dreams_manifest" | plutil -extract platforms.0.platformName raw -o - -)" == macos ]]
dreams_minimum="$(print -r -- "$dreams_manifest" | plutil -extract platforms.0.version raw -o - -)"
dreams_sdk="$(xcrun --sdk macosx --show-sdk-path)"
dreams_sdk_version="$(xcrun --sdk macosx --show-sdk-version)"

swift "$dreams_command" --sdk "$dreams_sdk" \
  -Xlinker -platform_version -Xlinker macos -Xlinker "$dreams_minimum" -Xlinker "$dreams_sdk_version" "$@"

# Validate the product instead of assuming the linker honored its SDK metadata.
if [[ "$dreams_command" == build && -n "$dreams_product" && " ${*} " != *" --show-bin-path "* ]]; then
  dreams_bin="$(swift build --sdk "$dreams_sdk" "$@" --show-bin-path)"
  dreams_build_info="$(xcrun vtool -show-build "$dreams_bin/$dreams_product")"
  dreams_linked_sdk="$(print -r -- "$dreams_build_info" | awk '$1 == "sdk" { print $2 }' | sort -u)"
  dreams_linked_minimum="$(print -r -- "$dreams_build_info" | awk '$1 == "minos" { print $2 }' | sort -u)"
  [[ "$dreams_linked_sdk" == "$dreams_sdk_version" && "$dreams_linked_minimum" == "$dreams_minimum" ]] \
    || { print -u2 "Unexpected macOS build metadata: min=$dreams_linked_minimum SDK=$dreams_linked_sdk"; exit 1; }
fi
