# Sound Matching Game: "Which Dinosaur Made That Sound?"

## Overview

Display three dinosaur images in a row, play a sound (roar, call, etc.), and invite the child to tap the image they think made that sound.

## Concept

```
┌─────────────────────────────────────────┐
│                                         │
│  🦕 T-Rex    🦖 Triceratops   🦕 Stego │
│                                         │
│         🔊 [Play Sound]                 │
│                                         │
│  "Which dinosaur made that sound?"     │
│                                         │
└─────────────────────────────────────────┘
```

## SwiftUI Implementation

### Basic Structure

```swift
import SwiftUI
import AVFoundation

struct SoundMatchingView: View {
    @State private var currentRound: Int = 1
    @State private var selectedImage: Int?
    @State private var correctAnswer: Int = 0
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var audioPlayer: AVAudioPlayer?
    
    // Current round's images and correct answer
    @State private var currentImages: [DinosaurImage] = []
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Which dinosaur made that sound?")
                .font(.title)
                .padding()
            
            // Three images in a row
            HStack(spacing: 20) {
                ForEach(Array(currentImages.enumerated()), id: \.element.id) { index, image in
                    DinosaurImageCard(
                        image: image,
                        isSelected: selectedImage == index,
                        isCorrect: showFeedback && index == correctAnswer,
                        isWrong: showFeedback && selectedImage == index && index != correctAnswer,
                        onTap: {
                            handleImageTap(index)
                        }
                    )
                }
            }
            .padding()
            
            // Play sound button
            Button(action: {
                playSound()
            }) {
                HStack {
                    Image(systemName: "speaker.wave.3")
                    Text("Play Sound")
                }
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            
            // Feedback
            if showFeedback {
                VStack {
                    Text(isCorrect ? "🎉 Correct!" : "❌ Try again!")
                        .font(.headline)
                        .foregroundColor(isCorrect ? .green : .red)
                    
                    if !isCorrect {
                        Button(action: {
                            playSound() // Replay sound
                            resetSelection()
                        }) {
                            Text("Listen again")
                        }
                        .padding()
                    } else {
                        Button(action: {
                            nextRound()
                        }) {
                            Text("Next")
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            setupRound()
        }
    }
    
    func setupRound() {
        // Select 3 random dinosaurs (one correct, two distractors)
        let allDinosaurs = DinosaurImage.allDinosaurs
        let shuffled = allDinosaurs.shuffled()
        currentImages = Array(shuffled.prefix(3))
        
        // Randomly choose which one is correct
        correctAnswer = Int.random(in: 0..<3)
        
        // Reset state
        selectedImage = nil
        showFeedback = false
        isCorrect = false
    }
    
    func playSound() {
        // Play the sound of the correct dinosaur
        let correctDinosaur = currentImages[correctAnswer]
        playAudioFile(correctDinosaur.soundFileName)
    }
    
    func handleImageTap(_ index: Int) {
        selectedImage = index
        isCorrect = (index == correctAnswer)
        showFeedback = true
        
        if isCorrect {
            // Play success sound
            playSuccessSound()
            
            // Play spoken feedback
            playAudio("That's right! That was the \(currentImages[correctAnswer].name)!")
            
            // Auto-advance after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                nextRound()
            }
        } else {
            // Play try again sound
            playTryAgainSound()
            
            // Play spoken feedback
            playAudio("Try again! Listen to the sound one more time.")
        }
    }
    
    func resetSelection() {
        selectedImage = nil
        showFeedback = false
    }
    
    func nextRound() {
        currentRound += 1
        setupRound()
    }
    
    func playAudioFile(_ fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
            print("Audio file not found: \(fileName)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error)")
        }
    }
    
    func playAudio(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.4
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    func playSuccessSound() {
        playAudioFile("success_chime")
    }
    
    func playTryAgainSound() {
        playAudioFile("try_again")
    }
}
```

### Data Model

```swift
struct DinosaurImage: Identifiable {
    let id: Int
    let name: String
    let icon: String
    let imageName: String
    let soundFileName: String // e.g., "trex_roar"
    
    static let allDinosaurs: [DinosaurImage] = [
        DinosaurImage(id: 1, name: "T-Rex", icon: "🦕", imageName: "trex", soundFileName: "trex_roar"),
        DinosaurImage(id: 2, name: "Triceratops", icon: "🦖", imageName: "triceratops", soundFileName: "triceratops_call"),
        DinosaurImage(id: 3, name: "Stegosaurus", icon: "🦕", imageName: "stegosaurus", soundFileName: "stegosaurus_roar"),
        DinosaurImage(id: 4, name: "Brontosaurus", icon: "🦖", imageName: "brontosaurus", soundFileName: "brontosaurus_call"),
        DinosaurImage(id: 5, name: "Velociraptor", icon: "🦕", imageName: "velociraptor", soundFileName: "velociraptor_screech"),
        DinosaurImage(id: 6, name: "Pterodactyl", icon: "🦖", imageName: "pterodactyl", soundFileName: "pterodactyl_scream"),
        // ... more dinosaurs
    ]
}
```

### Image Card Component

```swift
struct DinosaurImageCard: View {
    let image: DinosaurImage
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
                    .frame(width: 150, height: 150)
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
                                lineWidth: 4
                            )
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isSelected)
                
                if !isCorrect {
                    Text(image.name)
                        .font(.caption)
                }
            }
        }
        .disabled(showFeedback && !isCorrect) // Disable after feedback shown
    }
}
```

## Enhanced Features

### Auto-Play on Round Start

```swift
struct SoundMatchingView: View {
    @State private var autoPlayEnabled = true
    
    var body: some View {
        // ... existing code ...
        .onAppear {
            setupRound()
            if autoPlayEnabled {
                // Auto-play sound when round starts
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    playSound()
                }
            }
        }
    }
}
```

### Visual Feedback Enhancements

```swift
struct DinosaurImageCard: View {
    // ... existing properties ...
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Image
                Image(image.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                
                // Overlay effects
                if isCorrect {
                    // Success animation
                    ConfettiEffect()
                }
                
                if isWrong {
                    // Shake animation
                    ShakeEffect()
                }
            }
            .background(/* ... */)
        }
    }
}

struct ShakeEffect: ViewModifier {
    @State private var shake = false
    
    func body(content: Content) -> some View {
        content
            .offset(x: shake ? -10 : 10)
            .animation(.easeInOut(duration: 0.1).repeatCount(3), value: shake)
            .onAppear {
                shake = true
            }
    }
}
```

### Multiple Sound Types

```swift
enum SoundType {
    case roar
    case call
    case screech
    case footstep
    case eating
}

struct DinosaurImage {
    // ... existing properties ...
    let soundTypes: [SoundType: String] // Multiple sounds per dinosaur
    
    func getSoundFileName(for type: SoundType) -> String {
        return soundTypes[type] ?? soundTypes[.roar]!
    }
}

// In game view
func playSound() {
    let correctDinosaur = currentImages[correctAnswer]
    let soundType: SoundType = .roar // Or randomize
    let fileName = correctDinosaur.getSoundFileName(for: soundType)
    playAudioFile(fileName)
}
```

### Difficulty Levels

```swift
enum Difficulty {
    case easy    // 2 images, very distinct sounds
    case medium  // 3 images, somewhat similar sounds
    case hard    // 4 images, similar sounds
}

struct SoundMatchingView: View {
    @State private var difficulty: Difficulty = .easy
    
    func setupRound() {
        let allDinosaurs = DinosaurImage.allDinosaurs
        
        switch difficulty {
        case .easy:
            // Choose very different dinosaurs
            currentImages = selectDistinctDinosaurs(count: 2, from: allDinosaurs)
        case .medium:
            currentImages = selectDistinctDinosaurs(count: 3, from: allDinosaurs)
        case .hard:
            currentImages = selectDistinctDinosaurs(count: 4, from: allDinosaurs)
        }
        
        correctAnswer = Int.random(in: 0..<currentImages.count)
    }
    
    func selectDistinctDinosaurs(count: Int, from all: [DinosaurImage]) -> [DinosaurImage] {
        // Select dinosaurs with very different sounds
        // This could use a sound similarity matrix
        return Array(all.shuffled().prefix(count))
    }
}
```

## Audio Asset Strategy

### Sound File Organization

```
Assets/
├── Audio/
│   ├── Dinosaurs/
│   │   ├── trex_roar.m4a
│   │   ├── trex_call.m4a
│   │   ├── triceratops_call.m4a
│   │   ├── stegosaurus_roar.m4a
│   │   └── ...
│   ├── Feedback/
│   │   ├── success_chime.m4a
│   │   ├── try_again.m4a
│   │   └── correct.m4a
│   └── Instructions/
│       └── which_dinosaur.m4a
```

### Sound File Requirements

- **Format**: AAC (M4A) for iOS compatibility
- **Duration**: 2-5 seconds (short enough to replay easily)
- **Quality**: Clear, recognizable sounds
- **Volume**: Normalized (consistent volume levels)
- **Content**: Distinctive sounds per dinosaur

### Creating/Obtaining Sounds

**Option 1: Sound Effects Libraries**
- Freesound.org (free, requires attribution)
- Zapsplat (free with account)
- AudioJungle (paid, high quality)

**Option 2: AI-Generated Sounds**
- ElevenLabs (voice/sound generation)
- Mubert (AI music/sound)
- Create dinosaur-like roars

**Option 3: Synthesized Sounds**
- Use audio synthesis tools
- Create distinctive roars/calls per species

## Game Flow

### Round Structure

1. **Round Start**
   - Display 3 dinosaur images
   - Auto-play sound (or wait for button tap)
   - Spoken: "Which dinosaur made that sound?"

2. **Child Interaction**
   - Child taps an image
   - Visual feedback (highlight, animation)
   - Audio feedback (success/try again)

3. **Correct Answer**
   - Success animation
   - Spoken: "That's right! That was the [dinosaur name]!"
   - Auto-advance to next round after 3 seconds

4. **Wrong Answer**
   - Shake animation
   - Spoken: "Try again! Listen to the sound one more time."
   - Sound replay button appears
   - Child can try again

### Game State Management

```swift
class SoundMatchingGameState: ObservableObject {
    @Published var currentRound: Int = 1
    @Published var score: Int = 0
    @Published var totalRounds: Int = 10
    @Published var difficulty: Difficulty = .easy
    
    func recordCorrectAnswer() {
        score += 1
    }
    
    func isGameComplete() -> Bool {
        return currentRound > totalRounds
    }
    
    func nextRound() {
        currentRound += 1
    }
}
```

## Accessibility & Child-Friendly Design

### Visual Design

- **Large images**: 150x150 points minimum**
- **Clear visual feedback**: Color changes, animations
- **Simple layout**: Three images in a row, easy to see
- **Large play button**: Easy to tap

### Audio Design

- **Clear sounds**: Distinctive, recognizable
- **Replayable**: Can play sound multiple times
- **Spoken instructions**: "Which dinosaur made that sound?"
- **Spoken feedback**: "That's right!" or "Try again!"

### Interaction

- **Tap to select**: Simple, intuitive
- **Visual highlight**: Shows which image was tapped
- **No reading required**: All instructions spoken
- **Forgiving**: Can replay sound and try again

## Variations

### Variation 1: Sound First, Then Images

```swift
// Play sound first
playSound()

// Then show images after sound finishes
DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    showImages = true
}
```

### Variation 2: Multiple Sounds

```swift
// Play 2-3 sounds, child identifies all
let sounds = [sound1, sound2, sound3]
// Child taps images in order
```

### Variation 3: Sound + Visual Clue

```swift
// Play sound + show partial image (head, tail, etc.)
// Child matches sound to partial visual
```

## Summary

✅ **Fully Possible!**

**Key Components**:
1. Three images displayed in a row
2. Audio playback (dinosaur sounds)
3. Tap detection on images
4. Correct answer validation
5. Visual feedback (highlight, animation)
6. Audio feedback (spoken responses)
7. Game progression (next round)

**Benefits**:
- Educational (learns dinosaur sounds)
- Engaging (audio-visual matching)
- Child-friendly (simple tap interaction)
- Audio-supported (all instructions spoken)
- No reading required (visual + audio only)

**Audio Assets Needed**:
- 6-10 dinosaur sound files (roars, calls, etc.)
- Success/try again feedback sounds
- Spoken instructions (or use TTS)

This creates an engaging audio recognition game that teaches children to identify dinosaurs by their sounds!
