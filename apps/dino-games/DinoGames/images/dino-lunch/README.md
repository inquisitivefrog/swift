# dino-lunch (unreleased)

This game is **not** in shipping levels 1–4.

- **1024 masters** and **Xcode imagesets** for `Dinosaur-Lunch` live on git branch **`future-games`** (see also `origin/future-games`).
- Docs: `docs/architecture/FUTURE_GAMES_BRANCH.md` → `docs/architecture/APP_SIZE_AND_RELEASE_STRATEGY.md`

## Restore (do not re-bundle into the IPA unless shipping this game)

```bash
git checkout future-games -- \
  apps/dino-games/DinoGames/images/dino-lunch \
  apps/dino-games/DinoGames/DinoGames/Assets.xcassets/Dinosaur-Lunch
git lfs pull
```
