# dino-teens (unreleased)

This game is **not** in shipping levels 1–4.

- **Xcode imagesets** (`Assets.xcassets/Dinosaur-Teens`) live on git branch **`future-games`** (see also `origin/future-games`). They are **not** on `main`, so they are **not** in the IPA.
- There are **no** separate `images/dino-teens` 1024 masters in-repo; the parked catalog holds the shipping-resolution PNGs.
- Docs: `docs/architecture/FUTURE_GAMES_BRANCH.md` → `docs/architecture/APP_SIZE_AND_RELEASE_STRATEGY.md`

## Restore imagesets (do not re-bundle into the IPA unless shipping this game)

```bash
git checkout future-games -- \
  apps/dino-games/DinoGames/DinoGames/Assets.xcassets/Dinosaur-Teens
git lfs pull
```
