# Dino Games - Complete File Index

## Design & Brainstorming (docs/design/)

Design docs and brainstorming are under **docs/design/** for easier reading and future adaptation. See [design/README.md](design/README.md) for an overview.

### Brainstorming (docs/design/brainstorming/)
| File | Description |
|------|-------------|
| **BRAINSTORMING.md** | Main brainstorming document with all 20 game ideas |
| **SESSION_NOTES.md** | Summary of brainstorming session |

### Philosophy (docs/design/philosophy/)
| File | Description |
|------|-------------|
| **DESIGN_PHILOSOPHY.md** | Core design principles (Sound & Touch, Challenge Over Education, Humor, etc.) |
| **DESIGN_CONCERNS.md** | Design concerns and tradeoffs |
| **CHILD_PSYCHOLOGY_GUIDELINES.md** | Child psychology guidelines (3 facts rule, 20+ game elements) |
| **GAMEPLAY_DESIGN.md** | Challenge-first gameplay mechanics |

### Game Concepts (docs/design/game-concepts/)
| File | Description |
|------|-------------|
| **MATCHING_GAME.md** | Matching game implementation (dinosaurs & characteristics) |
| **MATCH_GAME_HANDRAILS.md** | Match game handrails and UX |
| **EATING_GAME.md** | Eating game (match dinosaur to plant) |
| **PLANT_FINDING_GAME.md** | Plant finding game (Where's the Plant) |
| **OCCUPATION_GAME.md** | Occupation game with diversity requirements |
| **FOSSIL_IDENTIFICATION.md** | Fossil identification (bone color vs matrix rock) |
| **TOOL_IDENTIFICATION.md** | Tool identification game |
| **SOUND_MATCHING.md** | Sound matching game implementation |
| **SPINNER_INTERFACE.md** | Spinner interface implementation and gambling analysis |
| **SIZE_COMPARISON.md** | Size comparison feature (children vs dinosaurs with reference objects) |
| **ZOOM_DETAIL_VIEW.md** | Zoom detail view for feature learning |
| **VISION_ANATOMY.md** | Vision and eye position features |
| **SKELETON_ANATOMY.md** | Skeleton and anatomy features |
| **DINOSAUR_CHARACTERISTICS.md** | Comprehensive characteristic system |
| **ANTHROPOMORPHIZATION.md** | Visual props system |
| **PLAYFUL_DEMONSTRATIONS.md** | Age-appropriate action demonstrations |
| **LEVEL_PROGRESSION.md** | Level progression system |
| **SPECIES_LISTS_12_PER_GROUP.md** | Species lists (12 per group) |

### Guidelines (docs/design/guidelines/)
| File | Description |
|------|-------------|
| **PRIVACY_LEGAL.md** | COPPA compliance and legal considerations |
| **SOCIAL_CONCERNS.md** | Advocacy group considerations and responses |

### Technical (docs/design/technical/)
| File | Description |
|------|-------------|
| **TECHNICAL_FEASIBILITY.md** | Technical assessment and feasibility analysis |
| **IMAGE_GENERATION_GUIDE.md** | Asset creation strategies and workflows |
| **AUDIO_STRATEGY.md** | Audio file sizes, memory usage, and strategies |
| **GRID_TOUCH_DETECTION.md** | Grid-based touch detection for Where's Waldo game |
| **FUN_FACTOR_AND_REPEAT_PLAY.md** | Fun factor and repeat play considerations |

---

## Docs root (docs/)

| File | Description |
|------|-------------|
| **README.md** | Project overview, tech stack, app size considerations |
| **FILE_INDEX.md** | This file – index of docs and design folder |

---

## File organization

```
dino-games/
├── docs/
│   ├── README.md
│   ├── FILE_INDEX.md (this file)
│   └── design/
│       ├── README.md
│       ├── brainstorming/
│       │   ├── BRAINSTORMING.md
│       │   └── SESSION_NOTES.md
│       ├── philosophy/
│       │   ├── DESIGN_PHILOSOPHY.md
│       │   ├── DESIGN_CONCERNS.md
│       │   ├── CHILD_PSYCHOLOGY_GUIDELINES.md
│       │   └── GAMEPLAY_DESIGN.md
│       ├── game-concepts/
│       │   └── (18 game/feature design docs)
│       ├── guidelines/
│       │   ├── PRIVACY_LEGAL.md
│       │   └── SOCIAL_CONCERNS.md
│       └── technical/
│           └── (5 technical design docs)
├── DinoGames/          (app + asset/setup docs)
└── ...
```

## Quick reference

### Start here
- **design/brainstorming/SESSION_NOTES.md** – Session summary
- **design/brainstorming/BRAINSTORMING.md** – All game ideas
- **design/philosophy/DESIGN_PHILOSOPHY.md** – Core design principles

### Key decisions
- **design/technical/TECHNICAL_FEASIBILITY.md** – What's possible
- **design/guidelines/PRIVACY_LEGAL.md** – Legal considerations
- **design/philosophy/CHILD_PSYCHOLOGY_GUIDELINES.md** – Design guidelines

### Implementation
- Game guides in **design/game-concepts/**
- Asset/audio guides in **design/technical/**

---

**Last updated:** Design folder created; docs sorted into design subfolders.
