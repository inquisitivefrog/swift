# Dino Games — Documentation

Documentation for the Dino Games iOS app. Everything lives under `apps/dino-games/docs/` — not inside the app source tree.

## Start here

| If you want to… | Read |
|-----------------|------|
| Understand code & data flow | [architecture/OVERVIEW.md](architecture/OVERVIEW.md) |
| Find **`future-games`** branch / missing `images/` art | [architecture/FUTURE_GAMES_BRANCH.md](architecture/FUTURE_GAMES_BRANCH.md) → full story in [architecture/APP_SIZE_AND_RELEASE_STRATEGY.md](architecture/APP_SIZE_AND_RELEASE_STRATEGY.md) |
| Onboard as a developer | [development/CONVENTIONS.md](development/CONVENTIONS.md) · [development/SETUP.md](development/SETUP.md) |
| See original game ideas | [brainstorm/BRAINSTORMING.md](brainstorm/BRAINSTORMING.md) |
| Understand child UX principles | [design/philosophy/DESIGN_PHILOSOPHY.md](design/philosophy/DESIGN_PHILOSOPHY.md) |
| Look up asset/audio naming | [reference/](reference/) |
| Dive into a specific game | [gameplay/](gameplay/) |

Full file list: [FILE_INDEX.md](FILE_INDEX.md).

## Structure

```
docs/
├── architecture/     How the app is organized (code + content layers)
├── development/      Best practices, setup, testing, Xcode CLI
│   └── setup/        One-off image/audio/Xcode fix guides
├── brainstorm/       Early ideation, session notes, open decisions
├── design/           Product philosophy, guidelines, technical design
├── gameplay/         Per-game design and implementation reference
└── reference/        Asset, audio, morphology, and data tables
```

## Technology

SwiftUI · Core Data · AVFoundation · XCTest. Details in [development/TECH_STACK.md](development/TECH_STACK.md).

## Design philosophy

**Sound & touch, not read & write.** The app targets pre-literate children (ages 4–6). Instructions are spoken; navigation is visual. See [design/philosophy/DESIGN_PHILOSOPHY.md](design/philosophy/DESIGN_PHILOSOPHY.md).
