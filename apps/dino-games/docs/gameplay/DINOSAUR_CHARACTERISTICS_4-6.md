# Dinosaur characteristics for ages 4–6 (Match the Dinosaur)

Simple, morphology-first traits so young players can match **body features** and **general facts**. Each dinosaur gets 1–2 characteristics; the game uses one per dinosaur per round (no duplicate trait labels in a round).

**Clade-based rounds:** Each round picks **one dinosaur per clade** (e.g. one theropod, one sauropod, one hadrosaur) so the three choices look and behave differently. That avoids "which theropod?" when art is simple and keeps gameplay varied. Clades: theropod, sauropod, ceratopsian, ankylosaurid, hadrosaur, spinosaurid, stegosaur, ornithopod, pachycephalosaur. See `DinoClade` and `dinosaurCladeById` in `MatchingGameView.swift`.

---

## Characteristic types (simple set)

### Morphology (how they look / move)

| Type | Who it’s for | Example |
|------|----------------|--------|
| **Two Feet** | Theropods (and bipedal ornithischians) | T-Rex, Velociraptor, Allosaurus |
| **Four Feet** | Sauropods, ceratopsians, ankylosaurids, hadrosaurs, stegosaurs | Apatosaurus, Triceratops, Ankylosaurus |
| **Long Neck** | Sauropods | Apatosaurus, Brachiosaurus, Diplodocus |
| **Long Tail** | Sauropods, some others | Apatosaurus, Diplodocus |
| **Frill** | Ceratopsians | Triceratops, Chasmosaurus, Torosaurus |
| **Horns** | Ceratopsians (face horns), some theropods (brow/nose) | Triceratops, Ceratosaurus, Allosaurus |
| **Spikes** | Stegosaurs (plates/spikes) | Stegosaurus |
| **Armor** | Ankylosaurids | Ankylosaurus |
| **Club Tail** | Ankylosaurids | Ankylosaurus |
| **Duck Bill** | Hadrosaurs | Corythosaurus, Parasaurolophus, Edmontosaurus |
| **Crest** | Hadrosaurs, some theropods | Corythosaurus, Parasaurolophus, Oviraptor |
| **Sail** | Spinosaurids | Spinosaurus |
| **Swims** | Spinosaurids (and piscivores) | Spinosaurus, Baryonyx |
| **Long Snout** | Spinosaurids (crocodile-like snout) | Spinosaurus, Baryonyx |
| **Claws** | Theropods (hands/feet) | Velociraptor, Deinonychus, Utahraptor |
| **Toe Claw** | Dromaeosaurs | Velociraptor, Deinonychus |
| **Long Claws** | Therizinosaurus | Therizinosaurus |
| **Thumb Spike** | Iguanodontians | Iguanodon |
| **Dome Head** | Pachycephalosaurs | Pachycephalosaurus |
| **Teeth** | Carnivorous theropods (big bite) | T-Rex, Allosaurus, Giganotosaurus |
| **Big** | Very large dinosaurs | Apatosaurus, Argentinosaurus, T-Rex |
| **Small** | Small species | Compsognathus, Microraptor, Archaeopteryx |
| **Feathers** | Many theropods (evidence or likely) | Therizinosaurus, Troodon, Oviraptor, Anchiornis |
| **Big Eyes** | Good night vision / smart | Troodon |
| **Smart** | High brain-to-body (Troodon, T-Rex) | T-Rex, Troodon |

### General (evidence / behavior – optional for variety)

| Type | Meaning for kids |
|------|-------------------|
| **Footprints Found** | We find their tracks |
| **Eggs Found** | We find their eggs (or they sit on eggs) |
| **Runs Fast** | Could run fast (theropods, ornithomimids) |
| **Carnivore** | Eats meat |
| **Herbivore** | Eats plants |
| **Eats Fish** | Eats fish (piscivore) |

---

## Suggested characteristics per dinosaur (all 43)

**Format:** Dinosaur (group) → **Primary**, *Secondary* (use 1–2 per dino in game data).

| # | Dinosaur | Group | Suggested characteristics |
|---|-----------|--------|---------------------------|
| 1 | **T-Rex** | Theropod | **Teeth**, *Footprints* (or *Two Feet*, *Big*) |
| 2 | **Triceratops** | Ceratopsian | **Frill**, *Horns* (or *Four Feet*) |
| 3 | **Stegosaurus** | Ornithischian (stegosaur) | **Spikes**, *Four Feet* |
| 4 | **Velociraptor** | Theropod | **Claws**, *Toe Claw* (or *Two Feet*, *Fast*) |
| 5 | **Therizinosaurus** | Theropod | **Long Claws**, *Feathers* (or *Two Feet*) |
| 6 | **Spinosaurus** | Spinosaurid | **Sail**, *Swims* (or *Long Snout*) |
| 7 | **Apatosaurus** | Sauropod | **Long Neck**, *Long Tail* (or *Four Feet*, *Big*) |
| 8 | **Ankylosaurus** | Ankylosaurid | **Armor**, *Club Tail* (or *Four Feet*) |
| 9 | **Corythosaurus** | Hadrosaur | **Duck Bill**, *Crest* (or *Four Feet*) |
| 10 | **Parasaurolophus** | Hadrosaur | **Crest**, *Duck Bill* (or *Four Feet*) |
| 11 | **Iguanodon** | Ornithischian (ornithopod) | **Thumb Spike**, *Four Feet* |
| 12 | **Troodon** | Theropod | **Smart**, *Big Eyes* (or *Two Feet*, *Feathers*) |
| 13 | **Edmontosaurus** | Hadrosaur | **Duck Bill**, *Big* (or *Four Feet*) |
| 14 | **Camarasaurus** | Sauropod | **Long Neck**, *Four Feet* (or *Long Tail*) |
| 15 | **Dryosaurus** | Ornithischian (small ornithopod) | **Four Feet**, *Fast* (or *Herbivore*) |
| 16 | **Gallimimus** | Theropod (ornithomimid) | **Two Feet**, *Fast* (or *Long Neck* for ostrich-like) |
| 17 | **Pachycephalosaurus** | Pachycephalosaur | **Dome Head**, *Two Feet* |
| 18 | **Albertosaurus** | Theropod | **Two Feet**, *Teeth* (or *Carnivore*) |
| 19 | **Anchiornis** | Small theropod | **Feathers**, *Two Feet* (or *Small*) |
| 20 | **Archaeopteryx** | Small theropod | **Feathers**, *Small* (or *Two Feet*) |
| 21 | **Argentinosaurus** | Sauropod | **Long Neck**, *Big* (or *Four Feet*, *Long Tail*) |
| 22 | **Baryonyx** | Spinosaurid | **Long Snout**, *Claws* (or *Swims*, *Eats Fish*) |
| 23 | **Brachiosaurus** | Sauropod | **Long Neck**, *Big* (or *Four Feet*, *Long Tail*) |
| 24 | **Ceratosaurus** | Theropod | **Two Feet**, *Horns* (nose horn) (or *Teeth*) |
| 25 | **Chasmosaurus** | Ceratopsian | **Frill**, *Horns* (or *Four Feet*) |
| 26 | **Compsognathus** | Theropod | **Two Feet**, *Small* (or *Teeth*) |
| 27 | **Deinonychus** | Theropod | **Claws**, *Toe Claw* (or *Two Feet*) |
| 28 | **Diplodocus** | Sauropod | **Long Neck**, *Long Tail* (or *Four Feet*, *Big*) |
| 29 | **Dromaeosaurus** | Theropod | **Two Feet**, *Claws* (or *Fast*) |
| 30 | **Eosinopteryx** | Small theropod | **Feathers**, *Two Feet* (or *Small*) |
| 31 | **Giganotosaurus** | Theropod | **Two Feet**, *Teeth* (or *Big*) |
| 32 | **Kosmoceratops** | Ceratopsian | **Frill**, *Horns* (or *Four Feet*) |
| 33 | **Microraptor** | Small theropod | **Feathers**, *Small* (or *Two Feet*) |
| 34 | **Pedopenna** | Small theropod | **Feathers**, *Two Feet* (or *Small*) |
| 35 | **Torosaurus** | Ceratopsian | **Frill**, *Horns* (or *Four Feet*) |
| 36 | **Utahraptor** | Theropod | **Claws**, *Toe Claw* (or *Two Feet*, *Big*) |
| 37 | **Xiaotingia** | Small theropod | **Feathers**, *Two Feet* (or *Small*) |
| 38 | **Masiakasaurus** | Theropod | **Two Feet**, *Teeth* (or *Carnivore*) |
| 39 | **Torvosaurus** | Theropod | **Two Feet**, *Teeth* (or *Big*) |
| 40 | **Rapetosaurus** | Sauropod | **Long Neck**, *Long Tail* (or *Four Feet*) |
| 41 | **Majungasaurus** | Theropod | **Two Feet**, *Teeth* (or *Carnivore*) |
| 42 | **Allosaurus** | Theropod | **Two Feet**, *Horns* (brow) (or *Teeth*) |
| 43 | **Oviraptor** | Theropod | **Crest**, *Feathers* (or *Eggs Found*, *Two Feet*) |

---

## Group summary (for your “walk on two/four feet” idea)

- **Theropods (two feet, bite):** 1, 4, 5, 12, 16, 18, 19, 20, 24, 26, 27, 29, 31, 33, 34, 36, 37, 38, 39, 41, 42, 43 → use **Two Feet**, **Teeth**, **Claws**, **Toe Claw**, **Fast**, **Smart**, **Feathers**, **Crest**, etc.
- **Sauropods (four feet, long neck & tail):** 7, 14, 21, 23, 28, 40 → **Long Neck**, **Long Tail**, **Four Feet**, **Big**.
- **Ceratopsians (four feet, frill & horns):** 2, 25, 32, 35 → **Frill**, **Horns**, **Four Feet**.
- **Ankylosaurids (four feet, armor & tail weapon):** 8 → **Armor**, **Club Tail**, **Four Feet**.
- **Hadrosaurs (four feet, duck bill & crest):** 9, 10, 13 → **Duck Bill**, **Crest**, **Four Feet**, **Big**.
- **Spinosaurids (long snout, sail, swims):** 6, 22 → **Sail**, **Swims**, **Long Snout**, **Claws**.
- **Other ornithischians:** 3 (Stegosaurus: **Spikes**, **Four Feet**), 11 (Iguanodon: **Thumb Spike**, **Four Feet**), 15 (Dryosaurus: **Four Feet**, **Fast**), 17 (Pachycephalosaurus: **Dome Head**, **Two Feet**).

---

## Implementation notes for Match the Dinosaur

1. **Live data:** `LandDinosaurData.allDinosaurs` + `characteristicIds`; round building in `MatchingGameView.swift` / `MatchingGameConfigs.dinoFeatures`. Game id: `match-the-dinosaur` (catalog level 7, not in the shipping 12).
2. **Round rules:** One characteristic per dinosaur per round; no duplicate trait **types** among the three dinosaurs or decoy options in that round.
3. **Feathers:** Single type **Feathers** with image `dino-char-proto-feathers` (proto-feathers). Pennaceous/flight feather assets are not used in this game.
4. **Diet traits** (carnivore, herbivore, piscivore, insectivore, omnivore): Not used in Match the Dinosaur — reserved for **Dino Diets!** (`match-the-diet`).
5. **Existing `dino-char-*` types in code:** Teeth, Footprints, Frill, Horns, Spikes, Claws, Fast, Toe Claw, Long Claws, Feathers, Sail, Swims, Long Neck, Big, Armor, Club Tail, Crest, Duck Bill, Thumb Spike, Smart, Big Eyes.
6. **New types you may want to add** (with new image sets, e.g. `dino-char-two-feet`, `dino-char-four-feet`, `dino-char-long-tail`, `dino-char-long-snout`, `dino-char-dome-head`, `dino-char-small`):
   - **Two Feet**, **Four Feet**, **Long Tail**, **Long Snout**, **Dome Head**, **Small**.
7. **General traits (optional later):** Footprints Found, Eggs Found, Runs Fast, Carnivore, Herbivore, Eats Fish – can share icons with existing or new `dino-char-*` assets.
8. **Per-dinosaur:** Give each dinosaur **at least one** characteristic (prefer morphology). Dinosaurs that currently have `characteristicIds: []` need entries in `allCharacteristics` and those ids in `characteristicIds` so they can appear in Match the Dinosaur.
9. **Duplicate types:** Multiple dinosaurs can share a type (e.g. **Crest** on Corythosaurus, Parasaurolophus, Oviraptor). The game already ensures no duplicate *labels* in a single round by picking one characteristic per dinosaur with a distinct type when building the round.

### Argentinosaurus (id 21) — Big vs Long Neck

Argentinosaurus currently has **Long Neck** and **Big**. In play, children often prefer **Big** because Argentinosaurus is famous for being one of the largest dinosaurs. Sauropods with long-neck and/or big traits include Apatosaurus, Camarasaurus, Argentinosaurus, Brachiosaurus, Diplodocus, Rapetosaurus, and Brontosaurus.

If you want Argentinosaurus to emphasize **Big** when the game ships:

1. **Use only Big:** Change Argentinosaurus `characteristicIds` in `LandDinosaurData.swift` from `[57, 58]` to `[58]`. Whenever Argentinosaurus is in a round, only “Big” is offered for him.
2. **Big + Long Tail:** Add a `Characteristic` with `dinosaurId: 21` and type `"Long Tail"` (reuse image `dino-char-long-tail`), then set `characteristicIds` to `[58, newId]` so his traits are Big and Long Tail and “Big” is the obvious choice.

If you tell me your preferred mix (e.g. “only morphology, no diet words” or “add Footprints / Eggs for a few”), I can narrow the list to exactly 1–2 traits per dinosaur and then we can map them into `allDinosaurs` and `allCharacteristics` in code and add any new `dino-char-*` assets you want.
