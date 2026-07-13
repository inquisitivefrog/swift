# Characteristic / Feature Image Sets

DinoGames uses a consistent naming scheme for creature images and their **feature** (characteristic) images in `Assets.xcassets`.

## Migration: rename existing dinosaur feature assets

If you still have the old **`char-*`** image sets (e.g. `char-teeth`, `char-crest`), rename each in Xcode to **`dino-char-*`**:

- In the Project navigator, select the imageset (e.g. `char-teeth.imageset`).
- Rename it to `dino-char-teeth` (and similarly for all others).

The code now expects **`dino-char-<name>`** for dinosaur features. Internal filenames inside each imageset (e.g. `char-teeth-80.png`) can stay as-is; Swift loads by asset name, not by those filenames.

---

## Naming convention

| Category         | Creatures              | Features (characteristics)     |
|------------------|------------------------|--------------------------------|
| Dinosaurs        | `dino-<name>`          | `dino-char-<name>`             |
| Pterosaurs       | `ptero-<name>`         | `ptero-char-<name>`            |
| Marine reptiles  | `marine-<name>` or per-clade | `marine-char-<name>` or per-clade |

**Per-clade option for marine reptiles** (when you add those games):  
`mosa-char-<name>`, `plesi-char-<name>`, `ichthy-char-<name>` for mosasaur, plesiosaur, and ichthyosaur-specific features if you want separate art per group.

---

## Dinosaur features (Match the Dinosaur)

Add image sets in Xcode with these **exact** names (rename existing `char-*` to `dino-char-*`).

| Dinosaur        | Feature    | Asset name              | Audio (Characteristics/) |
|-----------------|------------|--------------------------|---------------------------|
| T-Rex           | Teeth      | `dino-char-teeth`       | teeth                     |
| T-Rex           | Footprints | `dino-char-footprints`  | footprints                |
| Triceratops     | Frill      | `dino-char-frill`       | frill                     |
| Triceratops     | Horns      | `dino-char-horns`       | horns                     |
| Stegosaurus     | Spikes     | `dino-char-spikes`      | spikes                    |
| Velociraptor    | Claws      | `dino-char-claws`       | claws                     |
| Velociraptor    | Fast       | `dino-char-fast`        | fast                      |
| Velociraptor    | Toe Claw   | `dino-char-toe-claw`    | toe-claw                  |
| Therizinosaurus | Long Claws | `dino-char-long-claws`  | long-claws                |
| Therizinosaurus | Feathers   | `dino-char-feathers`    | feathers                  |
| Spinosaurus     | Sail       | `dino-char-sail`        | sail                      |
| Spinosaurus     | Swims      | `dino-char-swims`       | swims                     |
| Apatosaurus     | Long Neck  | `dino-char-long-neck`   | long-neck                 |
| Apatosaurus     | Big        | `dino-char-big`         | big                       |
| Ankylosaurus    | Armor      | `dino-char-armor`       | armor                     |
| Ankylosaurus    | Club Tail  | `dino-char-club-tail`   | club-tail                 |
| Corythosaurus   | Crest      | `dino-char-crest`       | crest                     |
| Corythosaurus   | Duck Bill  | `dino-char-duck-bill`   | duck-bill                 |
| Parasaurolophus | Crest      | `dino-char-crest`       | crest                     |
| Parasaurolophus | Duck Bill  | `dino-char-duck-bill`   | duck-bill                 |
| Iguanodon       | Thumb Spike| `dino-char-thumb-spike` | thumb-spike               |
| Troodon         | Smart      | `dino-char-smart`       | smart                     |
| Troodon         | Big Eyes   | `dino-char-big-eyes`    | big-eyes                  |

---

## Pterosaur features (Match the Pterosaur)

Add image sets with prefix **`ptero-char-`**. Unique feature names (one image set per; reuse across pterosaurs as needed):

| Asset name               | Feature  | Used by |
|--------------------------|----------|---------|
| `ptero-char-wings`      | Wings    | all     |
| `ptero-char-small`      | Small    | Pterodactyl, Anurognathus |
| `ptero-char-teeth`      | Teeth    | several |
| `ptero-char-crest`      | Crest    | Pteranodon, Dsungaripterus, Nyctosaurus, Tapejara, Tupandactylus |
| `ptero-char-no-teeth`   | No Teeth | Pteranodon, Nyctosaurus |
| `ptero-char-big`        | Big      | Quetzalcoatlus |
| `ptero-char-long-neck`  | Long Neck| Quetzalcoatlus |
| `ptero-char-long-tail`  | Long Tail| Rhamphorhynchus |
| `ptero-char-big-head`   | Big Head | Dimorphodon, Tupandactylus |

Audio for these is under `Characteristics/` (e.g. wings.m4a, small.m4a) and wired in `SpeechManager.audioFilePath(for:)`.

---

## Marine reptiles (future)

When you add Match the Marine Reptile (or similar):

- **Option A:** One prefix for all — `marine-char-<name>` (e.g. `marine-char-flippers`, `marine-char-long-neck`).
- **Option B:** Per-clade — `mosa-char-<name>`, `plesi-char-<name>`, `ichthy-char-<name>` for features specific to each group.

Creature images: `marine-<name>` or `mosa-<name>`, `plesi-<name>`, `ichthy-<name>`.
