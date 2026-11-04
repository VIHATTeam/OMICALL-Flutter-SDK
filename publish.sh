#!/usr/bin/env bash
# Vendor the OmiKit version pinned in the podspec (ios/Frameworks is not in git), then publish.
set -euo pipefail
cd "$(dirname "$0")"
OMIKIT_VERSION="$(sed -n 's/.*Vendored version: \([0-9][0-9.]*[0-9]\).*/\1/p' ios/omicall_flutter_plugin.podspec)"
[ -n "$OMIKIT_VERSION" ] || { echo "OmiKit version not found in podspec"; exit 1; }
scripts/update-omikit.sh "$OMIKIT_VERSION"
flutter pub publish --dry-run
flutter pub publish
