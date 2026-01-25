# Tool Identification Game

## Overview

Identify tools used by different professionals:
- **Paleontologist**: Map, shovel, gloves, hat, boots, sunblock, pickaxe, brush, burlap
- **Preparator**: Overhead magnifying glass, air scribe, chisel, hammer, scraper, liquid glue
- **Research Scientist**: Computer, microscope, digital camera

## Tool Categories

```swift
enum ProfessionalType {
    case paleontologist
    case preparator
    case researchScientist
}

struct Tool {
    let id: Int
    let name: String
    let icon: String
    let imageName: String
    let usedBy: [ProfessionalType]
    let description: String
}

// Paleontologist Tools
let paleontologistTools: [Tool] = [
    Tool(id: 1, name: "Map", icon: "🗺️", imageName: "map", usedBy: [.paleontologist], description: "Helps find dig sites!"),
    Tool(id: 2, name: "Shovel", icon: "🪚", imageName: "shovel", usedBy: [.paleontologist], description: "Digs in the ground!"),
    Tool(id: 3, name: "Gloves", icon: "🧤", imageName: "gloves", usedBy: [.paleontologist, .preparator], description: "Protects hands!"),
    Tool(id: 4, name: "Hat", icon: "🧢", imageName: "hat", usedBy: [.paleontologist], description: "Keeps sun away!"),
    Tool(id: 5, name: "Boots", icon: "👢", imageName: "boots", usedBy: [.paleontologist], description: "Strong shoes for walking!"),
    Tool(id: 6, name: "Sunblock", icon: "🧴", imageName: "sunblock", usedBy: [.paleontologist], description: "Protects from sun!"),
    Tool(id: 7, name: "Pickaxe", icon: "⛏️", imageName: "pickaxe", usedBy: [.paleontologist], description: "Breaks hard rocks!"),
    Tool(id: 8, name: "Brush", icon: "🪮", imageName: "brush", usedBy: [.paleontologist, .preparator], description: "Cleans fossils gently!"),
    Tool(id: 9, name: "Burlap", icon: "🧵", imageName: "burlap", usedBy: [.paleontologist], description: "Wraps fossils safely!")
]

// Preparator Tools
let preparatorTools: [Tool] = [
    Tool(id: 10, name: "Magnifying Glass", icon: "🔍", imageName: "magnifying_glass", usedBy: [.preparator], description: "See tiny details!"),
    Tool(id: 11, name: "Air Scribe", icon: "💨", imageName: "air_scribe", usedBy: [.preparator], description: "Removes rock carefully!"),
    Tool(id: 12, name: "Chisel", icon: "🔨", imageName: "chisel", usedBy: [.preparator], description: "Chips away rock!"),
    Tool(id: 13, name: "Hammer", icon: "🔨", imageName: "hammer", usedBy: [.preparator], description: "Hits chisel gently!"),
    Tool(id: 14, name: "Scraper", icon: "🔪", imageName: "scraper", usedBy: [.preparator], description: "Scrapes rock away!"),
    Tool(id: 15, name: "Liquid Glue", icon: "🧴", imageName: "glue", usedBy: [.preparator], description: "Fixes broken bones!")
]

// Research Scientist Tools
let researchScientistTools: [Tool] = [
    Tool(id: 16, name: "Computer", icon: "💻", imageName: "computer", usedBy: [.researchScientist], description: "Studies fossils on screen!"),
    Tool(id: 17, name: "Microscope", icon: "🔬", imageName: "microscope", usedBy: [.researchScientist], description: "See very tiny things!"),
    Tool(id: 18, name: "Digital Camera", icon: "📷", imageName: "camera", usedBy: [.researchScientist], description: "Takes pictures of fossils!")
]
```

## SwiftUI Implementation

### Tool Identification Game

```swift
import SwiftUI

struct ToolIdentificationView: View {
    @State private var targetProfessional: ProfessionalType = .paleontologist
    @State private var toolOptions: [Tool] = []
    @State private var selectedTool: Tool?
    @State private var showFeedback = false
    @State private var isCorrect = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Which tool does a \(targetProfessional.rawValue) use?")
                .font(.title)
                .padding()
            
            // Professional image
            ProfessionalCard(professional: targetProfessional)
                .padding()
            
            // Audio instruction
            Button(action: {
                playAudio("Which tool does a \(targetProfessional.rawValue) use? Look at the tools carefully!")
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
            
            // Tool options (grid or row)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                ForEach(toolOptions, id: \.id) { tool in
                    ToolCard(
                        tool: tool,
                        isSelected: selectedTool?.id == tool.id,
                        isCorrect: showFeedback && isCorrect && selectedTool?.id == tool.id,
                        isWrong: showFeedback && selectedTool?.id == tool.id && !isCorrect,
                        onTap: {
                            selectedTool = tool
                            checkAnswer(tool)
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
                    
                    if isCorrect, let tool = selectedTool {
                        Text("\(tool.name) - \(tool.description)")
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
        // Get tools for this professional
        let allTools = getAllTools()
        let correctTools = allTools.filter { $0.usedBy.contains(targetProfessional) }
        
        // Select one correct tool
        guard let correctTool = correctTools.randomElement() else { return }
        
        // Add correct tool + distractors
        var options: [Tool] = [correctTool]
        
        // Add tools from other professionals as distractors
        let otherTools = allTools.filter { tool in
            !tool.usedBy.contains(targetProfessional) ||
            (tool.usedBy.contains(targetProfessional) && tool.id != correctTool.id)
        }.shuffled().prefix(5)
        
        options.append(contentsOf: otherTools)
        toolOptions = Array(options.shuffled().prefix(6)) // 6 tools total
    }
    
    func getAllTools() -> [Tool] {
        return paleontologistTools + preparatorTools + researchScientistTools
    }
    
    func checkAnswer(_ tool: Tool) {
        isCorrect = tool.usedBy.contains(targetProfessional)
        showFeedback = true
        
        if isCorrect {
            playAudio("That's right! A \(targetProfessional.rawValue) uses a \(tool.name)! \(tool.description)")
            showCelebration()
            
            // Next round
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                nextRound()
            }
        } else {
            if let otherProfessional = tool.usedBy.first {
                playAudio("That tool is used by a \(otherProfessional.rawValue), not a \(targetProfessional.rawValue). Try again!")
            } else {
                playAudio("Try again! Look for tools a \(targetProfessional.rawValue) would use!")
            }
        }
    }
    
    func nextRound() {
        // Switch to different professional
        let professionals: [ProfessionalType] = [.paleontologist, .preparator, .researchScientist]
        targetProfessional = professionals.filter { $0 != targetProfessional }.randomElement() ?? .paleontologist
        setupRound()
        showFeedback = false
        selectedTool = nil
    }
}

struct ProfessionalCard: View {
    let professional: ProfessionalType
    
    var body: some View {
        VStack {
            Image("\(professional.rawValue)_professional")
                .resizable()
                .scaledToFit()
                .frame(height: 150)
            
            Text(professional.rawValue.capitalized)
                .font(.headline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.blue.opacity(0.2))
        )
    }
}

struct ToolCard: View {
    let tool: Tool
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Image(tool.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                
                Text(tool.name)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .padding()
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
```

### Professional-Specific Game Modes

```swift
struct ProfessionalToolGame: View {
    @State private var gameMode: ProfessionalType = .paleontologist
    
    var body: some View {
        VStack {
            // Professional selector
            Picker("Professional", selection: $gameMode) {
                Text("Paleontologist").tag(ProfessionalType.paleontologist)
                Text("Preparator").tag(ProfessionalType.preparator)
                Text("Research Scientist").tag(ProfessionalType.researchScientist)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Tool identification game for selected professional
            ToolIdentificationView(targetProfessional: gameMode)
        }
    }
}
```

## Educational Facts (Max 3 per game)

```swift
struct ToolFacts {
    let professional: ProfessionalType
    let tool: Tool
    let facts: [String] // Maximum 3
    
    static func getFacts(for professional: ProfessionalType, tool: Tool) -> [String] {
        var facts: [String] = []
        
        facts.append("A \(professional.rawValue) uses a \(tool.name)!")
        facts.append(tool.description)
        
        switch professional {
        case .paleontologist:
            facts.append("Paleontologists work outside at dig sites!")
        case .preparator:
            facts.append("Preparators work in labs to clean fossils!")
        case .researchScientist:
            facts.append("Research scientists study fossils in laboratories!")
        }
        
        return Array(facts.prefix(3)) // Ensure max 3
    }
}
```

## Summary

✅ **Tool Identification Game!**

**Key Features**:
1. **Three Professional Types**: Paleontologist, Preparator, Research Scientist
2. **Tool Sets**: 9 + 6 + 3 = 18 total tools
3. **Visual Identification**: Tools shown with images
4. **Educational**: Teaches what tools each professional uses
5. **Visual Learning**: No reading required

**Tool Lists**:
- **Paleontologist**: Map, shovel, gloves, hat, boots, sunblock, pickaxe, brush, burlap
- **Preparator**: Magnifying glass, air scribe, chisel, hammer, scraper, liquid glue
- **Research Scientist**: Computer, microscope, digital camera

**Gameplay**:
- Show professional
- Display 6 tool options
- Child taps correct tool
- Visual and audio feedback
- Educational facts (max 3)

**Educational Value**:
- Teaches about different science careers
- Shows tools used in each job
- Connects tools to professions
- Age-appropriate (visual matching)

This creates an engaging game that teaches children about the tools different scientists use!
