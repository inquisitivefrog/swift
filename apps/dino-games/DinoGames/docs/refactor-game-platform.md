# Game platform refactor — goals & progress

Single place to remember **what we want**, **what’s next**, and **what’s done** across Land (Dinosaurs), Air (Pterosaurs), and Marine Reptiles. Update this file when you **start** a PR (move to *In flight*) and when you **merge** (mark *Done*, add link, set the next *Next up*).

---

## North-star goals

1. **Shared game frameworks** — Dinosaur, Pterosaur, and Marine games reuse the same *mechanic* implementations (guess, match, weigh, footprint-style, etc.), not three parallel silos.
2. **Shared data ingestion** — Creature pools, rounds, and related metadata load from **versioned bundled definitions** (e.g. JSON) where appropriate, with one decoding/validation path.
3. **Shared victory ingestion** — Victory layout/audio/image contracts can be driven from **manifests** (bundled files) while reusing existing UI building blocks (e.g. split column + success stinger pattern).
4. **Shared testing** — One contract for **required imagesets** and **audio stems** per registered game; cross-category enumeration in CI without duplicating helpers in every XCTest file.

**Constraints we keep:** child-friendly **visual imagesets** and **audio** remain first-class; refactors must not regress asset discipline.

---

## Conventions

| Status        | Meaning                                      |
|---------------|----------------------------------------------|
| **Not started** | Queued; no branch / no meaningful WIP yet   |
| **In flight**   | Active branch or PR open                     |
| **Done**        | Merged to mainline; PR link in changelog     |
| **Blocked**     | Waiting on dependency or decision (note why) |

**After each merge:** set the completed row to **Done**, paste the PR URL, bump **Next up** to the next **Not started** item (or mark **Blocked**).

---

## PR roadmap (ordered)

Roughly **6–10** reviewable PRs total (see *Notes*). Order can shift if discovery forces it—update the table and add a sentence under *Decisions / discovery*.

| # | Title (working) | Status | Owner / notes |
|---|-----------------|--------|----------------|
| 1 | Shared XCTest bundle helpers (`projectRootURL`, `recursiveFiles`, audio stem scans) | Done | `DinoGamesTests/TestBundleHelpers.swift`; seven test files migrated off duplicated FS helpers |
| 2 | `GameCatalog` (or equivalent) — flatten all `(category, level, game)` for tests | Done | `GameCatalogPlacedGame`, `GameCatalog.allPlacedGames()`; `GameCatalogFlattenXCTests` |
| 3 | Unified media-contract test (skeleton) — one test, expand coverage per slice | Done | `UnifiedGameMediaContractXCTests`: card imageset per `GameCatalog.allPlacedGames()` slice (land / air / marine); extend for audio + success art |
| 4 | `BundledJSONRepository` / shared `JSONDecoder` bundle load helper | Not started | Adopt in one existing consumer (e.g. formations or habitats) first |
| 5 | `VictorySequenceManifest` types + bundle load (no game wired) | Not started | Codable manifest alongside `StandardVictorySequenceViews.swift` usage |
| 6 | Pilot: one game victory driven from manifest | Not started | Prove end-to-end before mass migration |
| 7 | Expand manifests / migrate more `VictorySplitColumnView` callers (batched) | Not started | Split into multiple PRs if diff explodes |
| 8 | Pilot: one game’s rounds/creatures from JSON (or migrate second JSON consumer) | Not started | Validates schema + loader under real gameplay |
| 9 | Extract one shared *engine* (e.g. silhouette guess) shared by land + air | Not started | Protocol + taxonomy-agnostic inputs |
| 10 | Optional capstone: registry / unified `GameType` factory behind catalogs | Not started | Largest; defer until manifests stable |

**Next up:** PR **4** (`BundledJSONRepository` / shared bundle JSON load).

---

## Changelog (merged work)

| Date | PR | Summary |
|------|-----|---------|
| 2026-05-12 | — | PR 3: `UnifiedGameMediaContractXCTests` — every land/air/marine catalog slot’s `GameType.imageName` exists in `ImageAssetNames`. |
| 2026-05-12 | — | PR 2: `GameCatalogPlacedGame` + `GameCatalog.allPlacedGames()`; `GameCatalogFlattenXCTests` (order vs per-category flatMap, unique `placementKey`, non-nil config ids). |
| 2026-05-09 | — | PR 1: Added `TestBundleHelpers` (`projectRootURL`, `urlUnderProjectRoot`, `directoryExists`, `recursiveFiles`, `audioStems` / `audioExtensions`); migrated Dino/Ptero/Marine audio + source + Dino Footprints asset tests. |

---

## Decisions / discovery log

Append **newest first** when something unexpectedly widens scope or changes direction.

| Date | Note |
|------|------|
| 2026-05-12 | PR 3 landed in tree; add GitHub PR link when opened/merged. |
| 2026-05-12 | PR 2 landed in tree; add GitHub PR link when opened/merged. |
| 2026-05-09 | PR 1 merged locally; add GitHub PR link in changelog when opened/merged. |

---

## Key code references (update if files move)

- Shared victory UI: `DinoGames/Views/StandardVictorySequenceViews.swift` (`VictorySplitColumnView`, `LandGameVictorySuccessStingerThenContinue`, …)
- `GameCatalog` flatten: `GameCatalog.swift` (`GameCatalogPlacedGame`, `allPlacedGames()`)
- Unified media-contract (PR 3 slice): `DinoGamesTests/UnifiedGameMediaContractXCTests.swift`
- Land / air / marine lists: `DinosaurGameCatalog.swift`, `PterosaurGameCatalog.swift`, `MarineReptileGameCatalog.swift`
- Example JSON-driven flows: `DinoGames/Views/DinoFormationsGameView.swift`, `DinoGames/Views/DinoHabitatsGameView.swift`
- Asset name set: `DinoGames/ImageAssetNames.generated.swift` (regenerate via `Scripts/regenerate-asset-names.sh` when catalog changes)

---

## Notes

- **PR count:** ~8 is a balanced default; fewer (4–5) if you combine slices; more if you split very fine. Scope creep belongs in *Decisions / discovery*, not silent growth of one PR.
- **Cursor / chat:** use this file as the source of truth; chat is for execution detail only.
