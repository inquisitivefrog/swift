# dino-bones (unreleased)

This game is **not** in shipping levels 1–4.

- **Xcode imagesets** (`Assets.xcassets/Dinosaur-Bones`) live on git branch **`future-games`** (see also `origin/future-games`). They are **not** on `main`, so they are **not** in the IPA.
- **1024 masters** under this folder may still exist on `main` for authoring. They are **not** in the app target / IPA. The same masters are also archived on `future-games`.
- Docs: `docs/architecture/FUTURE_GAMES_BRANCH.md` → `docs/architecture/APP_SIZE_AND_RELEASE_STRATEGY.md`

## Restore imagesets (do not re-bundle into the IPA unless shipping this game)

```bash
git checkout future-games -- \
  apps/dino-games/DinoGames/images/dino-bones \
  apps/dino-games/DinoGames/DinoGames/Assets.xcassets/Dinosaur-Bones
git lfs pull
```
