# Game Image Setup for Cover Page

## Image Needed

Add an image to Assets.xcassets for the Matching Game card on the cover page.

### Image Set Name:
- `game-matching`

### Recommended Size:
- **240x240 to 320x320 pixels** (or use @1x: 80px, @2x: 160px, @3x: 240px)

### How to Add:

1. **Open Assets.xcassets** in Xcode
2. **Create a new Image Set**:
   - Right-click in the asset list → "New Image Set"
   - Name it: `game-matching`
3. **Add your image**:
   - Drag image into Universal slot (or @1x, @2x, @3x slots)
4. **Done!** The game card will automatically use the image

### Fallback:
- If the image doesn't exist, the card will show the emoji icon (🔗) as fallback
- This allows you to add the image later without breaking the app

### Image Suggestions:
- A dinosaur matching puzzle/game visual
- Two dinosaurs with a match symbol
- Colorful, child-friendly illustration
- Should be recognizable as a "matching" game

---

**Note**: The code is ready - just add the image to Assets.xcassets with the name `game-matching` and it will appear automatically!
