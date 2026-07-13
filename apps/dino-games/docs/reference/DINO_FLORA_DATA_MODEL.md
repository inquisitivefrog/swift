# Dino Flora – Data Model

*For review, maintenance, and building round lists. Game plays like Dino Formations: one plant per round, player selects 3 of 5 dinosaurs that ate it.*

## Game Assets

| Asset | Path / Name |
|-------|-------------|
| Per-plant intro audio | `Audio/Flora/Dinosaurs/dino-flora-{slug}.m4a` (e.g. key `flora-horsetails` → `dino-flora-horsetails.m4a`) |
| Round prompt audio | `Games/game-dino-flora-which-three-dinosaurs.m4a` |
| Game card | `game-dino-flora` |
| Success card | `game-dino-flora-success` |

## Flora (19 types – images available)

*Imagesets use prefix `flora-{slug}-habitat` for plant in habitat; `flora-{slug}-seeds` for reproductive structures.*

| Slug | Display Name | Browse Height |
|------|--------------|---------------|
| horsetails | Horsetails | Low |
| moss | Moss | Ground |
| araucaria | Araucaria | Tree (conifer) |
| ginkgo | Ginkgo | Tree |
| cycads | Cycads | Low–mid |
| tree-fern | Tree Fern | Tall |
| fern | Fern | Low |
| charophytes | Charophytes | Aquatic/low |
| clubmoss | Clubmoss | Ground |
| equisetites | Equisetites | Low |
| fungi | Fungi | Ground |
| ginkgoites | Ginkgoites | Tree |
| liverwort | Liverwort | Ground |
| magnoliid | Magnoliid | Tree |
| paleopus | Paleopus | Mixed |
| taxodium | Taxodium | Tree (conifer) |
| totara | Totara | Tree (conifer) |
| walnut | Walnut | Tree |
| water-lilies | Water Lilies | Aquatic/low |

*Note: Slug-to-image mapping – horsetails→horsetail, cycads→cycad, fern→herbaceous-fern (singular/compound in asset names).*

## Gameplay Rules

1. **Five rounds per game**
2. **Per round:** Randomly choose a plant (from the 19). Display image, title, and play introduction from `Audio/Flora/Dinosaurs/dino-flora-{slug}.m4a` (audio key `flora-{slug}`)
3. **Track used plants:** Save plant name so it is not reused in the same game
4. **Build round:** Choose 3 dinosaurs from the plant's "Eats" list (herbivores/omnivores); add 2 decoys from "Won't eat"
5. **Play** `game-dino-flora-which-three-dinosaurs` audio
6. **Introduce 5 dinosaurs** by highlighted image, text, and audio (one per dinosaur)
7. **Player chooses 3** dinosaurs that ate the plant

**Victory sequence (standard):** Re-introduce dinosaurs used in game (walk list with highlight + name audio), play congratulations audio (`Feedback/congratulations` or `good-job-you-got-them-all` + `crowd-cheering`), display success game card (`game-dino-flora-success`).

**Placement:** Dinosaur games level 5 (Really Hard Games)

**Accessibility – photosensitive epilepsy:** Per-round plant display shows habitat image for 3 seconds, then switches to seeds image with a 0.4s fade. This was explicitly designed to avoid rapid flashing: photosensitive triggers are typically 5–30 Hz; our single transition at ~0.33 Hz is well below that. If the issue is raised later, this design choice is documented here and in `DinoFloraGameView` (`plantHabitatDisplaySeconds`).

---

## Dinosaur → Plants (Eat / Won't Eat)

*Pool: Herbivore + Omnivore only. Clade-based assignment; low browsers eat ground/low plants; high browsers eat trees.*

| ID | Name | Clade | Eats | Won't Eat |
|----|------|-------|------|-----------|
| 2 | Triceratops | ceratopsian | horsetails, moss, cycads, fern, tree-fern | araucaria, ginkgo |
| 3 | Stegosaurus | stegosaur | horsetails, moss, cycads, fern | araucaria, ginkgo, tree-fern |
| 5 | Therizinosaurus | theropod | horsetails, moss, cycads, fern, tree-fern | araucaria, ginkgo |
| 7 | Apatosaurus | sauropod | araucaria, ginkgo, tree-fern | horsetails, moss, cycads, fern |
| 8 | Ankylosaurus | ankylosaurid | horsetails, moss, cycads, fern | araucaria, ginkgo, tree-fern |
| 9 | Corythosaurus | hadrosaur | horsetails, moss, cycads, fern, tree-fern | araucaria, ginkgo |
| 10 | Parasaurolophus | hadrosaur | horsetails, moss, cycads, fern, tree-fern | araucaria, ginkgo |
| 11 | Iguanodon | ornithopod | horsetails, moss, cycads, fern, tree-fern | araucaria, ginkgo |
| 13 | Edmontosaurus | hadrosaur | horsetails, moss, cycads, fern, tree-fern | araucaria, ginkgo |
| 14 | Camarasaurus | sauropod | araucaria, ginkgo, tree-fern | horsetails, moss, cycads, fern |
| 15 | Dryosaurus | ornithopod | horsetails, moss, cycads, fern | araucaria, ginkgo, tree-fern |
| 16 | Gallimimus | theropod (omnivore) | horsetails, moss, cycads, fern | araucaria, ginkgo, tree-fern |
| 17 | Pachycephalosaurus | pachycephalosaur | horsetails, moss, cycads, fern | araucaria, ginkgo, tree-fern |
| 21 | Argentinosaurus | sauropod | araucaria, ginkgo, tree-fern | horsetails, moss, cycads, fern |
| 23 | Brachiosaurus | sauropod | araucaria, ginkgo, tree-fern | horsetails, moss, cycads, fern |
| 25 | Chasmosaurus | ceratopsian | horsetails, moss, cycads, fern, tree-fern | araucaria, ginkgo |
| 32 | Kosmoceratops | ceratopsian | horsetails, moss, cycads, fern, tree-fern | araucaria, ginkgo |
| 35 | Torosaurus | ceratopsian | horsetails, moss, cycads, fern, tree-fern | araucaria, ginkgo |
| 40 | Rapetosaurus | sauropod | araucaria, ginkgo, tree-fern | horsetails, moss, cycads, fern |
| 43 | Oviraptor | theropod (omnivore) | horsetails, moss, cycads, fern | araucaria, ginkgo, tree-fern |
| 44 | Brontosaurus | sauropod | araucaria, ginkgo, tree-fern | horsetails, moss, cycads, fern |
| 45 | Kentrosaurus | stegosaur | horsetails, moss, cycads, fern | araucaria, ginkgo, tree-fern |
| 46 | Edmontonia | ankylosaurid | horsetails, moss, cycads, fern | araucaria, ginkgo, tree-fern |
| 47 | Lambeosaurus | hadrosaur | horsetails, moss, cycads, fern, tree-fern | araucaria, ginkgo |
| 48 | Maiasaura | hadrosaur | horsetails, moss, cycads, fern, tree-fern | araucaria, ginkgo |
| 49 | Stegoceras | pachycephalosaur | horsetails, moss, cycads, fern | araucaria, ginkgo, tree-fern |
| 50 | Stygimoloch | pachycephalosaur | horsetails, moss, cycads, fern | araucaria, ginkgo, tree-fern |
| 51 | Nodosaurus | ankylosaurid | horsetails, moss, cycads, fern | araucaria, ginkgo, tree-fern |
| 52 | Huayangosaurus | stegosaur | horsetails, moss, cycads, fern | araucaria, ginkgo, tree-fern |
| 53 | Ouranosaurus | ornithopod | horsetails, moss, cycads, fern, tree-fern | araucaria, ginkgo |

*Note: Sauropods (7,14,21,23,28,40,44) = high browse → trees. Low browsers (ankylosaurs, stegosaurs, pachycephalosaurs) = ground/low. Mixed (hadrosaurs, ceratopsians, ornithopods) = low + tree fern. Omnivores (16,43) = low browse only.*

---

## Plant → Dinosaurs (for building rounds)

*Use when building a round: pick 3 from "eats" as correct; 2 decoys from "won't eat" or other plants' non-eaters.*

### horsetails
**Eats (correct):** 2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53  
**Won't eat (decoys):** 7, 14, 21, 23, 40, 43, 44

### moss
**Eats:** 2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53  
**Won't eat:** 7, 14, 21, 23, 40, 43, 44

### araucaria
**Eats:** 7, 14, 21, 23, 40, 44  
**Won't eat:** 2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53, 43

### ginkgo
**Eats:** 7, 14, 21, 23, 40, 44  
**Won't eat:** 2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53, 43

### cycads
**Eats:** 2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53  
**Won't eat:** 7, 14, 21, 23, 40, 43, 44

### tree-fern
**Eats:** 2, 5, 7, 9, 10, 11, 13, 14, 21, 23, 25, 32, 35, 40, 44, 47, 48, 53  
**Won't eat:** 3, 8, 15, 16, 17, 43, 45, 46, 49, 50, 51, 52 (low browsers; tree fern fronds high)

### fern
**Eats:** 2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 43, 45, 46, 47, 48, 49, 50, 51, 52, 53  
**Won't eat:** 7, 14, 21, 23, 40, 44 (sauropods prefer high browse; herbaceous fern = ground level)

---

## Round-Build Rules

For each round:
1. Pick one plant (from the 7).
2. **Correct** = 3 dinosaurs from that plant's "Eats" list (filter to those with `dino-*` images in pool).
3. **Decoys** = 2 dinosaurs from that plant's "Won't eat" list.
4. Shuffle the 5; present to player.
5. Player taps 3; game checks if all 3 are in the correct set.

*Ensure each plant has ≥ 3 eaters and ≥ 2 non-eaters in the image pool before using it.*

---

## Maintenance Notes

- **Add plant:** Add row to Dinosaur→Plants table; add Plant→Dinosaurs section; ensure ≥3 eaters, ≥2 non-eaters.
- **Add dinosaur:** Add to pool if Herbivore/Omnivore; assign Eats/Won't Eat per clade; update Plant→Dinosaurs.
- **Change assignment:** Edit both tables for consistency.
- **Image slug:** Use `flora-{slug}-habitat` for round display (e.g. `flora-horsetail-habitat`, `flora-herbaceous-fern-habitat`). Seeds: `flora-{slug}-seeds` (usage TBD).

### Seeds imagesets (`flora-{slug}-seeds`)

*Available but usage not yet determined. Options to consider:*
- **Correct-answer reveal** – after player picks 3 correct, briefly show seeds image with optional audio ("Ginkgo has winged seeds!")
- **Alternate round image** – some rounds show tree, some show seeds (adds variety; seeds may be harder to recognize)
- **Victory collage** – include seeds alongside tree in end-sequence plant recap
- **Educational bonus** – tap plant after round to see seeds + short fact
- **Intro sequence** – show tree then seeds (or vice versa) as part of plant introduction
