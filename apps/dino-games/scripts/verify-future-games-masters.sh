#!/usr/bin/env bash
# verify-future-games-masters.sh
#
# For each unexposed Assets.xcassets game folder (not in levels 1–4), report:
#   - size / imageset count on the current (release) branch
#   - whether 1024 masters exist on git branch future-games under images/<map>
#   - gap status: OK / MISSING_MASTERS / NO_IMAGES_DIR_ON_FUTURE
#
# Usage (from anywhere):
#   bash apps/dino-games/scripts/verify-future-games-masters.sh
#   FUTURE_GAMES_REF=origin/future-games bash apps/dino-games/scripts/verify-future-games-masters.sh
#
# Docs: docs/architecture/FUTURE_GAMES_BRANCH.md
#       docs/architecture/APP_SIZE_AND_RELEASE_STRATEGY.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DINO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$DINO_ROOT" && git rev-parse --show-toplevel 2>/dev/null)"
ASSETS="$DINO_ROOT/DinoGames/DinoGames/Assets.xcassets"
FUTURE_REF="${FUTURE_GAMES_REF:-future-games}"

cd "$REPO_ROOT"

if ! git rev-parse --verify "$FUTURE_REF" >/dev/null 2>&1; then
  echo "ERROR: ref '$FUTURE_REF' not found. Fetch with: git fetch origin future-games"
  exit 1
fi

# Assets folder → images/ dirname on future-games (authoring layout)
CANDIDATES="
Dinosaur-Bones|dino-bones
Dinosaur-Characteristics|dino-characteristics
Dinosaur-Clues|dino-clues
Dinosaur-Coprolites|dino-coprolites
Dinosaur-Fauna|dino-fauna
Dinosaur-Formations|dino-formations
Dinosaur-Fossil-Hunt|dino-fossil-hunt
Dinosaur-Habitats|habitats
Dinosaur-Lunch|dino-lunch
Dinosaur-Push|dino-push
Dinosaur-Teens|dino-teens
Dinosaur-Tools|dino-tools
Dinosaur-Toothache|dino-toothache
Dinosaur-Wacky|dino-wacky
Pterosaur-Characteristics|ptero-characteristics
Whose-Bones|whose-bones
"

printf '%-28s %10s %8s %10s %10s %s\n' \
  "ASSETS_FOLDER" "DISK" "SETS" "FG_PNG" "FG_1024" "STATUS"
printf '%-28s %10s %8s %10s %10s %s\n' \
  "----------------------------" "----------" "--------" "----------" "----------" "------"

ok=0
warn=0
missing=0
absent=0

echo "$CANDIDATES" | while IFS='|' read -r assets_name images_name; do
  # skip blank lines
  [ -z "${assets_name:-}" ] && continue

  assets_path="$ASSETS/$assets_name"
  images_git_prefix="apps/dino-games/DinoGames/images/$images_name"

  if [ ! -d "$assets_path" ]; then
    printf '%-28s %10s %8s %10s %10s %s\n' "$assets_name" "-" "-" "-" "-" "NO_ASSETS_ON_RELEASE"
    echo "NO_ASSETS_ON_RELEASE" >> /tmp/verify-future-games-status.$$
    continue
  fi

  disk=$(du -sh "$assets_path" 2>/dev/null | awk '{print $1}')
  sets=$(find "$assets_path" -name '*.imageset' 2>/dev/null | wc -l | tr -d ' ')

  fg_list=$(git ls-tree -r --name-only "$FUTURE_REF" -- "$images_git_prefix" 2>/dev/null | grep -E '\.png$' || true)
  if [ -z "$fg_list" ]; then
    fg_png=0
    fg_1024=0
  else
    fg_png=$(printf '%s\n' "$fg_list" | wc -l | tr -d ' ')
    fg_1024=$(printf '%s\n' "$fg_list" | grep -c '1024' || true)
  fi

  if [ "$fg_1024" -gt 0 ]; then
    status="OK"
  elif [ "$fg_png" -gt 0 ]; then
    status="HAS_PNG_NO_1024_NAME"
  else
    status="MISSING_ON_FUTURE_GAMES"
  fi

  printf '%-28s %10s %8s %10s %10s %s\n' \
    "$assets_name" "$disk" "$sets" "$fg_png" "$fg_1024" "$status"

  # counts via side file because while-subshell
  echo "$status" >> /tmp/verify-future-games-status.$$
done

if [ -f /tmp/verify-future-games-status.$$ ]; then
  ok=$(grep -c '^OK$' /tmp/verify-future-games-status.$$ || true)
  warn=$(grep -c 'HAS_PNG_NO_1024_NAME' /tmp/verify-future-games-status.$$ || true)
  missing=$(grep -c 'MISSING_ON_FUTURE_GAMES' /tmp/verify-future-games-status.$$ || true)
  absent=$(grep -c 'NO_ASSETS_ON_RELEASE' /tmp/verify-future-games-status.$$ || true)
  rm -f /tmp/verify-future-games-status.$$
fi

echo ""
echo "Ref: $FUTURE_REF"
echo "Summary: OK=$ok  HAS_PNG_NO_1024_NAME=$warn  MISSING_ON_FUTURE_GAMES=$missing  NO_ASSETS_ON_RELEASE=$absent"
echo ""
echo "OK                     → safe to copy Assets onto future-games, then delete from release"
echo "HAS_PNG_NO_1024_NAME   → PNGs on future-games but not *1024* in name; inspect before delete"
echo "MISSING_ON_FUTURE_GAMES → harvest largest PNG from Assets into images/ on future-games first"
echo "NO_ASSETS_ON_RELEASE   → already gone from Assets on this branch"
echo ""
echo "Next: for OK rows, park Assets.xcassets/<Folder> on $FUTURE_REF, then remove from release."
