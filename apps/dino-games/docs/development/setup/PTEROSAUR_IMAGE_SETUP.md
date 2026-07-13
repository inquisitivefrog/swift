# Pterosaur Image Setup Guide

## Image Sets Needed in Assets.xcassets

### Pterosaur Images (5 total):
1. `ptero-pterodactyl` - Pterodactyl
2. `ptero-pteranodon` - Pteranodon
3. `ptero-quetzalcoatlus` - Quetzalcoatlus
4. `ptero-rhamphorhynchus` - Rhamphorhynchus
5. `ptero-dimorphodon` - Dimorphodon

### Game Card Image:
- `game-pterosaur-features` - Game card image for "Match the Pterosaur!" on the selection screen

## Image Requirements

- **Size**: 240-320px recommended (or @1x: 80px, @2x: 160px, @3x: 240px)
- **Format**: PNG (with transparency) or JPEG
- **Location**: Assets.xcassets as Image Sets
- **Naming**: Must match exactly (case-sensitive)

## How to Add in Xcode

1. Open Assets.xcassets in Xcode
2. Right-click in the asset catalog
3. Select "New Image Set"
4. Name it exactly as listed above (e.g., `ptero-pterodactyl`)
5. Drag your images into the appropriate slots (@1x, @2x, @3x) or use Universal

## Current Status

✅ **Code is ready** - All 5 pterosaurs are integrated into the game
⏳ **Images needed** - Add the 5 pterosaur image sets and 1 game card image

Once images are added, the game will automatically use them!
