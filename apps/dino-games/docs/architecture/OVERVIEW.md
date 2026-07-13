# Architecture overview

## Xcode project

```
DinoGames/                          # Project root (open DinoGames.xcodeproj here)
├── DinoGames/                      # App target
│   ├── App/                        # DinoGamesApp, ContentView, Persistence
│   ├── Views/                      # Game screens
│   │   └── Shared/                 # Victory sequence, eggs shared, audio lock
│   ├── Catalogs/                   # Game catalogs, mechanic catalogs
│   ├── Data/                       # Species pools, display moments, flora registry
│   ├── Progress/                   # Per-category and per-game save state
│   ├── GameLogic/                  # Comparison, guess, racing geometry
│   ├── Morphology/                 # Smile & dental morphology helpers
│   ├── Support/                    # Image cache, generated asset names
│   ├── Assets.xcassets/            # Bundled images (imagesets)
│   ├── Assets/Audio/               # Bundled audio (.m4a)
│   └── DinoGames.xcdatamodeld/     # Core Data
├── json/                           # Authoring JSON (bundled with app)
├── images/                         # Source art (not bundled; export to xcassets)
├── DinoGamesTests/                 # Unit + contract tests
└── DinoGamesUITests/               # Smoke UI tests
```

Xcode uses filesystem-synchronized groups — folder moves on disk are picked up automatically.

## Three-layer content model

| Layer | Location | Role |
|-------|----------|------|
| **Authoring** | `json/`, `images/` | Human-editable source; README files colocated per domain |
| **Runtime bundle** | `Assets.xcassets/`, `Assets/Audio/` | What ships in the app |
| **Swift registries** | `Catalogs/`, `Data/` | Load JSON, enumerate games, validate at runtime |

New content flow: add authoring data → export assets → register in Swift catalog → add contract test.

## Data model: catalogs and files, not `Models/`

This app does **not** use a traditional `Models/` folder or Core Data for game content. That fits an offline, asset-heavy kids' app: hundreds of species, images, and audio clips that change often during authoring.

| Concern | Approach | Location |
|---------|----------|----------|
| **Game content** (species, rounds, mechanics) | Thin Swift types + static tables or bundled JSON | `Data/`, `Catalogs/`, `json/` |
| **Runtime assets** | Files keyed by name (`dino-trex`, `dino-flora-morrison-cycad`) | `Assets.xcassets/`, `Assets/Audio/` |
| **Player progress** | `UserDefaults` (completed game ids, matrix pairs, session) | `Progress/` |
| **Core Data** | Xcode template only (`Item` entity); not used for game domain | `App/Persistence.swift` |

Swift structs still exist (`Dinosaur`, `DinoFormation`, catalog `Entry` types) — they are registries and value types, not an ORM layer. Compare with **GroceryApp** in this monorepo, which uses `Models/` + Core Data entities for user-editable shopping data.

**Today (hybrid):**

- Land dinosaur pool — large static table in `Data/LandDinosaurData.swift`
- Formations — `Catalogs/DinoFormationsCatalog.swift` loads `json/dino-formations/` + `json/dinosaurs/char_*.json`
- Marine weights, habitats, matrix data — increasingly CSV/JSON under `json/`

**Direction:** more read-mostly content moves off hardcoded Swift onto bundled definitions; one shared decode/validation path ([REFACTOR_GAME_PLATFORM.md](REFACTOR_GAME_PLATFORM.md)). Contract tests in `DinoGamesTests/` keep files, catalogs, and bundle assets aligned.

## Game registration

`Catalogs/DinosaurGameCatalog.swift` (and air/sea equivalents) define levels, prerequisites, and visibility. Shipping land games = levels 1–4 (`GameLevel.visibleInGamePicker`).

Shared mechanics (guess, match, weigh, racing, eggs, smile, etc.) reuse `Views/` implementations parameterized by catalog configs.

## Cross-category platform

Land, air, and marine games share patterns but maintain separate catalogs and data files. Long-term goal: unify mechanic implementations and asset contracts. Progress tracker: [REFACTOR_GAME_PLATFORM.md](REFACTOR_GAME_PLATFORM.md).

## Tests as architecture guardrails

`DinoGamesTests/` uses unit XCTests with `@testable import DinoGames`:

- **Audio contracts** — every registered clip exists in bundle
- **Asset contracts** — every required imageset resolves
- **Catalog assertions** — game configs, species pools, mechanic data

Prefer unit tests over UI test infrastructure for game logic and victory flows. See [development/CONVENTIONS.md](../development/CONVENTIONS.md).

## Related docs

- [REFACTOR_GAME_PLATFORM.md](REFACTOR_GAME_PLATFORM.md) — shared framework roadmap
- [gameplay/GAME_SELECTION_ARCHITECTURE.md](../gameplay/GAME_SELECTION_ARCHITECTURE.md) — category picker and level gates
- [reference/DINO_FLORA_DATA_MODEL.md](../reference/DINO_FLORA_DATA_MODEL.md) — flora naming convention
