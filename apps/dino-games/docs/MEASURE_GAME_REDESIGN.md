# Measure the Dinosaur — Redesign (Boundary Enforcement)

## Design Origin

- **Which Dino is Taller:** Settles the question between two similar-sized dinosaurs.
- **Measure the Dinosaur:** Stack-chasing creation; first dinosaur assumed large. Teaches scale between dinosaurs.

## Size Buckets

| Bucket | Height (m) | Examples |
|--------|------------|----------|
| small  | ≤ 1.5      | Compsognathus 0.2, Archaeopteryx 0.5 |
| medium | 1.5–6      | Dryosaurus 2, Iguanodon 6 |
| large  | 6–12       | T-Rex 9, Triceratops 7 |
| huge   | > 12       | Brontosaurus 12, Argentinosaurus 22 |

## Scale Rules (audio triggers)

- **If first dinosaur is NOT huge** → any additional dinosaur can never be huge. Adding huge → `game-measure-you-cant-be-serious` (wrong scale).
- **If first dinosaur IS large** and second is not → dinosaurs afterwards could still be large but risk overshoot → `game-measure-that-dinosaur-is-too-tall`.
- **If first dinosaur is medium or small** → most dinosaurs blocked by these two rules; boundary enforcement ensures at least some remain addable.

## Boundary Rules

1. **Smallest cannot be chosen first** — Block selecting the smallest dinosaur in the grid as the left reference (when at least 2 distinct sizes exist).
2. **Small left → small replacement** — When the left reference is small, replacement for that slot prefers small-enough dinosaurs so at least one addable option remains.
3. **After two chosen, guarantee addable** — When left + 1 in stack, grid refresh ensures at least one dinosaur fits the remaining height.
4. **Differentiate off-limits feedback:**
   - **game-measure-you-cant-be-serious:** (a) Huge when left is not huge; (b) would need >5 of that species (ratio > 5).
   - **game-measure-that-dinosaur-is-too-tall:** Overshoots remaining height.

## Math

- **wouldBeHugeWhenLeftIsNot:** left bucket ≠ huge AND creature bucket = huge → "you can't be serious"
- **wouldRequireTooMany:** `remainingHeight / creatureH > 5` → "you can't be serious"
- **wouldOvershoot:** `currentSum + creatureH > leftH` → "that dinosaur is too tall"
- **Stack cap:** 6 max; "you-cant-be-serious-that-will-take-forever" when cap hit

## Round Building

- `makeRoundSlotsForDinosaurs(preferringSmallEnough:)` — When `remainingHeight` is set, ensure **at least one** clade contributes a small-enough dinosaur (not just "prefer" per clade).
- `replacementMeasureCreature(clade:excluding:preferringSmallEnough:)` — When replacing, prefer small enough when left reference is small.
