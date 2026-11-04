#!/usr/bin/env bash
# Usage: scripts/update-omikit.sh <omikit-git-tag>   e.g. 1.12.1
# Replaces the vendored ios/Frameworks/OmiKit.xcframework with the one from the given OmiKit tag.
# Then update the version comment in ios/omicall_flutter_plugin.podspec AND
# ios/omicall_flutter_plugin/Package.swift (SPM) so they stay in sync.
set -euo pipefail
VERSION="${1:?usage: $0 <omikit-git-tag>}"
DEST="$(cd "$(dirname "$0")/.." && pwd)/ios/Frameworks"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
git clone --quiet --depth 1 --branch "$VERSION" https://github.com/VIHATTeam/OmiKit.git "$TMP/OmiKit"
mkdir -p "$DEST"; rm -rf "$DEST/OmiKit.xcframework"
cp -R "$TMP/OmiKit/OmiKit.xcframework" "$DEST/"
echo "Vendored OmiKit $VERSION into $DEST/OmiKit.xcframework"
