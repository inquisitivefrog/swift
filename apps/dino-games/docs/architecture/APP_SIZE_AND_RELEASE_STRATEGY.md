# App size, catalog scope, and release strategy

Recorded **2026-08-05** after App Store Connect size review (Build **1.0 (3)**) and related product discussion. Use this when trimming assets, planning Build 4+, or deciding whether to add games / a second app.

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

## 4. Strategy chosen for now (Build 3 / Build 4+)

### Release / review

- **Build 3** stays the App Review / primary TestFlight binary until Apple responds.
- **Do not** attach a new build to the App Store version under review (resets the queue).
- Optional later: upload Build 4 to TestFlight **without** selecting it for App Store review.
- Local fixes (e.g. bugs 19/20, launch audio) wait for a deliberate Build 4 cut.

### Product shape

- **One app** (`DinoGames`): land / air / sea, levels **1–4** exposed.
- **Not** splitting into three store apps unless a biome can stand alone commercially; kids’ market is dinosaur-heavy.
- **Parity** (“every land game needs ptero + marine twins”) is a courtesy, not a store rule. Future land-only drops are allowed.
- **Do not** replace Flora with Push solely for size if that drops the paleobotany beat without air/sea alternates — revisit only as an explicit product decision.

### Packaging / size (forward)

1. **Do not pre-bundle unreleased games** in `Assets.xcassets`. Catalog “coming later” ≠ ship art now.
2. **Build 4 hygiene (planned):** remove unexposed imageset groups from the app target after confirming masters exist on `future-games` and/or harvested into `images/` (+ inventory JSON if needed). Remeasure ASC file sizes.
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
| Ship now | One app, levels 1–4, three biomes |
| Extra land games (5+) | Code/JSON/`future-games` masters OK; **out of IPA** until exposed |
| Size crisis | Trim unexposed Assets; don’t expect &lt;200 MB without redesigning 1–4 content or ODR |
| Second app | Only if intentional product split |
| Review | Don’t swap binaries while Build 3 is in review |
| Masters for Tools etc. | On **`future-games`**, not missing-from-LFS |
