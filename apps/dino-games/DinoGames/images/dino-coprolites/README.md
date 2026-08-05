# dino-coprolites (unreleased)

This game is **not** in shipping levels 1–4.

- **Xcode imagesets** (`Assets.xcassets/Dinosaur-Coprolites`) live on git branch **`future-games`** (see also `origin/future-games`). They are **not** on `main`, so they are **not** in the IPA.
- There are **no** separate `images/dino-coprolites` 1024 masters in-repo; the parked catalog is the archive.
- Docs: `docs/architecture/FUTURE_GAMES_BRANCH.md` → `docs/architecture/APP_SIZE_AND_RELEASE_STRATEGY.md`

## Restore imagesets (do not re-bundle into the IPA unless shipping this game)

```bash
git checkout future-games -- \
  apps/dino-games/DinoGames/DinoGames/Assets.xcassets/Dinosaur-Coprolites
git lfs pull
```
