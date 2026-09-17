# App size, catalog scope, and release strategy

Recorded **2026-08-05** after App Store Connect size review (Build **1.0 (3)**) and related product discussion. Updated **2026-08-20** after **1.0 (3)** went live (Pending Developer Release → released) and the post-ship discussion on levels 5+ / a second app. Updated **2026-09-17** after the TestFlight-Internal walkthrough demo build (crash fix + app-icon-validation fix) and the **1.0.2 (11)** metadata-only submission (title/subtitle/keywords ASO, category change). Use this when trimming assets, planning updates, or deciding whether to add games / a second listing.

> **`future-games` branch:** High-res `images/` masters for several level‑5+ games were moved off the release line onto **`future-games`** / `origin/future-games` (commit `bcf35920`, 2026-07-02). If `images/dino-tools/` (and similar) look empty here, check that branch first — it is not a Git LFS checkout failure. See [§3](#3-future-games-branch-do-not-forget).
>
> **Mnemonic doc (same name as the branch):** [`FUTURE_GAMES_BRANCH.md`](FUTURE_GAMES_BRANCH.md) — one-minute SRE cheat sheet that points here.

---

## 1. Product history (how we got here)

1. Started as a **dinosaur** learning app (personal paleontology interest + App Store / SwiftUI learning path after Shopping Kart was rejected as “done to death”).
2. Scope grew to ~20 land ideas, then **pterosaur** and **marine reptile** catalogs.
3. Debated land-first vs equal depth for all three biomes.
4. **Agreed shipping shape:** twelve mini-games per biome, sorted into **four levels** (`GameLevel.visibleInGamePicker` = levels **1–4**).
5. Land still has **extra game code and assets** for levels **5–10** (Tools, Push, Bones, Fauna, Habitats, Formations, Toothache, Fossil Hunt, Lunch, Wacky, …). Air/sea equivalents are incomplete or absent for many of those.
6. Image pipeline evolved: phone-era **80 / 160 / 240** (+ 1024 masters under `images/`) → ASC missing iPad artwork → universal iPhone+iPad with catalog slots **360 / 720 / 1024**.
7. Pedagogy examples kept in 1–4 on purpose (e.g. **Matrix** so young players might name matrix rock at a museum; **Flora** as paleobotany exposure). Heavier ecology games (Habitats / Formations / Fauna) and osteology-heavy ideas (Whose Bones / full bone counts) were deferred for age-appropriateness and size.

**Goals of the project (non-commercial first):** learn ASC mechanics, exercise genAI tooling, portfolio/demo, later a deeper teen/adult paleontology + acknowledgements app. Sales are a bonus; if it takes off, prefer loading **already-built dinosaur** extras first, then market-driven requests.

---

## 2. The size problem

### What App Store Connect showed (Build 3)

| Metric | Approx. |
|--------|---------|
| Universal compressed | **~3.89 GB** (fat package Apple stores — not a single-device download) |
| Typical thinned device download / install | **~1.2 GB / ~1.22 GB** |
| Warning | Over **200 MB** → no silent cellular download (Wi‑Fi / confirm) |

Riding near Apple’s ~**4 GB** package ceiling is a hard risk; the 200 MB banner is UX/network, not automatic rejection.

### Why it is fat

- Almost all art lives in **`DinoGames/Assets.xcassets`**. Local disk after parking unreleased imagesets off `main` (**2026-08-05**, commits `87c883ff` + `ac1d1209`): ~**5.36 GB** (was ~**5.8 GB** before trim). ASC Build 3 numbers above are pre-trim; remasure universal/thinned after the next archive upload.
- Spoken **audio** is smaller (~tens of MB) but cumulative.
- **Unlocking or listing only levels 1–4 does not omit assets.** If an imageset is in the app target, it ships. No On Demand Resources yet.
- App Thinning drops **device variants**, not “unused games.”

Rough disk examples (order-of-magnitude):

- Live ecology trio Flora (dino + ptero + marine): ~**626 MB** art alone.
- Unreleased level‑5+ imagesets are **out of** release `Assets.xcassets` (parked on `future-games`); verify with `bash apps/dino-games/scripts/verify-future-games-masters.sh` (expect `NO_ASSETS_ON_RELEASE`).

Repo masters under **`DinoGames/images/`** (~4+ GB) are for generation / provenance; they only affect the IPA if copied into the Xcode asset catalog / target.

---

## 3. `future-games` branch (do not forget)

**Commit:** `bcf35920` (2026-07-02) — *Move future-game image assets to future-games branch*.

**What moved:** high-res masters under `DinoGames/images/` only (~414 PNGs). **Not** removed: `json/`, Swift catalogs/views, or (on the main line) many **`Assets.xcassets`** groups for those games.

| `images/` folder moved | ~files | Game |
|------------------------|--------|------|
| `dino-tools/` | 159 | Dino Tools |
| `dino-toothache/` | 95 | Dino Toothache |
| `dino-fossil-hunt/` | 45 | Dino Fossil Hunt |
| `habitats/` | 33 | Dino Habitats |
| `dino-lunch/` | 26 | Dino Lunch |
| `dino-push/` | 25 | Dino Push |
| `whose-bones/` | 23 | Whose Bones |
| `ptero-formations/` | 8 | Ptero Formations |

**Branches:** `future-games` / `origin/future-games`.

**Implication:** Empty `images/dino-tools/` (etc.) on the release branch is **intentional**, not Git LFS “invisible until you cd there.” PNGs are LFS-tracked repo-wide, but those paths were deleted from this branch’s tree. Restore masters with e.g.:

```bash
git checkout future-games -- apps/dino-games/DinoGames/images/dino-tools
```

(Do **not** copy them back into `Assets.xcassets` until that game is scheduled to ship.)

**JSON:** Prefer keeping generation/provenance JSON under `DinoGames/json/<game>/`. Some parked games have rich JSON (e.g. Tools) while `images/` masters live only on `future-games`. Some Assets-only art lacks matching `images/` 1024s on this branch — **harvest from Assets or restore from `future-games` before deleting Assets groups.**

---

## 4. Strategy chosen for now (post–1.0)

### Release / review (historical + ongoing)

- **1.0 (3)** submitted **2026-08-03**, approved, then **manually released** **2026-08-20** (status had been Pending Developer Release).
- **1.0 (4)** stayed TestFlight-only (still labeled marketing version 1.0 — cannot relabel an uploaded binary).
- Bugfix follow-up: archive **1.0.1 (5)** → TestFlight → App Store version **1.0.1**, prefer **Automatically release this version** for patches.
- **1.0.1 (7)** is the live/current App Store release as of 2026-09.
- While a version is **In Review**, do not swap the selected binary (resets the queue).

### TestFlight-Internal walkthrough / demo track (2026-09-16 → 2026-09-17)

Built for showing the app at interviews (see [`WALKTHROUGH_TESTFLIGHT.md`](../development/WALKTHROUGH_TESTFLIGHT.md)) — separate from the App Store track above, same marketing version numbering but its own build lineage:

| Build | Result |
|-------|--------|
| **1.0.2 (8)** | Uploaded to TestFlight Internal Only; **crashed immediately on selecting Land**. Root cause: `DeveloperSessionFlags.showAllCatalogLevels` expanded the picker to every `GameLevel` for every category, which forced construction of Land's level 5–10 games (Dino Tools, Dino Bones, …) whose art is parked on `future-games`. At least two of those configs `fatalError()` when their round builder can't find enough qualifying creatures (`DinoToolsGameConfigs.dinoTools`, `GuessGameConfigs.dinoBones` — both confirmed via on-device crash traces). |
| **1.0.2 (9)** | Crash fixed (walkthrough reverted to the same 1–4 levels as shipping — free navigation without forced completion order was always the actual goal, not extra levels). Upload itself then **rejected by ASC** with icon errors (91111 missing opaque 1024 "Any Appearance" icon, 90023 missing iPad 152×152, 90022 missing iPhone 120×120). |
| **1.0.2 (10)** | Icon fixed (see app-icon fix below). Uploaded to TestFlight Internal Only successfully — this is the working interview/demo build. |

Also discovered along the way: the `DinoGames-Walkthrough` shared Xcode scheme didn't exist (`xcshareddata/xcschemes/` was empty) — only the `Walkthrough` build configuration did. Added shared schemes for both `DinoGames` and `DinoGames-Walkthrough` so `xcodebuild archive -scheme DinoGames-Walkthrough` works from the CLI.

### App icon fix (2026-09-17, applies to every config)

Two defects in `AppIcon.appiconset`, both real for the production build too (not walkthrough-specific):

1. `Dino-Games-app-icon-1024.png` carried an unused-but-present alpha channel (image was already 100% opaque). The App Store marketing icon slot requires **no alpha at all**; ASC treats an icon with any alpha channel as missing. Stripped the channel — lossless, no visual change.
2. The project never set `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS`, so Xcode's single-1024-source app icon never generated the full legacy icon roster (120×120 iPhone, 152×152 iPad, etc.) — contrary to the assumption in [`development/setup/APP_ICON_SETUP.md`](../development/setup/APP_ICON_SETUP.md) that a single 1024 PNG is sufficient. Added the build setting to all three `DinoGames` target configs.

### 1.0.2 (11) — metadata-only App Store submission (2026-09-17)

Production `DinoGames` (Release-scheme) archive, separate build number from the walkthrough track since App Store Connect enforces (version, build) uniqueness across TestFlight *and* the App Store regardless of which scheme built it. No functional/code changes beyond the app icon fix above — the walkthrough feature stays compile-gated off (`DINO_WALKTHROUGH`) for Release. Submitted for review with:

- Updated **Name**, **Subtitle**, and **Keywords** for ASO (current values live in App Store Connect; the app's bare "DinoGames" title/subtitle were indexing almost nothing per an unsolicited ASO-tool email that turned out to be factually correct).
- **Category** changed: primary **Family → Education**, secondary **Games → Puzzle** added — see [§7](#7-app-store-discovery-notes-2026-08-20), which had flagged this as a "revisit later" item since launch.

### Product shape

- **One app** (`DinoGames`): land / air / sea, levels **1–4** exposed.
- **Not** splitting into three store apps unless a biome can stand alone commercially; kids’ market is dinosaur-heavy.
- **Parity** (“every land game needs ptero + marine twins”) is a courtesy, not a store rule. Future land-only drops are allowed.
- **Do not** replace Flora with Push solely for size if that drops the paleobotany beat without air/sea alternates — revisit only as an explicit product decision.

### Future levels / second app (2026-08-20)

Do **not** treat “ship levels 5–8 in a renamed second App Store app” as the primary size strategy. A second listing is an intentional **product** split (new name, new page, split audience). It does **not** change the physics: image-heavy catalogs still blow the IPA if baked into *any* binary.

| Decision | Detail |
|----------|--------|
| Core app stays | Levels **1–4** in this listing |
| Do not pre-load 5+ art | Keep Fauna, Fossil Hunt, etc. out of release `Assets.xcassets` until that pack actually ships |
| Grow by pack | Prefer **On Demand Resources**, hosted packs, or updates that **add one pack** — not stuffing levels 5–8 into the main binary |
| Land-only OK | e.g. Dino Fauna without same-day Ptero/Marine Fauna — three-way parity multiplies size |
| Second app | Only if you want a separate product (e.g. Volume 2 / teen reference) — **not** because the binary is full |

**Known image-heavy candidates** (expect Flora-class pressure; measure before bundling):

- **Dino Fauna / Ptero Fauna / Marine Fauna** (especially all three)
- **Dino Fossil Hunt**

Treat those as **downloadable expansions** (or a later deliberate cut after measuring), not as “bump to 2.0 and stuff levels 5–8.”

### Packaging / size (forward)

1. **Do not pre-bundle unreleased games** in `Assets.xcassets`. Catalog “coming later” ≠ ship art now.
2. **Hygiene still useful:** remove any remaining unexposed imageset groups from the app target after confirming masters exist on `future-games` and/or harvested into `images/` (+ inventory JSON if needed). Remeasure ASC file sizes after each trim.
3. Trimming unexposed packs helps (~0.5 GB class of Assets fat) but **will not** alone get under 200 MB — levels 1–4 content is most of the thinned ~1.2 GB.
4. Long-term growth: **On Demand Resources**, hosted packs, or occasional updates that **add** a pack — not endless stuffing of the main binary. A second app is a product split, not the first size fix.
5. If the app never “takes off,” keep the ASC demo and architecture for the harder acknowledgements / reference app; don’t invent packaging debt for hypothetical catalogs.

### Provenance

- Keep **JSON prompts** and **1024 masters** as evidence of generation/custody where possible.
- Reverse-engineering prompts from PNGs is approximate; **file harvest + hash + date** is stronger than invented prompts if JSON was never saved.

---

## 5. Related code hooks

| Topic | Location |
|-------|----------|
| Levels shown in picker | `GameLevel.visibleInGamePicker` → `.level1`…`.level4` |
| Land / air / sea catalogs | `DinosaurGameCatalog`, `PterosaurGameCatalog`, `MarineReptileGameCatalog` |
| Skip landing cover for resume only (post-fix intent) | `CategoryPlaySession.shouldSkipLaunchIntros` — splash welcome should not be skipped for mere play progress |
| Asset org notes | [ASSETS_CATALOG_ORGANIZATION.md](../reference/ASSETS_CATALOG_ORGANIZATION.md) |

---

## 6. Summary

| Topic | Decision |
|-------|----------|
| Live (2026-08-20) | **1.0 (3)** released; patch via **1.0.1** (+ new build numbers) |
| Live (2026-09) | **1.0.1 (7)**; **1.0.2 (11)** submitted for review 2026-09-17 (metadata-only: ASO title/subtitle/keywords, category → Education + Games/Puzzle, app icon validation fix) |
| Demo track | TestFlight-Internal-Only `DinoGames-Walkthrough` scheme, separate build lineage; current working build **1.0.2 (10)** — never eligible for App Store submission |
| Ship core | One app, levels 1–4, three biomes |
| Extra land games (5+) | Code/JSON/`future-games` masters OK; **out of IPA** until exposed |
| Image-heavy next | Fauna (×3) and Fossil Hunt → packs / ODR, not main-binary stuffing |
| Size crisis | Trim unexposed Assets; don’t expect &lt;200 MB without redesigning 1–4 content or ODR |
| Levels 5–8 in a 2nd app | **Not** the size fix; second listing only for intentional product split |
| Review | Don’t swap binaries while a version is in review |
| Masters for Tools etc. | On **`future-games`**, not missing-from-LFS |

---

## 7. App Store discovery notes (2026-08-20)

Observed right after **1.0** went live:

- Direct link works: `https://apps.apple.com/app/dinogames/id6789705285` (listing shows **Family**, 4+, ~3.9 GB, $4.99).
- iPhone **Search** for `Dinogames` may not surface the new app yet (indexing lag + zero ratings vs established/sponsored results).
- Search suggestion chips under that query (e.g. kids, offline, zoo, baby, survival, hunter) are **related search terms**, **not** App Store primary categories — **Family does not appear there**, and that does not mean the listing lost its category.
- Visible competitors on that query were tagged **Education** in results. Revisit later whether primary category **Family** vs **Education** (or Education + Family secondary) helps ASO; change only as a deliberate metadata decision on a new version.
- **Resolved 2026-09-17:** changed primary category to **Education**, added secondary **Games → Puzzle**, as part of the **1.0.2 (11)** metadata submission (see §4).
