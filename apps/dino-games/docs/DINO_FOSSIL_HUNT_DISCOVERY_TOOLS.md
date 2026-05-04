# Dino Fossil Hunt — Discovery phase: `dino-tools-field-*` imagesets

Permanent reference for **which paleontologist (field) tool imagesets** belong to the **discovery** round. Discovery here means: where to look, looking around, sampling, taking notes, and marking where you are and where you plan to excavate — not basecamp gear, transport, or paperwork recorded by others.

**Audience:** young players (roughly 4–6); voice-led, picture-first.

**Game use:** Each session picks **two** correct tools at random from the eligible pool for that story’s discovery round; other slots use non–field tools as distractors (see main game doc).

---

## Canonical imageset names (Xcode asset name = folder name without `.imageset`)

All names use the prefix **`dino-tools-field-`** plus a kebab-case slug. Reference in Swift as `Image("dino-tools-field-{slug}")` / `ImageAssetCache.imageExists(named:)`.

| # | Slug | Full imageset name | In catalog (Dinosaur-Tools/paleontologist) |
|---|------|----------------------|---------------------------------------------|
| 1 | `locality-map` | `dino-tools-field-locality-map` | Yes |
| 2 | `tape-measure` | `dino-tools-field-tape-measure` | Yes |
| 3 | `surveyor-level` | `dino-tools-field-surveyor-level` | Yes |
| 4 | `clinometer` | `dino-tools-field-clinometer` | Yes |
| 5 | `gps` | `dino-tools-field-gps` | **Add** (not present yet) |
| 6 | `grid-kit` | `dino-tools-field-grid-kit` | **Add** (not present yet) |
| 7 | `flagging-tape` | `dino-tools-field-flagging-tape` | **Add** (not present yet) |
| 8 | `notes` | `dino-tools-field-notes` | **Add** (not present yet) |
| 9 | `rock-color-chart` | `dino-tools-field-rock-color-chart` | Yes |
|  10 | `boots` | `dino-tools-field-boots` | Yes *(DB slug `boots`, not `field-boots`, so the asset name is not `…-field-field-boots`)* |
|  (underwater only) | `long-handled-net` | `dino-tools-field-long-handled-net` | Yes |

**Note:** Until `dino-tools-field-gps` exists, you may temporarily use `dino-tools-field-gpr-surveyor` or `dino-tools-field-gnss-surveyor` in code only; this document’s **canonical** discovery GPS slot is `dino-tools-field-gps`.

---

## Pool size by story

| Stories | Discovery pool | Count |
|---------|----------------|-------|
| **All land-based stories** (Big Fossil, Small Tooth, Skull, Skeleton, Bone Bed, Botany, Cliff, Colony) | Slugs above including `boots`, no `long-handled-net` | **10** eligible field tools (+ `gpr-surveyor` as GPS stand-in in code) |
| **Underwater** | Above + `long-handled-net` only for that story | **11** eligible in pool |

**Cliff:** Discovery assumes the exposure is visible from the ground; no ladder in this pool (see design discussion).

**Underwater:** `long-handled-net` must **only** appear in the discovery pool for the underwater story — never for land stories — so it cannot be chosen as a correct answer elsewhere.

---

## Story slug → `fossilHuntStoryLibrary` id

| Story title | `storySlug` in code |
|-------------|---------------------|
| Big Fossil | `big_fossil` |
| Small Tooth | `small_tooth` |
| Skull | `skull` |
| Skeleton | `skeleton` |
| Bone Bed | `bone_bed` |
| Botany | `botany` *(single story: shale paleobotany + amber in debris; land-based, not Underwater)* |
| Cliff | `cliff` |
| Colony | `colony` |
| Underwater | `underwater` |

---

## Related docs

- `DINO_FOSSIL_HUNT_TOOL_IDENTIFIERS.md` — **slug**, **`field`/`lab`/`art` group**, and **`asset_name`** rules for DB + all phases.
- `DINO_FOSSIL_HUNT_EXCAVATE_TOOLS.md` — canonical **excavate** twelve + story extras.
- `DINO_FOSSIL_HUNT.md` — per-story tool notes (may predate this discovery list; **this file** is the source of truth for discovery `dino-tools-field-*` names and counts).
- Implementation: `DinoGames/Views/DinoFossilHuntGameView.swift` — `fossilHuntPhaseBasePaleontologistSlugs` / `fossilHuntStoryPhaseExtras`.

---

*Last aligned with repo asset check: discovery imagesets verified under `DinoGames/Assets.xcassets/Dinosaur-Tools/paleontologist/`.*
