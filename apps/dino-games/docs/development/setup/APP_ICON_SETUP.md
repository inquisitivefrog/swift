# App Icon Setup

## Status: ✅ Icon Added

The app icon has been configured:

- **File**: `AppIcon-1024.png` (1024x1024 pixels)
- **Location**: `Assets.xcassets/AppIcon.appiconset/`
- **Format**: PNG with transparency

## What Was Done

1. Copied your icon from `/Users/tim/Desktop/Dino-Games-icon.png` to the AppIcon asset set
2. Updated `Contents.json` to reference the icon file
3. Icon is configured for iOS universal (works on all iOS devices)

## Next Steps

1. **In Xcode**: 
   - Open `Assets.xcassets`
   - Click on `AppIcon`
   - Verify the 1024x1024 slot shows your icon
   - Xcode will automatically generate all required sizes from this single image

2. **Build and Run**:
   - Clean build folder (⇧⌘K)
   - Build (⌘B)
   - Run on device or simulator
   - The icon should appear on your home screen!

## Known gotchas (2026-09-17 — caused two App Store Connect upload rejections)

The claim below that "Xcode will automatically generate all required sizes from this single image" is **incomplete** — it only holds if a specific build setting is also on, and it says nothing about the alpha channel requirement. Both bit us on `1.0.2 (9)`'s upload (error codes 91111, 90023, 90022):

1. **Set `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES`** in Build Settings (all targets/configs — Debug, Release, and any custom config like Walkthrough). Without it, Xcode's single-1024-source app icon only generates the sizes actually used by the current Xcode/OS combo, not the full legacy roster (e.g. iPad's 152×152, iPhone's 120×120) App Store Connect's validator still requires.
2. **The 1024×1024 marketing icon must have no alpha channel at all.** `sips -g hasAlpha AppIcon.png` must say `no`. An icon that's 100% opaque but still *carries* an alpha channel (common when exported from tools that default to RGBA) gets treated by ASC as a **missing** icon for the "Any Appearance" slot, not just a warning. Fix losslessly if it's already fully opaque: `magick icon.png -alpha off icon.png` (verify with `magick identify -format "opaque=%[opaque]\n" icon.png` first — if that's not `True`, flattening needs an actual background color choice, not a blind channel strip).

Re-verify both after any icon file replacement, not just at initial setup — neither is checked by a normal Xcode build, only by ASC's upload validation.

## Optional: Additional Icon Variants

If you want to customize icons for:
- **Dark mode**: Add a dark variant to the dark appearance slot
- **Tinted icon**: Add a variant for iOS's tinted icon feature

For now, the single 1024x1024 icon will work for all contexts.

## Troubleshooting

If the icon doesn't appear:
1. Clean build folder (⇧⌘K)
2. Delete app from device/simulator
3. Rebuild and reinstall
4. Check that the icon appears in Xcode's AppIcon preview

---

**Note**: Modern iOS (iOS 11+) uses a single 1024x1024 icon as the source, but the legacy sizes are only auto-generated if `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS` is on and the source has no alpha channel — see "Known gotchas" above before assuming a single PNG is enough.
