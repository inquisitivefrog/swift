# Image Generation & Asset Creation Guide

## Overview

This guide covers strategies for creating consistent-style dinosaur images using AI image generation tools, and techniques for creating game variations (silhouettes, partial views, scenes).

## Game Types Requiring Images

1. **Name That Dinosaur**: Full dinosaur image
2. **Name the Silhouette**: Blacked-out silhouette shape
3. **Where's Waldo / Find the Dinosaur**: Scene with partially hidden dinosaur

## AI Image Generation Tools Comparison

### Midjourney (Recommended)
**Best for**: Character consistency, style control

**Features**:
- `--cref` (Character Reference): Reuse same dinosaur across scenes
- `--sref` (Style Reference): Lock in art style
- `--seed`: Control randomness for consistency
- `--cw` (Character Weight): How closely to match reference

**Workflow**:
1. Generate style reference: "child-friendly dinosaur illustration, bright colors, simple shapes"
2. Generate character reference: One dinosaur in desired style
3. Generate variations using `--cref` and `--sref`

**Example Prompt**:
```
/imagine T-Rex dinosaur, child-friendly illustration style, bright colors, 
simple shapes, cartoon-like, educational, suitable for ages 4-6, 
clean background --sref [style_reference_url] --seed 12345 --v 6
```

### Stable Diffusion (Advanced)
**Best for**: Maximum control, custom training

**Features**:
- LoRA training: Train model on your specific style
- ControlNet: Control poses and composition
- IP-Adapter: Maintain character consistency
- More technical setup required

**Workflow**:
1. Collect reference images
2. Train LoRA on your style
3. Generate with trained model

### DALL·E 3 (Easiest)
**Best for**: Quick prototyping, less control needed

**Features**:
- Easiest to use
- Less control over consistency
- Good for initial testing

## Style Guide Template

### Consistent Prompt Structure

```
[Dinosaur name], child-friendly illustration style, bright colors, 
simple shapes, cartoon-like, educational, suitable for ages 4-6, 
clean background, stylized but recognizable features, friendly appearance, 
vector art style, bold outlines, flat colors, no shadows or complex lighting
```

### Style Reference Image

Create one "master" style reference showing:
- Color palette (bright, primary colors)
- Line weight (bold, simple)
- Art style (cartoon, vector-like)
- Background style (clean, simple)

Use this as `--sref` for all generations.

## Asset Creation Workflow

### Step 1: Generate Base Images

**For each dinosaur species**:
- Generate 1-2 base images (front view, side view)
- Use consistent style reference
- Transparent or solid color background
- Save as high-resolution PNG

**Target List** (30 dinosaurs):
- T-Rex, Triceratops, Stegosaurus, Brontosaurus, Velociraptor, Pterodactyl, Spinosaurus, Ankylosaurus, Diplodocus, Allosaurus, etc.

### Step 2: Create Template Variations

#### Silhouette Version
1. Load base image
2. Extract dinosaur shape (use image segmentation or manual masking)
3. Create mask: dinosaur = opaque, background = transparent
4. Apply mask to create black silhouette
5. Save as separate asset

#### Partial View Versions
1. Load base image
2. Create masks for different parts:
   - Head only (mask body/tail)
   - Tail only (mask head/body)
   - Distinctive feature only (spikes, crest, etc.)
3. Apply masks to create partial views
4. Save each variation

#### Scene Compositions
1. Generate or composite scene images with multiple dinosaurs
2. Position target dinosaur partially hidden
3. Create mask to hide parts of target
4. Save scene + mask data

### Step 3: Programmatic Creation (iOS/Swift)

#### Silhouette Creation

```swift
import UIKit
import CoreImage

extension UIImage {
    /// Creates a silhouette version by masking everything except the subject
    func createSilhouette(using mask: UIImage, fillColor: UIColor = .black) -> UIImage? {
        guard let baseCG = self.cgImage,
              let maskCG = mask.cgImage else { return nil }
        
        let width = baseCG.width
        let height = baseCG.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        // Fill with black
        context.setFillColor(fillColor.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Apply mask to show only dinosaur shape
        if let maskImage = CGImage(
            maskWidth: maskCG.width,
            height: maskCG.height,
            bitsPerComponent: maskCG.bitsPerComponent,
            bitsPerPixel: maskCG.bitsPerPixel,
            bytesPerRow: maskCG.bytesPerRow,
            provider: maskCG.dataProvider!,
            decode: nil,
            shouldInterpolate: false
        ) {
            context.clip(to: CGRect(x: 0, y: 0, width: width, height: height), mask: maskImage)
            context.setFillColor(fillColor.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        guard let outputCG = context.makeImage() else { return nil }
        return UIImage(cgImage: outputCG, scale: self.scale, orientation: self.imageOrientation)
    }
    
    /// Creates a partial view showing only specified region
    func createPartialView(region: CGRect, blurEdges: Bool = true) -> UIImage? {
        // Implementation
        // Mask everything except the specified region
        // Optionally blur edges for smooth transition
    }
}
```

#### Usage Example

```swift
// Load base image
let baseImage = UIImage(named: "trex_full")!

// Load mask (dinosaur shape = white/opaque, background = transparent)
let maskImage = UIImage(named: "trex_mask")!

// Create silhouette
if let silhouette = baseImage.createSilhouette(using: maskImage) {
    // Save or use in game
    imageView.image = silhouette
}
```

## Asset Organization

### File Structure

```
Assets/
├── Dinosaurs/
│   ├── Base/
│   │   ├── trex_full.png
│   │   ├── triceratops_full.png
│   │   └── ...
│   ├── Silhouettes/
│   │   ├── trex_silhouette.png
│   │   ├── triceratops_silhouette.png
│   │   └── ...
│   ├── Partial/
│   │   ├── trex_head_only.png
│   │   ├── trex_tail_only.png
│   │   └── ...
│   ├── Scenes/
│   │   ├── forest_scene_1.png
│   │   ├── forest_scene_2.png
│   │   └── ...
│   └── Masks/
│       ├── trex_mask.png
│       └── ...
```

### Naming Convention

- Base: `[dinosaur]_full.png`
- Silhouette: `[dinosaur]_silhouette.png`
- Partial: `[dinosaur]_[part].png` (e.g., `trex_head.png`)
- Scene: `scene_[location]_[id].png`
- Mask: `[dinosaur]_mask.png`

## Optimization

### Format Conversion
- Convert PNG to HEIF/HEIC for 30-50% size reduction
- Use Asset Catalog with @1x, @2x, @3x variants
- Compress using ImageOptim or pngquant

### Size Estimates
- Base image: ~100-200 KB (HEIF)
- Silhouette: ~50-100 KB (simpler, less detail)
- Partial view: ~75-150 KB
- Scene: ~150-300 KB

**For 30 dinosaurs with variations**: ~15-30 MB total

## Quality Checklist

- [ ] Consistent art style across all images
- [ ] Bright, child-friendly colors
- [ ] Simple shapes, easy to recognize
- [ ] Clear, bold outlines
- [ ] Transparent or clean backgrounds
- [ ] All variations created from same base
- [ ] Optimized file sizes
- [ ] @1x, @2x, @3x variants created
- [ ] Tested on actual devices

## Tools & Resources

### Image Generation
- Midjourney: https://www.midjourney.com
- Stable Diffusion: https://stability.ai
- DALL·E 3: https://openai.com/dall-e-3

### Image Editing
- ImageOptim: https://imageoptim.com (compression)
- GIMP/Photoshop: Manual masking/editing
- Swift/Core Image: Programmatic processing

### Image Segmentation (Auto-masking)
- Remove.bg API: Automatic background removal
- Core ML models: On-device segmentation
- Manual: Use image editing software

## Next Steps

1. Choose image generation tool (Midjourney recommended)
2. Create style reference image
3. Generate test set (5-10 dinosaurs)
4. Test silhouette/partial view creation
5. Refine workflow based on results
6. Generate full set (30 dinosaurs)
7. Optimize and integrate into app
