#!/bin/bash
# Regenerates ImageAssetNames.generated.swift from the asset catalog.
# Run this when adding new image assets to keep imageExists checks accurate.
# Usage (from apps/dino-games): ./scripts/regenerate-asset-names.sh

set -e
ROOT="$(cd "$(dirname "$0")/../DinoGames" && pwd)"
cd "$ROOT"
OUTPUT="DinoGames/Support/ImageAssetNames.generated.swift"

{
  echo "// Auto-generated - do not edit. Run scripts/regenerate-asset-names.sh to regenerate."
  echo ""
  echo "import Foundation"
  echo ""
  echo "enum ImageAssetNames {"
  echo "    static let knownAssets: Set<String> = ["
  find DinoGames/Assets.xcassets -name "*.imageset" -type d | sed 's|.*/||' | sed 's/\.imageset//' | sort | while read name; do
    printf '        "%s",\n' "$name"
  done
  echo "    ]"
  echo "}"
} > "$OUTPUT"

echo "Generated $OUTPUT"
