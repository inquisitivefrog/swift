# Toothache Game – Asset Naming

**Design:** Trace-fossil games (teeth, tracks, eggs, coprolites) filter the dinosaur pool to only species that have the relevant assets. See [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md).

## Game concept

A paleontologist has found a tooth. The player inspects the tooth image and matches it to the correct dinosaur out of three grumpy dinosaurs (dinosaurs with sore mouths).

## Image assets (Assets.xcassets)

### Teeth (question image per round)

- **Prefix**: `tooth-`
- **Naming**: `tooth-{slug}` where `slug` matches the dinosaur’s image name without the `dino-` prefix.
- **Examples**: `tooth-trex`, `tooth-triceratops`, `tooth-stegosaurus`, `tooth-velociraptor`, etc.
- **Usage**: One tooth image per dinosaur used as a correct answer in a round. The game picks 3 dinosaurs per run and shows one tooth per round; the slug is derived from `dino-*` (e.g. `dino-trex` → `tooth-trex`).

### Grumpy dinosaurs (three options per round)

- **Prefix**: `grumpy-`
- **Naming**: `grumpy-{slug}` with the same slug as above (from the dinosaur’s `dino-*` image name).
- **Examples**: `grumpy-trex`, `grumpy-triceratops`, `grumpy-stegosaurus`, etc.
- **Usage**: Each of the three options in a round is shown as a grumpy dinosaur image; the correct one matches the tooth for that round.

### Game image (selection screen and transition)

- **Imageset**: `game-toothache`
- **Usage**: Shown on the “Choose a Dinosaur Game!” screen and on the transition screen before the game starts. Code uses `Image("game-toothache")`.

## Audio (Assets/Audio)

- **Transition / intro**: `Games/toothache.m4a`  
  - Mapped from the key `toothache`.  
  - Played when the user taps Toothache and the transition screen appears.

In-game feedback reuses existing clips: dinosaur names, “that’s right”, “try again”, “skipping this round”, “good job you got them all”, “you didn’t get them all right”, etc.

## Summary

| Asset type        | Prefix / name   | Example                | Location / notes                    |
|-------------------|-----------------|------------------------|-------------------------------------|
| Tooth (per dino)  | `tooth-`        | `tooth-trex`           | Assets.xcassets (imageset)         |
| Grumpy dinosaur   | `grumpy-`       | `grumpy-trex`          | Assets.xcassets (imageset)           |
| Game card         | `game-toothache`| `game-toothache`       | Assets.xcassets (imageset)          |
| Intro audio       | `toothache`      | `Games/toothache.m4a`      | Assets/Audio/Games/ |

Add tooth and grumpy imagesets for each dinosaur you want to appear in Toothache (same slug as the existing `dino-*` image for that dinosaur).

---

## Toothache assets checklist

Use this to confirm all assets are in place. Mark with `[x]` when added.

### Images (Assets.xcassets)

- [x] **game-toothache** – game card and transition screen
- [x] **tooth-*** – one per dinosaur (e.g. tooth-trex, tooth-triceratops, tooth-stegosaurus, tooth-velociraptor, tooth-therizinosaurus, tooth-spinosaurus, tooth-apatosaurus, tooth-ankylosaurus, tooth-corythosaurus, tooth-parasaurolophus, tooth-iguanodon, tooth-troodon)
- [x] **grumpy-*** – same set as teeth (e.g. grumpy-trex, grumpy-triceratops, …)

### Audio (Assets/Audio)

- [x] **Games/toothache.m4a** – transition when tapping Toothache
- [x] **Games/can-you-return-the-tooth.m4a** – plays when Toothache game view loads
- [ ] **Feedback** and **Dinosaurs** clips used in-game (thats-right-you-guessed-it, try-again, skipping-this-round, good-job-you-got-them-all, you-didnt-get-them-all-right, plus dinosaur name files) – confirm if any are missing
