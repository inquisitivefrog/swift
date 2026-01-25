# Skeleton & Anatomy Features

## Overview

Create educational content focusing on dinosaur bones and anatomy:
1. Dinosaur skeleton inside silhouette
2. Highlighted individual bones (femur, ribs, etc.)
3. Size comparisons (bone vs child)
4. Educational information about bone features (air sacs, weight reduction, etc.)

## Concept

### Image 1: Full Skeleton in Silhouette
```
┌─────────────────────────────────────────┐
│                                         │
│     🦴 Skeleton Outline                │
│     (inside dinosaur silhouette)        │
│                                         │
│     Shows full bone structure          │
│                                         │
└─────────────────────────────────────────┘
```

### Image 2: Highlighted Bone
```
┌─────────────────────────────────────────┐
│                                         │
│     🦴 Skeleton with                   │
│     ⭐ Femur highlighted               │
│     (glowing/highlighted)              │
│                                         │
└─────────────────────────────────────────┘
```

## Implementation Approaches

### Option 1: Pre-Rendered Images (Recommended)

Create composite images showing:
- Dinosaur silhouette (outline)
- Skeleton inside silhouette
- Highlighted bone version

**Pros**:
- ✅ Best visual quality
- ✅ Consistent style
- ✅ Easy to implement
- ✅ Can be created with AI + image editing

**Cons**:
- ⚠️ More image assets needed
- ⚠️ Less flexible

### Option 2: Programmatic Composition

Layer images programmatically:
- Base: Dinosaur silhouette
- Overlay: Skeleton image (with transparency)
- Highlight: Colored overlay for specific bone

**Pros**:
- ✅ More flexible
- ✅ Can highlight different bones dynamically
- ✅ Fewer base assets needed

**Cons**:
- ⚠️ More complex implementation
- ⚠️ Requires precise image alignment

### Option 3: Vector Graphics

Use SVG/PDF vector graphics for skeletons.

**Pros**:
- ✅ Scalable without quality loss
- ✅ Can programmatically highlight bones
- ✅ Smaller file sizes

**Cons**:
- ⚠️ More complex to create
- ⚠️ Requires vector graphics skills

## SwiftUI Implementation

### Skeleton View Component

```swift
import SwiftUI

struct SkeletonView: View {
    let dinosaur: Dinosaur
    let highlightedBone: BoneType?
    @State private var showLabels = false
    
    var body: some View {
        ZStack {
            // Background: Dinosaur silhouette
            Image("\(dinosaur.name.lowercased())_silhouette")
                .resizable()
                .scaledToFit()
                .foregroundColor(.black.opacity(0.1))
            
            // Skeleton overlay
            Image("\(dinosaur.name.lowercased())_skeleton")
                .resizable()
                .scaledToFit()
                .renderingMode(.template)
                .foregroundColor(.white)
            
            // Highlighted bone (if any)
            if let bone = highlightedBone {
                BoneHighlightView(
                    bone: bone,
                    dinosaur: dinosaur
                )
            }
        }
    }
}

enum BoneType: String, CaseIterable {
    case femur = "Femur"
    case rib = "Rib"
    case skull = "Skull"
    case spine = "Spine"
    case tail = "Tail"
    
    var description: String {
        switch self {
        case .femur:
            return "The thigh bone. It's the biggest bone in the body!"
        case .rib:
            return "These bones protect the lungs and have holes for air sacs to make the dinosaur lighter!"
        case .skull:
            return "This protects the brain!"
        case .spine:
            return "The backbone holds everything together!"
        case .tail:
            return "The tail helps with balance!"
        }
    }
    
    var icon: String {
        switch self {
        case .femur: return "🦴"
        case .rib: return "🦴"
        case .skull: return "💀"
        case .spine: return "🦴"
        case .tail: return "🦴"
        }
    }
}
```

### Bone Highlight Component

```swift
struct BoneHighlightView: View {
    let bone: BoneType
    let dinosaur: Dinosaur
    
    var body: some View {
        // Option 1: Use separate image with highlighted bone
        Image("\(dinosaur.name.lowercased())_skeleton_\(bone.rawValue.lowercased())_highlighted")
            .resizable()
            .scaledToFit()
            .overlay(
                // Glow effect
                Image("\(dinosaur.name.lowercased())_skeleton_\(bone.rawValue.lowercased())_highlighted")
                    .resizable()
                    .scaledToFit()
                    .blur(radius: 10)
                    .opacity(0.5)
            )
        
        // Option 2: Programmatic highlight using mask
        // (see below)
    }
}
```

### Programmatic Bone Highlighting

```swift
struct ProgrammaticBoneHighlight: View {
    let bone: BoneType
    let dinosaur: Dinosaur
    
    var body: some View {
        ZStack {
            // Base skeleton
            Image("\(dinosaur.name.lowercased())_skeleton")
                .resizable()
                .scaledToFit()
            
            // Highlighted bone mask
            Image("\(dinosaur.name.lowercased())_\(bone.rawValue.lowercased())_mask")
                .resizable()
                .scaledToFit()
                .blendMode(.screen)
                .overlay(
                    // Glow effect
                    Image("\(dinosaur.name.lowercased())_\(bone.rawValue.lowercased())_mask")
                        .resizable()
                        .scaledToFit()
                        .blur(radius: 15)
                        .opacity(0.6)
                )
        }
    }
}
```

## Size Comparison: Bone vs Child

### Femur Comparison View

```swift
struct BoneSizeComparisonView: View {
    let dinosaur: Dinosaur
    let bone: BoneType
    let boneLengthFeet: Double
    
    // Reference: 4-foot child
    let childHeightFeet: Double = 4.0
    let childHeightPixels: CGFloat = 100
    
    var boneLengthPixels: CGFloat {
        let ratio = boneLengthFeet / childHeightFeet
        return childHeightPixels * CGFloat(ratio)
    }
    
    var body: some View {
        VStack {
            Text("How big was a \(dinosaur.name) \(bone.rawValue)?")
                .font(.title)
                .padding()
            
            // Comparison area
            HStack(spacing: 40) {
                // Child reference
                VStack {
                    ChildSilhouette(type: .boy, height: childHeightPixels)
                    Text("You")
                        .font(.caption)
                }
                
                // Bone
                VStack {
                    BoneImage(
                        bone: bone,
                        length: boneLengthPixels
                    )
                    Text("\(bone.rawValue)")
                        .font(.caption)
                }
            }
            .padding()
            
            // Audio explanation
            Button(action: {
                playBoneComparisonAudio(dinosaur: dinosaur, bone: bone, length: boneLengthFeet)
            }) {
                HStack {
                    Image(systemName: "speaker.wave.2")
                    Text("Listen")
                }
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    func playBoneComparisonAudio(dinosaur: Dinosaur, bone: BoneType, length: Double) {
        let childLength = 1.5 // Approximate child femur length in feet
        let times = Int(length / childLength)
        
        let text = """
        A \(dinosaur.name) \(bone.rawValue.lowercased()) was \(Int(length)) feet long. 
        That's \(times) times longer than your \(bone.rawValue.lowercased())!
        """
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.4
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}
```

### Bone Image Component

```swift
struct BoneImage: View {
    let bone: BoneType
    let length: CGFloat
    
    var body: some View {
        Image("\(bone.rawValue.lowercased())_bone")
            .resizable()
            .scaledToFit()
            .frame(height: length)
            .rotationEffect(.degrees(bone == .femur ? 0 : 90)) // Horizontal for long bones
    }
}
```

## Educational Content: Air Sacs in Ribs

### Rib with Air Sac Holes View

```swift
struct RibAirSacsView: View {
    let dinosaur: Dinosaur
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Why do dinosaur ribs have holes?")
                .font(.title)
                .padding()
            
            // Rib image with highlighted air sac holes
            ZStack {
                // Full skeleton
                SkeletonView(
                    dinosaur: dinosaur,
                    highlightedBone: .rib
                )
                .frame(height: 300)
                
                // Close-up of rib with holes
                VStack {
                    Image("rib_with_air_sacs")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .overlay(
                            // Highlight air sac holes
                            ForEach(0..<5) { _ in
                                Circle()
                                    .fill(Color.yellow.opacity(0.5))
                                    .frame(width: 10, height: 10)
                                    .offset(x: CGFloat.random(in: -50...50),
                                           y: CGFloat.random(in: -30...30))
                            }
                        )
                    
                    Text("Air sac holes")
                        .font(.caption)
                }
            }
            .padding()
            
            // Explanation
            VStack(alignment: .leading, spacing: 10) {
                Text("Did you know?")
                    .font(.headline)
                
                Text("Dinosaur ribs have special holes for air sacs. These air sacs made the dinosaur lighter so it could move easier!")
                    .font(.body)
            }
            .padding()
            
            // Audio explanation
            Button(action: {
                playAirSacsExplanation()
            }) {
                HStack {
                    Image(systemName: "speaker.wave.2")
                    Text("Listen")
                }
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    func playAirSacsExplanation() {
        let text = """
        Dinosaur ribs have special holes called air sacs. 
        These air sacs made the dinosaur lighter, like having balloons inside! 
        That's why big dinosaurs could still move around easily.
        """
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.4
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}
```

## Interactive Bone Explorer

### Tap to Highlight Bones

```swift
struct InteractiveSkeletonView: View {
    let dinosaur: Dinosaur
    @State private var selectedBone: BoneType?
    
    var body: some View {
        VStack {
            Text("Tap a bone to learn about it!")
                .font(.title)
                .padding()
            
            // Skeleton with tappable bones
            SkeletonView(
                dinosaur: dinosaur,
                highlightedBone: selectedBone
            )
            .frame(height: 400)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        // Detect which bone was tapped
                        let tappedBone = detectBone(at: value.location)
                        selectedBone = tappedBone
                        
                        // Play audio about the bone
                        if let bone = tappedBone {
                            playBoneInfo(bone: bone)
                        }
                    }
            )
            
            // Bone information
            if let bone = selectedBone {
                VStack(alignment: .leading) {
                    Text(bone.rawValue)
                        .font(.headline)
                    Text(bone.description)
                        .font(.body)
                }
                .padding()
            }
        }
    }
    
    func detectBone(at location: CGPoint) -> BoneType? {
        // Use hit testing or bone region masks
        // This would require bone region data
        // For now, return based on approximate regions
        if location.y < 100 { return .skull }
        if location.y < 200 { return .rib }
        if location.y < 300 { return .spine }
        if location.y < 400 { return .femur }
        return .tail
    }
    
    func playBoneInfo(bone: BoneType) {
        let text = "This is the \(bone.rawValue.lowercased()). \(bone.description)"
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.4
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}
```

## Asset Creation Strategy

### Skeleton Images

**Option 1: AI Generation + Editing**
1. Generate dinosaur silhouette
2. Generate skeleton image (or find reference)
3. Composite skeleton inside silhouette
4. Create highlighted versions for each bone

**Prompt for AI**:
```
Dinosaur skeleton inside silhouette outline, educational illustration, 
black skeleton on white background, clear bone structure visible, 
suitable for children ages 4-6, simple clean style
```

**Option 2: Vector Graphics**
- Create skeleton as vector (SVG/PDF)
- Can programmatically highlight bones
- Scalable without quality loss

**Option 3: Image Editing**
- Start with skeleton reference image
- Place inside silhouette
- Create masks for individual bones
- Add glow/highlight effects

### Bone Masks

Create separate mask images for each bone:
- `trex_femur_mask.png` (white where femur is, transparent elsewhere)
- `trex_rib_mask.png`
- etc.

Use masks to highlight bones programmatically.

### Bone Size Data

```swift
struct BoneData {
    let bone: BoneType
    let lengthFeet: Double
    let widthFeet: Double?
    let specialFeatures: [String] // e.g., "air sac holes"
}

let trexBoneData: [BoneType: BoneData] = [
    .femur: BoneData(bone: .femur, lengthFeet: 4.0, widthFeet: 0.5, specialFeatures: []),
    .rib: BoneData(bone: .rib, lengthFeet: 3.0, widthFeet: 0.3, specialFeatures: ["air sac holes"]),
    // ... more bones
]
```

## Educational Features

### Bone Facts

```swift
struct BoneFact {
    let bone: BoneType
    let fact: String
    let audioText: String
}

let boneFacts: [BoneType: BoneFact] = [
    .femur: BoneFact(
        bone: .femur,
        fact: "The femur is the biggest bone in the body!",
        audioText: "The femur is the biggest bone in the body. It's in your leg!"
    ),
    .rib: BoneFact(
        bone: .rib,
        fact: "Ribs have holes for air sacs to make dinosaurs lighter!",
        audioText: "Dinosaur ribs have special holes for air sacs. These made the dinosaur lighter, like having balloons inside!"
    ),
    // ... more facts
]
```

### Size Comparison Examples

**Femur**:
- T-Rex femur: ~4 feet long
- Child femur: ~1.5 feet long
- Comparison: "A T-Rex femur was almost 3 times longer than your femur!"

**Rib**:
- T-Rex rib: ~3 feet long
- Child rib: ~0.5 feet long
- Comparison: "A T-Rex rib was 6 times longer than your rib!"

## Complete Feature View

```swift
struct SkeletonAnatomyView: View {
    let dinosaur: Dinosaur
    @State private var viewMode: ViewMode = .fullSkeleton
    @State private var selectedBone: BoneType?
    
    enum ViewMode {
        case fullSkeleton
        case highlightedBone
        case sizeComparison
        case airSacs
    }
    
    var body: some View {
        VStack {
            // Mode selector (for parents/adults, or simple for children)
            Picker("View", selection: $viewMode) {
                Text("Skeleton").tag(ViewMode.fullSkeleton)
                Text("Bones").tag(ViewMode.highlightedBone)
                Text("Size").tag(ViewMode.sizeComparison)
                Text("Air Sacs").tag(ViewMode.airSacs)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content based on mode
            switch viewMode {
            case .fullSkeleton:
                SkeletonView(dinosaur: dinosaur, highlightedBone: nil)
            case .highlightedBone:
                BoneSelectorView(dinosaur: dinosaur, selectedBone: $selectedBone)
            case .sizeComparison:
                if let bone = selectedBone {
                    BoneSizeComparisonView(dinosaur: dinosaur, bone: bone, boneLengthFeet: getBoneLength(bone))
                }
            case .airSacs:
                RibAirSacsView(dinosaur: dinosaur)
            }
        }
    }
    
    func getBoneLength(_ bone: BoneType) -> Double {
        // Get bone length from data
        return 4.0 // Example
    }
}
```

## Summary

✅ **Fully Possible!**

**Key Components**:
1. Skeleton inside silhouette (composite image)
2. Highlighted bone versions (separate images or programmatic)
3. Size comparisons (bone vs child)
4. Educational content (air sacs, bone facts)
5. Interactive exploration (tap to learn about bones)

**Asset Requirements**:
- Dinosaur silhouettes
- Skeleton images (inside silhouettes)
- Highlighted bone versions (one per bone type)
- Bone masks (for programmatic highlighting)
- Bone size data

**Benefits**:
- Educational (learns about dinosaur anatomy)
- Visual (clear skeleton structure)
- Interactive (tap to explore)
- Audio-supported (spoken explanations)
- Child-friendly (visual, no reading required)
- Age-appropriate (simplified anatomy concepts)

This creates an engaging educational feature that teaches children about dinosaur bones and anatomy!
