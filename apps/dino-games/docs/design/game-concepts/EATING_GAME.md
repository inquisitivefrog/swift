# Eating Game: Match Dinosaur to Plant

## Overview

Match dinosaur species with the plant they eat. Display plant in first row, show 3-4 dinosaur species (unique by morphology and teeth) in second row, child taps the correct dinosaur.

## Concept

```
┌─────────────────────────────────────────┐
│                                         │
│     🌿 Plant Image                     │
│     "Which dinosaur eats this?"        │
│                                         │
│     🦕 T-Rex    🦖 Triceratops         │
│     🦕 Stego    🦖 Bronto               │
│                                         │
│     (Tap the correct one!)             │
│                                         │
└─────────────────────────────────────────┘
```

## Data Model

```swift
struct Plant {
    let id: Int
    let name: String
    let imageName: String
    let description: String
    let eatenBy: [DinosaurType]
}

enum DinosaurType {
    case herbivore    // Plant eater
    case carnivore    // Meat eater
    case omnivore     // Eats both
}

struct Dinosaur {
    let id: Int
    let name: String
    let icon: String
    let imageName: String
    let type: DinosaurType
    let morphology: Morphology
    let teeth: ToothType
    let eats: [Plant]?
}

struct Morphology {
    let hasHorns: Bool
    let hasPlates: Bool
    let hasSpikes: Bool
    let neckLength: NeckLength
    let size: SizeCategory
}

enum NeckLength {
    case short
    case medium
    case long
    case veryLong
}

enum SizeCategory {
    case small
    case medium
    case large
    case veryLarge
}

enum ToothType {
    case sharp        // Carnivore
    case serrated     // Carnivore
    case flat         // Herbivore
    case leafShaped   // Herbivore
    case pointed      // Omnivore
}

// Example plants
let plants: [Plant] = [
    Plant(
        id: 1,
        name: "Ferns",
        imageName: "fern",
        description: "Green leafy plants",
        eatenBy: [.herbivore]
    ),
    Plant(
        id: 2,
        name: "Cycads",
        imageName: "cycad",
        description: "Palm-like plants",
        eatenBy: [.herbivore]
    ),
    Plant(
        id: 3,
        name: "Ginkgo",
        imageName: "ginkgo",
        description: "Tree with fan-shaped leaves",
        eatenBy: [.herbivore]
    ),
    Plant(
        id: 4,
        name: "Conifers",
        imageName: "conifer",
        description: "Pine trees",
        eatenBy: [.herbivore]
    )
]

// Example dinosaurs
let dinosaurs: [Dinosaur] = [
    Dinosaur(
        id: 1,
        name: "T-Rex",
        icon: "🦕",
        imageName: "trex",
        type: .carnivore,
        morphology: Morphology(hasHorns: false, hasPlates: false, hasSpikes: false, neckLength: .short, size: .large),
        teeth: .serrated,
        eats: nil
    ),
    Dinosaur(
        id: 2,
        name: "Triceratops",
        icon: "🦖",
        imageName: "triceratops",
        type: .herbivore,
        morphology: Morphology(hasHorns: true, hasPlates: false, hasSpikes: false, neckLength: .short, size: .large),
        teeth: .flat,
        eats: [plants[0], plants[1]] // Eats ferns and cycads
    ),
    Dinosaur(
        id: 3,
        name: "Stegosaurus",
        icon: "🦕",
        imageName: "stegosaurus",
        type: .herbivore,
        morphology: Morphology(hasHorns: false, hasPlates: true, hasSpikes: true, neckLength: .short, size: .large),
        teeth: .leafShaped,
        eats: [plants[0], plants[2]] // Eats ferns and ginkgo
    ),
    Dinosaur(
        id: 4,
        name: "Brontosaurus",
        icon: "🦖",
        imageName: "brontosaurus",
        type: .herbivore,
        morphology: Morphology(hasHorns: false, hasPlates: false, hasSpikes: false, neckLength: .veryLong, size: .veryLarge),
        teeth: .flat,
        eats: [plants[2], plants[3]] // Eats ginkgo and conifers (tall trees)
    )
]
```

## SwiftUI Implementation

```swift
import SwiftUI

struct EatingGameView: View {
    @State private var currentPlant: Plant?
    @State private var dinosaurOptions: [Dinosaur] = []
    @State private var selectedDinosaur: Dinosaur?
    @State private var showFeedback = false
    @State private var isCorrect = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Which dinosaur eats this plant?")
                .font(.title)
                .padding()
            
            // Plant display (first row)
            if let plant = currentPlant {
                VStack {
                    Image(plant.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .padding()
                    
                    Text(plant.name)
                        .font(.headline)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.green.opacity(0.2))
                )
            }
            
            // Audio instruction
            Button(action: {
                if let plant = currentPlant {
                    playAudio("Which dinosaur eats \(plant.name)? Look at their teeth and shape!")
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
            
            // Dinosaur options (second row)
            HStack(spacing: 20) {
                ForEach(dinosaurOptions, id: \.id) { dinosaur in
                    DinosaurCard(
                        dinosaur: dinosaur,
                        isSelected: selectedDinosaur?.id == dinosaur.id,
                        isCorrect: showFeedback && isCorrect && selectedDinosaur?.id == dinosaur.id,
                        isWrong: showFeedback && selectedDinosaur?.id == dinosaur.id && !isCorrect,
                        onTap: {
                            selectedDinosaur = dinosaur
                            checkAnswer(dinosaur)
                        }
                    )
                }
            }
            .padding()
            
            // Feedback
            if showFeedback {
                VStack {
                    Text(isCorrect ? "🎉 That's right!" : "❌ Try again!")
                        .font(.headline)
                        .foregroundColor(isCorrect ? .green : .red)
                    
                    if isCorrect, let plant = currentPlant, let dino = selectedDinosaur {
                        Text("\(dino.name) eats \(plant.name)!")
                            .font(.body)
                            .padding()
                    }
                }
                .padding()
            }
        }
        .onAppear {
            setupRound()
        }
    }
    
    func setupRound() {
        // Select a plant
        currentPlant = plants.randomElement()
        
        guard let plant = currentPlant else { return }
        
        // Find dinosaurs that eat this plant
        let correctDinosaurs = dinosaurs.filter { dino in
            dino.eats?.contains(where: { $0.id == plant.id }) ?? false
        }
        
        guard let correctDino = correctDinosaurs.randomElement() else { return }
        
        // Add correct dinosaur + distractors
        var options: [Dinosaur] = [correctDino]
        
        // Add distractors (different morphology/teeth)
        let distractors = dinosaurs.filter { dino in
            dino.id != correctDino.id &&
            (dino.type != correctDino.type || dino.teeth != correctDino.teeth)
        }.shuffled().prefix(3)
        
        options.append(contentsOf: distractors)
        dinosaurOptions = Array(options.shuffled())
    }
    
    func checkAnswer(_ dinosaur: Dinosaur) {
        guard let plant = currentPlant else { return }
        
        isCorrect = dinosaur.eats?.contains(where: { $0.id == plant.id }) ?? false
        showFeedback = true
        
        if isCorrect {
            playAudio("That's right! \(dinosaur.name) eats \(plant.name)! Look at its \(dinosaur.teeth.rawValue) teeth - perfect for eating plants!")
            showCelebration()
            
            // Next round after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                setupRound()
                showFeedback = false
                selectedDinosaur = nil
            }
        } else {
            if dinosaur.type == .carnivore {
                playAudio("\(dinosaur.name) is a meat eater! It has sharp teeth for eating meat, not plants. Try again!")
            } else {
                playAudio("\(dinosaur.name) eats different plants. Try again!")
            }
            
            // Reset after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showFeedback = false
                selectedDinosaur = nil
            }
        }
    }
}

struct DinosaurCard: View {
    let dinosaur: Dinosaur
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Image(dinosaur.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                
                Text(dinosaur.name)
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        isCorrect ? Color.green.opacity(0.3) :
                        isWrong ? Color.red.opacity(0.3) :
                        isSelected ? Color.blue.opacity(0.3) :
                        Color.gray.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isCorrect ? Color.green :
                        isWrong ? Color.red :
                        isSelected ? Color.blue :
                        Color.clear,
                        lineWidth: 3
                    )
            )
        }
    }
}
```

## Educational Facts (Max 3 per game)

```swift
struct EatingGameFacts {
    let plant: Plant
    let dinosaur: Dinosaur
    
    var facts: [String] {
        return [
            "\(dinosaur.name) eats \(plant.name)!",
            "\(dinosaur.name) has \(dinosaur.teeth.rawValue) teeth for eating plants!",
            "\(dinosaur.name) uses its \(dinosaur.morphology.neckLength.rawValue) neck to reach \(plant.name)!"
        ]
    }
}
```

## Summary

✅ **Eating Game: Match Dinosaur to Plant!**

**Key Features**:
1. **Plant Display**: Show plant in first row
2. **Dinosaur Options**: 3-4 dinosaurs in second row
3. **Visual Differences**: Unique morphology and teeth help identify
4. **Educational**: Teaches what dinosaurs ate
5. **Visual Learning**: No reading required

**Gameplay**:
- Plant shown at top
- 3-4 dinosaur options below
- Child taps correct dinosaur
- Visual and audio feedback
- Educational facts (max 3)

**Educational Value**:
- Teaches dinosaur diets
- Connects morphology to diet
- Teaches about prehistoric plants
- Age-appropriate (visual matching)

This creates an engaging game that teaches children about dinosaur diets through visual matching!
