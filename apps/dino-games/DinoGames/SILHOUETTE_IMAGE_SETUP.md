# Silhouette Image Setup Guide

## Image Set Naming Convention

**Prefix: `silhouette-`** (followed by the dinosaur name without the `dino-` prefix)

## Image Set Names Needed

Based on the 12 dinosaurs currently in the game, you'll need these Image Sets:

1. `silhouette-trex` (for T-Rex)
2. `silhouette-triceratops` (for Triceratops)
3. `silhouette-stegosaurus` (for Stegosaurus)
4. `silhouette-velociraptor` (for Velociraptor)
5. `silhouette-therizinosaurus` (for Therizinosaurus)
6. `silhouette-spinosaurus` (for Spinosaurus)
7. `silhouette-apatosaurus` (for Apatosaurus)
8. `silhouette-ankylosaurus` (for Ankylosaurus)
9. `silhouette-corythosaurus` (for Corythosaurus)
10. `silhouette-parasaurolophus` (for Parasaurolophus)
11. `silhouette-iguanodon` (for Iguanodon)
12. `silhouette-troodon` (for Troodon)

## How to Add in Xcode

1. **Open Assets.xcassets** in Xcode
2. **Right-click** in the asset catalog (or click the `+` button at the bottom)
3. Select **"New Image Set"**
4. **Name it** exactly as listed above (e.g., `silhouette-trex`)
5. **Drag your images** into the appropriate slots:
   - **Universal** slot (recommended): One image that works for all scales
   - **Or** use @1x, @2x, @3x slots for different resolutions

## Image Requirements

- **Size**: 240-320px recommended for Universal (or @1x: 80px, @2x: 160px, @3x: 240px)
- **Format**: PNG (with transparency) or JPEG
- **Content**: Black silhouette/shadow of the dinosaur on transparent or white background

## Naming Pattern

The code automatically generates the image name by:
1. Taking the dinosaur's `imageName` (e.g., `"dino-trex"`)
2. Removing the `"dino-"` prefix → `"trex"`
3. Adding `"silhouette-"` prefix → `"silhouette-trex"`

So if your dinosaur image is `dino-trex`, the silhouette should be `silhouette-trex`.

## Fallback Behavior

If a silhouette image doesn't exist, the game will:
- Try to use the full dinosaur image with a black overlay effect
- This works but won't look as good as actual silhouette images

## Example Structure in Assets.xcassets

```
Assets.xcassets/
  ├── silhouette-trex.imageset/
  │   ├── Contents.json
  │   └── trex-silhouette.png (or @1x/@2x/@3x versions)
  ├── silhouette-triceratops.imageset/
  │   ├── Contents.json
  │   └── triceratops-silhouette.png
  └── ... (etc for all 12 dinosaurs)
```

## Quick Reference: Dinosaur → Silhouette Name Mapping

| Dinosaur Image Name | Silhouette Image Name |
|---------------------|----------------------|
| `dino-trex` | `silhouette-trex` |
| `dino-triceratops` | `silhouette-triceratops` |
| `dino-stegosaurus` | `silhouette-stegosaurus` |
| `dino-velociraptor` | `silhouette-velociraptor` |
| `dino-therizinosaurus` | `silhouette-therizinosaurus` |
| `dino-spinosaurus` | `silhouette-spinosaurus` |
| `dino-apatosaurus` | `silhouette-apatosaurus` |
| `dino-ankylosaurus` | `silhouette-ankylosaurus` |
| `dino-corythosaurus` | `silhouette-corythosaurus` |
| `dino-parasaurolophus` | `silhouette-parasaurolophus` |
| `dino-iguanodon` | `silhouette-iguanodon` |
| `dino-troodon` | `silhouette-troodon` |

---

**Note**: You don't need all 12 silhouettes to start - the game will work with whatever silhouettes you have. Missing ones will use the fallback effect.
