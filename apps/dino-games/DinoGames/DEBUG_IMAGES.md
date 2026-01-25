# Debugging Missing Characteristic Images

## Expected Image Names in Assets.xcassets

The code expects these **exact** names (case-sensitive):

### Dinosaurs (working ✅):
- `dino-trex`
- `dino-triceratops`
- `dino-stegosaurus`

### Characteristics (not loading ❌):
- `char-teeth`
- `char-footprints`
- `char-eggs`
- `char-skin`
- `char-spikes`

## How to Check in Xcode

1. **Open Assets.xcassets** in Xcode
2. **Look for Image Sets** with these exact names
3. **Verify each Image Set has images** in the @1x, @2x, @3x slots

## Common Issues

### Issue 1: Wrong Image Set Names
- ❌ `teeth` (missing `char-` prefix)
- ❌ `Teeth` (wrong case)
- ❌ `char_teeth` (underscore instead of hyphen)
- ✅ `char-teeth` (correct)

### Issue 2: Images Not in Image Sets
- You can't just drag files into Assets.xcassets folder
- You must create **Image Sets** first, then drag images into the slots

### Issue 3: Images in Wrong Location
- Images must be in **Image Sets** within Assets.xcassets
- Not just loose files in the folder

## How to Fix

1. **In Assets.xcassets:**
   - Right-click → "New Image Set"
   - Name it exactly: `char-teeth`
   - Drag your 80px image → @1x slot
   - Drag your 160px image → @2x slot
   - Drag your 240px image → @3x slot
   - Repeat for all 5 characteristics

2. **Verify names match exactly:**
   - `char-teeth` (not `teeth`, not `Teeth`, not `char_teeth`)

3. **Clean and rebuild:**
   - Product → Clean Build Folder (⇧⌘K)
   - Product → Build (⌘B)
   - Run again

## Debug Output

I've added debug logging. When you run the app, check the console for:
- `⚠️ Characteristic image not found: 'char-teeth' - using emoji fallback`

This will tell you exactly which images are missing.

## Quick Checklist

- [ ] Created Image Sets (not just files) in Assets.xcassets
- [ ] Named Image Sets exactly: `char-teeth`, `char-footprints`, etc.
- [ ] Added images to @1x, @2x, @3x slots in each Image Set
- [ ] Cleaned build folder
- [ ] Rebuilt and ran
- [ ] Checked console for debug messages
