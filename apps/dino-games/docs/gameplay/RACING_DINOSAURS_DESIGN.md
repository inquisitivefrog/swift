# Racing Dinosaurs! – Design & Metrics (for later reference)

## Game concept

**Racing Dinosaurs!** – A game where dinosaurs race. Players see or hear which dinosaur wins (or rank 1–2–3), with optional “who’s faster?” comparisons.

Exact mechanics TBD (e.g. simple A vs B race, multi-dino race, or round-based). This doc saves the high-level idea and **racing metrics** so they can be used when we implement the game.

---

## Racing metrics (save for later)

Use these when defining data and logic for Racing Dinosaurs!

### Estimated top sprint speeds (by period)

Dinosaurs from the full list, split by period. Within each table, ordered **fastest to slowest** based on consensus estimated top sprint speeds (short bursts on land): biomechanical models, limb ratios, trackways, and studies like Sellers 2007 / updated simulations. Ranges are approximate—paleontologists emphasize exact figures vary, but relative rankings hold up well. Ornithomimids top most lists (ostrich-like builds); tiny theropods excel in some models for their size; massive sauropods and armored forms lag.

#### Jurassic Period (mostly Late Jurassic, ~163–145 Ma)

| Dinosaur Name   | Estimated Top Speed              | Notes |
|-----------------|----------------------------------|-------|
| Compsognathus   | 25–40 mph (40–64 km/h)           | Tiny theropod; often modeled as one of the absolute fastest due to lightweight build. |
| Allosaurus      | 20–30 mph (32–48 km/h)           | Agile predator; good burst speed for its size. |
| Stegosaurus     | 10–15 mph (16–24 km/h)           | Plated herbivore; short bursts possible but not sustained. |
| Diplodocus      | 12–15 mph (19–24 km/h)           | Long-necked sauropod; efficient walker, not a sprinter. |
| Brontosaurus    | 12–15 mph (19–24 km/h)           | Similar to other sauropods; massive size limits speed. |
| Apatosaurus     | 12–15 mph (19–24 km/h)           | Sauropod; slow, endurance-focused movement. |

#### Cretaceous Period (Early and Late, ~145–66 Ma)

| Dinosaur Name   | Estimated Top Speed              | Notes |
|-----------------|----------------------------------|-------|
| Ornithomimus    | 30–43 mph (48–70 km/h)           | Ostrich-like ornithomimid; among the fastest overall, built for sustained running. |
| Gallimimus      | 25–35 mph (40–56 km/h), up to ~43 in some | Large ornithomimid; fleet-footed escape artist. |
| Avimimus        | 25–35 mph (40–56 km/h)           | Bird-like theropod; agile and quick. |
| Oviraptor       | 25–35 mph (40–56 km/h)           | Lightweight, long-legged; ostrich-proportioned for speed. |
| Albertosaurus   | 20–30 mph (32–48 km/h)           | Tyrannosaurid; faster than T. rex due to lighter build. |
| Giganotosaurus  | 20–30 mph (32–48 km/h)           | Large theropod; burst speed for ambush/pursuit. |
| Velociraptor    | 20–25 mph (32–40 km/h)           | Agile dromaeosaur; quick in short dashes. |
| Deinonychus     | 20–25 mph (32–40 km/h)           | Similar to Velociraptor; pack hunter speed. |
| Dromaeosaurus   | 20–25 mph (32–40 km/h)           | Mid-sized raptor; agile but not top-tier. |
| Utahraptor      | 20–25 mph (32–40 km/h)           | Heavier dromaeosaur; power over pure speed. |
| Microraptor     | 15–25 mph (24–40 km/h)           | Tiny glider; fast on ground but aerial-focused. |
| Tyrannosaurus Rex | 10–25 mph (16–40 km/h), most ~12–20 | Massive; recent models favor ~12–18 mph walking/sprinting to avoid injury. |
| Triceratops     | 20–35 mph (32–56 km/h) (bursts; debated) | Ceratopsian; could charge surprisingly fast for defense. |
| Chasmosaurus    | 15–25 mph (24–40 km/h)           | Similar to other ceratopsians; burst charges. |
| Torosaurus      | 15–25 mph (24–40 km/h)           | Large ceratopsian; similar speed range. |
| Edmontosaurus   | 15–25 mph (24–40 km/h)           | Hadrosaur; decent for a big herbivore. |
| Baryonyx        | 15–25 mph (24–40 km/h)           | Spinosaurid relative; semi-aquatic but capable on land. |
| Spinosaurus     | 10–20 mph (16–32 km/h)           | Mostly aquatic; slow and awkward on land. |
| Therizinosaurus | 10–20 mph (16–32 km/h)           | Large, bulky therizinosaur; slow due to size/claws. |
| Argentinosaurus | 5–10 mph (8–16 km/h)            | Massive titanosaur sauropod; very slow mover. |
| Ankylosaurus    | 3–6 mph (5–10 km/h)              | Armored tank; relied on defense, not flight. |

#### Quick race takeaways

- **Jurassic winner:** Compsognathus (tiny size advantage for raw speed).
- **Cretaceous winner:** Ornithomimus (or Gallimimus close behind)—“ostrich dinosaurs” dominate modern estimates for land speed.
- **No overlap between periods** in this list, so no direct cross-era race; Cretaceous had more speed specialists (ornithomimids, raptors).

For implementation: use midpoint or max of each range (e.g. mph) to rank or assign a numeric “speed” per dinosaur; keep period split if we do Jurassic-only vs Cretaceous-only races.

---

## Implementation plan: two-lane race (Weigh-style layout)

Borrow layout from **Weigh the Dinosaur!** so we reduce the available dinosaurs to **eight**. Player chooses **two** dinosaurs from those eight; they race from **left to right** in two lanes (e.g. Stegosaurus above Allosaurus). Refresh positions every **2 seconds** until one reaches the finish line on the right.

### 1. Pool of 8 dinosaurs

- Define a **racing pool of 8 dinosaurs** (subset of the speed tables; use species we have assets for, e.g. from `MatchingGameConfigs.allDinosaurs` or a dedicated racing list).
- Each dinosaur has a **speed value** (e.g. midpoint of mph range from the tables above) for deterministic “who wins.”

### 2. Selection phase (like Weigh)

- **Layout:** Same idea as Weigh: a grid of items. Use a **2×4 or 4×2 grid** of 8 dinosaurs (instead of Weigh’s 3×3 with 9).
- **Flow:** Player taps **first dinosaur** (e.g. “lane 1” / top lane) → play name audio → then player taps **second dinosaur** (e.g. “lane 2” / bottom lane). Same two-step selection pattern as Weigh (first tap, wait for audio, second tap).
- **UI:** Reuse the Weigh-style `ItemCard` / grid: show 8 dinosaur cards; highlight selected; disable taps until first name finishes if we want to avoid double-tap.

### 3. Race view: two-lane track

- **Two horizontal lanes**, one above the other:
  - **Top lane:** First chosen dinosaur (e.g. Stegosaurus).
  - **Bottom lane:** Second chosen dinosaur (e.g. Allosaurus).
- **Track drawing:**
  - **Start:** Left edge of the track (or a vertical “start line”).
  - **Finish:** Vertical **finish line** at the **right** side of the lane (same x for both lanes).
  - **Lanes:** Two horizontal strips (e.g. two `Rectangle`s or one track with a horizontal divider). Each lane is a row from left to right; lane height ~equal (e.g. 50% of track height each). Optional: lane dividers, track color, or a simple “road” look.
- **One dinosaur per lane:** Each dinosaur is drawn in a **track and field jersey** (racer-* imageset) **inside** its lane, positioned by progress (see below). So we get: e.g. Stegosaurus in top lane, Allosaurus in bottom lane, both moving left → right.

### 4. Refresh every 2 seconds and move until finish

- **Progress:** Each dinosaur has a **progress** value from **0.0** (start, left) to **1.0** (finish, right).
- **Tick:** Every **2 seconds**, run a **tick**:
  1. **Update progress** using speed (faster dinosaur gains more per tick). For example:
     - `stepPerTick = 0.2` (tune so race lasts ~5–10 ticks).
     - `progressA += stepPerTick * (speedA / max(speedA, speedB))` (and same for B). So the faster dinosaur advances more each tick; when the faster one reaches 1.0, the slower one is still short of 1.0.
     - Or: `progress += stepPerTick * (speed / speedOfFasterDino)` so the faster dino reaches 1.0 in a fixed number of ticks (e.g. 5 ticks = 10 s).
  2. **Clamp** progress to 1.0.
  3. **Redraw:** Position each racer image (racer-* imageset) at **horizontal offset** = `progress * (laneWidth - imageWidth)` from the left (so at progress 1.0 the dinosaur is at the finish line).
  4. **Check finish:** If **either** progress ≥ 1.0, **stop the timer** and show the **winner** (the one that reached 1.0 first; if both in same tick, the one with higher progress or higher speed wins). Winner screen shows **winner-race-{slug}** image (winner pose with trophy) and “Winner: [name]” (and optional audio “and the winner is…”).
- **Implementation:** In SwiftUI, use a **Timer** (e.g. `Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true)`) or **DispatchQueue.main.asyncAfter(deadline: .now() + 2.0)** in a loop. Each firing: update `@State progressA` and `progressB`, then the view redraws and moves the racer images. When race over, invalidate the timer and present the winner screen with winner-race-* image and name.

### 5. How to draw it in SwiftUI (concept)

- **Track:** `VStack` of two lane views. Each lane = `ZStack(alignment: .leading)`:
  - Background: `Rectangle()` (track color).
  - Finish line: `Rectangle().frame(width: 2)` aligned to the **trailing** edge of the lane.
  - Racer: `Image(racerImageName)` (racer-* imageset, track & field jersey) at `.offset(x: progress * (geometry.size.width - imageWidth))` (or use a `GeometryReader` to get lane width). Center the image vertically in the lane.
- **Two lanes:** Top lane for first dinosaur, bottom lane for second; same layout in both, different `progress` and racer image.
- **Winner screen:** Show `Image(winnerRaceImageName)` (winner-race-* imageset, pose with trophy) and winner name.
- **Refresh:** When `progressA` or `progressB` changes (every 2 s), SwiftUI redraws and the images move. No need for smooth animation unless we add it later; discrete 2-second steps are enough.

### 6. Summary

| Step | What |
|------|------|
| Pool | 8 dinosaurs with speed values (from speed tables). |
| Selection | Weigh-style grid (2×4 or 4×2); tap first dino → top lane, tap second → bottom lane. |
| Track | Two horizontal lanes; start left, finish line right; one dino per lane (e.g. Stegosaurus above Allosaurus). |
| Movement | Every 2 s: progress += f(speed); position = progress × (laneWidth - imageWidth); if any progress ≥ 1.0, declare winner and stop. |
| Drawing | Two lanes (e.g. VStack of two ZStacks); each lane has background, finish line, and **racer-*** image at offset. Winner screen: **winner-race-*** image (pose with trophy) and name. |

This gives a deterministic race (faster dinosaur wins), simple layout (two lanes, left→right), and discrete 2-second “refresh” so the dinosaurs visibly move along each lane until one crosses the finish line.

---

### Per-dinosaur race stats (candidates)

| Metric        | Description                    | Example / unit   | Notes                    |
|---------------|--------------------------------|------------------|--------------------------|
| **Speed**     | How fast the dinosaur runs     | e.g. 1–10 or m/s | Primary for “who wins?”  |
| **Stamina**   | How long it can sustain speed  | e.g. 1–10        | Optional for long races  |
| **Acceleration** | How quickly it reaches top speed | e.g. 1–10     | Optional for short races |
| **Size/mass** | Affects traction or inertia    | e.g. kg or S/M/L | Optional for physics      |

*Add or remove metrics as the design is finalized.*

### Race format ideas

- **Head-to-head:** Two dinosaurs; one winner (faster wins).
- **Three-way race:** Three dinosaurs; rank 1st, 2nd, 3rd.
- **Round-based:** Multiple races; aggregate “wins” or points.
- **Distance:** Fixed distance (e.g. 100 m) or fixed time (who went farthest).

### How winners are determined (to be decided)

- **Deterministic:** Compare speed (and optionally other stats) to compute winner.
- **Randomized:** Speed (or a “race result” score) influences probability; outcome still random for variety.
- **Hybrid:** Base result on stats, add small randomness so same matchup isn’t always identical.

### Data source for metrics

- **Static list:** Each dinosaur in the game has a fixed speed (and optional other stats) in config/code.
- **Pool:** Reuse existing dinosaur pool (e.g. `MatchingGameConfigs.allDinosaurs`) and add a `speed` (and optional) fields, or a separate `RacingDinosaur` type that references dinosaur + metrics.
- **Filtering:** Like Toothache, only dinosaurs that have **racing assets** (racer-* and winner-race-* imagesets) might be in the pool. See [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) (trace-fossil / asset-filter pattern).

---

## Assets (for later)

- **Game card / transition:** e.g. `game-racing-dinosaurs` (imageset).
- **Audio:** e.g. transition intro `Games/racing-dinosaurs.m4a`, in-game “who’s faster?”, “and the winner is…”, etc.
- **Racer (in-race):** Each racing dinosaur appears in a **track and field jersey**. Use imageset prefix **racer-** (e.g. `racer-stegosaurus`, `racer-allosaurus`). One per dinosaur in the racing pool; shown in the two lanes during the race.
- **Winner (race result):** When a dinosaur wins, show a **winner pose with the trophy**. Use imageset prefix **winner-race-** (e.g. `winner-race-stegosaurus`, `winner-race-allosaurus`). One per dinosaur in the racing pool; shown on the race result screen.
- **Future winner assets:** A second game (type TBD) will also require a winner image. That game may use a different prefix (e.g. `winner-[game]-{slug}`) so we can have game-specific winner poses. For Racing Dinosaurs we use **winner-race-** only.
- **UI:** Race result screen: winner name, winner-race-* image (pose with trophy), optional audio “and the winner is…”.

---

## Where it fits in the app

- **Category:** Likely **Land (Dinosaurs)** initially; could add Air (Pterosaurs) or Sea later with separate pools/metrics.
- **Game list:** New `GameType.racing(RacingGameConfig)`; show card after e.g. Toothache, before Wacky (or as desired).
- **Design doc:** [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) – e.g. filter racing pool by dinosaurs that have racing assets if we use asset-driven pools.

---

## Summary

| Item            | Status / content |
|-----------------|------------------|
| Game name       | Racing Dinosaurs! |
| Core idea       | Dinosaurs race; player sees/hears who wins (and optionally order). |
| Racing metrics  | **Estimated top sprint speeds** (mph/km/h) by period: Jurassic (6 dinos, Compsognathus fastest) and Cretaceous (21 dinos, Ornithomimus/Gallimimus fastest). See tables above. Optional: Stamina, Acceleration, Size/mass. |
| Race format     | **Two-lane head-to-head:** 8 dinosaurs in pool; player picks 2; they race left→right in two lanes (top/bottom). See “Implementation plan: two-lane race” above. |
| Winner logic    | Deterministic: progress per 2 s tick = f(speed); first to progress ≥ 1.0 wins. |
| Data            | Per-dinosaur speed (and optional stats); pool possibly filtered by racing assets. Use midpoint or max of range for numeric ranking. |
| Assets          | game-racing-dinosaurs; audio; **racer-*** (track & field jersey, in-race); **winner-race-*** (winner pose with trophy). Second game later will also need winner images (prefix TBD). |

*Update this doc as you lock in mechanics and metrics.*
