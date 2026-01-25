# Plant Finding Game: Where's the Plant?

## Overview

Similar to "Where's Waldo" with dinosaurs, but for finding plants based on unique characteristics: size, shape, location.

## Concept

```
┌─────────────────────────────────────────┐
│                                         │
│     Scene with multiple plants         │
│     [Target plant partially hidden]   │
│                                         │
│     "Find the tall fern!"             │
│                                         │
└─────────────────────────────────────────┘
```

## Plant Characteristics

```swift
struct Plant {
    let id: Int
    let name: String
    let imageName: String
    let size: PlantSize
    let shape: PlantShape
    let location: PlantLocation
    let color: Color
}

enum PlantSize {
    case tiny
    case small
    case medium
    case large
    case huge
}

enum PlantShape {
    case fern        // Frond-like
    case tree        // Tall with trunk
    case bush        // Round, bushy
    case vine        // Long, trailing
    case palm        // Palm-like
    case cone        // Conical shape
}

enum PlantLocation {
    case ground      // On the ground
    case water       // In water
    case high        // High up (trees)
    case rock        // On rocks
    case shade       // In shade
}

// Example plants
let plants: [Plant] = [
    Plant(
        id: 1,
        name: "Fern",
        imageName: "fern",
        size: .small,
        shape: .fern,
        location: .ground,
        color: .green
    ),
    Plant(
        id: 2,
        name: "Ginkgo Tree",
        imageName: "ginkgo",
        size: .huge,
        shape: .tree,
        location: .high,
        color: .green
    ),
    Plant(
        id: 3,
        name: "Cycad",
        imageName: "cycad",
        size: .large,
        shape: .palm,
        location: .ground,
        color: .green
    )
]
```

## SwiftUI Implementation

### Plant Finding Game

```swift
import SwiftUI

struct PlantFindingGameView: View {
    @State private var targetPlant: Plant?
    @State private var sceneImage: String = ""
    @State private var targetCell: Int = 0
    @State private var gridSize: Int = 4
    @State private var selectedCell: Int?
    @State private var showFeedback = false
    @State private var isCorrect = false
    
    var body: some View {
        VStack {
            Text("Can you find the \(targetPlant?.characteristicDescription ?? "plant")?")
                .font(.title)
                .padding()
            
            // Audio instruction
            Button(action: {
                if let plant = targetPlant {
                    playAudio("Can you find the \(plant.characteristicDescription)? Look for a \(plant.size.rawValue) \(plant.shape.rawValue) \(plant.location.rawValue)!")
                }
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
            
            // Scene with grid overlay
            ZStack {
                // Scene image
                Image(sceneImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 400)
                
                // Grid overlay for touch detection
                GridOverlay(
                    gridSize: gridSize,
                    imageSize: CGSize(width: 400, height: 400),
                    targetCell: targetCell,
                    onCellTapped: { cellIndex in
                        selectedCell = cellIndex
                        checkAnswer(cellIndex)
                    }
                )
            }
            .padding()
            
            // Feedback
            if showFeedback {
                Text(isCorrect ? "🎉 You found it!" : "❌ Try again!")
                    .font(.headline)
                    .foregroundColor(isCorrect ? .green : .red)
                    .padding()
            }
        }
        .onAppear {
            setupRound()
        }
    }
    
    func setupRound() {
        // Select target plant
        targetPlant = plants.randomElement()
        
        guard let plant = targetPlant else { return }
        
        // Create or select scene with this plant
        sceneImage = "scene_with_\(plant.name.lowercased())"
        
        // Set target cell (where plant is located)
        targetCell = Int.random(in: 0..<(gridSize * gridSize))
    }
    
    func checkAnswer(_ cellIndex: Int) {
        isCorrect = (cellIndex == targetCell)
        showFeedback = true
        
        if isCorrect {
            if let plant = targetPlant {
                playAudio("Great job! You found the \(plant.name)! It's a \(plant.size.rawValue) \(plant.shape.rawValue)!")
            }
            showCelebration()
            
            // Next round
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                setupRound()
                showFeedback = false
                selectedCell = nil
            }
        } else {
            playAudio("Try again! Look for the \(targetPlant?.characteristicDescription ?? "plant")!")
        }
    }
}

extension Plant {
    var characteristicDescription: String {
        return "\(size.rawValue) \(shape.rawValue)"
    }
}
```

### Characteristic-Based Finding

```swift
struct CharacteristicBasedFinding: View {
    @State private var targetCharacteristic: PlantCharacteristic?
    @State private var sceneImage: String = ""
    
    enum PlantCharacteristic {
        case size(PlantSize)
        case shape(PlantShape)
        case location(PlantLocation)
        case color(Color)
    }
    
    var body: some View {
        VStack {
            // Show characteristic to find
            if let characteristic = targetCharacteristic {
                CharacteristicCard(characteristic: characteristic)
                    .padding()
            }
            
            // Scene
            Image(sceneImage)
                .resizable()
                .scaledToFit()
                .frame(height: 400)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            checkTapLocation(value.location, characteristic: targetCharacteristic)
                        }
                )
        }
    }
    
    func checkTapLocation(_ location: CGPoint, characteristic: PlantCharacteristic?) {
        // Check if tap is on plant matching characteristic
        // Implementation similar to Where's Waldo game
    }
}
```

## Educational Facts (Max 3 per game)

```swift
struct PlantFacts {
    let plant: Plant
    let facts: [String] // Maximum 3
    
    static func getFacts(for plant: Plant) -> [String] {
        return [
            "\(plant.name) is \(plant.size.rawValue) sized!",
            "\(plant.name) has a \(plant.shape.rawValue) shape!",
            "\(plant.name) grows \(plant.location.rawValue)!"
        ]
    }
}
```

## Summary

✅ **Plant Finding Game!**

**Key Features**:
1. **Similar to Where's Waldo**: Find plant in scene
2. **Characteristic-Based**: Size, shape, location
3. **Grid-Based Touch**: Tap correct area
4. **Visual Learning**: No reading required
5. **Educational**: Teaches plant identification

**Gameplay**:
- Scene with multiple plants
- Target plant has specific characteristics
- Child finds plant based on description
- Grid-based touch detection
- Visual and audio feedback

**Educational Value**:
- Teaches plant characteristics
- Visual discrimination skills
- Size, shape, location concepts
- Age-appropriate (visual matching)

This creates an engaging game that teaches children to identify plants by their characteristics!
