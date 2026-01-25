# Occupation Game: Spot the Scientist

## Overview

Game where children identify different types of scientists (paleontologist, geologist, wildlife biologist, etc.) from a matrix of images showing professionals with identifying gear or background settings. Includes humorous unrelated images (doctor, firefighter, dog catcher, scuba diver) for fun.

## Important: Diversity Requirements

**All animated images of people must show**:
- **Gender**: Male and female
- **Ethnicity**: White, Black, Asian, Native, Latino
- **Equal representation** across all occupations

## Occupations

### Scientific Occupations

```swift
enum ScientificOccupation: String, CaseIterable {
    case paleontologist = "Paleontologist"
    case geologist = "Geologist"
    case wildlifeBiologist = "Wildlife Biologist"
    case molecularBiologist = "Molecular Biologist"
    case researchScientist = "Research Scientist"
    case curator = "Curator"
    case preparator = "Preparator"
    
    var identifyingGear: [String] {
        switch self {
        case .paleontologist:
            return ["shovel", "brush", "hat", "boots", "fossil"]
        case .geologist:
            return ["rock_hammer", "magnifying_glass", "map", "rock_samples"]
        case .wildlifeBiologist:
            return ["binoculars", "notebook", "camera", "field_guide"]
        case .molecularBiologist:
            return ["microscope", "lab_coat", "test_tubes", "computer"]
        case .researchScientist:
            return ["computer", "microscope", "notebook", "lab_equipment"]
        case .curator:
            return ["museum", "display_case", "catalog", "gloves"]
        case .preparator:
            return ["air_scribe", "magnifying_glass", "brush", "fossil"]
        }
    }
    
    var backgroundSetting: String {
        switch self {
        case .paleontologist: return "dig_site"
        case .geologist: return "rock_formation"
        case .wildlifeBiologist: return "field_nature"
        case .molecularBiologist: return "laboratory"
        case .researchScientist: return "laboratory"
        case .curator: return "museum"
        case .preparator: return "preparation_lab"
        }
    }
    
    var icon: String {
        switch self {
        case .paleontologist: return "🦴"
        case .geologist: return "🪨"
        case .wildlifeBiologist: return "🦋"
        case .molecularBiologist: return "🔬"
        case .researchScientist: return "🔬"
        case .curator: return "🏛️"
        case .preparator: return "🛠️"
        }
    }
}
```

### Humorous Unrelated Occupations

```swift
enum HumorousOccupation: String, CaseIterable {
    case doctor = "Doctor"
    case firefighter = "Firefighter"
    case dogCatcher = "Dog Catcher"
    case scubaDiver = "Scuba Diver"
    case chef = "Chef"
    case astronaut = "Astronaut"
    case pilot = "Pilot"
    
    var identifyingGear: [String] {
        switch self {
        case .doctor: return ["stethoscope", "white_coat", "hospital"]
        case .firefighter: return ["fire_helmet", "hose", "fire_truck"]
        case .dogCatcher: return ["net", "animal_control_vehicle"]
        case .scubaDiver: return ["diving_mask", "fins", "oxygen_tank"]
        case .chef: return ["chef_hat", "apron", "kitchen"]
        case .astronaut: return ["space_suit", "rocket"]
        case .pilot: return ["pilot_hat", "airplane", "headset"]
        }
    }
    
    var icon: String {
        switch self {
        case .doctor: return "👨‍⚕️"
        case .firefighter: return "👨‍🚒"
        case .dogCatcher: return "🐕"
        case .scubaDiver: return "🤿"
        case .chef: return "👨‍🍳"
        case .astronaut: return "👨‍🚀"
        case .pilot: return "✈️"
        }
    }
}
```

## Diversity Representation

### Person Data Model

```swift
enum Gender {
    case male
    case female
}

enum Ethnicity {
    case white
    case black
    case asian
    case native
    case latino
}

struct Person {
    let gender: Gender
    let ethnicity: Ethnicity
    let occupation: Occupation
    let imageName: String
}

enum Occupation {
    case scientific(ScientificOccupation)
    case humorous(HumorousOccupation)
}
```

### Ensuring Diversity

```swift
struct OccupationImageSet {
    let occupation: ScientificOccupation
    let people: [Person] // Must include all combinations
    
    static func createDiverseSet(for occupation: ScientificOccupation) -> OccupationImageSet {
        var people: [Person] = []
        
        // Create all gender/ethnicity combinations
        for gender in [Gender.male, Gender.female] {
            for ethnicity in [Ethnicity.white, .black, .asian, .native, .latino] {
                people.append(Person(
                    gender: gender,
                    ethnicity: ethnicity,
                    occupation: .scientific(occupation),
                    imageName: "\(occupation.rawValue.lowercased())_\(gender.rawValue)_\(ethnicity.rawValue)"
                ))
            }
        }
        
        return OccupationImageSet(occupation: occupation, people: people)
    }
}
```

## Game Implementation

### Spot the Scientist Game

```swift
import SwiftUI

struct OccupationGameView: View {
    @State private var targetOccupation: ScientificOccupation = .paleontologist
    @State private var imageMatrix: [OccupationImage] = []
    @State private var selectedImage: OccupationImage?
    @State private var showFeedback = false
    @State private var isCorrect = false
    
    var body: some View {
        VStack {
            Text("Can you find the \(targetOccupation.rawValue)?")
                .font(.title)
                .padding()
            
            // Audio instruction
            Button(action: {
                playAudio("Can you find the \(targetOccupation.rawValue)? Look for \(targetOccupation.identifyingGear.first ?? "the tools")!")
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
            
            // Image matrix (3x3 or 4x4)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                ForEach(imageMatrix, id: \.id) { image in
                    OccupationImageCard(
                        image: image,
                        isSelected: selectedImage?.id == image.id,
                        isCorrect: showFeedback && image.occupation == .scientific(targetOccupation),
                        isWrong: showFeedback && selectedImage?.id == image.id && image.occupation != .scientific(targetOccupation),
                        onTap: {
                            selectedImage = image
                            checkAnswer(image)
                        }
                    )
                }
            }
            .padding()
            
            // Feedback
            if showFeedback {
                Text(isCorrect ? "🎉 That's right!" : "❌ Try again!")
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
        var images: [OccupationImage] = []
        
        // Add 1-2 correct occupation images (diverse)
        let correctImages = getDiverseOccupationImages(for: targetOccupation, count: 2)
        images.append(contentsOf: correctImages)
        
        // Add other scientific occupations (distractors)
        let otherOccupations = ScientificOccupation.allCases.filter { $0 != targetOccupation }
        for occupation in otherOccupations.shuffled().prefix(2) {
            images.append(getRandomOccupationImage(for: occupation))
        }
        
        // Add humorous occupations (10-20% of total)
        let humorousCount = max(1, images.count / 5) // ~20%
        for _ in 0..<humorousCount {
            let humorous = HumorousOccupation.allCases.randomElement()!
            images.append(OccupationImage(
                id: UUID(),
                occupation: .humorous(humorous),
                imageName: getRandomOccupationImage(for: .humorous(humorous)).imageName,
                person: getRandomDiversePerson()
            ))
        }
        
        // Shuffle and limit to 9 (3x3) or 16 (4x4)
        imageMatrix = Array(images.shuffled().prefix(9))
    }
    
    func getDiverseOccupationImages(for occupation: ScientificOccupation, count: Int) -> [OccupationImage] {
        // Ensure diversity - get different gender/ethnicity combinations
        let diverseSet = OccupationImageSet.createDiverseSet(for: occupation)
        return Array(diverseSet.people.shuffled().prefix(count)).map { person in
            OccupationImage(
                id: UUID(),
                occupation: .scientific(occupation),
                imageName: person.imageName,
                person: person
            )
        }
    }
    
    func getRandomDiversePerson() -> Person {
        // Randomly select diverse person
        let gender = Gender.allCases.randomElement()!
        let ethnicity = Ethnicity.allCases.randomElement()!
        return Person(gender: gender, ethnicity: ethnicity, occupation: .scientific(.paleontologist), imageName: "")
    }
    
    func checkAnswer(_ image: OccupationImage) {
        isCorrect = (image.occupation == .scientific(targetOccupation))
        showFeedback = true
        
        if isCorrect {
            playAudio("That's right! You found the \(targetOccupation.rawValue)! Great job!")
            showCelebration()
            
            // Next round after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                nextRound()
            }
        } else {
            if case .humorous(let humorous) = image.occupation {
                playAudio("That's a \(humorous.rawValue)! That's funny, but not a \(targetOccupation.rawValue). Try again!")
            } else {
                playAudio("That's not quite right. Look for \(targetOccupation.identifyingGear.first ?? "the tools"). Try again!")
            }
        }
    }
    
    func nextRound() {
        targetOccupation = ScientificOccupation.allCases.randomElement()!
        setupRound()
        showFeedback = false
        selectedImage = nil
    }
}

struct OccupationImage: Identifiable {
    let id: UUID
    let occupation: Occupation
    let imageName: String
    let person: Person
}

struct OccupationImageCard: View {
    let image: OccupationImage
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Image(image.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                isCorrect ? Color.green.opacity(0.3) :
                                isWrong ? Color.red.opacity(0.3) :
                                isSelected ? Color.blue.opacity(0.3) :
                                Color.gray.opacity(0.1)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
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
}
```

## Asset Creation Requirements

### Diversity Checklist

For each occupation, create images showing:

**Gender**:
- [ ] Male version
- [ ] Female version

**Ethnicity** (for each gender):
- [ ] White
- [ ] Black
- [ ] Asian
- [ ] Native
- [ ] Latino

**Total**: 10 images per occupation (2 genders × 5 ethnicities)

### AI Generation Prompts

**Paleontologist (Diverse)**:
```
[Gender] [Ethnicity] paleontologist at dig site, 
wearing hat, boots, holding shovel and brush, 
fossil visible in background, 
professional but friendly expression, 
child-friendly illustration, 
suitable for children ages 4-6, 
diverse representation, simple clean style
```

**Examples**:
- "Female Asian paleontologist at dig site, wearing hat, boots, holding shovel and brush..."
- "Male Black paleontologist at dig site, wearing hat, boots, holding shovel and brush..."
- "Female Native paleontologist at dig site..."

### Humorous Occupations

**Doctor**:
```
[Gender] [Ethnicity] doctor in hospital, 
wearing white coat, stethoscope, 
friendly expression, 
child-friendly illustration, 
diverse representation
```

**Firefighter**:
```
[Gender] [Ethnicity] firefighter, 
wearing fire helmet, holding hose, 
fire truck in background, 
friendly expression, 
child-friendly illustration, 
diverse representation
```

## Educational Facts (Max 3 per game)

```swift
struct OccupationFacts {
    let occupation: ScientificOccupation
    let facts: [String] // Maximum 3
    
    static let paleontologistFacts = OccupationFacts(
        occupation: .paleontologist,
        facts: [
            "Paleontologists dig for dinosaur bones!",
            "They use shovels and brushes to find fossils!",
            "They work at dig sites in the ground!"
        ]
    )
    
    static let geologistFacts = OccupationFacts(
        occupation: .geologist,
        facts: [
            "Geologists study rocks!",
            "They use hammers and magnifying glasses!",
            "They look at rock formations!"
        ]
    )
}
```

## Summary

✅ **Occupation Game with Diversity!**

**Key Features**:
1. **Scientific Occupations**: 7 types (paleontologist, geologist, etc.)
2. **Humorous Distractors**: Doctor, firefighter, dog catcher, scuba diver (10-20% of images)
3. **Diversity Requirement**: All images show male/female, white/black/Asian/Native/Latino
4. **Visual Identification**: Gear and background settings help identify
5. **Educational**: Teaches about different science careers

**Gameplay**:
- Matrix of images (3x3 or 4x4)
- Find the target occupation
- Humorous images add fun
- Diverse representation throughout

**Asset Requirements**:
- 10 images per occupation (2 genders × 5 ethnicities)
- Total: ~70 scientific occupation images + humorous occupation images
- All showing diverse representation

This creates an educational game that teaches children about science careers while ensuring inclusive, diverse representation!
