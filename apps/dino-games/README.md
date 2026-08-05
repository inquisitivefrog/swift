# Dino Games

Native iOS educational games for children ages 4–6. SwiftUI app with image- and audio-first UX (minimal reading required).

## Quick start

```bash
open DinoGames/DinoGames.xcodeproj
```

Build and run the **DinoGames** scheme on any iOS Simulator. See [docs/development/SETUP.md](docs/development/SETUP.md) for project layout and [docs/development/README.xcodebuild.md](docs/development/README.xcodebuild.md) for CLI builds.

## Documentation

| Folder | Contents |
|--------|----------|
| [docs/architecture/](docs/architecture/) | Code layout, content layers, platform refactor roadmap |
| [docs/development/](docs/development/) | Conventions, setup, testing, Xcode workflows |
| [docs/brainstorm/](docs/brainstorm/) | Early ideation and design decisions |
| [docs/design/](docs/design/) | Product philosophy, child UX, technical design |
| [docs/gameplay/](docs/gameplay/) | Per-game design and implementation notes |
| [docs/reference/](docs/reference/) | Asset, audio, and data naming tables |

Start with [docs/README.md](docs/README.md) or the full index at [docs/FILE_INDEX.md](docs/FILE_INDEX.md).

## Project layout

```
apps/dino-games/
├── DinoGames/                 # Xcode project root
│   ├── DinoGames/             # App target (Swift + bundled assets)
│   │   ├── App/               # Entry point, persistence
│   │   ├── Views/             # Game screens
│   │   ├── Catalogs/          # Game & mechanic registries
│   │   ├── Data/              # Species/content data
│   │   ├── Progress/          # Per-category save state
│   │   ├── GameLogic/         # Shared comparison/guess logic
│   │   ├── Assets.xcassets/   # Runtime images
│   │   └── Assets/Audio/      # Runtime audio
│   ├── json/                  # Authoring JSON (bundled)
│   ├── images/                # Source images (not bundled)
│   ├── DinoGamesTests/
│   └── DinoGamesUITests/
├── docs/                      # All human-facing documentation
└── scripts/                   # Asset/tooling scripts
```

## Shipping scope

Land / air / sea: **levels 1–4** in the game picker (`GameLevel.visibleInGamePicker`). Extra land games (levels 5+) may still have code and JSON on this branch.

**High-res masters for several unreleased games live on git branch `future-games`** (not an LFS glitch if `images/dino-tools/` etc. look empty here).

- Short: [docs/architecture/FUTURE_GAMES_BRANCH.md](docs/architecture/FUTURE_GAMES_BRANCH.md)  
- Full: [docs/architecture/APP_SIZE_AND_RELEASE_STRATEGY.md](docs/architecture/APP_SIZE_AND_RELEASE_STRATEGY.md)  

(Commit `bcf35920`; folders: Tools, Toothache, Fossil Hunt, Habitats, Lunch, Push, Whose Bones, Ptero Formations.)

Do **not** copy those masters into `Assets.xcassets` until that game is scheduled to ship (app is already ~1.2 GB thinned).

## Content pipeline

Authoring (`json/`, `images/`) → runtime bundle (`Assets.xcassets`, `Assets/Audio`) → Swift catalogs (`Catalogs/`, `Data/`). Contract tests in `DinoGamesTests/` verify audio and imagesets stay aligned. Unreleased masters may be parked on **`future-games`** instead of `images/` on the release line.
