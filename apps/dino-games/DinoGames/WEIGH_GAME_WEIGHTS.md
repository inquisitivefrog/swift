# Weigh Game – Dinosaur Weight Reference

The weigh game shows **nine dinosaurs chosen at random** from the pool below. Each session the set is shuffled; the nine chosen are then **ordered by estimated weight** (lightest → heaviest) and assigned game weights 1–9 so the seesaw comparisons stay consistent.

## Weight chart (lightest → heaviest)

| Species             | Est. weight (kg) | Est. weight (tons) | Notes (for future reference)        |
|---------------------|------------------|--------------------|--------------------------------------|
| Velociraptor        | ~20              | ~0.02              | Small theropod; ~2 m long            |
| Troodon             | ~50              | ~0.05              | Small theropod; ~2.4 m long         |
| Parasaurolophus     | ~2,700           | ~2.7               | Hadrosaur; ~9–10 m long              |
| Corythosaurus       | ~3,500           | ~3.5               | Hadrosaur; ~9–10 m long               |
| Iguanodon           | ~4,500           | ~4.5               | Ornithopod; ~9–10 m (tie with Stegosaurus) |
| Therizinosaurus     | ~5,000           | ~5                 | Therizinosaur; large; heavier than hadrosaurs |
| Stegosaurus         | ~4,500           | ~4.5               | Stegosaur; ~7–9 m (tie with Iguanodon) |
| Ankylosaurus        | ~6,000           | ~6                 | Ankylosaur; heavily armored          |
| Spinosaurus         | ~7,000           | ~7                 | Spinosaurid; semi-aquatic; ~14–18 m   |
| T-Rex               | ~8,000           | ~8                 | Large theropod; ~12 m long           |
| Triceratops         | ~9,000           | ~9                 | Ceratopsian; ~8–9 m long              |
| Apatosaurus         | ~25,000          | ~25                | Sauropod; ~21–23 m long               |

## Game behavior

- **Pool:** All 12 species above (those with `dino-*` image sets in the app).
- **Per session:** 9 are chosen at random; they are sorted by `estimatedWeightKg` and given game weights by rank (same estimated weight → same game weight so “they both weigh about the same” can play).
- **Seesaw:** Heavier game weight tilts down; equal weight or “nearly same” (difference ≤ 1) gets a small tilt and plays the “they both weigh about the same” message.

The same weight estimates and ordering are defined in code in `WeighGameView.swift` (see the `WeighableDinosaurPoolEntry` table and the comment block above it) so the chart and the game stay in sync.
