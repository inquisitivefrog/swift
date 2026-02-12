//
//  GuessGameView.swift
//  DinoGames
//
//  Created by Timothy Stilwell on 1/26/26.
//

import SwiftUI
import AVFoundation

// MARK: - Data Models

struct RoundQuestion: Identifiable {
    let id: Int // Round number (1, 2, 3)
    let questionImageName: String // Silhouette image name
    let questionImageFallback: String? // Fallback full image name
    let correctAnswerId: Int // ID of the correct dinosaur
    let options: [Dinosaur] // 3 dinosaurs: 1 correct + 2 decoys (all unique)
}

// MARK: - Game Configuration

struct GuessGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let rounds: [RoundQuestion] // 3 rounds of questions
    let availableDinosaurs: [Dinosaur] // All available dinosaurs for options
}

// MARK: - Main View

struct GuessGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: GuessGameConfig
    
    @State private var speechManager = SpeechManager()
    @State private var currentRound = 1 // 1, 2, or 3
    @State private var selectedDinosaur: Dinosaur?
    @State private var isAudioPlaying = false
    @State private var errorCount = 0 // Track errors across all rounds
    @State private var successCount = 0 // Track successful rounds
    @State private var wrongGuessesThisRound = 0
    @State private var isGameComplete = false
    @State private var isProcessingAnswer = false
    
    /// End sequence: -1 none, 1 = walking row (highlight + name audio), 2 = good-job + crowd then dismiss
    @State private var endSequenceStep: Int = -1
    @State private var endHighlightIndex: Int = 0
    
    /// Options walk: highlight each of the 3 choices and play name before allowing selection (each round).
    @State private var optionsWalkIndex: Int? = nil

    /// When true, show the Source Footprints hints overlay (Dino Footprints only).
    @State private var showSourceFootprintsHints = false

    /// The 3 correct dinosaurs in round order (for end-sequence row)
    private var endSequenceDinosaurs: [Dinosaur] {
        gameConfig.rounds.map { r in r.options.first(where: { $0.id == r.correctAnswerId })! }
    }
    
    // Get current round question
    private var currentQuestion: RoundQuestion? {
        gameConfig.rounds.first { $0.id == currentRound }
    }
    
    // Reset game state
    private func resetGameState() {
        currentRound = 1
        selectedDinosaur = nil
        errorCount = 0
        successCount = 0
        wrongGuessesThisRound = 0
        isGameComplete = false
        isProcessingAnswer = false
        endSequenceStep = -1
        endHighlightIndex = 0
        optionsWalkIndex = nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Title
                Text(gameConfig.title)
                    .font(.largeTitle)
                    .padding(.top)
                
                if let question = currentQuestion, !isGameComplete {
                    // Main game area - one question at a time
                    VStack(spacing: 40) {
                        // Top: Question image (silhouette), then round label below
                        VStack(spacing: 10) {
                            // Silhouette image
                            if UIImage(named: question.questionImageName) != nil {
                                Image(question.questionImageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 250, height: 250)
                            } else if let fallback = question.questionImageFallback, !fallback.isEmpty {
                                // Fallback: use full image with silhouette effect
                                Image(fallback)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 250, height: 250)
                                    .colorMultiply(.black)
                                    .opacity(0.8)
                            } else {
                                // Ultimate fallback: placeholder
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 250, height: 250)
                            }
                            Text("Round \(currentRound) of 3")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        
                        // Bottom: 3 dinosaur options in a row (options walk highlights each, then tap enabled)
                        HStack(spacing: 8) {
                            ForEach(Array(question.options.enumerated()), id: \.element.id) { index, dinosaur in
                                DinosaurOptionCard(
                                    dinosaur: dinosaur,
                                    isSelected: selectedDinosaur?.id == dinosaur.id,
                                    isDisabled: isProcessingAnswer || isAudioPlaying || optionsWalkIndex != nil,
                                    isHighlighted: optionsWalkIndex == index,
                                    onTap: {
                                        handleDinosaurTap(dinosaur, question: question)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .frame(maxWidth: .infinity)
                } else if isGameComplete {
                    // End sequence: darkened row of 3 dinosaurs → walk row (highlight + name audio) → good-job + crowd → dismiss
                    guessGameEndSequenceView
                }
            }
            .padding()
            .onAppear {
                resetGameState()
                speechManager.isPlaying = false
                speechManager.onAudioFinished = nil
                speechManager.onAudioFinished = {
                    isAudioPlaying = false
                }
                // Intro already played on the transition screen; for Dino Footprints play round intro at start of each round
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    startRoundIfNeeded()
                }
            }
            .onChange(of: currentRound) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startRoundIfNeeded()
                }
            }
            .onDisappear {
                speechManager.onAudioFinished = nil
                speechManager.stopCurrentAudio()
                isAudioPlaying = false
            }
            .allowsHitTesting(!isAudioPlaying && !isProcessingAnswer && optionsWalkIndex == nil)
            .opacity((isAudioPlaying || isProcessingAnswer) ? 0.7 : 1.0)
            .overlay(alignment: .topTrailing) {
                if gameConfig.id == "dino-footprints", currentQuestion != nil, !isGameComplete {
                    Button {
                        showSourceFootprintsHints = true
                    } label: {
                        Text("Hints")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Circle().fill(Color.blue))
                            .frame(width: 72, height: 72)
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 16)
                }
            }
            .fullScreenCover(isPresented: $showSourceFootprintsHints) {
                SourceFootprintsHintsView(onDismiss: { showSourceFootprintsHints = false })
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    /// Starts the round: for Dino Footprints plays "identify the footprint" then options walk; for other guess games goes straight to options walk.
    private func startRoundIfNeeded() {
        guard let question = currentQuestion, !question.options.isEmpty, optionsWalkIndex == nil else { return }
        if gameConfig.id == "dino-footprints" {
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.playFootprintsHintThenStartOptionsWalk()
            }
            speechManager.speak("game-dino-footprints-identify-the-footprint")
        } else {
            startOptionsWalkIfNeeded()
        }
    }

    /// Plays game-hint then starts the options walk. Keeps isAudioPlaying true so taps are blocked (no click sounds).
    private func playFootprintsHintThenStartOptionsWalk() {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.startOptionsWalkIfNeeded()
        }
        if let url = speechManager.urlForAudio(key: "game-hint") {
            speechManager.playAudioFile(url: url)
        } else {
            startOptionsWalkIfNeeded()
        }
    }

    private func startOptionsWalkIfNeeded() {
        guard let question = currentQuestion, !question.options.isEmpty, optionsWalkIndex == nil else { return }
        optionsWalkIndex = 0
        isAudioPlaying = true
        speechManager.onAudioFinished = { advanceOptionsWalk() }
        speechManager.speak(audioKey: question.options[0].imageName ?? question.options[0].name, fallbackText: question.options[0].name)
    }

    private func advanceOptionsWalk() {
        speechManager.onAudioFinished = nil
        guard let question = currentQuestion else {
            optionsWalkIndex = nil
            isAudioPlaying = false
            return
        }
        let next = (optionsWalkIndex ?? 0) + 1
        if next >= question.options.count {
            optionsWalkIndex = nil
            isAudioPlaying = false
            return
        }
        optionsWalkIndex = next
        speechManager.onAudioFinished = { advanceOptionsWalk() }
        speechManager.speak(audioKey: question.options[next].imageName ?? question.options[next].name, fallbackText: question.options[next].name)
    }

    private func handleDinosaurTap(_ dinosaur: Dinosaur, question: RoundQuestion) {
        guard !isProcessingAnswer && !isAudioPlaying && optionsWalkIndex == nil else { return }
        
        selectedDinosaur = dinosaur
        isAudioPlaying = true
        
        // Wait for dinosaur name to finish before playing thats-right / try-again (avoids truncation)
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.checkAnswer(dinosaur: dinosaur, question: question)
        }
        speechManager.speak(audioKey: dinosaur.imageName ?? dinosaur.name, fallbackText: dinosaur.name)
    }
    
    private func checkAnswer(dinosaur: Dinosaur, question: RoundQuestion) {
        isProcessingAnswer = true
        let isCorrectAnswer = dinosaur.id == question.correctAnswerId
        
        if isCorrectAnswer {
            // Correct! Play success audio; round/game advances after it finishes (no feedback text)
            successCount += 1
            wrongGuessesThisRound = 0
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                DispatchQueue.main.async {
                    self.selectedDinosaur = nil
                    if self.currentRound < 3 {
                        self.currentRound += 1
                        self.wrongGuessesThisRound = 0
                        self.isProcessingAnswer = false
                        self.isAudioPlaying = false
                        // startOptionsWalkIfNeeded() will run from .onChange(of: currentRound)
                    } else {
                        self.isGameComplete = true
                        // End sequence (darkened row → highlight + name → good-job + crowd → dismiss) runs in guessGameEndSequenceView
                    }
                }
            }
            speechManager.speak("thats-right-you-guessed-it")
        } else {
            wrongGuessesThisRound += 1
            errorCount += 1
            isAudioPlaying = true
            // No auto-skip: allow unlimited attempts so kids can map sound ↔ image.
            speechManager.speak("try-again")
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                DispatchQueue.main.async {
                    self.isAudioPlaying = false
                    self.selectedDinosaur = nil
                    self.isProcessingAnswer = false
                }
            }
        }
    }
    
    // MARK: - End sequence (3 rows: image left, name right → highlight each + name audio → good-job + crowd → dismiss)
    
    private var guessGameEndSequenceView: some View {
        VStack(spacing: 16) {
            Text("Good job!")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.top, 8)
                .padding(.bottom, 8)
            VStack(spacing: 12) {
                ForEach(Array(endSequenceDinosaurs.enumerated()), id: \.element.id) { index, dinosaur in
                    let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                    HStack(spacing: 16) {
                        guessGameEndSequenceImage(dinosaur: dinosaur, isHighlighted: isHighlighted)
                        Text(dinosaur.name)
                            .font(.title2)
                            .fontWeight(isHighlighted ? .semibold : .regular)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .opacity(isHighlighted ? 1.0 : 0.5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            if endSequenceDinosaurs.isEmpty {
                playGoodJobAndCrowdThenDismiss()
            } else {
                speechManager.speak(audioKey: endSequenceDinosaurs[0].imageName ?? endSequenceDinosaurs[0].name, fallbackText: endSequenceDinosaurs[0].name)
                speechManager.onAudioFinished = { advanceEndHighlight() }
            }
        }
    }
    
    private func guessGameEndSequenceImage(dinosaur: Dinosaur, isHighlighted: Bool) -> some View {
        Group {
            if let imageName = dinosaur.imageName, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .opacity(isHighlighted ? 1.0 : 0.4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
            } else {
                Text(dinosaur.icon)
                    .font(.system(size: 40))
                    .frame(width: 72, height: 72)
                    .opacity(isHighlighted ? 1.0 : 0.4)
            }
        }
    }
    
    private func advanceEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < endSequenceDinosaurs.count {
            speechManager.speak(audioKey: endSequenceDinosaurs[endHighlightIndex].imageName ?? endSequenceDinosaurs[endHighlightIndex].name, fallbackText: endSequenceDinosaurs[endHighlightIndex].name)
            speechManager.onAudioFinished = { advanceEndHighlight() }
        } else {
            playGoodJobAndCrowdThenDismiss()
        }
    }
    
    private func playGoodJobAndCrowdThenDismiss() {
        endSequenceStep = 2
        let goodJobURL = speechManager.urlForAudio(key: "good-job-you-got-them-all")
        let crowdURL = speechManager.urlForAudio(key: "crowd-cheering")
        if let u1 = goodJobURL, let u2 = crowdURL {
            speechManager.playTogether(url1: u1, url2: u2) {
                self.speechManager.onAudioFinished = nil
                self.isPresented = false
            }
        } else if let u = goodJobURL ?? crowdURL {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.isPresented = false
            }
            speechManager.playAudioFile(url: u)
        } else {
            isPresented = false
        }
    }
}

// MARK: - Dinosaur Option Card View

struct DinosaurOptionCard: View {
    let dinosaur: Dinosaur
    let isSelected: Bool
    let isDisabled: Bool
    /// When true (e.g. Find Mama options walk), show same highlight and name as selected.
    var isHighlighted: Bool = false
    let onTap: () -> Void

    private var showHighlight: Bool { isSelected || isHighlighted }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Dinosaur image or emoji (show icon when image asset is missing, e.g. some dinosaurs in catalog)
                if let imageName = dinosaur.imageName, UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 90, height: 90)
                } else {
                    Text(dinosaur.icon)
                        .font(.system(size: 60))
                }

                // Dinosaur name (shown when selected or highlighted during options walk)
                if showHighlight {
                    Text(dinosaur.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .allowsTightening(true)
                        .multilineTextAlignment(TextAlignment.center)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .frame(width: showHighlight ? 120 : 100, height: showHighlight ? 150 : 120)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(showHighlight ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(showHighlight ? Color.blue : Color.clear, lineWidth: 3)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

// MARK: - Source Footprints Hints (Dino Footprints)

/// One clade entry for the 2×2 source-footprints hints grid. Uses image set source-footprints-{clade} and audio Footprints/{clade}.m4a.
private struct SourceFootprintCladeHint: Identifiable {
    let id: String
    let imageName: String  // e.g. source-footprints-therapod
    let displayName: String
    let audioKey: String  // e.g. footprint-therapod → Footprints/therapod.m4a
}

private let sourceFootprintsHintClades: [SourceFootprintCladeHint] = [
    SourceFootprintCladeHint(id: "therapod", imageName: "source-footprints-therapod", displayName: "Theropod", audioKey: "footprint-therapod"),
    SourceFootprintCladeHint(id: "sauropod", imageName: "source-footprints-sauropod", displayName: "Sauropod", audioKey: "footprint-sauropod"),
    SourceFootprintCladeHint(id: "hadrosaur", imageName: "source-footprints-hadrosaur", displayName: "Hadrosaur", audioKey: "footprint-hadrosaur"),
    SourceFootprintCladeHint(id: "ceratopsian", imageName: "source-footprints-ceratopsian", displayName: "Ceratopsian", audioKey: "footprint-ceratopsian"),
    SourceFootprintCladeHint(id: "ankylosaur", imageName: "source-footprints-ankylosaur", displayName: "Ankylosaur", audioKey: "footprint-ankylosaur"),
]

struct SourceFootprintsHintsView: View {
    let onDismiss: () -> Void
    @State private var speechManager = SpeechManager()
    @State private var selectedClade: SourceFootprintCladeHint?

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 20) {
                Text("Source Footprints")
                    .font(.title2.weight(.semibold))
                    .padding(.top, 44)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    ForEach(sourceFootprintsHintClades) { clade in
                        Button {
                            selectedClade = clade
                            if let url = speechManager.urlForAudio(key: clade.audioKey) {
                                speechManager.playAudioFile(url: url)
                            } else {
                                speechManager.speak(clade.displayName)
                            }
                        } label: {
                            if UIImage(named: clade.imageName) != nil {
                                Image(clade.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 120)
                                    .clipped()
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 120)
                                    .overlay(Text(clade.displayName).font(.caption).foregroundColor(.secondary))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))

            // Back to game: < in upper left
            Button {
                onDismiss()
            } label: {
                Text("<")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
            }
            .padding(.leading, 8)
            .padding(.top, 8)

            // Enlarged + name overlay when a grid item was tapped
            if let clade = selectedClade {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { selectedClade = nil }
                VStack(spacing: 16) {
                    if UIImage(named: clade.imageName) != nil {
                        Image(clade.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 280, maxHeight: 280)
                    }
                    Text(clade.displayName)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.primary)
                }
                .padding(24)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
                .onTapGesture { selectedClade = nil }
            }
        }
    }
}

// MARK: - Dino Footprints (clade + size)

/// Footprint image sets: footprint-{clade}-{size} (scale: small, medium, large within each clade).
/// Use imageNameForAsset for lookup; asset names use "therapod" (common misspelling) for theropod.
private enum DinoClade: String, CaseIterable {
    case theropod
    case sauropod
    case hadrosaur
    case ceratopsian

    /// Name used in footprint image set names (footprint-{this}-{size}). Matches Assets.xcassets spelling.
    var imageNameForAsset: String {
        switch self {
        case .theropod: return "therapod"  // assets are footprint-therapod-* (misspelling)
        default: return rawValue
        }
    }
}

private enum DinoSize: String, CaseIterable {
    case small
    case medium
    case large
}

/// Map of dinosaur slug (dino-* suffix) → (clade, presumed footprint size). Only dinosaurs listed here are playable in Dino Footprints. Add new species here when you add them to the app.
private let footprintDinosaurMap: [String: (clade: DinoClade, size: DinoSize)] = [
    // Theropods
    "trex": (.theropod, .large),
    "velociraptor": (.theropod, .small),
    "spinosaurus": (.theropod, .large),
    "troodon": (.theropod, .small),
    "therizinosaurus": (.theropod, .medium),
    "masiakasaurus": (.theropod, .small),
    "torvosaurus": (.theropod, .large),
    "majungasaurus": (.theropod, .large),
    "allosaurus": (.theropod, .large),
    "oviraptor": (.theropod, .small),
    "compsognathus": (.theropod, .small),
    "microraptor": (.theropod, .small),
    "giganotosaurus": (.theropod, .large),
    "deinonychus": (.theropod, .medium),
    "dromeosaurus": (.theropod, .medium),
    // Sauropods
    "apatosaurus": (.sauropod, .large),
    "diplodocus": (.sauropod, .large),
    "camarasaurus": (.sauropod, .large),
    "rapetosaurus": (.sauropod, .large),
    // Ceratopsians
    "triceratops": (.ceratopsian, .large),
    "chasmosaurus": (.ceratopsian, .medium),
    "torosaurus": (.ceratopsian, .large),
    "kosmoceratops": (.ceratopsian, .medium),
    // Hadrosaurs and other ornithischians (stegosaurs, ankylosaurs, etc.)
    "stegosaurus": (.hadrosaur, .medium),
    "ankylosaurus": (.hadrosaur, .medium),
    "corythosaurus": (.hadrosaur, .medium),
    "parasaurolophus": (.hadrosaur, .medium),
    "iguanodon": (.hadrosaur, .medium),
    "edmontosaurus": (.hadrosaur, .large),
    "pachycephalosaurus": (.hadrosaur, .small),
]

private func clade(forDinosaurSlug slug: String) -> DinoClade? {
    footprintDinosaurMap[slug]?.clade
}

private func size(forDinosaurSlug slug: String) -> DinoSize? {
    footprintDinosaurMap[slug]?.size
}

// MARK: - Game Configurations

struct GuessGameConfigs {
    // Create a random game configuration with 3 rounds (identify by silhouette = Name that Dinosaur)
    static var nameThatDinosaur: GuessGameConfig {
        // Get all available dinosaurs
        let allDinosaurs = MatchingGameConfigs.allDinosaurs
        
        // Ensure we have at least 3 dinosaurs
        guard allDinosaurs.count >= 3 else {
            fatalError("Need at least 3 dinosaurs for guess game, but only have \(allDinosaurs.count)")
        }
        
        // Pick 3 unique dinosaurs to use as questions (only those with silhouette assets so the question image displays).
        // Use an explicit allowlist so every dinosaur with a silhouette asset (including Apatosaurus) is included.
        let silhouetteSlugs: Set<String> = [
            "ankylosaurus", "apatosaurus", "corythosaurus", "iguanodon", "pachycephalosaurus",
            "parasaurolophus", "spinosaurus", "stegosaurus", "therizinosaurus", "trex",
            "triceratops", "troodon", "velociraptor"
        ]
        let withSilhouette = allDinosaurs.filter { d in
            guard let imageName = d.imageName, imageName.hasPrefix("dino-") else { return false }
            let base = imageName.replacingOccurrences(of: "dino-", with: "").lowercased()
            return silhouetteSlugs.contains(base)
        }
        let pool = withSilhouette.count >= 3 ? withSilhouette : allDinosaurs
        let shuffledAll = pool.shuffled()
        let questionDinosaurs = Array(shuffledAll.prefix(3))
        guard questionDinosaurs.count == 3,
              Set(questionDinosaurs.map { $0.id }).count == 3 else {
            fatalError("Need at least 3 unique dinosaurs for guess game")
        }
        
        var rounds: [RoundQuestion] = []
        
        for (roundNumber, questionDinosaur) in questionDinosaurs.enumerated() {
            let roundId = roundNumber + 1
            
            // Get 2 unique decoys (any dinosaurs other than this round's question)
            let decoyCandidates = allDinosaurs.filter { $0.id != questionDinosaur.id }
            guard decoyCandidates.count >= 2 else {
                fatalError("Not enough dinosaurs for decoys in round \(roundId)")
            }
            let decoys = Array(decoyCandidates.shuffled().prefix(2))
            
            // Verify decoys are unique
            let decoyIds = Set(decoys.map { $0.id })
            assert(decoyIds.count == 2, "Both decoys must be unique")
            assert(!decoyIds.contains(questionDinosaur.id), "Decoys must not match question")
            
            // Combine: 1 correct + 2 decoys, then shuffle
            var options = [questionDinosaur] + decoys
            options.shuffle()
            
            // Verify all 3 options are unique
            let optionIds = Set(options.map { $0.id })
            assert(optionIds.count == 3, "All 3 options must be unique")
            
            // Create silhouette image name (dino-silhouette- prefix for Name That Dinosaur; allows ptero-silhouette- etc. later)
            let baseName = questionDinosaur.imageName?.replacingOccurrences(of: "dino-", with: "") ?? ""
            let silhouetteImageName = "dino-silhouette-\(baseName)"
            
            let round = RoundQuestion(
                id: roundId,
                questionImageName: silhouetteImageName,
                questionImageFallback: questionDinosaur.imageName,
                correctAnswerId: questionDinosaur.id,
                options: options
            )
            
            rounds.append(round)
        }
        
        // Verify all rounds have unique question dinosaurs (no duplicate silhouettes)
        let questionIds = Set(rounds.map { $0.correctAnswerId })
        assert(questionIds.count == 3, "All 3 rounds must have unique question dinosaurs")
        
        return GuessGameConfig(
            id: "name-that-dinosaur",
            title: "Name That Dinosaur!",
            introAudio: "can-you-name-the-dinosaur",
            rounds: rounds,
            availableDinosaurs: allDinosaurs
        )
    }
    
    // Name That Pterosaur!: identify by silhouette (same structure as Name That Dinosaur, using ptero-silhouette-* assets).
    static var nameThatPterosaur: GuessGameConfig {
        let allPterosaurs = MatchingGameConfigs.allPterosaurs
        guard allPterosaurs.count >= 3 else {
            fatalError("Need at least 3 pterosaurs for guess game, but only have \(allPterosaurs.count)")
        }
        let shuffledAll = allPterosaurs.shuffled()
        let questionPterosaurs = Array(shuffledAll.prefix(3))
        guard questionPterosaurs.count == 3,
              Set(questionPterosaurs.map { $0.id }).count == 3 else {
            fatalError("Need at least 3 unique pterosaurs for guess game")
        }
        var rounds: [RoundQuestion] = []
        for (roundNumber, questionCreature) in questionPterosaurs.enumerated() {
            let roundId = roundNumber + 1
            let decoyCandidates = allPterosaurs.filter { $0.id != questionCreature.id }
            guard decoyCandidates.count >= 2 else {
                fatalError("Not enough pterosaurs for decoys in round \(roundId)")
            }
            let decoys = Array(decoyCandidates.shuffled().prefix(2))
            var options = [questionCreature] + decoys
            options.shuffle()
            let baseName = questionCreature.imageName?.replacingOccurrences(of: "ptero-", with: "") ?? ""
            let silhouetteImageName = "ptero-silhouette-\(baseName)"
            let round = RoundQuestion(
                id: roundId,
                questionImageName: silhouetteImageName,
                questionImageFallback: questionCreature.imageName,
                correctAnswerId: questionCreature.id,
                options: options
            )
            rounds.append(round)
        }
        return GuessGameConfig(
            id: "name-that-pterosaur",
            title: "Name That Pterosaur!",
            introAudio: "can-you-name-the-pterosaur",
            rounds: rounds,
            availableDinosaurs: allPterosaurs
        )
    }
    
    // Dino Footprints!: match footprint morphology (clade only). One clade footprint shown per round; options = 1 from that clade + 2 from two different other clades so the child matches shape, not size.
    static var dinoFootprints: GuessGameConfig {
        let landDinosaurs = MatchingGameConfigs.allDinosaurs.filter { $0.imageName?.hasPrefix("dino-") == true }
        let all = landDinosaurs.filter { d in
            let slug = d.imageName?.replacingOccurrences(of: "dino-", with: "").lowercased() ?? ""
            return footprintDinosaurMap[slug] != nil
        }
        guard all.count >= 3 else {
            fatalError("Need at least 3 dinosaurs in footprintDinosaurMap for Dino Footprints, but only have \(all.count)")
        }
        let byClade: [DinoClade: [Dinosaur]] = Dictionary(grouping: all) { d -> DinoClade in
            let slug = d.imageName?.replacingOccurrences(of: "dino-", with: "").lowercased() ?? ""
            return footprintDinosaurMap[slug]!.clade
        }
        let cladesWithOneOrMore = DinoClade.allCases.filter { (byClade[$0] ?? []).count >= 1 }
        guard cladesWithOneOrMore.count >= 3 else {
            fatalError("Need at least 3 clades with 1+ dinosaur for Dino Footprints (have \(cladesWithOneOrMore.count))")
        }
        // One clade per round; show one footprint image per clade (canonical size: medium) so player matches morphology only.
        let cladesForRounds = Array(cladesWithOneOrMore.shuffled().prefix(3))
        var usedQuestionIds: Set<Int> = []
        var rounds: [RoundQuestion] = []
        for roundId in 1...3 {
            let clade = cladesForRounds[roundId - 1]
            let sameClade = byClade[clade] ?? []
            let correct = sameClade.shuffled().first { !usedQuestionIds.contains($0.id) } ?? sameClade.first!
            usedQuestionIds.insert(correct.id)
            let otherClades = cladesForRounds.filter { $0 != clade }
            let decoyClade1 = otherClades[0]
            let decoyClade2 = otherClades[1]
            let decoy1 = (byClade[decoyClade1] ?? []).randomElement()!
            let decoy2 = (byClade[decoyClade2] ?? []).randomElement()!
            var options = [correct, decoy1, decoy2]
            options.shuffle()
            let footprintImageName = "footprint-\(clade.imageNameForAsset)-medium"
            rounds.append(RoundQuestion(
                id: roundId,
                questionImageName: footprintImageName,
                questionImageFallback: correct.imageName,
                correctAnswerId: correct.id,
                options: options
            ))
        }
        return GuessGameConfig(
            id: "dino-footprints",
            title: "Dino Footprints!",
            introAudio: "game-dino-footprints",
            rounds: rounds,
            availableDinosaurs: all
        )
    }
    
    // Future: Add a more sophisticated "Guess the Dinosaur!" game; this one is identify-by-silhouette (Name that Dinosaur).
    // Example:
    // static var dinosaurExperts: GuessGameConfig {
    //     // Similar structure but with different question types
    // }
}
