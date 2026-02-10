# Level Progression System

## Concept

Games appear as levels numbered 1, 2, 3. After level 1 is completed, it scrolls off the bottom screen and level 4 appears at the top.

## Visual Design

```
Before Completion:
┌─────────────────────────────────────────┐
│                                         │
│     Level 3                            │
│     [Game Preview]                     │
│                                         │
│     Level 2                            │
│     [Game Preview]                     │
│                                         │
│     Level 1 ⭐ (Current)               │
│     [Game Preview]                     │
│                                         │
└─────────────────────────────────────────┘

After Level 1 Complete:
┌─────────────────────────────────────────┐
│                                         │
│     Level 4 (New!)                     │
│     [Game Preview]                     │
│                                         │
│     Level 3                            │
│     [Game Preview]                     │
│                                         │
│     Level 2 ⭐ (Current)               │
│     [Game Preview]                     │
│                                         │
│     Level 1 ✅ (Completed, scrolling) │
│     [Game Preview]                      │
│                                         │
└─────────────────────────────────────────┘
```

## SwiftUI Implementation

### Basic Level Progression

```swift
import SwiftUI

struct LevelProgressionView: View {
    @State private var levels: [GameLevel] = []
    @State private var currentLevelIndex: Int = 0
    @State private var completedLevels: Set<Int> = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
                    LevelCard(
                        level: level,
                        isCurrent: index == currentLevelIndex,
                        isCompleted: completedLevels.contains(level.id),
                        onTap: {
                            startLevel(level)
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding()
        }
        .onAppear {
            initializeLevels()
        }
    }
    
    func initializeLevels() {
        // Start with levels 1, 2, 3
        levels = [
            GameLevel(id: 1, number: 1, game: .nameThatDinosaur),
            GameLevel(id: 2, number: 2, game: .matchingGame),
            GameLevel(id: 3, number: 3, game: .soundMatching)
        ]
    }
    
    func startLevel(_ level: GameLevel) {
        // Start the game
        // When completed, call levelCompleted(level)
    }
    
    func levelCompleted(_ level: GameLevel) {
        // Mark as completed
        completedLevels.insert(level.id)
        
        // Scroll completed level off
        withAnimation(.easeInOut(duration: 1.0)) {
            // Remove completed level from view
            if let index = levels.firstIndex(where: { $0.id == level.id }) {
                levels.remove(at: index)
            }
            
            // Add new level at top
            let nextLevelNumber = levels.count + completedLevels.count + 1
            let newLevel = GameLevel(
                id: nextLevelNumber,
                number: nextLevelNumber,
                game: getRandomGame()
            )
            levels.insert(newLevel, at: 0)
            
            // Update current level
            currentLevelIndex = min(currentLevelIndex + 1, levels.count - 1)
        }
        
        // Celebration
        showCelebration()
        playAudio("Great job! Level \(level.number) complete! Here comes level \(newLevel.number)!")
    }
}

struct GameLevel: Identifiable {
    let id: Int
    let number: Int
    let game: GameType
    let isLocked: Bool = false
}

struct LevelCard: View {
    let level: GameLevel
    let isCurrent: Bool
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Level number
                VStack {
                    Text("Level")
                        .font(.caption)
                    Text("\(level.number)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .frame(width: 80)
                
                // Game preview
                VStack(alignment: .leading) {
                    Text(level.game.displayName)
                        .font(.headline)
                    
                    Image(level.game.previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                }
                
                Spacer()
                
                // Status indicator
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.largeTitle)
                } else if isCurrent {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.largeTitle)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isCurrent ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isCurrent ? Color.blue : Color.clear, lineWidth: 3)
            )
        }
        .disabled(isCompleted) // Can't replay completed levels (or allow if desired)
    }
}
```

### Smooth Scrolling Animation

```swift
struct AnimatedLevelProgression: View {
    @State private var levels: [GameLevel] = []
    @State private var isAnimating: Bool = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(levels) { level in
                        LevelCard(level: level)
                            .id(level.id)
                    }
                }
                .padding()
            }
            .onChange(of: levels.count) { _ in
                // Scroll to show new level
                if let newLevel = levels.first {
                    withAnimation {
                        proxy.scrollTo(newLevel.id, anchor: .top)
                    }
                }
            }
        }
    }
    
    func levelCompleted(_ level: GameLevel) {
        isAnimating = true
        
        // Animate completed level scrolling off
        withAnimation(.easeInOut(duration: 1.0)) {
            // Move completed level down and fade
            if let index = levels.firstIndex(where: { $0.id == level.id }) {
                // Animate out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    levels.remove(at: index)
                }
            }
        }
        
        // Add new level at top
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let newLevel = createNextLevel()
            withAnimation(.easeInOut(duration: 0.5)) {
                levels.insert(newLevel, at: 0)
            }
            
            isAnimating = false
        }
    }
}
```

### Level Card with Completion Animation

```swift
struct LevelCard: View {
    let level: GameLevel
    let isCurrent: Bool
    let isCompleted: Bool
    @State private var showCompletionAnimation = false
    
    var body: some View {
        ZStack {
            // Card content
            HStack {
                // ... card content ...
            }
            .padding()
            .background(/* ... */)
            
            // Completion animation
            if showCompletionAnimation {
                CompletionAnimation()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: isCompleted) { completed in
            if completed {
                showCompletionAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showCompletionAnimation = false
                }
            }
        }
    }
}

struct CompletionAnimation: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // Confetti
            ForEach(0..<20) { _ in
                Circle()
                    .fill(Color.random)
                    .frame(width: 10, height: 10)
                    .offset(
                        x: CGFloat.random(in: -50...50),
                        y: CGFloat.random(in: -50...50)
                    )
            }
            
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring()) {
                scale = 1.0
            }
            withAnimation(.easeOut(duration: 1.0)) {
                opacity = 0.0
            }
        }
    }
}
```

### Level Management

```swift
class LevelManager: ObservableObject {
    @Published var levels: [GameLevel] = []
    @Published var currentLevelIndex: Int = 0
    @Published var completedLevelIds: Set<Int> = []
    
    init() {
        initializeLevels()
    }
    
    func initializeLevels() {
        levels = [
            GameLevel(id: 1, number: 1, game: .nameThatDinosaur),
            GameLevel(id: 2, number: 2, game: .matchingGame),
            GameLevel(id: 3, number: 3, game: .soundMatching)
        ]
    }
    
    func completeLevel(_ levelId: Int) {
        guard !completedLevelIds.contains(levelId) else { return }
        
        completedLevelIds.insert(levelId)
        
        // Remove completed level
        levels.removeAll { $0.id == levelId }
        
        // Add new level
        let nextNumber = completedLevelIds.count + levels.count + 1
        let newLevel = GameLevel(
            id: nextNumber,
            number: nextNumber,
            game: selectNextGame()
        )
        
        levels.insert(newLevel, at: 0)
        
        // Update current level index
        if currentLevelIndex >= levels.count {
            currentLevelIndex = levels.count - 1
        }
    }
    
    func selectNextGame() -> GameType {
        // Select game type for new level
        // Could be random, or follow a pattern
        let allGames: [GameType] = [.nameThatDinosaur, .matchingGame, .soundMatching, .sizeComparison]
        return allGames.randomElement() ?? .nameThatDinosaur
    }
    
    var currentLevel: GameLevel? {
        guard currentLevelIndex < levels.count else { return nil }
        return levels[currentLevelIndex]
    }
}
```

### Visual Enhancements

```swift
struct EnhancedLevelCard: View {
    let level: GameLevel
    let isCurrent: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            // Level number with badge
            ZStack {
                Circle()
                    .fill(isCurrent ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Text("\(level.number)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(isCurrent ? .white : .primary)
            }
            
            // Game preview image
            Image(level.game.previewImage)
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .cornerRadius(10)
            
            // Game name
            Text(level.game.displayName)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // Status badge
            if isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete!")
                }
                .foregroundColor(.green)
                .font(.caption)
            } else if isCurrent {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Play Now!")
                }
                .foregroundColor(.blue)
                .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: isCurrent ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), radius: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isCurrent ? Color.blue : Color.clear, lineWidth: 3)
        )
    }
}
```

## Summary

✅ **Level Progression System!**

**Key Features**:
1. **Visible Levels**: Shows 1, 2, 3 (or more) at once
2. **Completion Animation**: Level scrolls off bottom when completed
3. **New Level Appears**: Level 4 appears at top after level 1 complete
4. **Smooth Transitions**: Animated scrolling and appearance
5. **Visual Feedback**: Current level highlighted, completed levels marked

**Benefits**:
- Clear progression
- Visual feedback
- Sense of accomplishment
- Always new content
- Engaging animation

**Implementation**:
- ScrollView with VStack
- Animated transitions
- Level management system
- Completion tracking
- Dynamic level generation

This creates an engaging progression system that shows children their progress while always providing new challenges!
