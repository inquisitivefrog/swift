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

// MARK: - Name That Dinosaur used-creature persistence (avoid repeat in future games, acknowledge in victory block)

private enum NameThatDinosaurStorage {
    static let usedCreatureIdsKey = "nameThatDinosaurUsedCreatureIds"
    static let usedCladeRawValuesKey = "nameThatDinosaurUsedCladeRawValues"
    static let cladeCount = 9 // DinoClade cases; reset after all used to maximize variety

    static func loadUsedCreatureIds() -> Set<Int> {
        guard let array = UserDefaults.standard.array(forKey: usedCreatureIdsKey) as? [Int] else { return [] }
        return Set(array)
    }

    static func appendUsedCreatureIds(_ ids: [Int]) {
        var current = loadUsedCreatureIds()
        current.formUnion(ids)
        UserDefaults.standard.set(Array(current), forKey: usedCreatureIdsKey)
    }

    static func clearIfNeeded(availableCount: Int) {
        if availableCount < 3 {
            UserDefaults.standard.removeObject(forKey: usedCreatureIdsKey)
        }
    }

    /// Clades already used in recent games; not used again until all 9 have been used (then cleared).
    static func loadUsedCladeRawValues() -> Set<String> {
        guard let array = UserDefaults.standard.array(forKey: usedCladeRawValuesKey) as? [String] else { return [] }
        return Set(array)
    }

    static func appendUsedCladeRawValues(_ rawValues: [String]) {
        var current = loadUsedCladeRawValues()
        current.formUnion(rawValues)
        UserDefaults.standard.set(Array(current), forKey: usedCladeRawValuesKey)
        if current.count >= cladeCount {
            UserDefaults.standard.removeObject(forKey: usedCladeRawValuesKey)
        }
    }

    static func clearUsedCladesIfAllUsed() {
        if loadUsedCladeRawValues().count >= cladeCount {
            UserDefaults.standard.removeObject(forKey: usedCladeRawValuesKey)
        }
    }
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

    /// Tracks first appearance so we only reset on initial load, not when advancing rounds (avoids resetting currentRound when SwiftUI re-invokes onAppear).
    @State private var hasInitiallyAppeared = false

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
                if !hasInitiallyAppeared {
                    hasInitiallyAppeared = true
                    resetGameState()
                }
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
            // No dimming when audio plays — keep full brightness so dinosaurs are easy to see during intro walk
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
        } else if gameConfig.id == "dino-bones" {
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.playDinoBonesHintThenStartOptionsWalk()
            }
            speechManager.speak("game-dino-bones-identify-the-skeleton")
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

    private func playDinoBonesHintThenStartOptionsWalk() {
        startOptionsWalkIfNeeded()
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
    
    /// Fixed row height and scroll height so exactly 4 full rows are visible (no 4.5 or 5). Includes top/bottom padding.
    private let victoryRowHeight: CGFloat = 92
    private var victoryListVisibleHeight: CGFloat { 16 + 4 * victoryRowHeight + 3 * 12 + 16 }

    // MARK: - End sequence: same as Dino Diets / Match the Dinosaur — top half list (highlight + name audio), bottom half "Good job!" then success image (centered, no wrapper), then good-job + crowd and dismiss
    private var guessGameEndSequenceView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top half: scrolling list of the 3 dinosaurs, highlight + name audio, scroll to center — fixed height so ~4 visible (consistent across games)
                ScrollViewReader { proxy in
                    ScrollView {
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
                                .frame(height: victoryRowHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                                .id(index)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    }
                    .frame(height: victoryListVisibleHeight)
                    .onChange(of: endHighlightIndex) { _, newIndex in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // Bottom half: during walk show empty; after walk show success image only (centered, no wrapper)
                Group {
                    if endSequenceStep == 2 {
                        guessGameSuccessImageView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    playGoodJobAndCrowdThenDismiss()
                                }
                            }
                    } else {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            if endSequenceDinosaurs.isEmpty {
                endSequenceStep = 2
            } else {
                speechManager.speak(audioKey: endSequenceDinosaurs[0].imageName ?? endSequenceDinosaurs[0].name, fallbackText: endSequenceDinosaurs[0].name)
                speechManager.onAudioFinished = { advanceEndHighlight() }
            }
        }
    }

    /// Success image only (no card wrapper); centered in victory bottom half. Same pattern as Match the Dinosaur / Dino Diets.
    private var guessGameSuccessImageView: some View {
        ZStack {
            guessGameSuccessImageContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var guessGameSuccessImageContent: some View {
        Group {
            let successName = "game-\(gameConfig.id)-success"
            let fallbackName = "game-\(gameConfig.id)"
            if UIImage(named: successName) != nil {
                Image(successName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
            } else if UIImage(named: fallbackName) != nil {
                Image(fallbackName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
            } else {
                Text("🎉")
                    .font(.system(size: 100))
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
            endSequenceStep = 2
        }
    }
    
    private func playGoodJobAndCrowdThenDismiss() {
        endSequenceStep = 2
        // Remember the 3 dinosaurs and their clades so they are not repeated in future games and are acknowledged in the victory block (already shown in end sequence).
        if gameConfig.id == "name-that-dinosaur" {
            let usedIds = gameConfig.rounds.map { $0.correctAnswerId }
            NameThatDinosaurStorage.appendUsedCreatureIds(usedIds)
            let cladeById = MatchingGameConfigs.dinosaurCladeById
            let usedCladeRawValues = usedIds.compactMap { cladeById[$0]?.rawValue }
            NameThatDinosaurStorage.appendUsedCladeRawValues(usedCladeRawValues)
        }
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
            // Full brightness during intro walk (no dim) so dinosaurs are easy to see when introduced
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
    @State private var introPlayed = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Show either grid or full-screen detail (no overlay — avoids jarring partial visibility)
            if selectedClade == nil {
                gridView
            } else {
                detailView
            }

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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            playIntroOnce()
        }
    }

    private var gridView: some View {
        VStack(spacing: 20) {
            Text("Source Footprints")
                .font(.title2.weight(.semibold))
                .padding(.top, 44)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(sourceFootprintsHintClades) { clade in
                    Button {
                        showCladeDetail(clade)
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
    }

    @ViewBuilder
    private var detailView: some View {
        if let clade = selectedClade {
            VStack(spacing: 20) {
                Spacer()
                if UIImage(named: clade.imageName) != nil {
                    Image(clade.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 320, maxHeight: 320)
                }
                Text(clade.displayName)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func playIntroOnce() {
        guard !introPlayed else { return }
        introPlayed = true
        if let url = speechManager.urlForAudio(key: "game-dino-footprints-tap-the-footprint-to-hear-description") {
            speechManager.onAudioFinished = nil
            speechManager.playAudioFile(url: url)
        }
    }

    private func showCladeDetail(_ clade: SourceFootprintCladeHint) {
        selectedClade = clade
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            speechManager.onAudioFinished = nil
            // Auto-return to grid after clade audio finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                selectedClade = nil
            }
        }
        if let url = speechManager.urlForAudio(key: clade.audioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(clade.displayName)
            // TTS completion triggers onAudioFinished via AVSpeechSynthesizerDelegate
        }
    }
}

// MARK: - Dino Footprints (clade + size)

/// Footprint image sets: footprint-{clade}-{size} or footprint-{clade}-{variant}-{size}. For variety, use up to 3 variants per clade (e.g. footprint-therapod-1-medium, footprint-therapod-2-medium, footprint-therapod-3-medium); the game randomly picks one to reduce memorization.
/// Use imageNameForAsset for lookup; asset names use "therapod" (common misspelling) for theropod.
/// Separate from MatchingGameView.DinoClade (9 clades for Match the Dinosaur); this is the 5-clade set for Dino Footprints.
private enum FootprintClade: String, CaseIterable {
    case theropod
    case sauropod
    case hadrosaur
    case ceratopsian
    case ankylosaur

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
private let footprintDinosaurMap: [String: (clade: FootprintClade, size: DinoSize)] = [
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
    // Hadrosaurs and other ornithopods
    "stegosaurus": (.hadrosaur, .medium),
    "corythosaurus": (.hadrosaur, .medium),
    "parasaurolophus": (.hadrosaur, .medium),
    "iguanodon": (.hadrosaur, .medium),
    "edmontosaurus": (.hadrosaur, .large),
    "pachycephalosaurus": (.hadrosaur, .small),
    // Ankylosaurs
    "ankylosaurus": (.ankylosaur, .large),
    "euoplocephalus": (.ankylosaur, .medium),
    "edmontonia": (.ankylosaur, .medium),
    "nodosaurus": (.ankylosaur, .medium),
    "polacanthus": (.ankylosaur, .medium),
]

private func clade(forDinosaurSlug slug: String) -> FootprintClade? {
    footprintDinosaurMap[slug]?.clade
}

private func size(forDinosaurSlug slug: String) -> DinoSize? {
    footprintDinosaurMap[slug]?.size
}

/// Returns a random footprint image name for the clade. Supports 3 variants per clade (footprint-{clade}-1-medium, -2-, -3-) to reduce memorization; falls back to footprint-{clade}-medium when variants are missing.
private func footprintImageNameForClade(_ clade: FootprintClade) -> String {
    let base = clade.imageNameForAsset
    let fallback = "footprint-\(base)-medium"
    let variants = (1...3).map { "footprint-\(base)-\($0)-medium" }
    let available = variants.filter { UIImage(named: $0) != nil }
    if available.isEmpty { return fallback }
    return available.randomElement() ?? fallback
}

// MARK: - Game Configurations

struct GuessGameConfigs {
    // Create a random game configuration with 3 rounds (identify by silhouette = Name that Dinosaur).
    // Rules: (1) choose 3 dinosaur clades at random; (2) choose 1 dinosaur from each clade; (3) exclude dinosaurs already used in previous games (persisted); victory block acknowledges the 3.
    static var nameThatDinosaur: GuessGameConfig {
        let allDinosaurs = MatchingGameConfigs.allDinosaurs
        guard allDinosaurs.count >= 5 else {
            fatalError("Need at least 5 dinosaurs for guess game, but only have \(allDinosaurs.count)")
        }

        // Pool: dinosaurs with dino- image (for silhouette asset name). Exclude previously used so they are not repeated in future games.
        var usedIds = NameThatDinosaurStorage.loadUsedCreatureIds()
        var pool = allDinosaurs.filter { d in
            guard let imageName = d.imageName, imageName.hasPrefix("dino-") else { return false }
            return !usedIds.contains(d.id)
        }
        if pool.count < 5 {
            NameThatDinosaurStorage.clearIfNeeded(availableCount: pool.count)
            usedIds = []
            pool = allDinosaurs.filter { d in
                guard let imageName = d.imageName, imageName.hasPrefix("dino-") else { return false }
                return true
            }
        }
        let questionPool = pool.count >= 5 ? pool : allDinosaurs

        // Pick 3 clades at random; prefer clades not yet used in recent games (maximize variety across 9 clades).
        let cladeById = MatchingGameConfigs.dinosaurCladeById
        let byClade = Dictionary(grouping: questionPool) { cladeById[$0.id] ?? .theropod }
        let allCladesWithDinos = byClade.keys.filter { !(byClade[$0] ?? []).isEmpty }
        var usedClades = NameThatDinosaurStorage.loadUsedCladeRawValues()
        if usedClades.count >= NameThatDinosaurStorage.cladeCount {
            NameThatDinosaurStorage.clearUsedCladesIfAllUsed()
            usedClades = []
        }
        let availableClades = allCladesWithDinos.filter { !usedClades.contains($0.rawValue) }
        let cladesToUse = (availableClades.count >= 5 ? availableClades : allCladesWithDinos).shuffled()
        let questionDinosaurs: [Dinosaur]
        if cladesToUse.count >= 5 {
            questionDinosaurs = (0..<5).compactMap { i in
                let clade = cladesToUse[i]
                return (byClade[clade] ?? []).shuffled().first
            }
        } else {
            questionDinosaurs = Array(questionPool.shuffled().prefix(5))
        }
        guard questionDinosaurs.count == 5,
              Set(questionDinosaurs.map { $0.id }).count == 5 else {
            fatalError("Need at least 5 unique dinosaurs for guess game")
        }
        
        var rounds: [RoundQuestion] = []
        
        for (roundNumber, questionDinosaur) in questionDinosaurs.enumerated() {
            let roundId = roundNumber + 1
            
            // Decoys must be from different clades than the question so silhouettes are visually distinct (e.g. avoid Argentinosaurus vs Brachiosaurus — both sauropods look similar).
            let questionClade = cladeById[questionDinosaur.id] ?? .theropod
            let decoyCandidates = questionPool.filter { d in
                d.id != questionDinosaur.id && (cladeById[d.id] ?? .theropod) != questionClade
            }
            // Prefer 2 decoys from 2 different clades for maximum visual variety
            var decoys: [Dinosaur]
            if decoyCandidates.count >= 2 {
                let byCladeForDecoys = Dictionary(grouping: decoyCandidates) { cladeById[$0.id] ?? .theropod }
                let otherClades = byCladeForDecoys.keys.filter { $0 != questionClade }.shuffled()
                if otherClades.count >= 2 {
                    let firstDecoy = (byCladeForDecoys[otherClades[0]] ?? []).shuffled().first!
                    let secondCladeCandidates = decoyCandidates.filter { (cladeById[$0.id] ?? .theropod) != otherClades[0] }
                    let secondDecoy = secondCladeCandidates.shuffled().first!
                    decoys = [firstDecoy, secondDecoy]
                } else {
                    decoys = Array(decoyCandidates.shuffled().prefix(2))
                }
            } else {
                // Fallback: allow same-clade decoys only if we have too few from other clades
                let fallbackCandidates = questionPool.filter { $0.id != questionDinosaur.id }
                guard fallbackCandidates.count >= 2 else {
                    fatalError("Not enough dinosaurs for decoys in round \(roundId)")
                }
                decoys = Array(fallbackCandidates.shuffled().prefix(2))
            }
            
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
        assert(questionIds.count == 5, "All 5 rounds must have unique question dinosaurs")
        
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
        guard allPterosaurs.count >= 5 else {
            fatalError("Need at least 5 pterosaurs for guess game, but only have \(allPterosaurs.count)")
        }
        let shuffledAll = allPterosaurs.shuffled()
        let questionPterosaurs = Array(shuffledAll.prefix(5))
        guard questionPterosaurs.count == 5,
              Set(questionPterosaurs.map { $0.id }).count == 5 else {
            fatalError("Need at least 5 unique pterosaurs for guess game")
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
        guard all.count >= 5 else {
            fatalError("Need at least 5 dinosaurs in footprintDinosaurMap for Dino Footprints, but only have \(all.count)")
        }
        let byClade: [FootprintClade: [Dinosaur]] = Dictionary(grouping: all) { d -> FootprintClade in
            let slug = d.imageName?.replacingOccurrences(of: "dino-", with: "").lowercased() ?? ""
            return footprintDinosaurMap[slug]!.clade
        }
        let cladesWithOneOrMore = FootprintClade.allCases.filter { (byClade[$0] ?? []).count >= 1 }
        guard cladesWithOneOrMore.count >= 5 else {
            fatalError("Need at least 5 clades with 1+ dinosaur for Dino Footprints (have \(cladesWithOneOrMore.count))")
        }
        // One clade per round; show one footprint image per clade. Randomly picks from up to 3 variants per clade to reduce memorization.
        let cladesForRounds = Array(cladesWithOneOrMore.shuffled().prefix(5))
        var usedQuestionIds: Set<Int> = []
        var rounds: [RoundQuestion] = []
        for roundId in 1...5 {
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
            let footprintImageName = footprintImageNameForClade(clade)
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
    
    // Dino Bones!: identify dinosaur from museum preparator scene—skeleton on tarp, paleontologist with gift fossil, one bone missing.
    // Clue: nearly articulated skeleton, gift fossil (partially in matrix), skull, or obvious missing bone (skull/foreleg/femur).
    // 3 rounds, 3 options per round. Images: dino-bones-{slug} (e.g. dino-bones-trex).
    static var dinoBones: GuessGameConfig {
        let allDinosaurs = MatchingGameConfigs.allDinosaurs
        guard allDinosaurs.count >= 5 else {
            fatalError("Need at least 5 dinosaurs for Dino Bones, but only have \(allDinosaurs.count)")
        }
        let pool = allDinosaurs.filter { d in
            guard let imageName = d.imageName, imageName.hasPrefix("dino-") else { return false }
            return true
        }
        guard pool.count >= 3 else {
            fatalError("Need at least 3 dinosaurs with dino- images for Dino Bones")
        }
        let cladeById = MatchingGameConfigs.dinosaurCladeById
        let byClade = Dictionary(grouping: pool) { cladeById[$0.id] ?? .theropod }
        let allCladesWithDinos = byClade.keys.filter { !(byClade[$0] ?? []).isEmpty }
        let finalQuestionDinosaurs: [Dinosaur]
        if allCladesWithDinos.count >= 3 {
            let cladesToUse = Array(allCladesWithDinos.shuffled().prefix(3))
            finalQuestionDinosaurs = cladesToUse.compactMap { (byClade[$0] ?? []).shuffled().first }
        } else {
            finalQuestionDinosaurs = Array(pool.shuffled().prefix(3))
        }
        guard finalQuestionDinosaurs.count == 3, Set(finalQuestionDinosaurs.map { $0.id }).count == 3 else {
            fatalError("Need 3 unique dinosaurs for Dino Bones")
        }
        var rounds: [RoundQuestion] = []
        for (roundNumber, questionDinosaur) in finalQuestionDinosaurs.enumerated() {
            let roundId = roundNumber + 1
            let questionClade = cladeById[questionDinosaur.id] ?? .theropod
            let decoyCandidates = pool.filter { d in
                d.id != questionDinosaur.id && (cladeById[d.id] ?? .theropod) != questionClade
            }
            let decoys: [Dinosaur]
            if decoyCandidates.count >= 2 {
                decoys = Array(decoyCandidates.shuffled().prefix(2))
            } else {
                let fallback = pool.filter { $0.id != questionDinosaur.id }
                decoys = Array(fallback.shuffled().prefix(2))
            }
            guard decoys.count == 2 else {
                fatalError("Not enough decoys for Dino Bones round \(roundId)")
            }
            var options = [questionDinosaur] + decoys
            options.shuffle()
            let baseName = questionDinosaur.imageName?.replacingOccurrences(of: "dino-", with: "") ?? ""
            let bonesImageName = "dino-bones-\(baseName)"
            rounds.append(RoundQuestion(
                id: roundId,
                questionImageName: bonesImageName,
                questionImageFallback: questionDinosaur.imageName,
                correctAnswerId: questionDinosaur.id,
                options: options
            ))
        }
        return GuessGameConfig(
            id: "dino-bones",
            title: "Dino Bones!",
            introAudio: "game-dino-bones",
            rounds: rounds,
            availableDinosaurs: allDinosaurs
        )
    }
}
