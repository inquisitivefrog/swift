# Audio Files Reference (DinoGames)

All paths are relative to **`Assets/Audio/`** (or `DinoGames/Assets/Audio/` in the bundle). Use **`.m4a`** (or `.mp3`). If a file is missing, the app falls back to **TTS** for that phrase.

---

## Feedback (shared phrases)

| Path | When used |
|------|-----------|
| `Feedback/great-match.m4a` | Matching game: correct match |
| `Feedback/try-again.m4a` | Guess / Toothache / Find Mama / Dino Lunch / Matrix: wrong answer |
| `Feedback/thats-right-you-guessed-it.m4a` | Name That Dinosaur, Name That Pterosaur, Dino Footprints, Dino Lunch, Find Mama, Toothache: correct guess |
| `Feedback/not-that-one.m4a` | Matching: wrong creature selected |
| `Feedback/good-job-you-got-them-all.m4a` | Victory (multiple games) |
| `Feedback/crowd-cheering.m4a` | Victory (multiple games) |
| `Feedback/you-did-it.m4a` | Balance game: balanced / ran out |
| `Feedback/pick-a-dinosaur-first.m4a` | Matching (Land): tap before selecting dinosaur |
| `Feedback/pick-a-pterosaur-first.m4a` | Matching (Air): tap before selecting pterosaur |
| `Feedback/pick-another-one.m4a` | Matching: already-matched creature tapped |
| `Feedback/is-heavier.m4a` | Weigh game: “X is heavier” |
| `Feedback/they-both-weigh-about-the-same.m4a` | Weigh game: same weight |
| `Feedback/game-balance-pick-someone-heavier.m4a` | Balance: chose too light |
| `Feedback/game-balance-good-job-keep-going.m4a` | Balance: good progress |
| `Feedback/game-balance-this-game-will-end-quick.m4a` | Balance: only one left to add |
| `Feedback/game-balance-see-I-told-you.m4a` | Balance: balanced with 1–2 items |
| `Feedback/game-balance-almost-there.m4a` | Balance: nearly balanced |
| `Feedback/starting-whistle.m4a` | Racing: start (if used) |
| `Feedback/game-intro-pterosaur.m4a` | Match the Pterosaur intro (if used) |

---

## Games (game cards + transition / intro)

**Pattern:** `Games/game-{id}.m4a` is used for the **transition** when the player taps a game (and for the game-name “walk”). Config `id` values and any **extra** intro keys are listed below.

| Path | Game |
|------|------|
| `Games/game-match-the-dinosaur.m4a` | Match the Dinosaur |
| `Games/game-match-the-pterosaur.m4a` | Match the Pterosaur |
| `Games/game-weigh-dinosaur.m4a` | Weigh the Dinosaur |
| `Games/game-weigh-pterosaur.m4a` | Weigh the Pterosaur |
| `Games/game-balance-the-dinosaurs.m4a` | Balance the Dinosaurs |
| `Games/game-balance-the-pterosaurs.m4a` | Balance the Pterosaurs |
| `Games/game-name-that-dinosaur.m4a` | Name That Dinosaur |
| `Games/game-name-that-pterosaur.m4a` | Name That Pterosaur |
| `Games/game-dino-footprints.m4a` | Dino Footprints |
| `Games/game-racing-dinosaurs.m4a` | Racing Dinosaurs |
| `Games/game-matrix-materials.m4a` | Matrix Materials |
| `Games/game-find-mama.m4a` | Find Mama |
| `Games/game-dino-lunch.m4a` | Dino Lunch |
| `Games/game-toothache.m4a` | Toothache |
| `Games/game-wacky-dinosaurs.m4a` | Wacky Dinosaurs |
| (and any other `game-{slug}` for games you add) | |

**Other game-specific (optional):**

| Path | When used |
|------|-----------|
| `Games/can-you-name-the-dinosaur.m4a` | Name That Dinosaur intro (in-game) |
| `Games/name-that-dinosaur.m4a` | Name That Dinosaur transition variant |
| `Games/can-you-name-the-pterosaur.m4a` | Name That Pterosaur intro |
| `Games/game-can-you-balance-the-dinosaurs.m4a` | Balance the Dinosaurs intro |
| `Games/game-can-you-balance-the-pterosaurs.m4a` | Balance the Pterosaurs intro |
| `Games/game-balance-choose-a-heavy-dinosaur.m4a` | Balance (Land): “Choose a heavy dinosaur” |
| `Games/game-balance-choose-a-heavy-pterosaur.m4a` | Balance (Air): “Choose a heavy pterosaur” |
| `Games/game-intro-weigh.m4a` | Weigh the Dinosaur intro |
| `Games/game-intro-weigh-pterosaur.m4a` | Weigh the Pterosaur intro |
| `Games/game-can-you-match-each-dinosaur.m4a` | Match the Dinosaur intro |
| `Games/game-can-you-match-each-pterosaur.m4a` | Match the Pterosaur intro |
| `Games/game-racer-choose-your-first-dinosaur-to-race.m4a` | Racing: first dino |
| `Games/game-racer-choose-your-second-dinosaur-to-race.m4a` | Racing: second dino |
| `Games/racing-the-winner-is.m4a` | Racing: winner announcement |
| `Games/game-matrix-which-one.m4a` | Matrix Materials in-game |
| `Games/game-find-mama-return-the-egg.m4a` | Find Mama |
| `Games/game-find-mama-help-the-paleontologist.m4a` | Find Mama |
| `Games/game-give-this-nutritious-lunch.m4a` | Dino Lunch |
| `Games/game-can-you-return-the-tooth.m4a` | Toothache |

---

## Cover & category flow

| Path | When used |
|------|-----------|
| `Games/welcome-to-dino-games.m4a` | Welcome (after category chosen) |
| `Cover/cover-welcome-to-dino-games.m4a` | Cover sequence |
| `Cover/cover-dinosaurs-on-land.m4a` | Cover: land |
| `Cover/cover-pterosaurs-in-the-sky.m4a` | Cover: air |
| `Cover/cover-and-marine-reptiles-in-the-sea.m4a` | Cover: sea |
| `Cover/cover-choose-a-dinosaur-game.m4a` | Land chosen |
| `Cover/cover-choose-a-pterosaur-game.m4a` | Air chosen |
| `Cover/cover-choose-a-marine-reptile-game.m4a` | Sea chosen |
| `Cover/cover-dinosaurs.m4a` | Category card: Dinosaurs |
| `Cover/cover-pterosaurs.m4a` | Category card: Pterosaurs |
| `Cover/cover-marine-reptiles.m4a` | Category card: Marine Reptiles |

---

## Levels (Dinosaurs – level picker)

| Path | When used |
|------|-----------|
| `Levels/choose-a-level.m4a` | When level picker appears |
| `Levels/level-1-really-easy-games.m4a` | Level 1 |
| `Levels/level-2-easy-games.m4a` | Level 2 |
| `Levels/level-3-getting-harder.m4a` | Level 3 |
| `Levels/level-4-hard-games.m4a` | Level 4 |
| `Levels/level-5-really-hard-games.m4a` | Level 5 |
| `Levels/level-6-really-hard-games.m4a` | Level 6 |

---

## Creature names (by image key)

**Dinosaurs:** `Dinosaurs/dino-{slug}.m4a`  
Example: `Dinosaurs/dino-trex.m4a`, `Dinosaurs/dino-velociraptor.m4a`.  
Any `dino-*` key used in the app (Match, Name That Dinosaur, Weigh, Balance, Dino Footprints, etc.) resolves to `Dinosaurs/{key}.m4a` (e.g. `Dinosaurs/dino-majungasaurus.m4a`). Add one file per dinosaur you want spoken by name.

**Pterosaurs:** `Pterosaurs/ptero-{slug}.m4a`  
Example: `Pterosaurs/ptero-pteranodon.m4a`.  
Same idea: any `ptero-*` key → `Pterosaurs/{key}.m4a`. Add one per pterosaur.

---

## Characteristics (Match the Dinosaur / Match the Pterosaur)

**Land:** `Dino-Characteristics/{trait}.m4a`  
Examples: `Dino-Characteristics/teeth.m4a`, `Dino-Characteristics/footprints.m4a`, `Dino-Characteristics/claws.m4a`, `Dino-Characteristics/long-neck.m4a`, etc.

**Air:** `Ptero-Characteristics/{trait}.m4a`  
Examples: `Ptero-Characteristics/wings.m4a`, `Ptero-Characteristics/crest.m4a`, `Ptero-Characteristics/small.m4a`, etc.

(Exact keys come from the characteristic `type` in the game config; see `MatchingGameView` / `audioFilePath` for the full list.)

---

## Other game-specific folders

| Folder | Pattern | When used |
|--------|--------|-----------|
| **Teens** | `Teens/teen-{diet}-{slug}.m4a` | Dino Lunch: teen intro (e.g. `Teens/teen-herbivore-triceratops.m4a`) |
| **Trays** | `Trays/contents-{slug}.m4a` | Dino Lunch: tray contents |
| **Clues** | `Clues/clue-{dinosaur}-{hint}.m4a` | Find Mama: egg clues |
| **Formations** | `Formations/{slug}-formation.m4a` | Dino Formations: formation name (key `formation-name-{slug}`) |
| **Materials** | `Materials/{slug}.m4a` | Matrix Materials: limestone, sandstone, etc. |

---

## Minimum set (if you add nothing else)

- **Feedback:** `Feedback/great-match.m4a`, `Feedback/try-again.m4a`, `Feedback/thats-right-you-guessed-it.m4a`, `Feedback/good-job-you-got-them-all.m4a`, `Feedback/crowd-cheering.m4a`, `Feedback/you-did-it.m4a`, `Feedback/not-that-one.m4a`, `Feedback/pick-a-dinosaur-first.m4a`, `Feedback/pick-a-pterosaur-first.m4a`, `Feedback/pick-another-one.m4a`, `Feedback/is-heavier.m4a`, `Feedback/they-both-weigh-about-the-same.m4a`, and the `Feedback/game-balance-*` phrases if you use Balance.
- **Games:** one `Games/game-{id}.m4a` per game you use (so transition + walk have audio).
- **Levels:** `Levels/choose-a-level.m4a` and `Levels/level-1-really-easy-games.m4a` … `Levels/level-6-really-hard-games.m4a` if you use the level picker.
- **Cover:** at least `Cover/cover-choose-a-dinosaur-game.m4a` (and other cover steps you use).
- **Creature names:** as many `Dinosaurs/dino-*.m4a` and `Pterosaurs/ptero-*.m4a` as you want; the rest fall back to TTS.

Everything else is optional; the app will use TTS when a file is missing.
