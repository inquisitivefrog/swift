# How to Add Images to Assets.xcassets in Xcode

## The Problem
Copying files via Finder doesn't add them to the asset catalog. You must create **Image Sets** in Xcode.

## Step-by-Step Instructions

### For Each Characteristic Image (5 total):

1. **Open Assets.xcassets in Xcode**
   - In Project Navigator, find `Assets.xcassets`
   - Click to open it

2. **Create a New Image Set**
   - Right-click in the left sidebar (where other assets are listed)
   - Select **"New Image Set"**
   - OR: Click the **"+"** button at the bottom of the asset list
   - OR: File menu → New → Image Set

3. **Name the Image Set**
   - Click on the new "Image" name (it will be highlighted/editable)
   - Type the exact name: `char-teeth` (for the first one)
   - Press Enter

4. **Add Your Images to the Slots**
   - You'll see slots for @1x, @2x, @3x, and Universal
   - Drag your **80px image** → drop into **@1x** slot
   - Drag your **160px image** → drop into **@2x** slot
   - Drag your **240px image** → drop into **@3x** slot
   - OR: Drag one image into **Universal** slot (if you only have one size)

5. **Repeat for All 5 Characteristics:**
   - `char-teeth`
   - `char-footprints`
   - `char-eggs`
   - `char-skin`
   - `char-spikes`

### Verify Dinosaur Images Too:
- Check that these exist (they're working, but verify):
  - `dino-trex`
  - `dino-triceratops`
  - `dino-stegosaurus`

## Visual Guide

```
Assets.xcassets
├── AppIcon
├── CoverImage
├── dino-trex          ← Image Set (working ✅)
├── dino-triceratops   ← Image Set (working ✅)
├── dino-stegosaurus   ← Image Set (working ✅)
├── char-teeth         ← Image Set (CREATE THIS ❌)
├── char-footprints    ← Image Set (CREATE THIS ❌)
├── char-eggs          ← Image Set (CREATE THIS ❌)
├── char-skin          ← Image Set (CREATE THIS ❌)
└── char-spikes        ← Image Set (CREATE THIS ❌)
```

## Important Notes

- **Image Set name** = what you reference in code (`Image("char-teeth")`)
- **File names don't matter** - you can name your source files anything
- **Must be Image Sets** - not just files dragged into the folder
- **Case-sensitive** - `char-teeth` not `Char-Teeth` or `char_teeth`

## After Adding Images

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Build**: Product → Build (⌘B)
3. **Run**: Product → Run (⌘R)

The debug messages should disappear and images should appear!

## Troubleshooting

**If images still don't appear:**
- Verify Image Set names match exactly (check spelling, hyphens, case)
- Make sure images are in the slots (not just in the folder)
- Clean build folder and rebuild
- Delete app from simulator and reinstall
