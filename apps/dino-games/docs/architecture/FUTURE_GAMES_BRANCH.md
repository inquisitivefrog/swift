# `future-games` git branch

**You are looking for this note if `images/dino-tools/` (or similar) is empty and git/LFS feels confusing.**

## Canonical write-up

**Full history, size limits, and packaging strategy:**

[`docs/architecture/APP_SIZE_AND_RELEASE_STRATEGY.md`](APP_SIZE_AND_RELEASE_STRATEGY.md)

(Repo path from `apps/dino-games/`: `docs/architecture/APP_SIZE_AND_RELEASE_STRATEGY.md`)

## One-minute version (SRE-friendly)

| Fact | Detail |
|------|--------|
| Branch | `future-games` / `origin/future-games` |
| Why it exists | Park **unreleased** high-res game art so the shipping app stays thinner |
| What moved (Jul 2026, `bcf35920`) | `DinoGames/images/` masters for Tools, Toothache, Fossil Hunt, Habitats, Lunch, Push, Whose Bones, Ptero Formations — **not** `Assets.xcassets` |
| LFS | Already repo-wide (`*.png` in `.gitattributes`). No per-branch enable. After `git checkout future-games`, run `git lfs pull` |
| Shipping app still fat? | Unreleased **imagesets** may still live under `DinoGames/Assets.xcassets/` on the release branch — those go in the IPA until removed |

## Restore masters onto this branch (do not re-bundle unless shipping)

```bash
git checkout future-games -- apps/dino-games/DinoGames/images/dino-tools
git lfs pull
```

Do **not** copy parked art into `Assets.xcassets` until that game is in levels 1–4 (or a later deliberate release).

## Verify before parking Assets off the release branch

```bash
bash apps/dino-games/scripts/verify-future-games-masters.sh
```

Reports per candidate folder whether `future-games` already has `*-1024*` under `images/<game>/`. **OK** → safe to copy Assets onto `future-games` then delete from release. **MISSING_ON_FUTURE_GAMES** → harvest from Assets first.
