# Fossil Identification: Bone Color vs Matrix Rock Color

## Overview

Educational feature teaching children to identify fossils by recognizing the color difference between fossil bone and the surrounding matrix rock (sandstone, mudstone, limestone, siltstone, claystone, shale, tuffstone).

## Concept

**Visual Learning**: Children learn to spot fossils by recognizing:
- **Fossil bone color**: Typically different from surrounding rock
- **Matrix rock color**: Varies by rock type (sandstone = tan/beige, limestone = gray/white, etc.)

## Rock Types & Colors

```swift
enum RockType: String, CaseIterable {
    case sandstone    // Tan, beige, yellow
    case mudstone    // Gray, brown
    case limestone   // Gray, white, cream
    case siltstone   // Gray, brown
    case claystone   // Red, brown, gray
    case shale       // Dark gray, black, brown
    case tuffstone   // Light gray, tan
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var typicalColor: Color {
        switch self {
        case .sandstone: return Color(red: 0.9, green: 0.85, blue: 0.7) // Tan/beige
        case .mudstone: return Color(red: 0.6, green: 0.6, blue: 0.6) // Gray
        case .limestone: return Color(red: 0.85, green: 0.85, blue: 0.85) // Light gray/white
        case .siltstone: return Color(red: 0.65, green: 0.6, blue: 0.55) // Gray-brown
        case .claystone: return Color(red: 0.7, green: 0.5, blue: 0.4) // Red-brown
        case .shale: return Color(red: 0.3, green: 0.3, blue: 0.3) // Dark gray
        case .tuffstone: return Color(red: 0.75, green: 0.75, blue: 0.7) // Light gray-tan
        }
    }
    
    var icon: String {
        switch self {
        case .sandstone: return "🟨"
        case .mudstone: return "🟫"
        case .limestone: return "⬜"
        case .siltstone: return "🟫"
        case .claystone: return "🟥"
        case .shale: return "⬛"
        case .tuffstone: return "🟨"
        }
    }
}

struct FossilInMatrix {
    let boneColor: Color
    let matrixRock: RockType
    let boneShape: BoneShape
    let imageName: String
}

enum BoneShape {
    case longBone    // Femur, tibia
    case roundBone   // Vertebra, skull
    case flatBone    // Rib, plate
    case fragment    // Broken piece
}
```

## Visual Learning Feature

### Fossil Identification Game

```swift
import SwiftUI

struct FossilIdentificationView: View {
    @State private var currentFossil: FossilInMatrix?
    @State private var selectedBoneArea: CGRect?
    @State private var showHint = false
    @State private var isCorrect = false
    
    var body: some View {
        VStack {
            Text("Can you find the fossil bone?")
                .font(.title)
                .padding()
            
            // Fossil in matrix image
            if let fossil = currentFossil {
                ZStack {
                    // Matrix rock background
                    Rectangle()
                        .fill(fossil.matrixRock.typicalColor)
                        .frame(width: 400, height: 400)
                    
                    // Fossil bone (different color)
                    BoneShapeView(
                        shape: fossil.boneShape,
                        color: fossil.boneColor
                    )
                    .frame(width: 200, height: 100)
                    .position(x: 200, y: 200)
                    
                    // Tap detection overlay
                    GeometryReader { geometry in
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        checkTapLocation(value.location, fossil: fossil)
                                    }
                            )
                    }
                }
                .frame(width: 400, height: 400)
                .padding()
                
                // Rock type indicator
                HStack {
                    Text("Rock type:")
                        .font(.headline)
                    Text(fossil.matrixRock.displayName)
                        .foregroundColor(fossil.matrixRock.typicalColor)
                    Text(fossil.matrixRock.icon)
                }
                .padding()
                
                // Hint button
                Button(action: {
                    showHint.toggle()
                    playAudio("Look for the different color! The bone is a different color than the rock!")
                }) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                        Text("Hint")
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
                
                // Feedback
                if isCorrect {
                    Text("🎉 You found it! The bone is \(fossil.boneColor.description) and the rock is \(fossil.matrixRock.typicalColor.description)!")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding()
                }
            }
        }
        .onAppear {
            loadNewFossil()
        }
    }
    
    func checkTapLocation(_ location: CGPoint, fossil: FossilInMatrix) {
        // Check if tap is on bone area
        let boneArea = getBoneArea(for: fossil)
        if boneArea.contains(location) {
            isCorrect = true
            playAudio("That's right! You found the fossil bone! It's \(fossil.boneColor.description) and the rock is \(fossil.matrixRock.displayName)!")
            showCelebration()
            
            // Next fossil after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                loadNewFossil()
            }
        } else {
            playAudio("Try again! Look for a different color!")
        }
    }
    
    func loadNewFossil() {
        // Load new fossil with random rock type
        let rockType = RockType.allCases.randomElement()!
        currentFossil = createFossilInMatrix(rockType: rockType)
        isCorrect = false
        showHint = false
    }
}
```

### Bone Shape Views

```swift
struct BoneShapeView: View {
    let shape: BoneShape
    let color: Color
    
    var body: some View {
        Group {
            switch shape {
            case .longBone:
                LongBoneShape()
                    .fill(color)
            case .roundBone:
                Circle()
                    .fill(color)
            case .flatBone:
                FlatBoneShape()
                    .fill(color)
            case .fragment:
                FragmentShape()
                    .fill(color)
            }
        }
    }
}

struct LongBoneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Draw long bone shape (elongated with rounded ends)
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: rect.height/2, height: rect.height/2))
        return path
    }
}

struct FlatBoneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Draw flat bone shape (rib-like)
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 10, height: 10))
        return path
    }
}

struct FragmentShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Draw irregular fragment shape
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
```

## Rock Type Learning

### Rock Color Matching

```swift
struct RockColorMatchingView: View {
    @State private var targetRock: RockType?
    @State private var rockOptions: [RockType] = []
    @State private var selectedRock: RockType?
    
    var body: some View {
        VStack {
            Text("Match the rock color!")
                .font(.title)
                .padding()
            
            // Show rock name
            if let rock = targetRock {
                Text("Find \(rock.displayName)")
                    .font(.headline)
                    .padding()
                
                // Show color sample
                Rectangle()
                    .fill(rock.typicalColor)
                    .frame(width: 200, height: 100)
                    .cornerRadius(10)
                    .padding()
            }
            
            // Rock options
            HStack {
                ForEach(rockOptions, id: \.self) { rock in
                    RockColorCard(
                        rock: rock,
                        isSelected: selectedRock == rock,
                        onTap: {
                            selectedRock = rock
                            checkMatch()
                        }
                    )
                }
            }
            .padding()
        }
        .onAppear {
            setupRound()
        }
    }
    
    func setupRound() {
        targetRock = RockType.allCases.randomElement()
        rockOptions = RockType.allCases.shuffled().prefix(3).map { $0 }
    }
    
    func checkMatch() {
        if selectedRock == targetRock {
            playAudio("That's right! \(targetRock!.displayName) is \(targetRock!.typicalColor.description)!")
            showCelebration()
            nextRound()
        } else {
            playAudio("Try again! Look at the color carefully!")
        }
    }
}

struct RockColorCard: View {
    let rock: RockType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Rectangle()
                    .fill(rock.typicalColor)
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
                
                Text(rock.displayName)
                    .font(.caption)
            }
        }
    }
}
```

## Fossil Discovery Game

### "Find the Fossil" Game

```swift
struct FossilDiscoveryGame: View {
    @State private var currentRock: RockType = .sandstone
    @State private var fossils: [FossilInMatrix] = []
    @State private var foundFossils: Set<Int> = []
    @State private var score: Int = 0
    
    var body: some View {
        VStack {
            Text("Find all the fossils in the \(currentRock.displayName)!")
                .font(.title)
                .padding()
            
            // Rock sample with multiple fossils
            ZStack {
                // Rock background
                Rectangle()
                    .fill(currentRock.typicalColor)
                    .frame(width: 500, height: 500)
                
                // Multiple fossil bones (some visible, some hidden)
                ForEach(Array(fossils.enumerated()), id: \.offset) { index, fossil in
                    if !foundFossils.contains(index) {
                        BoneShapeView(
                            shape: fossil.boneShape,
                            color: fossil.boneColor
                        )
                        .frame(width: 80, height: 40)
                        .position(fossil.position)
                        .onTapGesture {
                            foundFossil(at: index)
                        }
                    } else {
                        // Show checkmark where fossil was
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.largeTitle)
                            .position(fossil.position)
                    }
                }
            }
            .frame(width: 500, height: 500)
            .padding()
            
            // Progress
            Text("Found: \(foundFossils.count) / \(fossils.count)")
                .font(.headline)
                .padding()
            
            // Score
            Text("Score: \(score)")
                .font(.headline)
        }
        .onAppear {
            setupRockSample()
        }
    }
    
    func setupRockSample() {
        // Create rock sample with 3-5 fossils
        let fossilCount = Int.random(in: 3...5)
        fossils = (0..<fossilCount).map { index in
            FossilInMatrix(
                boneColor: getBoneColor(for: currentRock),
                matrixRock: currentRock,
                boneShape: [.longBone, .roundBone, .flatBone, .fragment].randomElement()!,
                position: CGPoint(
                    x: CGFloat.random(in: 100...400),
                    y: CGFloat.random(in: 100...400)
                )
            )
        }
        foundFossils = []
    }
    
    func getBoneColor(for rock: RockType) -> Color {
        // Bone color should contrast with rock color
        switch rock {
        case .sandstone: return Color.brown // Dark brown on tan
        case .mudstone: return Color.white // White on gray
        case .limestone: return Color.brown // Brown on light gray
        case .siltstone: return Color.white // White on gray-brown
        case .claystone: return Color.white // White on red-brown
        case .shale: return Color.white // White on dark gray
        case .tuffstone: return Color.brown // Brown on light gray-tan
        }
    }
    
    func foundFossil(at index: Int) {
        foundFossils.insert(index)
        score += 100
        
        playAudio("Great! You found a fossil! Look for more!")
        
        if foundFossils.count == fossils.count {
            playAudio("Amazing! You found all the fossils! Great job, paleontologist!")
            showCelebration()
            nextRockSample()
        }
    }
    
    func nextRockSample() {
        currentRock = RockType.allCases.randomElement()!
        setupRockSample()
    }
}
```

## Educational Content

### Rock Type Facts (Max 3 per game)

```swift
struct RockTypeFacts {
    let rock: RockType
    let facts: [String] // Maximum 3
    
    static let sandstoneFacts = RockTypeFacts(
        rock: .sandstone,
        facts: [
            "Sandstone is tan or beige colored!",
            "Fossils in sandstone are often brown or dark!",
            "Sandstone is made from sand!"
        ]
    )
    
    static let limestoneFacts = RockTypeFacts(
        rock: .limestone,
        facts: [
            "Limestone is gray or white colored!",
            "Fossils in limestone are often brown!",
            "Limestone is made from shells!"
        ]
    )
}
```

### Audio Descriptions

```swift
func playRockTypeAudio(rock: RockType) {
    let text = """
    \(rock.displayName) is \(rock.typicalColor.description) colored!
    Fossils in \(rock.displayName) are often a different color.
    Can you spot the difference?
    """
    
    playAudio(text)
}

func playFossilFoundAudio(fossil: FossilInMatrix) {
    let text = """
    Great! You found the fossil bone!
    The bone is \(fossil.boneColor.description) and the rock is \(fossil.matrixRock.displayName)!
    The different colors help us find fossils!
    """
    
    playAudio(text)
}
```

## Visual Examples

### Fossil in Sandstone
```
┌─────────────────────────────────────────┐
│  🟨 Sandstone (tan/beige)              │
│                                         │
│     🦴 Brown fossil bone                │
│     (different color = fossil!)        │
│                                         │
└─────────────────────────────────────────┘
```

### Fossil in Limestone
```
┌─────────────────────────────────────────┐
│  ⬜ Limestone (gray/white)             │
│                                         │
│     🦴 Brown fossil bone                │
│     (different color = fossil!)        │
│                                         │
└─────────────────────────────────────────┘
```

## Game Integration

### As Part of Skeleton Explorer

```swift
struct SkeletonWithFossilView: View {
    let dinosaur: Dinosaur
    @State private var showFossilView = false
    
    var body: some View {
        VStack {
            // Skeleton view
            SkeletonView(dinosaur: dinosaur)
            
            // Toggle to fossil view
            Button(action: {
                showFossilView.toggle()
            }) {
                Text(showFossilView ? "Show Skeleton" : "Show as Fossil")
                    .font(.headline)
                    .padding()
            }
            
            if showFossilView {
                // Show skeleton as it would appear in rock
                FossilInMatrixView(
                    dinosaur: dinosaur,
                    rockType: .sandstone // Or random
                )
            }
        }
    }
}
```

## Asset Creation

### Fossil Images

**AI Generation Prompt**:
```
Fossil dinosaur bone embedded in [rock type] matrix, 
educational illustration, bone color different from rock color, 
clear contrast visible, child-friendly, 
suitable for children ages 4-6, simple clean style
```

**Examples**:
- "Fossil dinosaur bone embedded in sandstone matrix, brown bone on tan rock, educational illustration"
- "Fossil dinosaur bone embedded in limestone matrix, brown bone on gray rock, educational illustration"

## Summary

✅ **Fossil Identification Learning Feature!**

**Key Concepts**:
1. **Visual Recognition**: Learn to spot fossils by color difference
2. **Rock Types**: 7 different rock types with distinct colors
3. **Color Contrast**: Bone color vs matrix rock color
4. **Paleontology Skills**: Basic fossil identification

**Game Applications**:
- Find the fossil (tap the bone in the rock)
- Rock color matching
- Fossil discovery game (find multiple fossils)
- Part of skeleton explorer

**Educational Value**:
- Teaches visual discrimination
- Introduces geology concepts
- Age-appropriate (visual, no complex science)
- Connects to real paleontology

**Facts Per Game**: Maximum 3
- Fact 1: Rock type and color
- Fact 2: Bone color in that rock
- Fact 3: How to spot the difference

This creates an engaging visual learning feature that teaches children basic fossil identification skills!
