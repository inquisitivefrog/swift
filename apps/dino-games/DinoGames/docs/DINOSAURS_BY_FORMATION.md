# Dinosaurs by formation (Dino Formations game)

Same idea as **clades**: group species by **formation**. For three rounds with no repeat dinosaurs per round, each formation needs **at least 3 species** in the pool (3 correct + 2 decoys per round).

Your 24 formations (with suggested **slug** for JSON/filenames and audio):

| # | Your name           | Slug (for app)        | Count | Species (dino-* in pool) |
|---|---------------------|------------------------|-------|---------------------------|
| 1 | candeleros          | candeleros             | 1     | dino-giganotosaurus       |
| 2 | cedar mountain      | cedar-mountain         | 1     | dino-utahraptor           |
| 3 | cloverly            | cloverly               | 1     | dino-deinonychus          |
| 4 | daohugou beds       | daohugou-beds          | 1     | dino-pedopenna            |
| 5 | dinosaur park       | dinosaur-park          | 7     | dino-stegoceras, dino-lambeosaurus, dino-parasaurolophus, dino-troodon, dino-chasmosaurus, dino-corythosaurus, dino-albertosaurus |
| 6 | djadokhta           | djadokhta              | 2     | dino-oviraptor, dino-velociraptor |
| 7 | elrhaz              | elrhaz                 | 2     | dino-suchomimus, dino-ouranosaurus |
| 8 | frontier            | frontier               | 1     | dino-nodosaurus           |
| 9 | hell creek          | hell-creek             | 7     | dino-stygimoloch, dino-torosaurus, dino-trex, dino-pachycephalosaurus, dino-edmontosaurus, dino-ankylosaurus, dino-triceratops |
| 10 | horseshoe canyon   | horseshoe-canyon       | 1     | dino-edmontonia           |
| 11 | huincul            | huincul                | 1     | dino-argentinosaurus      |
| 12 | jehol biota        | jehol-biota            | 1     | dino-microraptor          |
| 13 | kaiparowitz        | kaiparowits            | 1     | dino-kosmoceratops        |
| 14 | kem kem            | kem-kem                | 1     | dino-spinosaurus          |
| 15 | lance              | lance                  | 0*    | *(often grouped with Hell Creek; could add same species as Hell Creek)* |
| 16 | maevarano          | maevarano              | 3     | dino-majungasaurus, dino-masiakasaurus, dino-rapetosaurus |
| 17 | morrison           | morrison               | 10    | dino-dryosaurus, dino-torvosaurus, dino-stegosaurus, dino-diplodocus, dino-ceratosaurus, dino-camarasaurus, dino-brontosaurus, dino-brachiosaurus, dino-apatosaurus, dino-allosaurus |
| 18 | nemegt             | nemegt                 | 2     | dino-gallimimus, dino-therizinosaurus |
| 19 | shaximiao          | shaximiao              | 1     | dino-huayangosaurus       |
| 20 | solnhofen limestone| solnhofen-limestone    | 2     | dino-compsognathus, dino-archaeopteryx |
| 21 | tendaguru          | tendaguru              | 1     | dino-kentrosaurus         |
| 22 | tiaojishan         | tiaojishan             | 3     | dino-xiaotingia, dino-eosinopteryx, dino-anchiornis |
| 23 | two medicine       | two-medicine           | 1     | dino-maiasaura            |
| 24 | wealden group      | wealden-group          | 2     | dino-iguanodon, dino-baryonyx |

**Source:** `formation_id` in `json/dinosaurs/char_*.json`. Some dinosaurs appear in more than one formation in real life; only one formation per character file was used above.

---

## Summary: formations with ≥3 species (ready for game)

| Formation        | Slug             | Count |
|------------------|------------------|-------|
| Hell Creek       | hell-creek       | 7     |
| Morrison         | morrison         | 10    |
| Dinosaur Park    | dinosaur-park    | 7     |
| Maevarano        | maevarano        | 3     |
| Tiaojishan       | tiaojishan       | 3     |

**5 formations** currently have ≥3 species. The rest have 0–2 and would need more species (or sharing species across formations, e.g. Lance = Hell Creek list) to be playable.

---

## What “sort species by formation” looks like in code

Same pattern as clades:

- **Clades:** `dinosaurCladeById: [Int: DinoClade]` → dinosaur id → clade; group by clade to get “dinosaurs per clade.”
- **Formations:** formation → set of `dinoImageNames` (e.g. `dino-trex`, `dino-triceratops`). The game already uses this: each **DinoFormation** has `dinoImageNames: Set<String>`. So “species sorted by formation” is exactly that: for each formation, the list of `dino-*` names that belong to it.

To drive the Dino Formations game from data (e.g. JSON in the app bundle), each formation file should look like:

```json
{
  "name": "Hell Creek",
  "dinoImageNames": ["dino-trex", "dino-triceratops", "dino-ankylosaurus", "dino-edmontosaurus", "dino-pachycephalosaurus", "dino-torosaurus", "dino-stygimoloch"],
  "hintLocation": "Montana, North Dakota, South Dakota, Wyoming, USA",
  "hintPeriod": "Late Cretaceous"
}
```

So “sorting species by formation” = one such object per formation, with `dinoImageNames` listing every species (from your 54) that is found in that formation. The table above is that view for your 24 formations from the current `char_*.json` data.

---

## Formation slug vs JSON formation files

Your repo has `json/dino-formations/<name>_formation.json` (habitat/period scene data) and `formation_id` on each `json/dinosaurs/char_*.json`. **`DinoFormationsCatalog`** loads both at runtime: formation metadata from `json/dino-formations/`, species lists grouped from matching `formation_id` on char files (with `MORRISON` → `MORRISON_LJ` prefix matching).

To add formations: add or fix `*_formation.json` under `json/dino-formations/` and ensure ≥3 char files reference that `formation_id` with shipped `dino-*` images.

The table above gives you the “species sorted by formation” view and which formations already have ≥3 species.
