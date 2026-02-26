# Match the Dinosaur — Dinosaur vs characteristics table

This table reflects the data in `MatchingGameView.swift` (`MatchingGameConfigs.allDinosaurs` and `allCharacteristics`). Each dinosaur has multiple characteristics; the game picks **one characteristic per dinosaur** per round and avoids **duplicate characteristic types** in the round (so no two dinosaurs in the same round share the same trait, and decoy options don’t repeat a trait that belongs to one of the three dinosaurs).

**Feathers:** The game uses a single type, **Feathers**, with image `dino-char-proto-feathers` (proto-feathers). Other feather assets (pennaceous, flight) are not used in this game.

**Diet (carnivore, herbivore, piscivore, insectivore, omnivore):** Not used in Match the Dinosaur; reserved for a future game. You can remove those from dino-characteristics assets if desired.

**Note:** Argentinosaurus (id 21) currently has **Long Neck** and **Big**. In play, children often prefer **Big** because Argentinosaurus is famous for being one of the largest dinosaurs. Consider giving Argentinosaurus **Big** plus one other trait (e.g. **Long Tail** or **Four Feet**) so “Big” is the obvious choice when it appears, or otherwise prioritizing “Big” when both are in the pool.

| # | Dinosaur         | Characteristics                                      |
|---|------------------|------------------------------------------------------|
| 1 | T-Rex            | Teeth, Smart                                         |
| 2 | Triceratops      | Frill, Horns                                         |
| 3 | Stegosaurus      | Plates                                               |
| 4 | Velociraptor     | Claws, Fast, Toe Claw                                |
| 5 | Therizinosaurus  | Long Claws, Feathers                                 |
| 6 | Spinosaurus      | Sail, Swims                                          |
| 7 | Apatosaurus      | Long Neck, Big                                       |
| 8 | Ankylosaurus     | Armor, Tail Club                                     |
| 9 | Corythosaurus    | Crest, Duck Bill                                     |
| 10 | Parasaurolophus | Crest, Duck Bill                                     |
| 11 | Iguanodon       | Thumb Spike                                          |
| 12 | Troodon         | Smart, Big Eyes                                      |
| 13 | Edmontosaurus   | Duck Bill, Big                                       |
| 14 | Camarasaurus    | Long Neck, Four Feet                                 |
| 15 | Dryosaurus     | Four Feet, Fast                                      |
| 16 | Gallimimus     | Two Feet, Fast                                       |
| 17 | Pachycephalosaurus | Dome Head, Two Feet                              |
| 18 | Albertosaurus  | Two Feet, Teeth                                      |
| 19 | Anchiornis     | Feathers, Two Feet                                   |
| 20 | Archaeopteryx  | Feathers, Small                                      |
| **21** | **Argentinosaurus** | **Long Neck, Big** *(see note above)*        |
| 22 | Baryonyx       | Long Snout, Claws                                    |
| 23 | Brachiosaurus  | Long Neck, Big                                       |
| 24 | Ceratosaurus   | Two Feet, Horns                                      |
| 25 | Chasmosaurus   | Frill, Horns                                         |
| 26 | Compsognathus  | Two Feet, Small                                      |
| 27 | Deinonychus    | Claws, Toe Claw                                      |
| 28 | Diplodocus     | Long Neck, Long Tail                                 |
| 29 | Dromaeosaurus  | Two Feet, Claws                                      |
| 30 | Eosinopteryx   | Feathers, Two Feet                                   |
| 31 | Giganotosaurus | Two Feet, Teeth                                      |
| 32 | Kosmoceratops  | Frill, Horns                                         |
| 33 | Microraptor    | Feathers, Small                                      |
| 34 | Pedopenna      | Feathers, Two Feet                                   |
| 35 | Torosaurus     | Frill, Horns                                         |
| 36 | Utahraptor     | Claws, Toe Claw                                      |
| 37 | Xiaotingia     | Feathers, Two Feet                                  |
| 38 | Masiakasaurus  | Two Feet, Teeth                                      |
| 39 | Torvosaurus    | Two Feet, Teeth                                      |
| 40 | Rapetosaurus   | Long Neck, Long Tail                                 |
| 41 | Majungasaurus  | Two Feet, Teeth                                      |
| 42 | Allosaurus     | Two Feet, Horns                                      |
| 43 | Oviraptor      | Crest, Feathers                                      |
| 44 | Brontosaurus   | Long Neck, Long Tail                                 |
| 45 | Kentrosaurus   | Tail Spikes, Four Feet                               |
| 46 | Edmontonia     | Armor, Four Feet                                     |
| 47 | Lambeosaurus   | Crest, Duck Bill                                     |
| 48 | Maiasaura      | Duck Bill, Crest                                     |
| 49 | Stegoceras     | Dome Head, Two Feet                                  |
| 50 | Stygimoloch    | Dome Head, Two Feet                                  |
| 51 | Nodosaurus     | Armor, Four Feet                                     |
| 52 | Huayangosaurus | Plates, Four Feet                                    |
| 53 | Ouranosaurus   | Sail, Four Feet                                      |
| 54 | Suchomimus     | Long Snout, Swims                                    |

## Sauropods with “Long Neck” and/or “Big”

- **Apatosaurus (7):** Long Neck, Big  
- **Camarasaurus (14):** Long Neck, Four Feet  
- **Argentinosaurus (21):** Long Neck, Big ← *commonly known for “biggest”*  
- **Brachiosaurus (23):** Long Neck, Big  
- **Diplodocus (28):** Long Neck, Long Tail  
- **Rapetosaurus (40):** Long Neck, Long Tail  
- **Brontosaurus (44):** Long Neck, Long Tail  

If you want Argentinosaurus to emphasize “Big” for the matching game, options in `MatchingGameView.swift`:

1. **Use only Big:** Change Argentinosaurus `characteristicIds` from `[57, 58]` to `[58]`. Then whenever Argentinosaurus is in a round, only “Big” is offered for him, so kids always match Big → Argentinosaurus (other dinosaurs in the round still have two traits).
2. **Big + Long Tail:** Add a new `Characteristic` with `dinosaurId: 21` and type `"Long Tail"` (reuse image `dino-char-long-tail`), then set Argentinosaurus `characteristicIds` to `[58, newId]` so his two traits are Big and Long Tail and “Big” is the obvious choice.
