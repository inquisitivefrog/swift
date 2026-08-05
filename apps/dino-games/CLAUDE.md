Audio must complete before user input is re-enabled

## Release scope and `future-games` branch

- Ship **levels 1–4** only in the picker. Unreleased game **1024 masters** for Tools, Toothache, Fossil Hunt, Habitats, Lunch, Push, Whose Bones, and Ptero Formations were moved to git branch **`future-games`** (`bcf35920`). Empty `images/<those-games>/` on this branch is intentional.
- **Docs (search: future-games):** `docs/architecture/FUTURE_GAMES_BRANCH.md` (short) → `docs/architecture/APP_SIZE_AND_RELEASE_STRATEGY.md` (full).
- Restore: `git checkout future-games -- apps/dino-games/DinoGames/images/<folder>` then `git lfs pull`
- Do not re-add those into `Assets.xcassets` until the game ships (size / ASC limits).

## Flora series naming (Dino / Ptero / Marine Flora)

Plant instance = `(pack, formation, taxon)`. Registry: `dinoFloraPlants` in `LandGameDisplayMoment.swift`.

- **Images:** `{pack}-flora-{formation}-{taxon}-habitat` / `-seeds` (globally unique imageset names)
- **Audio:** `Audio/{Pack}-Flora/{FormationFolder}/{pack}-flora-{formation}-{taxon}.m4a`
- **Audio key:** same as filename stem (e.g. `dino-flora-morrison-cycad`)
- **FormationFolder** uses underscores (`Lance_Hell_Creek`); **formation slug** in names uses hyphens (`lance-hell-creek`)
- **Hints:** `Audio/{Pack}-Flora/hints/{pack}-hint-{concept}.m4a`

Add new plants to the registry first; CI audio contract tests must pass.
