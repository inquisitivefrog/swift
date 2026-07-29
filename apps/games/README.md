# Games

An experimental iOS app for trying multiple small games in one place. Built with SwiftUI and Xcode.

## Overview

The app opens on a **home catalog**: available games listed in sections by **genre**. Tap a game to play it. New games plug into the catalog without changing the home screen layout.

**Included now**

| Game | Genre | Difficulty | Notes |
|------|--------|------------|--------|
| Tic-Tac-Toe | Puzzle | Easy | Two players on one device; SF Symbols for X/O |
| Sudoku | Puzzle | Easy | 9×9 grid, number pad, conflict highlighting |
| Easy French | Trivia | Medium | Flashcards + quiz; TTS; speak or tap answers |
| Underground Maze | Arcade | Medium | Procedural 3-level mazes; random stairs/treasure |
| Side Scroller | Arcade | Medium | SpriteKit platformer — run, jump, reach the goal |
| Grid Movement | Strategy | Easy | 16×16 map, 4×4 scrolling viewport, bird’s-eye |

## Architecture

```
GamesApp
  └─ ContentView (home catalog, NavigationStack)
       └─ GameID → game view (e.g. TicTacToeView)
```

| Piece | Role |
|-------|------|
| `GameCatalog.swift` | Genres, difficulty, game entries, section grouping |
| `ContentView.swift` | Home list; navigates by `GameID` |
| `TicTacToeGame.swift` | Tic-Tac-Toe rules / state (`@Observable`) |
| `TicTacToeView.swift` | Tic-Tac-Toe UI |
| `SudokuGame.swift` | Sudoku rules, puzzles, conflicts (`@Observable`) |
| `SudokuView.swift` | Sudoku board + number pad |
| `FrenchVocabulary.swift` | Easy French categories (10 words each) |
| `EasyFrenchGame.swift` | Study + quiz session state |
| `EasyFrenchView.swift` | Category list, flashcards, quiz UI |
| `UndergroundMazeGame.swift` | 3-level maze rules / state |
| `UndergroundMazeView.swift` | Maze board, D-pad, swipe controls |
| `SideScrollerScene.swift` | SpriteKit side-scrolling platform level |
| `SideScrollerView.swift` | SpriteView host + move/jump controls |
| `GridMovementGame.swift` | 16×16 map, 4×4 camera clamp, dog position |
| `GridMovementView.swift` | Viewport, D-pad, bird’s-eye minimap |

### Catalog fields

Each `GameEntry` has:

- **id** (`GameID`) — navigation key  
- **title / subtitle** — list display  
- **genre** — section on home (Puzzle, Strategy, Card, Trivia, Arcade, AR)  
- **difficulty** — Easy / Medium / Hard  
- **systemImage** — SF Symbol in the row  
- **isAvailable** — only `true` games appear on home  

Sections are sorted by genre order; games within a section are A–Z by title.

## Adding a game

1. Add a `GameID` case in `GameCatalog.swift`.
2. Append a `GameEntry` to `GameCatalog.games` (`isAvailable: true` when ready).
3. Implement model + view (e.g. `MyGame.swift`, `MyGameView.swift`).
4. Handle the new `GameID` in `ContentView.gameDestination(for:)`.
5. Add unit tests under `GamesTests`.

For real-time / physics games, keep SwiftUI for shell and menus; use SpriteKit (or SceneKit / RealityKit) inside the game view when needed.

## Requirements

- Xcode 16+ (or current stable with iOS Simulator)
- iOS deployment target as set in the Xcode project

## Build & run

Open the project and run from Xcode:

```bash
open apps/games/Games/Games.xcodeproj
```

Or build from the command line:

```bash
xcodebuild -scheme Games \
  -project apps/games/Games/Games.xcodeproj \
  -destination 'generic/platform=iOS' \
  build
```

## Testing

Unit tests live in `Games/GamesTests/` and cover:

- Catalog sections (Puzzle + Trivia games)
- Tic-Tac-Toe win, draw, no overwrite, reset
- Sudoku conflicts / solve
- Easy French category word counts and quiz scoring

Run in Xcode with **Product → Test** (⌘U), or:

```bash
xcodebuild -scheme Games \
  -project apps/games/Games/Games.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  test
```

Adjust the simulator name/OS to match what’s installed (`xcodebuild -showdestinations`).

`GamesUITests` are still Xcode stubs and do not yet cover game flows.

## Project layout

```
apps/games/
├── README.md                 # This file
└── Games/
    ├── Games.xcodeproj
    ├── Games/                # App sources
    │   ├── GamesApp.swift
    │   ├── ContentView.swift
    │   ├── GameCatalog.swift
    │   ├── TicTacToeGame.swift
    │   ├── TicTacToeView.swift
    │   ├── SudokuGame.swift
    │   ├── SudokuView.swift
    │   ├── FrenchVocabulary.swift
    │   ├── EasyFrenchGame.swift
    │   ├── EasyFrenchView.swift
    │   ├── UndergroundMazeGame.swift
    │   ├── UndergroundMazeView.swift
    │   ├── SideScrollerScene.swift
    │   ├── SideScrollerView.swift
    │   └── Assets.xcassets/
    ├── GamesTests/           # Unit tests
    └── GamesUITests/         # UI test stubs
```

## Design notes

- **Home, not tabs per game** — one catalog scales as genres grow; add a genre filter later if the list gets long.
- **SF Symbols first** — swap in custom art later if desired; X/O do not require image assets yet.
- **SwiftData removed** — the Xcode template list/Item model is gone; the catalog is in-code for now.
