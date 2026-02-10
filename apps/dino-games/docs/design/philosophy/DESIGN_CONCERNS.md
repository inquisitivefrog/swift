# Design Concerns (Recorded for Later Review)

*Concerns raised during design and species-selection work, so they are not lost and can be revisited when making decisions.*

---

## 1. Image generator limitations

- **Cuteness and friendliness** constraints make members of the same family look nearly identical (e.g. T-Rex, Albertosaurus, Allosaurus, Ceratosaurus end up looking very similar).
- **Gemini Nano Banana** (or similar) image generation has difficulty emphasizing subtle morphological features unless explicitly prompted to **exaggerate** them.
- **Risk:** If we don’t stress one clear, exaggeratable feature per species in prompts, kids won’t be able to tell species apart and the matching game loses its point.

*Mitigation:* Use the one-hook-per-species lists (e.g. `SPECIES_LISTS_12_PER_GROUP.md`) in image prompts and ask the generator to exaggerate that feature.

---

## 2. Fun and repeat play depend on dataset size

- The **main driver of repeat gameplay is the random factor**.
- If the pool is **sufficiently large**, it takes a long time to memorize all combinations, so the player feels challenged.
- Raptors vs ceratopsians vs ornithischians vs sauropods vs armored dinosaurs are clearly different *groups*, but that doesn’t help much if the **image tool makes all members of the same family look nearly identical** (see above).
- So **fun is dependent on both (a) dataset size and (b) visual distinctiveness** of the species we use.

---

## 3. Scope creep and depth

- While researching **dinosaur experts** (for a separate game that honors them), it became clear that **paleobotany, comparative anatomy, bone histology, biomechanics, and microbiology** also play a part.
- That led to **considerations for who studies ancient marine reptiles and pterosaurs** — and whether to honor or reference those experts too.
- **Concern:** This feels like potential **scope creep**.
- **Concern:** “I’m out of my depth on both topics” (dinosaurs vs marine reptiles/pterosaurs and the breadth of disciplines involved).

*Note:* The 12-species-per-group reference gives a stable list to work from; expert-honor games and other disciplines can be scoped separately so the core match games don’t depend on resolving all of that at once.

---

## 4. Uncertainty about sufficient species (addressed)

- **Concern:** “At the moment I’m not assured that sufficient species exist” (for pterosaurs, mosasaurs, ichthyosaurs, plesiosaurs) with **unique morphology** so that:
  - We have enough for a large random pool (e.g. 12 per group), and
  - They don’t all look the same (e.g. “like salmon” for ichthyosaurs).
- **Resolution:** A reference list of **12 species per group** with **one clear morphological hook each** was created (`SPECIES_LISTS_12_PER_GROUP.md`) so we have a concrete basis for art prompts and match-game design.

---

## 5. Background and product discipline

- **Used to Engineering, Service, or Operations** — not Product — so not used to thinking in **application needs** first.
- **Avid gamer** — tends to think in **modern game terms** (competition, scores, conflict).
- **Has helped make, test, or support games** — easy to **forget original goals** (ages 4–6, tap/listen only, no losing, no scores) and **behave like still working at a game studio** (e.g. adding competition, scorekeeping, bragging rights).
- **Explicit non-goals** (recorded elsewhere): older youth wanting more paleontology detail or conflict-based competition; scorekeeping and centralized bragging rights.

*Use:* Revisit this doc and the goals/non-goals when tempted to add competition, scores, or complexity.

---

*Document created to record concerns; update as new ones arise or as concerns are resolved.*
