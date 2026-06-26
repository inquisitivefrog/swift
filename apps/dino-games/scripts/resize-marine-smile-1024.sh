#!/usr/bin/env bash
# Generate @1x/@2x/@3x PNGs from marine-smile-*-1024.png masters.
# Usage: resize-marine-smile-1024.sh [directory ...]
# Default: all marine-smile-*-1024.png under DinoGames/images/marine-smile

set -euo pipefail

sizes=(80 160 240)
count=0

process_file() {
  local file="$1"
  local base="${file%-1024.png}"
  local size out
  for size in "${sizes[@]}"; do
    out="${base}-${size}.png"
    sips -Z "$size" "$file" --out "$out" >/dev/null
    echo "$out"
  done
  count=$((count + 1))
}

if [[ $# -eq 0 ]]; then
  root="$(cd "$(dirname "$0")/../DinoGames/images/marine-smile" && pwd)"
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    process_file "$file"
  done < <(find "$root" -name 'marine-smile-*-1024.png' | sort)
else
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    process_file "$file"
  done < <(find "$@" -name 'marine-smile-*-1024.png' | sort)
fi

if [[ "$count" -eq 0 ]]; then
  echo "No marine-smile-*-1024.png files found." >&2
  exit 1
fi

echo "Done: ${count} source(s) → $(( count * 3 )) resized file(s)."
