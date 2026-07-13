# Weigh Game Image Setup

## Image Location

The `weigh-the-dinosaur.png` image should be added to **Assets.xcassets** as a new Image Set (NOT in AppIcon).

## Steps in Xcode:

1. **Open Assets.xcassets** in Xcode
2. **Create a new Image Set**:
   - Right-click in the asset list → "New Image Set"
   - Name it: `game-weigh-dinosaur`
3. **Add your image**:
   - Drag `weigh-the-dinosaur.png` into the Universal slot (or @1x, @2x, @3x slots)
4. **Done!** The game card will automatically use this image

## Why This Name?

The game configuration has:
- `id: "weigh-dinosaur"`
- The code generates image name as: `"game-\(config.id)"` = `"game-weigh-dinosaur"`

## Current Status

- ✅ Code expects: `game-weigh-dinosaur` in Assets.xcassets
- ⏳ You need to: Create the Image Set and add your image
- 📁 Image file: `/Users/tim/Desktop/weigh-the-dinosaur.png`

Once you add it to Assets.xcassets with the name `game-weigh-dinosaur`, it will appear on the cover page game card automatically!
