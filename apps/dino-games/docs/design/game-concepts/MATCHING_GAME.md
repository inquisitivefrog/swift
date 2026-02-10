# Matching Game: Dinosaurs & Characteristics

## Overview

A matching game where children tap a dinosaur (left side) and a characteristic (right side). If they match, a line connects them (even if they're in different rows). If not, encourage to try again.

**Note**: Lines can connect items in different rows - the implementation handles this with curved lines and proper z-ordering.

## Layout Design

```
┌─────────────────────────────────────────┐
│  🦕 T-Rex        │  🦷 Teeth              │
│  🦖 Triceratops  │  👣 Footprints         │
│  🦕 Stegosaurus  │  🥚 Eggs               │
│  🦖 Brontosaurus │  💩 Coprolites         │
│                 │  🦴 Skin Impressions    │
└─────────────────────────────────────────┘
```

## SwiftUI Implementation

### Basic Structure

```swift
import SwiftUI

struct MatchingGameView: View {
    @State private var selectedDinosaur: Dinosaur?
    @State private var selectedCharacteristic: Characteristic?
    @State private var matchedPairs: [MatchPair] = []
    @State private var showFeedback = false
    @State private var isCorrect = false
    
    let dinosaurs: [Dinosaur] = [
        Dinosaur(id: 1, name: "T-Rex", icon: "🦕", characteristics: [.teeth, .footprints]),
        Dinosaur(id: 2, name: "Triceratops", icon: "🦖", characteristics: [.eggs, .skin]),
        Dinosaur(id: 3, name: "Stegosaurus", icon: "🦕", characteristics: [.coprolites]),
        Dinosaur(id: 4, name: "Brontosaurus", icon: "🦖", characteristics: [.footprints, .eggs])
    ]
    
    let characteristics: [Characteristic] = [
        Characteristic(id: 1, type: .teeth, icon: "🦷", dinosaurId: 1),
        Characteristic(id: 2, type: .footprints, icon: "👣", dinosaurId: 1),
        Characteristic(id: 3, type: .eggs, icon: "🥚", dinosaurId: 2),
        Characteristic(id: 4, type: .skin, icon: "🦴", dinosaurId: 2),
        Characteristic(id: 5, type: .coprolites, icon: "💩", dinosaurId: 3),
        Characteristic(id: 6, type: .footprints, icon: "👣", dinosaurId: 4)
    ]
    
    var body: some View {
        VStack {
            Text("Match the dinosaur to its characteristic!")
                .font(.title)
                .padding()
            
            // Main game area
            HStack(spacing: 40) {
                // Left: Dinosaurs
                VStack(spacing: 20) {
                    Text("Dinosaurs")
                        .font(.headline)
                    
                    ForEach(dinosaurs) { dinosaur in
                        DinosaurCard(
                            dinosaur: dinosaur,
                            isSelected: selectedDinosaur?.id == dinosaur.id,
                            isMatched: matchedPairs.contains { $0.dinosaurId == dinosaur.id },
                            onTap: {
                                handleDinosaurTap(dinosaur)
                            }
                        )
                    }
                }
                
                // Right: Characteristics
                VStack(spacing: 20) {
                    Text("Characteristics")
                        .font(.headline)
                    
                    ForEach(characteristics) { characteristic in
                        CharacteristicCard(
                            characteristic: characteristic,
                            isSelected: selectedCharacteristic?.id == characteristic.id,
                            isMatched: matchedPairs.contains { $0.characteristicId == characteristic.id },
                            onTap: {
                                handleCharacteristicTap(characteristic)
                            }
                        )
                    }
                }
            }
            .padding()
            
            // Line drawing overlay
            GeometryReader { geometry in
                ZStack {
                    // Draw lines for matched pairs
                    ForEach(matchedPairs) { pair in
                        if let dino = dinosaurs.first(where: { $0.id == pair.dinosaurId }),
                           let char = characteristics.first(where: { $0.id == pair.characteristicId }) {
                            MatchLine(
                                from: getDinosaurPosition(dino, in: geometry),
                                to: getCharacteristicPosition(char, in: geometry)
                            )
                        }
                    }
                }
            }
            
            // Feedback
            if showFeedback {
                Text(isCorrect ? "🎉 Great match!" : "❌ Try again!")
                    .font(.headline)
                    .foregroundColor(isCorrect ? .green : .red)
            }
        }
    }
    
    func handleDinosaurTap(_ dinosaur: Dinosaur) {
        // Play audio: "T-Rex"
        playAudio(dinosaur.name)
        
        selectedDinosaur = dinosaur
        selectedCharacteristic = nil // Reset characteristic selection
        
        // If both selected, check match
        if let selectedDino = selectedDinosaur,
           let selectedChar = selectedCharacteristic {
            checkMatch(dinosaur: selectedDino, characteristic: selectedChar)
        }
    }
    
    func handleCharacteristicTap(_ characteristic: Characteristic) {
        // Play audio: "Teeth" or characteristic name
        playAudio(characteristic.type.rawValue)
        
        selectedCharacteristic = characteristic
        
        // If both selected, check match
        if let selectedDino = selectedDinosaur,
           let selectedChar = selectedCharacteristic {
            checkMatch(dinosaur: selectedDino, characteristic: selectedChar)
        }
    }
    
    func checkMatch(dinosaur: Dinosaur, characteristic: Characteristic) {
        let isMatch = dinosaur.characteristics.contains(characteristic.type) &&
                     characteristic.dinosaurId == dinosaur.id
        
        isCorrect = isMatch
        showFeedback = true
        
        if isMatch {
            // Add to matched pairs
            let newPair = MatchPair(
                id: UUID(),
                dinosaurId: dinosaur.id,
                characteristicId: characteristic.id
            )
            matchedPairs.append(newPair)
            
            // Play success audio
            playAudio("Great match!")
            
            // Reset selection
            selectedDinosaur = nil
            selectedCharacteristic = nil
            
            // Check if game complete
            if matchedPairs.count == dinosaurs.count {
                // Game complete!
                playAudio("You did it! All matches found!")
            }
        } else {
            // Play try again audio
            playAudio("Try again!")
            
            // Reset selection after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                selectedDinosaur = nil
                selectedCharacteristic = nil
                showFeedback = false
            }
        }
    }
    
    func getDinosaurPosition(_ dinosaur: Dinosaur, in geometry: GeometryProxy) -> CGPoint {
        // Calculate position based on dinosaur's index
        let index = dinosaurs.firstIndex(where: { $0.id == dinosaur.id }) ?? 0
        let yPosition = CGFloat(index) * 100 + 50 // Adjust based on card height
        return CGPoint(x: 100, y: yPosition) // Left side x position
    }
    
    func getCharacteristicPosition(_ characteristic: Characteristic, in geometry: GeometryProxy) -> CGPoint {
        // Calculate position based on characteristic's index
        let index = characteristics.firstIndex(where: { $0.id == characteristic.id }) ?? 0
        let yPosition = CGFloat(index) * 100 + 50 // Adjust based on card height
        return CGPoint(x: geometry.size.width - 100, y: yPosition) // Right side x position
    }
}
```

### Data Models

```swift
struct Dinosaur: Identifiable {
    let id: Int
    let name: String
    let icon: String
    let characteristics: [CharacteristicType]
}

struct Characteristic: Identifiable {
    let id: Int
    let type: CharacteristicType
    let icon: String
    let dinosaurId: Int // Which dinosaur this belongs to
}

enum CharacteristicType: String {
    case teeth = "Teeth"
    case footprints = "Footprints"
    case eggs = "Eggs"
    case coprolites = "Coprolites"
    case skin = "Skin Impressions"
}

struct MatchPair: Identifiable {
    let id: UUID
    let dinosaurId: Int
    let characteristicId: Int
}
```

### Card Components

```swift
struct DinosaurCard: View {
    let dinosaur: Dinosaur
    let isSelected: Bool
    let isMatched: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(dinosaur.icon)
                    .font(.system(size: 60))
                
                if !isMatched {
                    Text(dinosaur.name)
                        .font(.headline)
                }
            }
            .frame(width: 200, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.blue.opacity(0.3) : 
                          isMatched ? Color.green.opacity(0.3) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.blue : 
                           isMatched ? Color.green : Color.clear, lineWidth: 3)
            )
        }
        .disabled(isMatched) // Can't select already matched items
    }
}

struct CharacteristicCard: View {
    let characteristic: Characteristic
    let isSelected: Bool
    let isMatched: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(characteristic.icon)
                    .font(.system(size: 60))
                
                if !isMatched {
                    Text(characteristic.type.rawValue)
                        .font(.headline)
                }
            }
            .frame(width: 200, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.blue.opacity(0.3) : 
                          isMatched ? Color.green.opacity(0.3) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.blue : 
                           isMatched ? Color.green : Color.clear, lineWidth: 3)
            )
        }
        .disabled(isMatched) // Can't select already matched items
    }
}
```

### Line Drawing

```swift
struct MatchLine: View {
    let from: CGPoint
    let to: CGPoint
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(Color.green, lineWidth: 4)
        .animation(.easeInOut(duration: 0.5), value: from)
    }
}
```

## More Robust Line Drawing

### With Animation

```swift
struct AnimatedMatchLine: View {
    let from: CGPoint
    let to: CGPoint
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .trim(from: 0, to: animationProgress)
        .stroke(Color.green, lineWidth: 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animationProgress = 1.0
            }
        }
    }
}
```

### Curved Lines (More Visual Appeal)

```swift
struct CurvedMatchLine: View {
    let from: CGPoint
    let to: CGPoint
    
    var body: some View {
        Path { path in
            path.move(to: from)
            
            // Create a curved path
            let controlPoint1 = CGPoint(
                x: from.x + (to.x - from.x) * 0.5,
                y: from.y
            )
            let controlPoint2 = CGPoint(
                x: from.x + (to.x - from.x) * 0.5,
                y: to.y
            )
            
            path.addCurve(
                to: to,
                control1: controlPoint1,
                control2: controlPoint2
            )
        }
        .stroke(Color.green, lineWidth: 4)
        .animation(.easeInOut(duration: 0.5), value: from)
    }
}
```

## Better Position Calculation

### Using GeometryReader for Accurate Positions

```swift
struct MatchingGameView: View {
    @State private var dinosaurPositions: [Int: CGPoint] = [:]
    @State private var characteristicPositions: [Int: CGPoint] = [:]
    
    var body: some View {
        HStack {
            // Left: Dinosaurs with position tracking
            VStack {
                ForEach(dinosaurs) { dinosaur in
                    DinosaurCard(dinosaur: dinosaur, ...)
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        let position = CGPoint(
                                            x: geometry.frame(in: .global).midX,
                                            y: geometry.frame(in: .global).midY
                                        )
                                        dinosaurPositions[dinosaur.id] = position
                                    }
                            }
                        )
                }
            }
            
            // Right: Characteristics with position tracking
            VStack {
                ForEach(characteristics) { characteristic in
                    CharacteristicCard(characteristic: characteristic, ...)
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        let position = CGPoint(
                                            x: geometry.frame(in: .global).midX,
                                            y: geometry.frame(in: .global).midY
                                        )
                                        characteristicPositions[characteristic.id] = position
                                    }
                            }
                        )
                }
            }
        }
        .overlay(
            // Draw lines using tracked positions
            ZStack {
                ForEach(matchedPairs) { pair in
                    if let from = dinosaurPositions[pair.dinosaurId],
                       let to = characteristicPositions[pair.characteristicId] {
                        MatchLine(from: from, to: to)
                    }
                }
            }
        )
    }
}
```

## Audio Integration

```swift
func playAudio(_ text: String) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    utterance.rate = 0.5 // Slower for children
    
    let synthesizer = AVSpeechSynthesizer()
    synthesizer.speak(utterance)
}

// Or use pre-recorded audio files
func playAudioFile(_ fileName: String) {
    guard let url = Bundle.main.url(forResource: fileName, withExtension: "m4a") else { return }
    
    do {
        let player = try AVAudioPlayer(contentsOf: url)
        player.play()
    } catch {
        print("Error playing audio: \(error)")
    }
}
```

## Visual Feedback

### Selection Highlight

```swift
struct DinosaurCard: View {
    let isSelected: Bool
    
    var body: some View {
        // ... card content ...
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
```

### Match Celebration

```swift
struct MatchCelebration: View {
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            if showConfetti {
                // Confetti animation
                ForEach(0..<50) { _ in
                    ConfettiParticle()
                }
            }
        }
        .onAppear {
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showConfetti = false
            }
        }
    }
}
```

## Game State Management

```swift
class MatchingGameState: ObservableObject {
    @Published var selectedDinosaur: Dinosaur?
    @Published var selectedCharacteristic: Characteristic?
    @Published var matchedPairs: [MatchPair] = []
    @Published var score: Int = 0
    @Published var attempts: Int = 0
    
    func reset() {
        selectedDinosaur = nil
        selectedCharacteristic = nil
        matchedPairs = []
        score = 0
        attempts = 0
    }
    
    func isComplete() -> Bool {
        return matchedPairs.count == totalPossibleMatches
    }
}
```

## Accessibility

### For Pre-Literate Children

- **Spoken instructions**: "Tap a dinosaur, then tap its characteristic"
- **Audio feedback**: Spoken dinosaur and characteristic names on tap
- **Visual feedback**: Highlight selected items, draw lines for matches
- **Large touch targets**: Cards are 200x80 points minimum
- **Clear visual distinction**: Different colors for selected vs matched

## Handling Cross-Row Matches

### The Challenge

If a dinosaur in row 1 matches a characteristic in row 3, the line will cross over other rows. This is fine, but we should handle it visually.

### Solutions

#### Option 1: Curved Lines (Recommended)

Curved lines look better when crossing rows and are less visually confusing:

```swift
struct CurvedMatchLine: View {
    let from: CGPoint
    let to: CGPoint
    
    var body: some View {
        Path { path in
            path.move(to: from)
            
            // Create a smooth curve
            let midX = (from.x + to.x) / 2
            let controlPoint1 = CGPoint(x: midX, y: from.y)
            let controlPoint2 = CGPoint(x: midX, y: to.y)
            
            path.addCurve(
                to: to,
                control1: controlPoint1,
                control2: controlPoint2
            )
        }
        .stroke(Color.green, lineWidth: 4)
        .animation(.easeInOut(duration: 0.5), value: from)
    }
}
```

#### Option 2: Z-Ordering (Bring Matched Items Forward)

Move matched items to the front so lines appear behind them:

```swift
struct DinosaurCard: View {
    let isMatched: Bool
    
    var body: some View {
        // ... card content ...
        .zIndex(isMatched ? 10 : 1) // Matched items on top
    }
}
```

#### Option 3: Reorder After Matching

Move matched pairs to the same row after matching:

```swift
func handleMatch(dinosaur: Dinosaur, characteristic: Characteristic) {
    // Add to matched pairs
    matchedPairs.append(MatchPair(...))
    
    // Reorder: move matched items to top
    reorderMatchedItems()
}

func reorderMatchedItems() {
    // Move matched dinosaurs to top
    dinosaurs.sort { dino1, dino2 in
        let dino1Matched = matchedPairs.contains { $0.dinosaurId == dino1.id }
        let dino2Matched = matchedPairs.contains { $0.dinosaurId == dino2.id }
        return dino1Matched && !dino2Matched
    }
    
    // Move matched characteristics to top
    characteristics.sort { char1, char2 in
        let char1Matched = matchedPairs.contains { $0.characteristicId == char1.id }
        let char2Matched = matchedPairs.contains { $0.characteristicId == char2.id }
        return char1Matched && !char2Matched
    }
}
```

#### Option 4: Different Line Styles for Cross-Row

Use different line styles to distinguish cross-row matches:

```swift
struct MatchLine: View {
    let from: CGPoint
    let to: CGPoint
    
    // Check if line crosses rows
    var isCrossRow: Bool {
        let rowDifference = abs(Int((to.y - from.y) / 100)) // Assuming ~100pt per row
        return rowDifference > 1
    }
    
    var body: some View {
        Path { path in
            if isCrossRow {
                // Curved line for cross-row
                path.move(to: from)
                let midX = (from.x + to.x) / 2
                path.addCurve(
                    to: to,
                    control1: CGPoint(x: midX, y: from.y),
                    control2: CGPoint(x: midX, y: to.y)
                )
            } else {
                // Straight line for same-row
                path.move(to: from)
                path.addLine(to: to)
            }
        }
        .stroke(isCrossRow ? Color.blue : Color.green, lineWidth: 4)
        .animation(.easeInOut(duration: 0.5), value: from)
    }
}
```

### Recommended Approach

**Use curved lines + z-ordering**:
- Curved lines look better and are less confusing
- Matched items appear on top (z-index)
- Lines can cross rows naturally
- Visual clarity maintained

## Updated Implementation with Cross-Row Support

```swift
struct MatchingGameView: View {
    @State private var matchedPairs: [MatchPair] = []
    
    var body: some View {
        HStack {
            // Left: Dinosaurs
            VStack(spacing: 20) {
                ForEach(dinosaurs) { dinosaur in
                    DinosaurCard(
                        dinosaur: dinosaur,
                        isMatched: matchedPairs.contains { $0.dinosaurId == dinosaur.id }
                    )
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(
                                    key: DinosaurPositionKey.self,
                                    value: [dinosaur.id: geometry.frame(in: .global).center]
                                )
                        }
                    )
                    .zIndex(matchedPairs.contains { $0.dinosaurId == dinosaur.id } ? 10 : 1)
                }
            }
            
            // Right: Characteristics
            VStack(spacing: 20) {
                ForEach(characteristics) { characteristic in
                    CharacteristicCard(
                        characteristic: characteristic,
                        isMatched: matchedPairs.contains { $0.characteristicId == characteristic.id }
                    )
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(
                                    key: CharacteristicPositionKey.self,
                                    value: [characteristic.id: geometry.frame(in: .global).center]
                                )
                        }
                    )
                    .zIndex(matchedPairs.contains { $0.characteristicId == characteristic.id } ? 10 : 1)
                }
            }
        }
        .overlay(
            // Draw lines using tracked positions
            GeometryReader { geometry in
                ZStack {
                    ForEach(matchedPairs) { pair in
                        if let from = dinosaurPositions[pair.dinosaurId],
                           let to = characteristicPositions[pair.characteristicId] {
                            CurvedMatchLine(from: from, to: to)
                                .zIndex(0) // Lines behind cards
                        }
                    }
                }
            }
        )
    }
}
```

## Visual Example

```
Row 1: 🦕 T-Rex        ────────→  🦷 Teeth (row 1)
Row 2: 🦖 Triceratops              👣 Footprints (row 2)
Row 3: 🦕 Stegosaurus   ╭────────→  🥚 Eggs (row 4) ← Cross-row!
       (curved line)    │
Row 4: 🦖 Brontosaurus  │            💩 Coprolites
```

The curved line clearly shows the connection even when crossing rows.

## Summary

✅ **Fully Possible!**

**Key Components**:
1. Two-column layout (dinosaurs left, characteristics right)
2. Tap detection on cards
3. Selection state tracking
4. Match validation logic
5. Line drawing between matched pairs (handles cross-row)
6. Visual and audio feedback

**Cross-Row Handling**:
- ✅ Curved lines for better visual clarity
- ✅ Z-ordering (matched items on top)
- ✅ Position tracking works regardless of row
- ✅ Optional: reorder after matching

**Benefits**:
- Educational (learns dinosaur characteristics)
- Engaging (interactive matching)
- Visual (clear feedback, connecting lines even across rows)
- Audio-supported (spoken names)
- Child-friendly (large touch targets, simple interaction)
- No reading required (icons and spoken names)

This creates an engaging matching game that teaches children about dinosaur characteristics while using only sound and touch (no reading required)!
