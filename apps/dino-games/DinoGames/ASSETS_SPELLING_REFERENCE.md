# Asset spelling reference

Use this list to rename assets for consistency. Code has been updated to use these spellings where applicable.

---

## T-Rex: use **trex** (no hyphen)

All T-Rex assets should use the slug **trex**, not **t-rex**.

### Audio
| Current (incorrect) | Update to |
|---------------------|-----------|
| `DinoGames/Assets/Audio/Dinosaurs/t-rex.m4a` | `Dinosaurs/dino-trex.m4a` (code now looks for `dino-trex`) |

### Image assets (imageset name → filenames inside)
| Imageset | Current filenames in Contents.json | Update to |
|----------|-------------------------------------|-----------|
| `dino-trex.imageset` | `t-rex-80.png`, `t-rex-160.png`, `t-rex-240.png` | `trex-80.png`, `trex-160.png`, `trex-240.png` (and update Contents.json) |

These already use **trex** (no hyphen) and need no change:
- `lunch-carnivore-trex.imageset` (filenames: lunch-trex-80.png, …)
- `teen-carnivore-trex.imageset` (filenames: teen-trex-80.png, …)
- `dino-silhouette-trex.imageset`, `racer-trex.imageset`, `winner-race-trex.imageset`, `tooth-trex.imageset`, `grumpy-trex.imageset`
- `wacky-trex.imageset` (filenames: trex-beachcombing-80.png, …)

---

## Parasaurolophus: use **parasaurolophus** (two u’s)

Scientific spelling has two u’s. Use **parasaurolophus** everywhere for consistency.

### Image assets currently using **parasauralophus** (one u – incorrect)
| Imageset | Current filenames | Update to |
|----------|-------------------|-----------|
| `lunch-herbivore-parasauralophus.imageset` | imageset name + Contents already reference `lunch-parasaurolophus-80.png` etc. | Rename **imageset** folder to `lunch-herbivore-parasaurolophus.imageset`; keep filenames as `lunch-parasaurolophus-80.png` (already correct) |
| `teen-herbivore-parasauralophus.imageset` | `teen-parasauralophus-80.png`, … | Rename imageset to `teen-herbivore-parasaurolophus.imageset`; rename PNGs to `teen-parasaurolophus-80.png`, … and update Contents.json |
| `wacky-parasauralophus.imageset` | `wacky-parasauralophus-composing-a-song-80.png`, … | Rename imageset to `wacky-parasaurolophus.imageset`; rename PNGs to `wacky-parasaurolophus-composing-a-song-80.png`, … and update Contents.json |

After you rename these assets to **parasaurolophus**, the code can be updated to use `parasaurolophus` for lunch/teen asset slugs (and the `lunchTeenAssetSlug` mapping for Parasaurolophus can be removed).

---

## Summary

1. **T-Rex**
   - Rename audio: `t-rex.m4a` → `dino-trex.m4a` under `Dinosaurs/`.
   - In `dino-trex.imageset`: rename PNGs from `t-rex-*` to `trex-*` and update Contents.json.

2. **Parasaurolophus**
   - Rename the three imagesets (and their PNGs) from **parasauralophus** to **parasaurolophus**.
