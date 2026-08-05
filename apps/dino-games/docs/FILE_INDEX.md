# Dino Games — Documentation Index

## Top level

| Path | Purpose |
|------|---------|
| [README.md](README.md) | Documentation hub |
| [architecture/](architecture/) | Code layout, content pipeline, platform refactor |
| [development/](development/) | Conventions, setup, testing, Xcode CLI |
| [brainstorm/](brainstorm/) | Early ideation and design decisions |
| [design/](design/) | Product philosophy, guidelines, technical design |
| [gameplay/](gameplay/) | Per-game design and implementation |
| [reference/](reference/) | Asset, audio, morphology, data tables |

---

## Architecture (`architecture/`)

| File | Description |
|------|-------------|
| [OVERVIEW.md](architecture/OVERVIEW.md) | Folder layout, three-layer content model, tests |
| [FUTURE_GAMES_BRANCH.md](architecture/FUTURE_GAMES_BRANCH.md) | **`future-games` branch** cheat sheet (missing images/) |
| [APP_SIZE_AND_RELEASE_STRATEGY.md](architecture/APP_SIZE_AND_RELEASE_STRATEGY.md) | App size, `future-games` masters, Build 3/4 packaging strategy |
| [REFACTOR_GAME_PLATFORM.md](architecture/REFACTOR_GAME_PLATFORM.md) | Shared framework refactor goals and progress |

---

## Development (`development/`)

| File | Description |
|------|-------------|
| [CONVENTIONS.md](development/CONVENTIONS.md) | Best practices — audio UX, testing, naming |
| [SETUP.md](development/SETUP.md) | Xcode project setup |
| [TECH_STACK.md](development/TECH_STACK.md) | Technologies and tool versions |
| [README.xcodebuild.md](development/README.xcodebuild.md) | CLI build and test |
| [POC_TESTING.md](development/POC_TESTING.md) | POC testing notes |

### Setup guides (`development/setup/`)

ADD_IMAGES_TO_XCODE · APP_ICON_SETUP · DEBUG_IMAGES · FIX_APPICON · FIX_DUPLICATE_AUDIO · GAME_IMAGE_SETUP · IMAGE_INTEGRATION_STATUS · IMAGE_SETUP · PTEROSAUR_IMAGE_SETUP · RESIZE_IMAGES · SILHOUETTE_IMAGE_SETUP · VERIFY_AUDIO_FILES · WEIGH_GAME_IMAGE_SETUP

---

## Brainstorm (`brainstorm/`)

| File | Description |
|------|-------------|
| [BRAINSTORMING.md](brainstorm/BRAINSTORMING.md) | All 20 original game ideas |
| [SESSION_NOTES.md](brainstorm/SESSION_NOTES.md) | Brainstorming session summary |
| [DESIGN_DECISIONS.md](brainstorm/DESIGN_DECISIONS.md) | Key product decisions |
| [DESIGN_PRINCIPLES_YOUNG_CHILDREN.md](brainstorm/DESIGN_PRINCIPLES_YOUNG_CHILDREN.md) | Age-appropriate principles |
| [BRAINSTORM_DINO_FLORA.md](brainstorm/BRAINSTORM_DINO_FLORA.md) | Dino flora ideation |

---

## Design (`design/`)

### Philosophy (`design/philosophy/`)
DESIGN_PHILOSOPHY · DESIGN_CONCERNS · CHILD_PSYCHOLOGY_GUIDELINES · GAMEPLAY_DESIGN

### Guidelines (`design/guidelines/`)
PRIVACY_LEGAL · SOCIAL_CONCERNS

### Technical (`design/technical/`)
TECHNICAL_FEASIBILITY · IMAGE_GENERATION_GUIDE · AUDIO_STRATEGY · GRID_TOUCH_DETECTION · FUN_FACTOR_AND_REPEAT_PLAY

---

## Gameplay (`gameplay/`)

### Implementation & reference
GAME_SELECTION_ARCHITECTURE · DINOSAURS_BY_FORMATION · DINOSAUR_CHARACTERISTICS_4-6 · MATCHING_GAME_DESIGN · MATCHING_GAME_REVIEW · MATCHING_GAME_LOGIC_REVIEW · MULTIPLE_MATCHING_GAMES · RACING_DINOSAURS_DESIGN · PTEROSAUR_GAME_PLAN · TOOTHACHE_ASSETS · NAME_THAT_DINOSAUR_ASSETS · WEIGH_GAME_WEIGHTS · HEIGHT_STACK_GAME_RULES · MEASURE_GAME_REDESIGN · SPECIES_LISTS_12_PER_GROUP · LEVEL_PROGRESSION

### Concept docs (brainstorm-era)
MATCHING_GAME · MATCH_GAME_HANDRAILS · EATING_GAME · PLANT_FINDING_GAME · OCCUPATION_GAME · FOSSIL_IDENTIFICATION · TOOL_IDENTIFICATION · SOUND_MATCHING · SPINNER_INTERFACE · SIZE_COMPARISON · ZOOM_DETAIL_VIEW · VISION_ANATOMY · SKELETON_ANATOMY · DINOSAUR_CHARACTERISTICS · ANTHROPOMORPHIZATION · PLAYFUL_DEMONSTRATIONS

---

## Reference (`reference/`)

ASSETS_REFERENCE · ASSETS_CATALOG_ORGANIZATION · ASSETS_SPELLING_REFERENCE · ASSETS_COMPARISON · DINOSAUR_ASSETS_TABLE · CHARACTERISTIC_IMAGES · AUDIO_SETUP · AUDIO_FILES_REFERENCE · AUDIO_FILES_NEEDED · AUDIO_SCRIPTS · AUDIO_RECORDING_NOTES · DINO_FLORA_DATA_MODEL · DENTAL_MORPHOLOGY_SOURCE_OF_TRUTH · DINOSAURS_BY_TOOTH_MORPHOLOGY · DINO_SMILE_TOOTH_MAPPING_REVIEW · DINO_FOSSIL_HUNT (+ discovery/excavate/tool docs) · Char.md · LICENSING_AND_CREDITS

---

## File organization

```
apps/dino-games/
├── README.md
├── docs/
│   ├── README.md
│   ├── FILE_INDEX.md
│   ├── architecture/
│   ├── development/
│   │   └── setup/
│   ├── brainstorm/
│   ├── design/
│   │   ├── philosophy/
│   │   ├── guidelines/
│   │   └── technical/
│   ├── gameplay/
│   └── reference/
├── DinoGames/              # Xcode project (no docs here)
└── scripts/
```

---

**Last updated:** Docs reorganized — merged `DinoGames/docs/`, added architecture/development/brainstorm/reference top-level folders.
