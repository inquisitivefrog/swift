# Measure the Dinosaur! (planned) — rules

Mini game: stack dinosaurs on the right to match the height of a reference dinosaur on the left. Short rounds.

## Order of selection

- Game play begins with "choose your first dinosaur" followed by "choose your second dinosaur"; no separate "pick a dinosaur first" feedback is needed.

## Size buckets (scale teaching)

- **small** ≤1.5m, **medium** 1.5–6m, **large** 6–12m, **huge** >12m.
- If first dinosaur is **not huge**, any additional dinosaur can never be huge → `game-measure-you-cant-be-serious`.
- If first dinosaur is **large** and second is not, dinosaurs afterwards could still be large but risk overshoot → `game-measure-that-dinosaur-is-too-tall`.
- If first dinosaur is **medium or small**, most dinosaurs are blocked; boundary enforcement ensures at least some remain addable.

## Right side: mix and match

- The right side is **not** “N copies of one dinosaur.” The player can **stack different dinosaurs** one on top of another until the combined height matches the reference.
- Example: left = sauropod; right = Triceratops, then T-Rex on top, then Parasaurolophus, then Compsognathus, then Anchiornis, then Archaeopteryx — each added on top until the stack height matches.

## Ratio cap (1:5) — keep rounds short

- When the player adds a dinosaur to the right stack, compute how many of **that** dinosaur would be needed to fill the **remaining** height (remaining height ÷ that dinosaur’s height).
- If that number **> 5**, do **not** add it. Instead play **`Audio/Feedback/you-cant-be-serious-that-will-take-forever.m4a`** and reject the add. This avoids a single round turning into “stacking and stacking” (e.g. 20× Compsognathus to match a sauropod).

## Audio paths (wired in code)

- `Games/game-measure-you-cant-be-serious` — dinosaur too small (would need >5 of that species).
- `Games/game-measure-that-dinosaur-is-too-tall` — dinosaur overshoots remaining height.
- `Feedback/you-cant-be-serious-that-will-take-forever` — stack cap (6) reached.

## Implementation notes

- Need **estimated length (or height)** per dinosaur for ratio math.
- Left: one dinosaur at full “tower” height. Right: stack of 1–N dinosaurs (mixed species), each scaled so the stack’s total height matches the reference. Cap any single-species contribution at 5 when deciding whether to allow the add.

## Expansion (Measure the Pterosaur / Measure the Mosasaur)

- The game is **config-driven** so it can be cloned for other categories. **MeasureGameView** is pool-agnostic: it uses **MeasureCreature** (id, name, imageName, icon) and **MeasureGameConfig.poolKind** (`.dinosaurs`, `.pterosaurs`, `.marineReptiles`).
- **MeasureGameConfigs.makeRoundCreatures(poolKind:excluding:)** returns one creature per group (e.g. 9 for dinosaurs = 9 clades). To add Measure the Pterosaur: define pterosaur grouping (e.g. by family), add `measurePterosaur` config with `poolKind: .pterosaurs`, and implement or extend `makeRoundPterosaurs`. Same idea for marine reptiles with a pool and grouping.
- Intro audio and game card images are per config (e.g. `game-intro-measure`, `game-intro-measure-pterosaur`, `game-measure-the-dinosaur`, `game-measure-the-pterosaur`).
