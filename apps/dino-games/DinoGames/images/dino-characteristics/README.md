# dino-characteristics (unreleased)

This game is **not** in shipping levels 1–4.

- **1024 masters** and **Xcode imagesets** for `Dinosaur-Characteristics` live on git branch **`future-games`** (see also `origin/future-games`).
- Docs: `docs/architecture/FUTURE_GAMES_BRANCH.md` → `docs/architecture/APP_SIZE_AND_RELEASE_STRATEGY.md`

## Restore (do not re-bundle into the IPA unless shipping this game)

```bash
git checkout future-games -- \
  apps/dino-games/DinoGames/images/dino-characteristics \
  apps/dino-games/DinoGames/DinoGames/Assets.xcassets/Dinosaur-Characteristics
git lfs pull
```
