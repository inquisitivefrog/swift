# Organizing Assets in Xcode: Folders + Prefix Naming

You can use **both** naming prefixes and **folders** inside `Assets.xcassets` so assets are easier to find and stay consistent across games.

## How to add containers in Xcode

With **Assets.xcassets** selected, use the **+** button at the bottom of the asset list. You’ll see:

- **Image Set** – new imageset (e.g. `dino-trex`)
- **Folder** – organizing container; asset names stay the same at runtime (no code change)
- **Folder with Namespace** – folder name becomes part of the asset name (code must use path, e.g. `"Dinosaurs/trex"`)
- **Folder from Selection** – create a folder and move the selected items into it

There is no separate “Add Group” in the asset catalog; use **Folder** (or **Folder with Namespace**) as your container.

## Folder vs Folder with Namespace

| Option | Behavior | Code |
|--------|----------|------|
| **Folder** | Organizes only. Assets are still loaded by **image set name only** (flat namespace). | `Image("dino-trex")` — no change after moving into a folder. |
| **Folder with Namespace** | Folder path is part of the asset name. Lets you reuse the same image set name in different folders. | `Image("Dinosaurs/dino-trex")` — you must reference the path. |

For **organization only** (no code changes), use **Folder**. Drag existing image sets into it; the app still uses `Image("dino-trex")` etc.

Use **Folder with Namespace** only if you want path-based names (e.g. same logical name in different folders); then update code to use the path.

## Suggested folder structure (matches current prefixes)

A structure that aligns with your prefixes and ~40 dinosaurs × multiple positions (use plain **Folder** so names stay the same):

| Folder               | Contents (prefix)           | Use |
|---------------------|----------------------------|-----|
| **Dinosaurs**       | `dino-*` (main character art) | Dino Formations, Dino Ages, Match, etc. |
| **Dinosaurs / Levels** | `dino-level-*`           | Level picker (1–6) |
| **Dinosaurs / Silhouettes** | `dino-silhouette-*`   | Guess / Name That Dinosaur |
| **Dinosaurs / Racers** | `dino-racer-*`          | Racing game |
| **Dinosaurs / Characteristics** | `dino-char-*`      | Matching / traits |
| **Formations**      | `formation-*`              | Dino Formations |
| **Clues**           | `clue-*`                    | Find Mama (egg clues) |
| **Footprints**      | `footprint-*`, `source-footprints-*` | Dino Footprints |
| **Matrix**          | `matrix-*`                  | Matrix Materials |
| **Lunch**           | `lunch-*-*` (carnivore/herbivore/omnivore) | Dino Lunch |
| **Toothache**       | `tooth-*`, `grumpy-*`, `grump-*` | Toothache game |
| **Wacky**           | `wacky-*`                   | Wacky Dinosaurs |
| **Games**           | `game-*` (icons)            | Game selection cards |
| **Categories**      | `category-*`               | Land / Air / Sea |
| **Periods**         | `period-*`                  | Jurassic / Cretaceous |
| **Eggs**            | `egg-*`                     | Find Mama |
| **Pterosaurs**      | `ptero-*`                   | Air games |

You can refine this (e.g. **Habitat**, **Flora**, **Fauna**, **Style**) as you lock in your formation/habitat/flora/fauna/style system.

## Summary

- **Prefixes** = how the app and code identify asset *type* and *role*.
- **Folder** (from the + menu) = organizing container; asset names stay the same, so no code changes when you move image sets into folders.
- **Folder with Namespace** = use only if you want path-based names and are willing to update code to use the path.

Using **Folder** plus your prefix naming keeps the catalog organized and naming consistent across games without changing any image names in code.
