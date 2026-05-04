# Image Setup for Investor Demo

## Current Status
The code now supports images instead of emojis. Images will be used if available, with emojis as fallback.

## Image Names Expected

### Dinosaurs (in Assets.xcassets)
- `dino-trex` - T-Rex image
- `dino-triceratops` - Triceratops image  
- `dino-stegosaurus` - Stegosaurus image

### Characteristics (in Assets.xcassets)
- `char-teeth` - Teeth image
- `char-footprints` - Footprints image
- `char-eggs` - Eggs image
- `char-skin` - Skin image
- `char-spikes` - Spikes image

## How to Add Images

1. **Prepare your images** (PNG or JPEG, recommended size: 200x200 to 400x400 pixels)
2. **In Xcode**:
   - Open `Assets.xcassets`
   - Right-click → "New Image Set"
   - Name it (e.g., "dino-trex")
   - Drag your image into the 1x, 2x, or 3x slot (or Universal)
3. **Repeat for all images**

## Fallback Behavior

- If image exists in Assets.xcassets → uses image
- If image doesn't exist → falls back to emoji
- This allows gradual migration from emojis to images

## For Investor Demo

You can:
1. Add temporary placeholder images now (any images will work)
2. Replace with final artwork later
3. The code automatically uses images when available

## Image Recommendations

### Size Guidelines
- **Recommended**: 240x240 to 320x320 pixels
- **Maximum**: 400x400 pixels (no need for larger)
- **Why**: Images display at 80x80 points in the UI
  - @1x displays: 80x80 pixels
  - @2x displays: 160x160 pixels  
  - @3x displays: 240x240 pixels
- **1024x1024 is too large** - wastes storage and memory, no visual benefit

### Format & Style
- **Format**: PNG (with transparency preferred) or JPEG
- **Style**: Child-friendly, colorful, clear
- **Background**: Transparent or solid color

### Xcode Asset Setup

**No Special Naming Required!**

When you add images to Assets.xcassets, Xcode uses **slots**, not filenames. Here's how it works:

**Option 1: Single Universal Image (Easiest for Demo)**
1. In Assets.xcassets, create a new Image Set (right-click → "New Image Set")
2. Name the Image Set (e.g., "dino-trex") - this is what you reference in code
3. Drag your image (240-320px) into the "Universal" slot
4. ✅ Done! Xcode automatically scales it for all devices

**Option 2: Multiple Sizes (Best Quality)**
1. Create Image Set named "dino-trex"
2. Drag your images into the appropriate slots:
   - Drag 80x80px image → @1x slot
   - Drag 160x160px image → @2x slot  
   - Drag 240x240px image → @3x slot
3. ✅ Done! iOS picks the right size automatically

**Important Notes:**
- **File names don't matter** - you can name your source files anything (e.g., "trex.png", "dinosaur1.jpg", etc.)
- **Image Set name matters** - this is what you use in code: `Image("dino-trex")`
- Xcode shows slots visually - just drag images into the right slot
- It's the **SAME image**, just different pixel dimensions

**For Investor Demo**: Use Option 1 (single Universal image) - it's much faster and looks great!

---

**Note**: The code is ready for images. Just add them to Assets.xcassets with the names listed above.
