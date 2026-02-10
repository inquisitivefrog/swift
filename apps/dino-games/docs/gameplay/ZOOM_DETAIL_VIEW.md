# Zoom Detail View: Highlighted Regions

## Overview

Create an educational feature that shows:
1. **Full dinosaur silhouette** with one region highlighted (head, tail, skin, etc.)
2. **Zoomed detail view** of the highlighted region showing specific features (skin pattern, teeth, spikes, etc.)
3. **Purpose**: Help children recognize these features for later matching games

## Concept

### Step 1: Full View with Highlight
```
┌─────────────────────────────────────────┐
│                                         │
│     🦕 Dinosaur Silhouette              │
│     [Head region highlighted]          │
│                                         │
│     "Tap to see the teeth!"            │
│                                         │
└─────────────────────────────────────────┘
```

### Step 2: Zoomed Detail View
```
┌─────────────────────────────────────────┐
│                                         │
│     🔍 Zoomed View                      │
│     [Close-up of teeth]                 │
│                                         │
│     "These are sharp teeth!"            │
│                                         │
└─────────────────────────────────────────┘
```

## SwiftUI Implementation

### Main View with Transition

```swift
import SwiftUI

struct ZoomDetailView: View {
    let dinosaur: Dinosaur
    @State private var showDetail = false
    @State private var highlightedRegion: BodyRegion?
    
    var body: some View {
        VStack {
            if !showDetail {
                // Full silhouette with highlight
                FullSilhouetteView(
                    dinosaur: dinosaur,
                    highlightedRegion: highlightedRegion ?? .head,
                    onRegionTap: { region in
                        withAnimation(.spring()) {
                            highlightedRegion = region
                            showDetail = true
                        }
                        playAudio("Let's look at the \(region.rawValue)!")
                    }
                )
            } else {
                // Zoomed detail view
                DetailZoomView(
                    dinosaur: dinosaur,
                    region: highlightedRegion ?? .head,
                    onBack: {
                        withAnimation(.spring()) {
                            showDetail = false
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

enum BodyRegion: String, CaseIterable {
    case head = "head"
    case teeth = "teeth"
    case skin = "skin"
    case tail = "tail"
    case spikes = "spikes"
    case crest = "crest"
    case feet = "feet"
    
    var displayName: String {
        switch self {
        case .head: return "head"
        case .teeth: return "teeth"
        case .skin: return "skin"
        case .tail: return "tail"
        case .spikes: return "spikes"
        case .crest: return "crest"
        case .feet: return "feet"
        }
    }
    
    var description: String {
        switch self {
        case .head: return "The head protects the brain!"
        case .teeth: return "These sharp teeth help the dinosaur eat!"
        case .skin: return "Look at this special pattern!"
        case .tail: return "The tail helps with balance!"
        case .spikes: return "These spikes protect the dinosaur!"
        case .crest: return "This crest helps the dinosaur show off!"
        case .feet: return "These feet help the dinosaur walk!"
        }
    }
}
```

### Full Silhouette with Highlight

```swift
struct FullSilhouetteView: View {
    let dinosaur: Dinosaur
    let highlightedRegion: BodyRegion
    let onRegionTap: (BodyRegion) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tap a part to see it up close!")
                .font(.title)
                .padding()
            
            // Dinosaur silhouette with highlighted region
            ZStack {
                // Base silhouette
                Image("\(dinosaur.name.lowercased())_silhouette")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 400)
                
                // Highlighted region overlay
                RegionHighlightOverlay(
                    dinosaur: dinosaur,
                    region: highlightedRegion
                )
            }
            .padding()
            
            // Region selector buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(BodyRegion.allCases, id: \.self) { region in
                        RegionButton(
                            region: region,
                            isSelected: highlightedRegion == region,
                            onTap: {
                                onRegionTap(region)
                            }
                        )
                    }
                }
                .padding()
            }
            
            // Audio instruction
            Button(action: {
                playAudio("Tap the \(highlightedRegion.displayName) to see it up close!")
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
}
```

### Region Highlight Overlay

```swift
struct RegionHighlightOverlay: View {
    let dinosaur: Dinosaur
    let region: BodyRegion
    
    var body: some View {
        // Option 1: Use pre-rendered highlight mask
        Image("\(dinosaur.name.lowercased())_\(region.rawValue)_highlight")
            .resizable()
            .scaledToFit()
            .frame(height: 400)
            .blendMode(.screen)
            .overlay(
                // Glow effect
                Image("\(dinosaur.name.lowercased())_\(region.rawValue)_highlight")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 400)
                    .blur(radius: 20)
                    .opacity(0.5)
            )
        
        // Option 2: Programmatic highlight using region coordinates
        // (see below)
    }
}
```

### Programmatic Region Highlighting

```swift
struct ProgrammaticRegionHighlight: View {
    let dinosaur: Dinosaur
    let region: BodyRegion
    
    // Region coordinates (defined per dinosaur)
    var regionRect: CGRect {
        // Get region bounds from data
        return getRegionBounds(for: dinosaur, region: region)
    }
    
    var body: some View {
        ZStack {
            // Base silhouette
            Image("\(dinosaur.name.lowercased())_silhouette")
                .resizable()
                .scaledToFit()
            
            // Highlight overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: regionRect.width, height: regionRect.height)
                .position(x: regionRect.midX, y: regionRect.midY)
                .blur(radius: 10)
                .overlay(
                    // Border
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.yellow, lineWidth: 4)
                        .frame(width: regionRect.width, height: regionRect.height)
                        .position(x: regionRect.midX, y: regionRect.midY)
                )
        }
    }
    
    func getRegionBounds(for dinosaur: Dinosaur, region: BodyRegion) -> CGRect {
        // This would come from data structure defining regions per dinosaur
        // Example data structure below
        return CGRect(x: 100, y: 50, width: 150, height: 100) // Example
    }
}
```

### Detail Zoom View

```swift
struct DetailZoomView: View {
    let dinosaur: Dinosaur
    let region: BodyRegion
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Back button
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .padding()
                }
                Spacer()
            }
            .padding()
            
            // Zoomed detail image
            Image("\(dinosaur.name.lowercased())_\(region.rawValue)_detail")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            
            // Description
            VStack(alignment: .leading, spacing: 10) {
                Text(region.displayName.capitalized)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(region.description)
                    .font(.body)
            }
            .padding()
            
            // Audio explanation
            Button(action: {
                playDetailAudio(dinosaur: dinosaur, region: region)
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
            .padding()
        }
    }
    
    func playDetailAudio(dinosaur: Dinosaur, region: BodyRegion) {
        let text = """
        This is a \(dinosaur.name) \(region.displayName). 
        \(region.description)
        Remember what this looks like - you'll see it in the matching game!
        """
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.4
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}
```

### Region Button Component

```swift
struct RegionButton: View {
    let region: BodyRegion
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Text(region.icon)
                    .font(.system(size: 40))
                
                Text(region.displayName.capitalized)
                    .font(.caption)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
        }
    }
}

extension BodyRegion {
    var icon: String {
        switch self {
        case .head: return "👤"
        case .teeth: return "🦷"
        case .skin: return "🦎"
        case .tail: return "🦴"
        case .spikes: return "🔺"
        case .crest: return "👑"
        case .feet: return "👣"
        }
    }
}
```

## Connecting to Matching Games

### Feature Recognition Data

```swift
struct DinosaurFeature {
    let region: BodyRegion
    let detailImage: String
    let description: String
    let matchingGameHint: String // For use in matching games
}

struct Dinosaur {
    let id: Int
    let name: String
    let features: [DinosaurFeature]
    
    // Example
    static let trex = Dinosaur(
        id: 1,
        name: "T-Rex",
        features: [
            DinosaurFeature(
                region: .teeth,
                detailImage: "trex_teeth_detail",
                description: "Sharp, serrated teeth for eating meat",
                matchingGameHint: "Look for the dinosaur with sharp, pointy teeth!"
            ),
            DinosaurFeature(
                region: .skin,
                detailImage: "trex_skin_detail",
                description: "Scaly skin with bumpy texture",
                matchingGameHint: "Look for the dinosaur with bumpy, scaly skin!"
            )
        ]
    )
}
```

### Integration with Matching Game

```swift
struct MatchingGameWithFeatures: View {
    let dinosaur: Dinosaur
    
    var body: some View {
        VStack {
            // Show feature detail as hint
            Text("Remember what you learned?")
                .font(.headline)
            
            // Show one of the detail images as a hint
            if let feature = dinosaur.features.randomElement() {
                Image(feature.detailImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                
                Text(feature.matchingGameHint)
                    .font(.body)
                    .padding()
                
                // Play audio hint
                Button(action: {
                    playAudio(feature.matchingGameHint)
                }) {
                    Text("Listen to hint")
                }
            }
            
            // Then show matching game options
            // (from previous matching game implementation)
        }
    }
}
```

## Asset Creation Strategy

### Image Types Needed

1. **Base Silhouette**
   - `trex_silhouette.png` - Full dinosaur outline

2. **Region Highlights**
   - `trex_head_highlight.png` - Head region highlighted
   - `trex_teeth_highlight.png` - Teeth region highlighted
   - `trex_skin_highlight.png` - Skin region highlighted
   - etc.

3. **Detail Zoom Images**
   - `trex_teeth_detail.png` - Close-up of teeth
   - `trex_skin_detail.png` - Close-up of skin pattern
   - `trex_head_detail.png` - Close-up of head
   - etc.

### Creation Workflow

**Option 1: AI Generation + Editing**
1. Generate dinosaur silhouette
2. Create region highlight overlays (in image editor)
3. Generate detail zoom images (close-up views)
4. Ensure consistent style

**Option 2: Image Editing**
1. Start with dinosaur reference image
2. Create silhouette version
3. Create region masks for highlighting
4. Crop/zoom regions for detail views
5. Add educational annotations

### AI Generation Prompts

**Detail Images**:
```
Close-up view of [dinosaur name] [body part], educational illustration, 
high detail, clear texture/pattern visible, suitable for children ages 4-6, 
simple clean style, white background
```

**Examples**:
- "Close-up view of T-Rex teeth, sharp serrated teeth, educational illustration"
- "Close-up view of Triceratops skin pattern, scaly texture, educational illustration"
- "Close-up view of Stegosaurus tail spikes, sharp pointed spikes, educational illustration"

## Animation & Transitions

### Smooth Zoom Transition

```swift
struct ZoomTransition: ViewModifier {
    let isZoomed: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isZoomed ? 3.0 : 1.0)
            .offset(x: isZoomed ? -100 : 0, y: isZoomed ? -150 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isZoomed)
    }
}
```

### Interactive Zoom Gesture

```swift
struct InteractiveZoomView: View {
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    var body: some View {
        Image("detail_image")
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = value
                    }
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    }
            )
    }
}
```

## Educational Flow

### Learning Sequence

1. **Introduction**
   - Show full silhouette
   - Audio: "Let's learn about the T-Rex! Tap different parts to see them up close."

2. **Region Selection**
   - Child taps a region (head, teeth, skin, etc.)
   - Region highlights
   - Audio: "You tapped the head! Let's look at it up close."

3. **Zoom Detail**
   - View zooms to detail
   - Shows close-up of feature
   - Audio: "These are sharp teeth! Remember what they look like."

4. **Connection to Games**
   - Audio: "You'll see these teeth in the matching game! Can you find the dinosaur with sharp teeth?"

## Complete Feature View

```swift
struct FeatureLearningView: View {
    let dinosaur: Dinosaur
    @State private var currentRegion: BodyRegion = .head
    @State private var showDetail = false
    
    var body: some View {
        NavigationView {
            VStack {
                if !showDetail {
                    FullSilhouetteView(
                        dinosaur: dinosaur,
                        highlightedRegion: currentRegion,
                        onRegionTap: { region in
                            currentRegion = region
                            showDetail = true
                        }
                    )
                } else {
                    DetailZoomView(
                        dinosaur: dinosaur,
                        region: currentRegion,
                        onBack: {
                            showDetail = false
                        }
                    )
                }
            }
            .navigationTitle(dinosaur.name)
        }
    }
}
```

## Summary

✅ **Fully Possible!**

**Key Components**:
1. Full silhouette with highlighted regions
2. Region selection (tap to highlight)
3. Zoom transition to detail view
4. Close-up detail images (teeth, skin, etc.)
5. Audio explanations
6. Connection to matching games

**Asset Requirements**:
- Dinosaur silhouettes
- Region highlight overlays (one per region)
- Detail zoom images (close-ups of each region)
- Region coordinate data (for programmatic highlighting)

**Benefits**:
- Educational (learns to recognize features)
- Prepares for matching games
- Visual (clear feature details)
- Interactive (tap to explore)
- Audio-supported (spoken explanations)
- Child-friendly (visual, no reading required)

**Connection to Matching Games**:
- Children learn to recognize features (teeth, skin patterns, etc.)
- These features appear in matching games
- "Find the dinosaur with sharp teeth" becomes easier after learning

This creates an educational feature that prepares children for matching games by teaching them to recognize specific dinosaur features!
