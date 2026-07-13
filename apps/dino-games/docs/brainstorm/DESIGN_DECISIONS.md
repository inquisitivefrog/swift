# Design decisions

Notes that affect how games and assets are built. Use these when adding new trace-fossil games or when deciding which dinosaurs appear in a game.

---

## 1. Trace-fossil games: filter pool by available assets

**Decision:** For games based on trace fossils (teeth, tracks, eggs, coprolites, etc.), the dinosaur pool must be **filtered at runtime** to include only dinosaurs that have the specific trace-fossil assets for that game.

**Reason:** Paleontology discovery is uneven. We don’t have “teeth” or “tracks” for every species in the app; we only have assets for a subset. A game that shows “match this tooth to the dinosaur” should only use dinosaurs for which we actually have tooth (and, where relevant, grumpy or other) images.

**Implementation:**

- Do **not** use the full `MatchingGameConfigs.allDinosaurs` list for trace-fossil games.
- For each game type, define a filtered pool: only dinosaurs that have every asset type that game needs (e.g. `tooth-*` and `grumpy-*` for Toothache).
- Build rounds (correct answer + decoys) from that filtered pool only.
- Require a minimum pool size (e.g. ≥ 3) or the game should not run / should show a clear error.

**Example:** Toothache uses only dinosaurs that have both `tooth-{slug}` and `grumpy-{slug}` imagesets; see `ToothacheGameConfigs.dinosaursWithToothAndGrumpyImages`.

**Future games:** Tracks, eggs, coprolites, etc. should follow the same pattern: a dedicated “dinosaurs with this trace fossil” list (or filter) and rounds built only from that list.

---

## 2. Art style and species limits (AI-generated assets)

**Decision:** Art is generated with an AI tool (e.g. “Google Gemini Nano Banana”) and is **cartoony and exaggerated for young children**. The style has limits on detail and on scary or highly realistic imagery. That **intentionally limits** which dinosaur species can be shown in a given game.

**Reasons:**

- The tool produces a consistent, child-friendly look but struggles with fine anatomical or paleontological detail.
- Similar species (e.g. two raptors) may be hard to tell apart in this style—e.g. teeth or silhouettes may not be unique enough for more than one species.
- So we only use species for which the AI can produce **distinct, recognizable** assets for that game (e.g. one raptor with unique teeth, not several that look the same).

**Implications:**

- The pool of dinosaurs with usable assets for a given game may be **smaller** than the full species list.
- It’s acceptable (and expected) that some games have fewer species; we prefer a small, clearly differentiated set over many similar-looking options.
- When adding new trace-fossil games or new species, expect that not every species will get a unique asset for every fossil type.

---

## Summary

| Topic | Decision |
|-------|----------|
| Trace-fossil games (teeth, tracks, eggs, coprolites) | Filter dinosaur pool to only species that have the trace-fossil assets for that game. |
| Art / species range | AI-generated, cartoony art limits how many species can be uniquely shown; use only species with distinct, recognizable assets per game. |
