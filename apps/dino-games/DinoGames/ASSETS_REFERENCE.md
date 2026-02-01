# DinoGames – Assets reference

All audio paths and key image names the app expects.

**Design:** Trace-fossil games use only dinosaurs that have the required images (e.g. tooth + grumpy for Toothache). Art is AI-generated and cartoony, so the number of species with distinct assets per game is intentionally limited. See [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md). Use this to verify files are in the bundle. Paths are relative to `Assets/Audio/` or `Assets.xcassets` as noted.

---

## Audio (Assets/Audio)

Paths below are under `DinoGames/Assets/Audio/`. The app looks for `{path}.m4a` (e.g. `Games/toothache.m4a`).

### Games/

| Key / usage | Path | Notes |
|-------------|------|--------|
| Transition: Toothache | Games/toothache | When user taps Toothache |
| Toothache game load | Games/can-you-return-the-tooth | When Toothache view appears |
| Transition: Match Dinosaur | Games/can-you-match-each-dinosaur | |
| Transition: Match Pterosaur | Games/can-you-match-each-pterosaur | |
| Transition: Weigh Dinosaur | Games/guess-which-dinosaur-is-heavier | |
| Transition: Weigh Pterosaur | Games/guess-which-pterosaur-is-heavier | |
| Transition: Name That Dinosaur | Games/can-you-name-that-dinosaur | |
| Transition: Name the Dinosaur | Games/can-you-name-the-dinosaur | |
| Transition: Name the Pterosaur | Games/can-you-name-the-pterosaur | |
| Game intro (name-that) | Games/name-that-dinosaur | |
| Welcome | Games/welcome-to-dino-games | |
| Choose dinosaur game | Games/choose-a-dinosaur-game | |
| Choose pterosaur game | Games/choose-a-pterosaur-game | |
| Choose marine reptile game | Games/choose-a-marine-reptile-game | |
| Category: Land | Games/dinosaurs | |
| Category: Sea | Games/marine-reptiles | |
| Category: Air | Games/pterosaurs | |

### Feedback/

| Key / usage | Path | Notes |
|-------------|------|--------|
| Great match | Feedback/great-match | Matching game correct pair |
| That’s right you guessed it | Feedback/thats-right-you-guessed-it | Guess / Toothache correct |
| Try again | Feedback/try-again | First wrong guess |
| That’s not right, try again | Feedback/thats-not-right-try-again | Matching first wrong |
| That’s still not right | Feedback/thats-still-not-right | Matching second wrong (same dino) |
| That’s not right | Feedback/thats-not-right | Matching second wrong (other) |
| Skipping this round | Feedback/skipping-this-round | Guess / Toothache 2 wrong in round |
| Good job you got them all | Feedback/good-job-you-got-them-all | All rounds correct |
| You didn’t get them all right | Feedback/you-didnt-get-them-all-right | Game over with errors |
| Great job you weighed six dinosaurs | Feedback/great-job-you-weighed-six-dinosaurs | Weigh game success |
| Sorry game over | Feedback/sorry-game-over | (Legacy; app uses you-didnt-get-them-all-right) |
| Success all matches | Feedback/success-all-matches | (Legacy; app uses good-job-you-got-them-all) |
| Is heavier | Feedback/is-heavier | Weigh game |
| They both weigh about the same | Feedback/they-both-weigh-about-the-same | Weigh game |
| Game intro pterosaur | Feedback/game-intro-pterosaur | Pterosaur matching (if used) |

### Dinosaurs/

Dinosaur name speech maps to `Dinosaurs/{slug}.m4a`. Slugs: t-rex, triceratops, stegosaurus, troodon, velociraptor, iguanodon, ankylosaurus, therizinosaurus, spinosaurus, apatosaurus, corythosaurus, parasaurolophus (plus diplodocus, pachycephalosaurus if ever used).

### Pterosaurs/

Pterosaur name speech maps to `Pterosaurs/ptero-{slug}.m4a`: ptero-pteradactyl, ptero-pteranodon, ptero-quetzacoatlus, ptero-rhamphorhynchus, ptero-dimorphodon, ptero-anurognathus, ptero-dsungaripterus, ptero-nyctosaurus, ptero-tapejara, ptero-tupandactylus.

### Dino-Characteristics/ and Ptero-Characteristics/

Characteristic words (teeth, footprints, frill, horns, spikes, claws, etc.) map to files under `Dino-Characteristics/` or `Ptero-Characteristics/` as set in the matching game. See `MatchingGameView` `audioFilePath(for:)` for the full list.

---

## Images (Assets.xcassets)

### Game cards (selection + transition)

These are used as `Image(imageName)` where `imageName` comes from the game config id (`game-{id}`):

| Game | Imageset name |
|------|----------------|
| Match the Dinosaur! | game-match-the-dinosaur |
| Match the Pterosaur! | game-match-the-pterosaur |
| Weigh game | game-weigh-dinosaur |
| Name That Dinosaur! | game-name-that-dinosaur |
| Wacky Dinosaurs! | game-wacky-dinosaurs |
| Toothache! | game-toothache |

### Other shared

- **CoverImage** – cover on category/game selection (Land), splash if used.

### Matching game

- **Dinosaur images**: `dino-trex`, `dino-triceratops`, `dino-stegosaurus`, etc. (see `MatchingGameConfigs.allDinosaurs`).
- **Characteristic images**: `dino-char-teeth`, `dino-char-footprints`, etc. and `ptero-char-wings`, etc. (see `MatchingGameConfigs`).

### Guess (Name That Dinosaur)

- **Silhouettes**: `silhouette-trex`, `silhouette-triceratops`, etc.

### Toothache

- **Teeth**: `tooth-{slug}` (e.g. tooth-trex, tooth-triceratops) – same slug as `dino-*`.
- **Grumpy dinosaurs**: `grumpy-{slug}` (e.g. grumpy-trex, grumpy-triceratops).

### Weigh / Wacky

- Dinosaur images same as matching (`dino-*`).

---

## Possibly missing or optional

- **Dinosaurs/diplodocus.m4a**, **Dinosaurs/pachycephalosaurus.m4a** – mapped in code but those dinosaurs are commented out in config; only needed if you re-enable them.
- **Feedback/sorry-game-over.m4a**, **Feedback/success-all-matches.m4a** – no longer used by app; safe to keep or remove.
- **game-intro-pterosaur** – used only if pterosaur matching plays an intro in-view; transition already uses can-you-match-each-pterosaur.
- Any **tooth-*** or **grumpy-*** for dinosaurs not in `MatchingGameConfigs.allDinosaurs` – not needed unless you add more dinosaurs to the pool.
