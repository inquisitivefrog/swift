# Dino Fossil Hunt — Excavate phase: `dino-tools-field-*` tools

Permanent reference for **field** tools whose **`hunt_phase` is `excavate` only** in Dino Fossil Hunt.

**Meaning of excavate here:** **extraction** — remove overburden and matrix, expose the fossil, work wet or dry sediment **while still in dig mode**. Not discovery (where to look), not preserve (glue / jacket / pack), not transport (crates / manifests).

**Audience:** young players (roughly 4–6); same DB rules as **`DINO_FOSSIL_HUNT_TOOL_IDENTIFIERS.md`**.

---

## Excluded from excavate (by design)

- **Discovery-only** tools (the canonical ten):  
  `locality-map`, `tape-measure`, `surveyor-level`, `clinometer`, `gps`, `grid-kit`, `flagging-tape`, `notes`, `rock-color-chart`, `long-handled-net` *(underwater discovery only)* — see **`DINO_FOSSIL_HUNT_DISCOVERY_TOOLS.md`**.
- **Preserve:** e.g. `plaster-jacket`, `specimen-stabilizer`, `site-cover`, `separation-layer`, `micro-vial-set`, `waterproof-collection`, consolidant / “glue” (when represented as distinct tools).
- **Transport:** e.g. `transport-sled`, `specimen-crate`, `shipping-manifest`, `slotted-shale-crate`, `tribal-permit`.
- **Camp / vehicles / heavy industrial** (teen or other games): tents, trucks, generators, etc.

---

## Canonical excavate pool: **12** slugs (even dozen)

These are the **default** eligible **excavate** tools (variety for “pick two correct”). Each has **`hunt_phase = excavate`** and **`group = field`**.

| # | Slug | Full imageset name | In catalog |
|---|------|---------------------|------------|
| 1 | `dental-pick` | `dino-tools-field-dental-pick` | Yes |
| 2 | `fine-chisel` | `dino-tools-field-fine-chisel` | Yes |
| 3 | `medium-chisel` | `dino-tools-field-medium-chisel` | Yes |
| 4 | `rock-hammer` | `dino-tools-field-rock-hammer` | Yes |
| 5 | `pick-axe` | `dino-tools-field-pick-axe` | Yes |
| 6 | `transfer-shovel` | `dino-tools-field-transfer-shovel` | Yes |
| 7 | `shale-splitter` | `dino-tools-field-shale-splitter` | Yes |
| 8 | `rock-saw` | `dino-tools-field-rock-saw` | Yes — **cutting rock / matrix in the field** |
| 9 | `hand-held-sifting-screen` | `dino-tools-field-hand-held-sifting-screen` | Yes — **dry screening / working loose matrix** |
| 10 | `fine-brush` | `dino-tools-field-fine-brush` | Yes |
| 11 | `wide-brush` | `dino-tools-field-wide-brush` | Yes |
| 12 | `dust-blower` | `dino-tools-field-dust-blower` | Yes |

### Not in Hunt excavate: `specimen-saw`

**`specimen-saw`** is often associated with **lab / prep** work (e.g. trimming a jacketed block or careful cuts under control), not the main **field extraction** fantasy for Dino Fossil Hunt. Keep it for **Dino Fossil Prep** (lab tool pools, likely `group = lab` with a `dino-tools-lab-*` imageset when you split art). The field catalog may still contain `dino-tools-field-specimen-saw` for reuse or legacy; **Hunt** does not list it under **`hunt_phase = excavate`**.

**Story-specific additions** (still **`hunt_phase = excavate`**; merged only for matching stories):

| Story slug | Extra excavate slugs | Notes |
|------------|----------------------|--------|
| `underwater` | `wet-sieve-stack` | Wet matrix (**`hand-held-sifting-screen`** is already in the base ten). |
| `botany` | `dry-sieve-stack` | Shale + amber in debris; asset **`dino-tools-field-dry-sieve-stack`** — add when ready. |
| `bone_bed` | `sifting-screen` | Extra screen size vs hand-held (base pool). |
| `colony` | `sifting-screen` | Same idea as bone bed. |

**Cliff-only** tools (`cliff-scaffold`, `climbing-harness`, `debris-netting`, etc.) are **not** in the asset catalog yet; add a **`cliff`** row here when imagesets exist, all with **`hunt_phase = excavate`**.

---

## Overlap check

- **`long-handled-net`** is **not** an excavate tool — it stays **discovery** (underwater only).
- **`specimen-stabilizer`** and **glue** are **preserve**, not excavate.
- **`rock-color-chart`** and **`optical-lens`** stay **discovery** (compare / look), not excavate.
- **`specimen-saw`** is **not** Hunt excavate — reserve for **Dino Fossil Prep** (lab / jacket work).

---

## Related docs

- **`DINO_FOSSIL_HUNT_DISCOVERY_TOOLS.md`** — discovery ten.
- **`DINO_FOSSIL_HUNT_TOOL_IDENTIFIERS.md`** — `slug`, `group`, `hunt_phase`, `asset_name`.
- **`DinoGames/Views/DinoFossilHuntGameView.swift`** — pools should be updated to match this file.

---

*Excavate = extraction / matrix removal; preserve = stabilize and pack — see design threads in project history.*
