# Multiple Matching Games Architecture

## Overview

The codebase now supports multiple matching games, each with unique:
- **Title** (e.g., "Match the Dinosaur!")
- **Data** (dinosaurs and characteristics)
- **Images** (game card image, dinosaur images, characteristic images)
- **Audio** (intro audio file)

## How It Works

### 1. Game Configuration (`MatchingGameConfig`)

Each matching game is defined by a `MatchingGameConfig` that contains:
- `id`: Unique identifier (e.g., "dino-features", "dino-habitat")
- `title`: Display title for the game
- `introAudio`: Audio file name for game intro
- `dinosaurs`: Array of dinosaurs for this game
- `characteristics`: Array of characteristics for this game

### 2. Current Game

**Game ID**: `dino-features`
- **Title**: "Match the Dinosaur!"
- **Image Name**: `game-dino-features` (in Assets.xcassets)
- **Intro Audio**: played on transition as `can-you-match-each-dinosaur` (no separate game-intro)
- **Content**: Dinosaurs matched to their special features (teeth, footprints, eggs, skin, spikes)

## Adding a New Matching Game

### Step 1: Create Game Configuration

In `MatchingGameView.swift`, add a new config to `MatchingGameConfigs`:

```swift
static let dinoHabitat = MatchingGameConfig(
    id: "dino-habitat",
    title: "Where Do Dinosaurs Live?",
    introAudio: "game-intro-habitat",
    dinosaurs: [
        Dinosaur(id: 1, name: "T-Rex", icon: "🦖", imageName: "dino-trex", characteristicIds: [1]),
        // ... more dinosaurs
    ],
    characteristics: [
        Characteristic(id: 1, type: "Forest", icon: "🌲", imageName: "char-forest", dinosaurId: 1),
        // ... more characteristics
    ]
)
```

### Step 2: Add to Game Selection

In `GameSelectionView.swift`, add to the `matchingGames` array:

```swift
private let matchingGames: [GameType] = [
    .matching(MatchingGameConfigs.dinoFeatures),
    .matching(MatchingGameConfigs.dinoHabitat)  // ← Add here
]
```

### Step 3: Add Assets

1. **Game Card Image**: Add `game-dino-habitat` to Assets.xcassets
2. **Dinosaur Images**: Use existing or add new (e.g., `dino-trex`, etc.)
3. **Characteristic Images**: Add new (e.g., `char-forest`, etc.)
4. **Audio Files**: Add intro audio (e.g., `game-intro-habitat.m4a`)

## Image Naming Convention

- **Game Cards**: `game-{game-id}` (e.g., `game-dino-features`, `game-dino-habitat`)
- **Dinosaurs**: `dino-{name}` (can be shared across games)
- **Characteristics**: `char-{name}` (game-specific)

## Example: Adding "Dinosaur Habitats" Game

```swift
// In MatchingGameView.swift
static let dinoHabitat = MatchingGameConfig(
    id: "dino-habitat",
    title: "Where Do Dinosaurs Live?",
    introAudio: "game-intro-habitat",
    dinosaurs: [
        Dinosaur(id: 1, name: "T-Rex", icon: "🦖", imageName: "dino-trex", characteristicIds: [1]),
        Dinosaur(id: 2, name: "Triceratops", icon: "🦏", imageName: "dino-triceratops", characteristicIds: [2]),
    ],
    characteristics: [
        Characteristic(id: 1, type: "Forest", icon: "🌲", imageName: "char-forest", dinosaurId: 1),
        Characteristic(id: 2, type: "Plains", icon: "🌾", imageName: "char-plains", dinosaurId: 2),
    ]
)
```

Then in `GameSelectionView.swift`:
```swift
private let matchingGames: [GameType] = [
    .matching(MatchingGameConfigs.dinoFeatures),
    .matching(MatchingGameConfigs.dinoHabitat)  // New game!
]
```

## Benefits

✅ **Unique Identity**: Each game has its own ID, title, and assets
✅ **Easy to Add**: Just create a new config and add to the list
✅ **Shared Components**: Same `MatchingGameView` handles all matching games
✅ **Flexible**: Each game can have different numbers of dinosaurs/characteristics
✅ **Scalable**: Add as many matching games as needed

## Current Status

- ✅ Architecture supports multiple games
- ✅ Current game (`dino-features`) works
- ⏳ Ready for you to add 2+ more matching games!
