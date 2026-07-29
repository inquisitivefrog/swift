# Dino Smile: Dinosaur ↔ Tooth Mapping Review

**Purpose:** Review the mapping between dinosaur smiles and tooth shapes in Dino Smile. The game uses `DentalMorphology.smileToothType(for:)` for `dino-smile-tooth-*` images. Dino Toothache uses `DentalMorphology.toothType(for:)` for `dino-toothache-tooth-*`.

---

## How It Works

- **Smiles:** `dino-smile-{slug}` (e.g. dino-smile-trex)
- **Teeth:** `dino-smile-tooth-{toothType}` (e.g. dino-smile-tooth-banana)
- **Mapping:** `DentalMorphology.smileToothType(for: dino)` returns the tooth type slug for Dino Smile
- **Playable:** A dinosaur is in the pool only if BOTH its smile image AND its tooth image exist

---

## Current Dino Smile Mappings (as of last update)

| Dinosaurs | Tooth type |
|-----------|------------|
| stegosaurus, kentrosaurus, huayangosaurus | flute-leaf |
| gallimimus, ornithomimus, struthiomimus | nipping-beak |
| oviraptor, deinocheirus, gigantoraptor | nutcracker |
| triceratops | forked-battery |
| iguanodon, ouranosaurus | diamond-battery |

---

## Mismatches: DentalMorphology vs dino-smile-tooth-* Assets

DentalMorphology was designed for Dino Toothache (`dino-toothache-tooth-*`). Dino Smile uses `dino-smile-tooth-*` with different asset names.

| DentalMorphology returns | dino-smile-tooth asset exists? | Dinosaurs affected |
|--------------------------|--------------------------------|--------------------|
| banana | ✓ | trex, albertosaurus, majungasaurus |
| forked-grinder | ✗ | **triceratops** |
| fluted-leaf-v1 | ✗ | **stegosaurus** |
| fluted-leaf-v2 | ✗ | **kentrosaurus, huayangosaurus** |
| hooked-blade | ✓ | velociraptor, deinonychus, dromaeosaurus, utahraptor |
| leaf-slicer | ✓ | therizinosaurus |
| smooth-cone | ✓ | spinosaurus, suchomimus, baryonyx |
| pencil-peg | ✓ | apatosaurus, diplodocus, brontosaurus, amargasaurus, mamenchisaurus |
| large-ridged-leaf | ✓ | ankylosaurus, edmontonia, nodosaurus, euoplocephalus, polacanthus |
| honeycomb-battery | ✓ | corythosaurus, parasaurolophus, edmontosaurus, lambeosaurus, maiasaura |
| diamond-battery-v1 | ✗ | **iguanodon, ouranosaurus** |
| hooked-needle | ✓ | troodon, fukuiraptor |
| silver-spoon | ✓ | camarasaurus, brachiosaurus |
| small-scalloped-leaf | ✓ | dryosaurus, gasparinisaura |
| nipping-beak-v1 | ✗ | **gallimimus** |
| nipping-beak-v2 | ✗ | **oviraptor, deinocheirus, gigantoraptor, ornithomimus, struthiomimus** |
| scalloped-blade | ✓ | pachycephalosaurus |
| needle-spike | ✓ | archaeopteryx, compsognathus, eosinopteryx, microraptor, pedopenna, xiaotingia |
| heavy-peg | ✓ | argentinosaurus, rapetosaurus |
| forked-battery | ✓ | chasmosaurus, kosmoceratops, torosaurus, styracosaurus |
| nutcracker | ✓ | stegoceras, stygimoloch |
| grand-blade | ✓ | giganotosaurus, acrocanthosaurus, carcharodontosaurus, gigantosaurus |
| forward-spear | ✓ | masiakasaurus |
| hooked-slicer | ✓ | ceratosaurus, torvosaurus, allosaurus, australovenator |
| sharp-serrated-leaf | ✓ | anchiornis |

---

## Dinosaurs Excluded from Dino Smile (Missing Tooth Asset)

These dinosaurs have smile images but are **not playable** because their DentalMorphology tooth type has no matching `dino-smile-tooth-*` asset:

| Dinosaur | DentalMorphology tooth | Missing asset |
|----------|------------------------|---------------|
| triceratops | forked-grinder | dino-smile-tooth-forked-grinder |
| stegosaurus | fluted-leaf-v1 | dino-smile-tooth-fluted-leaf-v1 |
| kentrosaurus | fluted-leaf-v2 | dino-smile-tooth-fluted-leaf-v2 |
| huayangosaurus | fluted-leaf-v2 | dino-smile-tooth-fluted-leaf-v2 |
| iguanodon | diamond-battery-v1 | dino-smile-tooth-diamond-battery-v1 |
| ouranosaurus | diamond-battery-v1 | dino-smile-tooth-diamond-battery-v1 |
| gallimimus | nipping-beak-v1 | dino-smile-tooth-nipping-beak-v1 |
| oviraptor | nipping-beak-v2 | dino-smile-tooth-nipping-beak-v2 |
| deinocheirus | nipping-beak-v2 | dino-smile-tooth-nipping-beak-v2 |
| gigantoraptor | nipping-beak-v2 | dino-smile-tooth-nipping-beak-v2 |
| ornithomimus | nipping-beak-v2 | dino-smile-tooth-nipping-beak-v2 |
| struthiomimus | nipping-beak-v2 | dino-smile-tooth-nipping-beak-v2 |

---

## Orphaned dino-smile-tooth-* Assets (No Dinosaur Maps to Them)

These tooth assets exist but no dinosaur in DentalMorphology maps to them:

| Asset | Notes |
|-------|-------|
| flute-leaf | Stegosaurs (stegosaurus, kentrosaurus, huayangosaurus) map to fluted-leaf-v1/v2 |
| parrot-beak-ankylosaurid | Ankylosaurs map to large-ridged-leaf |
| parrot-beak-ceratopsian | Triceratops maps to forked-grinder |
| parrot-beak-stegosaurid | Stegosaurs map to fluted-leaf-v1/v2 |
| duck-bill | Hadrosaurs map to honeycomb-battery |

**Intentional:** Some of these assets were created even though they are not yet used in gameplay. They may be needed later (e.g., for beak-focused content or to distinguish beak vs. dental battery).

**Herbivore feeding:** Herbivores often use both the **beak or bill** (for cropping/grasping) and the **dental battery** (for chewing). The parrot-beak and duck-bill assets represent the beak/bill; the battery assets (honeycomb-battery, forked-battery, large-ridged-leaf, etc.) represent the chewing teeth. Both play a role in herbivore feeding.

---

## Possible Fixes

### Option A: Add alias mapping in SmilingDinosGameView
Map DentalMorphology tooth types to dino-smile-tooth asset names where they differ:
- `forked-grinder` → `parrot-beak-ceratopsian` (or `forked-battery`)
- `fluted-leaf-v1`, `fluted-leaf-v2` → `flute-leaf`
- `diamond-battery-v1` → `diamond-battery`
- `nipping-beak-v1`, `nipping-beak-v2` → `nipping-beak`

### Option B: Add missing dino-smile-tooth-* assets
Create imagesets for: forked-grinder, fluted-leaf-v1, fluted-leaf-v2, diamond-battery-v1, nipping-beak-v1, nipping-beak-v2 (could copy from dino-toothache-tooth-* if they exist).

### Option C: Update DentalMorphology for Dino Smile
Use dino-smile-tooth asset names in DentalMorphology. Would require a separate mapping for Dino Toothache (or a game-specific lookup layer) since Toothache uses different asset names.

---

## Morphology Accuracy (For Paleontology Review)

The parrot-beak vs leaf-tooth distinction is notable:
- **Ceratopsians** (triceratops): Have a parrot-like beak; `parrot-beak-ceratopsian` may be more accurate than `forked-grinder`
- **Stegosaurs** (stegosaurus): Small leaf-shaped teeth; `flute-leaf` / `fluted-leaf` are both plausible
- **Ankylosaurs** (ankylosaurus): Have parrot-like beaks; `parrot-beak-ankylosaurid` may be more accurate than `large-ridged-leaf` for the beak, though ankylosaurs also have leaf-shaped cheek teeth
