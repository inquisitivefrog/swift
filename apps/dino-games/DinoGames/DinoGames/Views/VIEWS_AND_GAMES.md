# View Files and Games They Manage

This document maps each view file in `DinoGames/Views` to the game(s) it runs, and how the catalog organizes games by category. Use it for maintenance as you add more dinosaur, pterosaur, and marine reptile games.

---

## 1. Shell / Navigation Views (no single game)

| View | Purpose |
|------|--------|
| **SplashScreenView** | App splash (copyright, welcome audio). Transitions to CategorySelectionView. |
| **CategorySelectionView** | “Choose A Game Type” cover: three cards — **Dinosaurs**, **Pterosaurs**, **Marine Reptiles**. Plays cover audio, then navigates to game list. |
| **GameSelectionView** | After a category is chosen: for **Dinosaurs**, shows level picker (1–6) then game list; for **Air/Sea**, shows game list. Walks the list with audio, presents game sheets (MatchingGameView, WeighGameView, etc.). |

---

## 2. One View, Multiple Games (config‑driven)

These views are shared by several games. The **game type** (and its **config**) decide title, assets, and behavior.

### MatchingGameView.swift

**Games using this view:**

| Game | Config ID | Catalog | Description |
|------|-----------|---------|-------------|
| **Match the Dinosaur** | `match-the-dinosaur` | Land L1 | Match 3 dinosaurs to “Special Feature” (characteristics: feathers, horns, etc.). Uses `Dino-Characteristics` images and audio. |
| **Dino Diets!** | `match-the-diet` | Land L2 | Match 3 dinosaurs to **Diet Type** (Herbivore, Carnivore, etc.). Uses `dino-diets-*` images and `Audio/Dino-Diets/dino-diet-{slug}.m4a`. |
| **Match the Pterosaur** | `match-the-pterosaur` | Air | Same mechanic as Match the Dinosaur but pterosaurs and `Ptero-Characteristics`. |

- **Config type:** `MatchingGameConfig` (e.g. `MatchingGameConfigs.dinoFeatures`, `dinoDietFeatures`, `pterosaurFeatures`).
- **How to tell them apart in code:** `gameConfig.id == "match-the-dinosaur"`, `"match-the-diet"`, or `"match-the-pterosaur"`.
- **Adding a new “matching” game:** Add a new config (and optional config factory), add a new `GameType.matching(YourConfig)` entry in the right catalog, and add branches in `MatchingGameView` where needed (title, right column label, audio paths).

### WeighGameView.swift

**Games:** Weigh the Dinosaur (Land), Weigh the Pterosaur (Air).  
Config selects items (dinosaurs vs pterosaurs) and copy. Same view, different `WeighGameConfig`.

### BalanceGameView.swift

**Games:** Balance the Dinosaurs (Land), Balance the Pterosaur (Air).  
Same view, config drives which creatures and audio.

### GuessGameView.swift

**Games:** Name That Dinosaur, Dino Footprints (and any other “guess” games you add).  
Config drives options and behavior.

### RacingGameView.swift

**Games:** Racing Dinosaurs (Land), Racing Pterosaurs (Air).  
Config drives racers and period selection.

---

## 3. One View, One Game (1:1)

Each of these views is used by a single game in the catalog.

| View | Game | Catalog |
|------|------|---------|
| **WackyGameView** | Wack Dinosaurs | Land L1 |
| **ToothacheGameView** | Toothache | Land L5 |
| **FindMamaGameView** | Find Mama | Land L5 |
| **DinoLunchGameView** | Dino Lunch | Land L5 |
| **DinoMatrixGameView** | Dino Matrix | Land L4 |
| **DinoAgesGameView** | Dino Ages | Land L4 |
| **DinoFormationsGameView** | Dino Formations | Land L4 |

---

## 4. Where Games Are Defined (Catalogs)

- **Land (Dinosaurs):** `DinosaurGameCatalog.swift` — levels 1–6, each level returns an array of `GameType` (e.g. `.matching(...)`, `.weigh(...)`).
- **Air (Pterosaurs):** `PterosaurGameCatalog.swift` — list of pterosaur games.
- **Sea (Marine Reptiles):** `MarineReptileGameCatalog.swift` — list of marine reptile games (can later split by ichthyosaurs / plesiosaurs / mosasaurs).

Adding a new game: add the right `GameType` (and config) to the right catalog; if it reuses an existing view (e.g. `MatchingGameView`), add config and any view branches. If it’s a new mechanic, add a new view file and a new `GameType` case, then present it from `GameSelectionView`.

---

## 5. Quick Reference: “Which view for which game?”

| If the game is… | View file | Notes |
|------------------|-----------|--------|
| Match the Dinosaur | MatchingGameView | Config id: `match-the-dinosaur` |
| Dino Diets! | MatchingGameView | Config id: `match-the-diet`; right column = Diet Type, diet- images/audio |
| Match the Pterosaur | MatchingGameView | Config id: `match-the-pterosaur` |
| Weigh the Dinosaur / Pterosaur | WeighGameView | |
| Balance the Dinosaurs / Pterosaur | BalanceGameView | |
| Name That Dinosaur, Dino Footprints | GuessGameView | |
| Racing Dinosaurs / Pterosaurs | RacingGameView | |
| Wack Dinosaurs | WackyGameView | |
| Toothache | ToothacheGameView | |
| Find Mama | FindMamaGameView | |
| Dino Lunch | DinoLunchGameView | |
| Dino Matrix | DinoMatrixGameView | Config id: `dino-matrix` |
| Dino Ages | DinoAgesGameView | |
| Dino Formations | DinoFormationsGameView | |
| Measure the Dinosaur! | MeasureGameView | Config id: `measure-the-dinosaur`; pool-agnostic for Measure the Pterosaur / Measure the Mosasaur |

---

## 6. Planned games / design notes

- **Measure the Dinosaur!:** Stack dinosaurs on the right to match a reference height on the left. View is **pool-agnostic** (MeasureCreature + poolKind) for cloning as Measure the Pterosaur or Measure the Mosasaur. Rules (pick left first, mix-and-match right stack, 1:5 ratio cap with “you-cant-be-serious-that-will-take-forever” feedback) are documented in **`HEIGHT_STACK_GAME_RULES.md`** at the project root.

---

## 7. DRY vs clarity as you scale

- **Shared views (e.g. MatchingGameView):** One place for the “match three creatures to traits” mechanic; config and `gameConfig.id` branches control title, labels, and assets. Good for many similar games (e.g. 20 dinosaur “matching” variants) as long as branches stay readable.
- **When to split:** If Dino Diets (or another variant) gets a different layout, flow, or a lot of diet‑specific logic, consider a dedicated view (e.g. `DinoDietsGameView`) that either wraps or replaces `MatchingGameView` for that game only. Same idea for pterosaur or marine‑reptile‑specific flows.
- **Marine reptiles:** With many games (ichthyosaurs, plesiosaurs, mosasaurs), you can keep one view per *mechanic* (e.g. one MatchingView for all “match creature to X”) and use config/category to switch assets and copy, or introduce one view per sub‑category if that keeps maintenance clearer.
