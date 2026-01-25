# Resizing Images for Dino Games

## Method 1: Using Preview (Built-in macOS Tool) - Easiest

### Steps:
1. **Open your image in Preview**
   - Double-click the image file, or
   - Right-click → "Open With" → Preview

2. **Open Tools menu**
   - Click "Tools" in the menu bar
   - Select "Adjust Size..." (or press ⌘⌥I)

3. **Set dimensions**
   - Make sure "Scale proportionally" is checked ✅
   - Change width or height to **320 pixels** (the other will auto-adjust)
   - Units should be "pixels"
   - Click "OK"

4. **Save the resized image**
   - File → Save (⌘S) to overwrite, or
   - File → Export... (⌘⇧E) to save as new file
   - For new file, choose PNG format and save

### Batch Resize Multiple Images:
1. Select all images in Finder (⌘A or click-drag)
2. Right-click → "Open With" → Preview
3. Preview opens all images in sidebar
4. For each image:
   - Click image in sidebar
   - Tools → Adjust Size... → Set to 320px → OK
   - File → Save (⌘S)
5. Close Preview when done

---

## Method 2: Command Line (sips) - Fastest for Batch ⚡

### Single Image:
```bash
sips -Z 320 /path/to/your/image.png --out /path/to/resized/image.png
```

### Batch Resize All Images in a Folder:

**For Single Universal Image (320px):**
```bash
cd /path/to/your/images
for file in *.png *.jpg *.jpeg; do
    sips -Z 320 "$file" --out "${file%.*}-320.png"
done
```

**For Three Separate Sizes (80, 160, 240px):**
```bash
cd /path/to/your/images
for file in *.png *.jpg *.jpeg; do
    # Create @1x (80px)
    sips -Z 80 "$file" --out "${file%.*}-80.png"
    # Create @2x (160px)
    sips -Z 160 "$file" --out "${file%.*}-160.png"
    # Create @3x (240px)
    sips -Z 240 "$file" --out "${file%.*}-240.png"
done
```

### Resize and Overwrite Originals (Use with Caution):
```bash
cd /path/to/your/images
for file in *.png *.jpg *.jpeg; do
    sips -Z 320 "$file"
done
```

### Quick Examples:

**If images are on Desktop:**
```bash
cd ~/Desktop
sips -Z 320 dino-trex.png --out dino-trex-320.png
```

**Resize all images in current folder:**
```bash
# Creates new files with -320 suffix
for file in *.png *.jpg *.jpeg; do
    sips -Z 320 "$file" --out "${file%.*}-320.png"
done
```

**Resize and convert to PNG (if source is JPG):**
```bash
for file in *.jpg *.jpeg; do
    sips -Z 320 "$file" --out "${file%.*}.png"
done
```

---

## Recommended Sizes

**Option A: Single Universal Image (Easiest)**
- **320x320 pixels** - Slightly larger than needed, gives best quality when Xcode scales it down
- Xcode automatically scales this for @1x, @2x, @3x displays

**Option B: Three Separate Sizes (Best Quality)**
- **@1x: 80x80 pixels** (for older devices)
- **@2x: 160x160 pixels** (for most iPhones)
- **@3x: 240x240 pixels** (for newer iPhones)

**Why the difference?**
- Images display at **80x80 points** in the UI
- iOS scales: @1x = 80px, @2x = 160px, @3x = 240px
- 320px is a "safe" size for Universal that covers all cases with extra quality

## File Format
- **PNG** recommended (supports transparency)
- Or **JPEG** if no transparency needed

---

## Quick Checklist
- [ ] Open image in Preview
- [ ] Tools → Adjust Size → 320px
- [ ] Save/Export as PNG
- [ ] Repeat for all 8 images (3 dinosaurs + 5 characteristics)
- [ ] Add to Assets.xcassets with correct names
