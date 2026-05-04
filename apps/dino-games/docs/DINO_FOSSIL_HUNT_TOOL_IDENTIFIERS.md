# Dino Fossil Hunt — tool identifiers (database & asset consistency)

Use **one convention everywhere**: JSON, SQLite, CMS, and Swift can all key off the same fields so **story + phase + tool** matching stays unambiguous.

---

## 1. Tool row (global catalog)

| Field | Type | Rule |
|--------|------|------|
| **`slug`** | string, primary key | Lowercase **kebab-case**. **No** `dino-tools-` prefix. Examples: `tape-measure`, `dental-pick`, `plaster-jacket`. Globally unique across all groups. |
| **`group`** | enum | `field` \| `lab` \| `art` — maps to game roles **paleontologist** / **preparator** / **restorer** and to asset folders under `Dinosaur-Tools/`. |
| **`asset_name`** | string | **Derived** from `group` + `slug` (see below). Store explicitly only if an old asset breaks the rule. |
| **`display_label`** | string | Short UI/voice label (optional override table for acronyms like PLB). |
| **`hunt_phase`** | enum or null | **Field tools only:** exactly one of `discovery` \| `excavate` \| `preserve` \| `transport`. **Lab/art tools:** `null` (they are never “the” correct field tool for a phase; they only appear as distractors). |

### Why `hunt_phase` exists (young players)

Kids get frustrated when **the same tool** could be “right” in more than one round. In **Dino Fossil Hunt**, treat each **field** tool as belonging to **one phase only** for this game—even if real field work reuses gear across steps.

**Rule:** If **tool X** is used in **excavate**, it is **not** in the discovery, preserve, or transport answer pools for any story. Example: `dental-pick` → `hunt_phase = excavate` only; `plaster-jacket` → `preserve` only.

**Data check:** For every row with `group = field`, `hunt_phase` must be set. Story-specific pools are **subsets** of tools that already match that phase:

`story_phase_tool` may only reference `slug`s where `tools.hunt_phase = story_phase_tool.phase` (for field tools).

Real-world overlap is a **different product** (e.g. Dino Fossil Prep); **Hunt** stays **non-overlapping** for clarity.

### `asset_name` formula (matches Xcode imageset names)

| `group` | Folder | Pattern |
|---------|--------|---------|
| `field` | `paleontologist/` | `dino-tools-field-{slug}` |
| `lab` | `preparator/` | `dino-tools-lab-{slug}` |
| `art` | `restorer/` | `dino-tools-art-{slug}` |

Examples:

- `slug=tape-measure`, `group=field` → `asset_name=dino-tools-field-tape-measure`
- `slug=downdraft-bench`, `group=lab` → `asset_name=dino-tools-lab-downdraft-bench`
- `slug=3d-printer`, `group=art` → `asset_name=dino-tools-art-3d-printer`

**Swift / UI:** load images with `Image(asset_name)` / `ImageAssetCache.imageExists(named: asset_name)`.

---

## 2. Phase eligibility (per story, same shape for every phase)

Which **story** uses which **tools** is still **membership** on top of `hunt_phase`:

- First, each field tool has **one** `hunt_phase` (see §1).
- Then, **story_phase_tool** narrows “this story’s discovery pool includes these discovery-phase tools only,” etc.

**Option A — junction table**

`story_phase_tool (story_slug, phase, slug, …)`

- `story_slug`: e.g. `botany`, `underwater` (matches `fossilHuntStoryLibrary` ids).
- `phase`: `discovery` \| `excavate` \| `preserve` \| `transport`
- `slug`: FK to `tools.slug`

**Constraint:** For field tools, `phase` must equal `tools.hunt_phase`. (No duplicate slug across phases.)

**Option B — JSON per story**

One blob per story: `{ "discovery": ["slug", …], "excavate": […], … }`

Same keys for **every** story. Every slug in `"excavate"` must have `hunt_phase = excavate` in the catalog.

---

## 3. Pool size vs schema

- **Schema is identical** for all phases: always `story` + `phase` + list of `slug`s (however many you need — six, eight, ten).
- **Discovery** has a documented cap of **9** (land) or **10** (underwater + `long-handled-net`); other phases can use different counts without changing table shape.

Canonical discovery slugs: **`DINO_FOSSIL_HUNT_DISCOVERY_TOOLS.md`**.

Canonical excavate slugs: **`DINO_FOSSIL_HUNT_EXCAVATE_TOOLS.md`**.

---

## 4. Distractors (two correct, three wrong)

The game still picks **two** tools from the **field** pool for that `story` + `phase`, and **three** from **other** groups (`lab` + `art`). Lab/art tools do **not** need a `hunt_phase`; they are never “correct” for a field phase—only filler. That keeps the rule simple: **only field tools with the matching `hunt_phase`** can be correct for that round.

---

## 5. Future: Dino Fossil Prep

Same **`slug` + `group` + `asset_name`** rules. Prep rounds use **`lab`** (and optionally `art`) pools with the **same** junction/JSON pattern (`story` or `prep_module` + `phase` + slugs).

---

## 6. Code alignment

`DinoGames/Views/DinoFossilHuntGameView.swift` still builds image names as `dino-tools-{slug}` in places; the catalog uses `dino-tools-field-{slug}` for field tools. When wiring the DB or refactoring, resolve **`asset_name`** from the table above so **one** string drives both DB and assets.
