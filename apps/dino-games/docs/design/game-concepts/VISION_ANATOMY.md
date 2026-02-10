# Vision & Anatomy: Eye Position and Vision Types

## Overview

Create educational content showing dinosaur skulls to explain vision capabilities:
1. **Stereo-optic vision** (binocular): Forward-facing eyes → can track movement AND estimate distance (like T-Rex)
2. **Monocular vision**: Side-facing eyes → can see movement but NOT estimate distance well (like many herbivores)

## Concept

### Skull with Eye Sockets Highlighted

```
┌─────────────────────────────────────────┐
│                                         │
│     💀 Dinosaur Skull                  │
│     [Eye sockets highlighted]          │
│                                         │
│     "Look at where the eyes are!"      │
│                                         │
└─────────────────────────────────────────┘
```

### Vision Type Comparison

```
┌─────────────────────────────────────────┐
│  T-Rex (Forward Eyes)                  │
│  👁️    👁️                              │
│  "Can see distance!"                    │
│                                         │
│  Triceratops (Side Eyes)                │
│  👁️         👁️                         │
│  "Can see movement!"                    │
└─────────────────────────────────────────┘
```

## SwiftUI Implementation

### Vision Type Data Model

```swift
enum VisionType {
    case stereoOptic  // Forward-facing eyes (binocular vision)
    case monocular    // Side-facing eyes (peripheral vision)
    
    var description: String {
        switch self {
        case .stereoOptic:
            return "Forward-facing eyes let this dinosaur see distance and track movement!"
        case .monocular:
            return "Side-facing eyes let this dinosaur see movement all around, but not distance well!"
        }
    }
    
    var audioDescription: String {
        switch self {
        case .stereoOptic:
            return "This dinosaur has eyes in the front, like you! It can see how far away things are and track movement. That's why it's a good hunter!"
        case .monocular:
            return "This dinosaur has eyes on the sides of its head. It can see movement all around, but it's harder to tell how far away things are. That's why it needs to watch for danger!"
        }
    }
}

struct DinosaurVision {
    let dinosaur: Dinosaur
    let visionType: VisionType
    let eyeSocketPosition: EyePosition
    let skullImage: String
    let visionExplanation: String
}

struct EyePosition {
    let leftEye: CGPoint  // Position on skull
    let rightEye: CGPoint
    let isForwardFacing: Bool
    
    var visionField: VisionField {
        if isForwardFacing {
            return .binocular(overlap: 0.6) // 60% overlap
        } else {
            return .peripheral(overlap: 0.1) // 10% overlap
        }
    }
}

enum VisionField {
    case binocular(overlap: Double)  // Forward-facing, overlapping vision
    case peripheral(overlap: Double) // Side-facing, minimal overlap
}
```

### Skull Vision View

```swift
import SwiftUI

struct SkullVisionView: View {
    let dinosaurVision: DinosaurVision
    @State private var showVisionField = false
    @State private var showExplanation = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("How did \(dinosaurVision.dinosaur.name) see?")
                .font(.title)
                .padding()
            
            // Skull image with eye sockets
            ZStack {
                // Base skull image
                Image(dinosaurVision.skullImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                
                // Highlighted eye sockets
                EyeSocketOverlay(
                    eyePosition: dinosaurVision.eyeSocketPosition,
                    visionType: dinosaurVision.visionType
                )
                
                // Vision field visualization (optional)
                if showVisionField {
                    VisionFieldOverlay(
                        eyePosition: dinosaurVision.eyeSocketPosition,
                        visionType: dinosaurVision.visionType
                    )
                }
            }
            .padding()
            
            // Toggle vision field
            Button(action: {
                withAnimation {
                    showVisionField.toggle()
                }
            }) {
                Text(showVisionField ? "Hide Vision" : "Show Vision Field")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            // Explanation
            VStack(alignment: .leading, spacing: 10) {
                Text(dinosaurVision.visionType == .stereoOptic ? "Forward Eyes" : "Side Eyes")
                    .font(.headline)
                
                Text(dinosaurVision.visionType.description)
                    .font(.body)
            }
            .padding()
            
            // Audio explanation
            Button(action: {
                playVisionExplanation(dinosaurVision: dinosaurVision)
            }) {
                HStack {
                    Image(systemName: "speaker.wave.2")
                    Text("Listen")
                }
                .font(.headline)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    func playVisionExplanation(dinosaurVision: DinosaurVision) {
        let text = """
        \(dinosaurVision.dinosaur.name) had \(dinosaurVision.visionType == .stereoOptic ? "forward-facing" : "side-facing") eyes. 
        \(dinosaurVision.visionType.audioDescription)
        """
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.4
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}
```

### Eye Socket Overlay

```swift
struct EyeSocketOverlay: View {
    let eyePosition: EyePosition
    let visionType: VisionType
    
    var body: some View {
        ZStack {
            // Left eye socket
            Circle()
                .fill(Color.yellow.opacity(0.5))
                .frame(width: 30, height: 30)
                .position(eyePosition.leftEye)
                .overlay(
                    Circle()
                        .stroke(Color.yellow, lineWidth: 3)
                        .frame(width: 30, height: 30)
                        .position(eyePosition.leftEye)
                )
            
            // Right eye socket
            Circle()
                .fill(Color.yellow.opacity(0.5))
                .frame(width: 30, height: 30)
                .position(eyePosition.rightEye)
                .overlay(
                    Circle()
                        .stroke(Color.yellow, lineWidth: 3)
                        .frame(width: 30, height: 30)
                        .position(eyePosition.rightEye)
                )
            
            // Connection line (shows if forward or side-facing)
            if eyePosition.isForwardFacing {
                // Forward-facing: eyes closer together
                Path { path in
                    path.move(to: eyePosition.leftEye)
                    path.addLine(to: eyePosition.rightEye)
                }
                .stroke(Color.green, lineWidth: 2)
            } else {
                // Side-facing: eyes far apart
                Path { path in
                    path.move(to: eyePosition.leftEye)
                    path.addLine(to: eyePosition.rightEye)
                }
                .stroke(Color.blue, lineWidth: 2)
                .opacity(0.5) // Lighter line for side-facing
            }
        }
    }
}
```

### Vision Field Overlay

```swift
struct VisionFieldOverlay: View {
    let eyePosition: EyePosition
    let visionType: VisionType
    
    var body: some View {
        ZStack {
            if visionType == .stereoOptic {
                // Binocular vision field (forward-facing)
                BinocularVisionField(eyePosition: eyePosition)
            } else {
                // Peripheral vision field (side-facing)
                PeripheralVisionField(eyePosition: eyePosition)
            }
        }
    }
}

struct BinocularVisionField: View {
    let eyePosition: EyePosition
    
    var body: some View {
        // Forward-facing vision cone
        Path { path in
            let centerX = (eyePosition.leftEye.x + eyePosition.rightEye.x) / 2
            let centerY = (eyePosition.leftEye.y + eyePosition.rightEye.y) / 2
            let center = CGPoint(x: centerX, y: centerY)
            
            // Create forward-facing cone
            let angle: CGFloat = 60 // degrees
            let distance: CGFloat = 200
            
            path.move(to: center)
            path.addArc(
                center: center,
                radius: distance,
                startAngle: .degrees(-angle/2),
                endAngle: .degrees(angle/2),
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(Color.green.opacity(0.2))
        .stroke(Color.green, lineWidth: 2)
    }
}

struct PeripheralVisionField: View {
    let eyePosition: EyePosition
    
    var body: some View {
        // Side-facing vision fields (left and right)
        ZStack {
            // Left eye vision field
            Path { path in
                let angle: CGFloat = 120 // Wide angle
                let distance: CGFloat = 200
                
                path.move(to: eyePosition.leftEye)
                path.addArc(
                    center: eyePosition.leftEye,
                    radius: distance,
                    startAngle: .degrees(180 - angle/2),
                    endAngle: .degrees(180 + angle/2),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(Color.blue.opacity(0.2))
            .stroke(Color.blue, lineWidth: 2)
            
            // Right eye vision field
            Path { path in
                let angle: CGFloat = 120
                let distance: CGFloat = 200
                
                path.move(to: eyePosition.rightEye)
                path.addArc(
                    center: eyePosition.rightEye,
                    radius: distance,
                    startAngle: .degrees(-angle/2),
                    endAngle: .degrees(angle/2),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(Color.blue.opacity(0.2))
            .stroke(Color.blue, lineWidth: 2)
        }
    }
}
```

## Comparison View

### Side-by-Side Vision Comparison

```swift
struct VisionComparisonView: View {
    let predator: DinosaurVision  // T-Rex (stereo-optic)
    let herbivore: DinosaurVision // Triceratops (monocular)
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Compare How Dinosaurs See")
                .font(.title)
                .padding()
            
            HStack(spacing: 40) {
                // Predator (forward eyes)
                VStack {
                    Text(predator.dinosaur.name)
                        .font(.headline)
                    
                    SkullVisionView(dinosaurVision: predator)
                        .frame(width: 300)
                    
                    Text("Can see distance!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                // Herbivore (side eyes)
                VStack {
                    Text(herbivore.dinosaur.name)
                        .font(.headline)
                    
                    SkullVisionView(dinosaurVision: herbivore)
                        .frame(width: 300)
                    
                    Text("Can see movement!")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            
            // Comparison explanation
            VStack(alignment: .leading, spacing: 10) {
                Text("Did you know?")
                    .font(.headline)
                
                Text("""
                Hunters like \(predator.dinosaur.name) have forward-facing eyes to see distance and track prey.
                
                Plant-eaters like \(herbivore.dinosaur.name) have side-facing eyes to see danger coming from all sides!
                """)
                .font(.body)
            }
            .padding()
            
            // Audio comparison
            Button(action: {
                playComparisonAudio(predator: predator, herbivore: herbivore)
            }) {
                HStack {
                    Image(systemName: "speaker.wave.2")
                    Text("Listen to Comparison")
                }
                .font(.headline)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    func playComparisonAudio(predator: DinosaurVision, herbivore: DinosaurVision) {
        let text = """
        \(predator.dinosaur.name) has forward-facing eyes, like you! It can see how far away things are. 
        That's why it's a good hunter!
        
        \(herbivore.dinosaur.name) has eyes on the sides of its head. It can see movement all around, 
        but it's harder to tell distance. That's why it needs to watch for danger from all sides!
        """
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.4
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}
```

## Interactive Exploration

### Tap to Learn About Vision

```swift
struct InteractiveVisionExplorer: View {
    @State private var selectedDinosaur: DinosaurVision?
    
    let allDinosaurs: [DinosaurVision] = [
        DinosaurVision(
            dinosaur: Dinosaur(id: 1, name: "T-Rex"),
            visionType: .stereoOptic,
            eyeSocketPosition: EyePosition(
                leftEye: CGPoint(x: 150, y: 100),
                rightEye: CGPoint(x: 170, y: 100),
                isForwardFacing: true
            ),
            skullImage: "trex_skull",
            visionExplanation: "Forward eyes help T-Rex hunt!"
        ),
        DinosaurVision(
            dinosaur: Dinosaur(id: 2, name: "Triceratops"),
            visionType: .monocular,
            eyeSocketPosition: EyePosition(
                leftEye: CGPoint(x: 100, y: 120),
                rightEye: CGPoint(x: 250, y: 120),
                isForwardFacing: false
            ),
            skullImage: "triceratops_skull",
            visionExplanation: "Side eyes help Triceratops watch for danger!"
        )
        // ... more dinosaurs
    ]
    
    var body: some View {
        VStack {
            Text("Tap a dinosaur to learn about its vision!")
                .font(.title)
                .padding()
            
            // Dinosaur selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(allDinosaurs, id: \.dinosaur.id) { dinoVision in
                        DinosaurCard(
                            dinosaur: dinoVision.dinosaur,
                            isSelected: selectedDinosaur?.dinosaur.id == dinoVision.dinosaur.id,
                            onTap: {
                                selectedDinosaur = dinoVision
                                playVisionExplanation(dinosaurVision: dinoVision)
                            }
                        )
                    }
                }
                .padding()
            }
            
            // Selected dinosaur vision view
            if let selected = selectedDinosaur {
                SkullVisionView(dinosaurVision: selected)
            }
        }
    }
}
```

## Educational Content

### Vision Type Explanations

```swift
struct VisionExplanation {
    let visionType: VisionType
    let advantages: [String]
    let disadvantages: [String]
    let exampleDinosaurs: [String]
    
    static let stereoOptic = VisionExplanation(
        visionType: .stereoOptic,
        advantages: [
            "Can see distance (depth perception)",
            "Can track moving objects",
            "Good for hunting"
        ],
        disadvantages: [
            "Limited side vision",
            "Can't see behind easily"
        ],
        exampleDinosaurs: ["T-Rex", "Velociraptor", "Allosaurus"]
    )
    
    static let monocular = VisionExplanation(
        visionType: .monocular,
        advantages: [
            "Can see all around (wide field of view)",
            "Good for spotting danger",
            "Can see movement from sides"
        ],
        disadvantages: [
            "Hard to judge distance",
            "Less depth perception"
        ],
        exampleDinosaurs: ["Triceratops", "Stegosaurus", "Brontosaurus"]
    )
}
```

## Asset Creation Strategy

### Skull Images

**Option 1: AI Generation**
- Generate dinosaur skull images
- Ensure eye sockets are clearly visible
- Consistent style across all skulls

**Prompt**:
```
Dinosaur skull, [species name], educational illustration, 
clear eye socket positions visible, side view or front view, 
suitable for children ages 4-6, simple clean style, white background
```

**Option 2: Reference Images + Editing**
- Use scientific reference images
- Simplify for children
- Highlight eye sockets clearly

### Eye Position Data

```swift
struct EyePositionData {
    let dinosaurName: String
    let leftEyeX: CGFloat
    let leftEyeY: CGFloat
    let rightEyeX: CGFloat
    let rightEyeY: CGFloat
    let isForwardFacing: Bool
}

let eyePositions: [String: EyePositionData] = [
    "T-Rex": EyePositionData(
        dinosaurName: "T-Rex",
        leftEyeX: 150,
        leftEyeY: 100,
        rightEyeX: 170,
        rightEyeY: 100,
        isForwardFacing: true
    ),
    "Triceratops": EyePositionData(
        dinosaurName: "Triceratops",
        leftEyeX: 100,
        leftEyeY: 120,
        rightEyeX: 250,
        rightEyeY: 120,
        isForwardFacing: false
    )
    // ... more dinosaurs
]
```

## Complete Feature View

```swift
struct VisionAnatomyFeature: View {
    @State private var selectedDinosaur: DinosaurVision?
    @State private var showComparison = false
    
    let dinosaurs: [DinosaurVision] = [
        // T-Rex (stereo-optic)
        DinosaurVision(...),
        // Triceratops (monocular)
        DinosaurVision(...)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                if showComparison {
                    VisionComparisonView(
                        predator: dinosaurs[0], // T-Rex
                        herbivore: dinosaurs[1] // Triceratops
                    )
                } else if let selected = selectedDinosaur {
                    SkullVisionView(dinosaurVision: selected)
                } else {
                    InteractiveVisionExplorer()
                }
                
                // Mode toggle
                HStack {
                    Button("Explore") {
                        showComparison = false
                    }
                    Button("Compare") {
                        showComparison = true
                    }
                }
                .padding()
            }
            .navigationTitle("Dinosaur Vision")
        }
    }
}
```

## Summary

✅ **Fully Possible!**

**Key Components**:
1. Skull images with eye sockets visible
2. Eye socket highlighting (visual overlay)
3. Vision field visualization (binocular vs peripheral)
4. Vision type explanations (stereo-optic vs monocular)
5. Comparison view (hunter vs herbivore)
6. Audio explanations

**Educational Value**:
- Teaches anatomy (eye position)
- Explains behavior (why hunters vs herbivores see differently)
- Visual learning (see the difference)
- Age-appropriate (simplified concepts)

**Benefits**:
- Educational (learns about vision and behavior)
- Visual (clear skull illustrations)
- Interactive (explore different dinosaurs)
- Audio-supported (spoken explanations)
- Child-friendly (visual, no reading required)
- Connects anatomy to behavior

This creates an engaging educational feature that teaches children about dinosaur vision and how eye position relates to behavior!
