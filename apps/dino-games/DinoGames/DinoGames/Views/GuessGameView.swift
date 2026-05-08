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
    /// Whose Bones?: victory walk speaks `body-{key}` → Audio/Body/{key}.m4a (e.g. skull, ribcage).
    let bodySegmentSpeechKey: String?

    init(
        id: Int,
        questionImageName: String,
        questionImageFallback: String?,
        correctAnswerId: Int,
        options: [Dinosaur],
        bodySegmentSpeechKey: String? = nil
    ) {
        self.id = id
        self.questionImageName = questionImageName
        self.questionImageFallback = questionImageFallback
        self.correctAnswerId = correctAnswerId
        self.options = options
        self.bodySegmentSpeechKey = bodySegmentSpeechKey
    }
}

// MARK: - Name That Dinosaur used-creature persistence (avoid repeat in future games, acknowledge in victory block)

private enum NameThatDinosaurStorage {
    static let usedCreatureIdsKey = "nameThatDinosaurUsedCreatureIds"
    static let usedCladeRawValuesKey = "nameThatDinosaurUsedCladeRawValues"
    static let cladeCount = DinoClade.allCases.count

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

// MARK: - Name That Marine Reptile used-creature / clade persistence

private enum NameThatMarineReptileStorage {
    static let usedCreatureIdsKey = "nameThatMarineReptileUsedCreatureIds"
    static let usedCladeRawValuesKey = "nameThatMarineReptileUsedCladeRawValues"

    static func loadUsedCreatureIds() -> Set<Int> {
        guard let array = UserDefaults.standard.array(forKey: usedCreatureIdsKey) as? [Int] else { return [] }
        return Set(array)
    }

    static func appendUsedCreatureIds(_ ids: [Int]) {
        var current = loadUsedCreatureIds()
        current.formUnion(ids)
        UserDefaults.standard.set(Array(current), forKey: usedCreatureIdsKey)
    }

    static func clearUsedCreaturesIfNeeded(availableCount: Int, roundCount: Int) {
        if availableCount < roundCount {
            UserDefaults.standard.removeObject(forKey: usedCreatureIdsKey)
        }
    }

    static func loadUsedCladeRawValues() -> Set<String> {
        guard let array = UserDefaults.standard.array(forKey: usedCladeRawValuesKey) as? [String] else { return [] }
        return Set(array)
    }

    static func appendUsedCladeRawValues(_ rawValues: [String], maxCladeCount: Int) {
        var current = loadUsedCladeRawValues()
        current.formUnion(rawValues)
        UserDefaults.standard.set(Array(current), forKey: usedCladeRawValuesKey)
        if current.count >= maxCladeCount {
            UserDefaults.standard.removeObject(forKey: usedCladeRawValuesKey)
        }
    }

    static func clearUsedCladesIfAllUsed(maxCladeCount: Int) {
        if maxCladeCount > 0, loadUsedCladeRawValues().count >= maxCladeCount {
            UserDefaults.standard.removeObject(forKey: usedCladeRawValuesKey)
        }
    }
}

// MARK: - Game Configuration

struct GuessGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let rounds: [RoundQuestion]
    let availableDinosaurs: [Dinosaur]
    /// Runs when the player finishes all rounds, as the final “good job + crowd” begins (e.g. UserDefaults for Name That Dinosaur).
    let victorySideEffect: (() -> Void)?

    init(
        id: String,
        title: String,
        introAudio: String,
        rounds: [RoundQuestion],
        availableDinosaurs: [Dinosaur],
        victorySideEffect: (() -> Void)? = nil
    ) {
        self.id = id
        self.title = title
        self.introAudio = introAudio
        self.rounds = rounds
        self.availableDinosaurs = availableDinosaurs
        self.victorySideEffect = victorySideEffect
    }
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

    /// The correct dinosaurs per round in round order, filtered for duplicates (first appearance) for end-sequence row.
    private var endSequenceDinosaurs: [Dinosaur] {
        var seen: Set<Int> = []
        return gameConfig.rounds
            .map { r in r.options.first(where: { $0.id == r.correctAnswerId })! }
            .filter { seen.insert($0.id).inserted }
    }

    /// Whose Bones?: body segment keys aligned with `endSequenceDinosaurs` for victory audio.
    private var endSequenceBodySegmentSpeechKeys: [String] {
        guard gameConfig.id == "whose-bones" else { return [] }
        var keys: [String] = []
        var seen: Set<Int> = []
        for r in gameConfig.rounds {
            guard let seg = r.bodySegmentSpeechKey else { continue }
            guard let dino = r.options.first(where: { $0.id == r.correctAnswerId }) else { continue }
            guard seen.insert(dino.id).inserted else { continue }
            keys.append(seg)
        }
        return keys
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
                            // Question image: primary silhouette, then dinosaur alternate `dino-silhouette-*`, then tinted body (pterosaurs skip dino path when fallback is `ptero-*`).
                            if UIImage(named: question.questionImageName) != nil {
                                Image(question.questionImageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 250, height: 250)
                            } else {
                                let fallbackKey = question.questionImageFallback?.lowercased() ?? ""
                                let isPterosaurBody = fallbackKey.hasPrefix("ptero-")
                                let isMarineBody = fallbackKey.hasPrefix("marine-")
                                let dinoAlt: String? = {
                                    guard !isPterosaurBody, !isMarineBody else { return nil }
                                    let baseName = question.questionImageFallback?.replacingOccurrences(of: "dino-", with: "") ?? ""
                                    guard !baseName.isEmpty else { return nil }
                                    return "dino-silhouette-\(baseName)"
                                }()
                                if let dinoAlt, UIImage(named: dinoAlt) != nil {
                                    Image(dinoAlt)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 250, height: 250)
                                } else if let fallback = question.questionImageFallback, !fallback.isEmpty {
                                    Image(fallback)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 250, height: 250)
                                        .colorMultiply(.black)
                                        .opacity(0.8)
                                } else {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 250, height: 250)
                                }
                            }
                            Text("Round \(currentRound) of \(gameConfig.rounds.count)")
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
                // Intro already played on the transition screen; for Dino Footprints and Dino Bones play round intro at start of each round
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
    
    /// Starts the round: for Dino Footprints plays "identify the footprint" then options walk; for Dino Bones plays "identify the skeleton" then options walk; for other guess games goes straight to options walk.
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
        } else if gameConfig.id == "whose-bones" {
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.startOptionsWalkIfNeeded()
            }
            speechManager.speak("game-whose-bones-gameplay")
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
                    if self.currentRound < self.gameConfig.rounds.count {
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
            speechManager.speak(correctGuessAudioKey)
        } else {
            wrongGuessesThisRound += 1
            errorCount += 1
            isAudioPlaying = true
            // No auto-skip: allow unlimited attempts so kids can map sound ↔ image.
            speechManager.speak(tryAgainAudioKey)
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
    private var victoryListVisibleHeight: CGFloat {
        let visibleRows = max(1, min(4, endSequenceDinosaurs.count))
        let visibleGaps = max(0, visibleRows - 1)
        return 16 + CGFloat(visibleRows) * victoryRowHeight + CGFloat(visibleGaps) * 12 + 16
    }

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
                                // Keep the transition from the final highlighted creature to the success card snappy.
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
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
            } else if gameConfig.id == "whose-bones" {
                let keys = endSequenceBodySegmentSpeechKeys
                if !keys.isEmpty {
                    speechManager.speak("body-\(keys[0])")
                } else {
                    speechManager.speak(audioKey: endSequenceDinosaurs[0].imageName ?? endSequenceDinosaurs[0].name, fallbackText: endSequenceDinosaurs[0].name)
                }
                speechManager.onAudioFinished = { advanceEndHighlight() }
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

    /// End-sequence success art: name-that games use a larger frame than the level-two list card so `game-*-success` is easy to see.
    private var guessGameSuccessImageSide: CGFloat {
        switch gameConfig.id {
        case "name-that-dinosaur", "name-that-pterosaur", "name-that-marine-reptile":
            return GameCatalogImageMetrics.nameThatVictorySuccessImageSide
        default:
            return 180
        }
    }

    private var guessGameSuccessImageContent: some View {
        Group {
            let successName = "game-\(gameConfig.id)-success"
            let fallbackName = "game-\(gameConfig.id)"
            if UIImage(named: successName) != nil {
                Image(successName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: guessGameSuccessImageSide, height: guessGameSuccessImageSide)
                    .layoutPriority(1)
            } else if UIImage(named: fallbackName) != nil {
                Image(fallbackName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: guessGameSuccessImageSide, height: guessGameSuccessImageSide)
                    .layoutPriority(1)
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
            if gameConfig.id == "whose-bones" {
                let keys = endSequenceBodySegmentSpeechKeys
                if endHighlightIndex < keys.count {
                    speechManager.speak("body-\(keys[endHighlightIndex])")
                } else {
                    speechManager.speak(audioKey: endSequenceDinosaurs[endHighlightIndex].imageName ?? endSequenceDinosaurs[endHighlightIndex].name, fallbackText: endSequenceDinosaurs[endHighlightIndex].name)
                }
            } else {
                speechManager.speak(audioKey: endSequenceDinosaurs[endHighlightIndex].imageName ?? endSequenceDinosaurs[endHighlightIndex].name, fallbackText: endSequenceDinosaurs[endHighlightIndex].name)
            }
            speechManager.onAudioFinished = { advanceEndHighlight() }
        } else {
            endSequenceStep = 2
        }
    }
    
    private func playGoodJobAndCrowdThenDismiss() {
        endSequenceStep = 2
        gameConfig.victorySideEffect?()
        let goodJobURL = speechManager.urlForAudio(key: victoryGoodJobAudioKey)
        let crowdURL = speechManager.urlForAudio(key: "crowd-cheering")
        if let u1 = goodJobURL, let u2 = crowdURL {
            speechManager.playTogether(url1: u1, url2: u2) {
                self.speechManager.onAudioFinished = nil
                LandDinosaurProgress.notifyCompletionIfLandGame(configId: self.gameConfig.id)
                MarineReptileProgress.notifyCompletionIfMarineGame(configId: self.gameConfig.id)
                PterosaurProgress.notifyCompletionIfPterosaurGame(configId: self.gameConfig.id)
                self.isPresented = false
            }
        } else if let u = goodJobURL ?? crowdURL {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                LandDinosaurProgress.notifyCompletionIfLandGame(configId: self.gameConfig.id)
                MarineReptileProgress.notifyCompletionIfMarineGame(configId: self.gameConfig.id)
                PterosaurProgress.notifyCompletionIfPterosaurGame(configId: self.gameConfig.id)
                self.isPresented = false
            }
            speechManager.playAudioFile(url: u)
        } else {
            LandDinosaurProgress.notifyCompletionIfLandGame(configId: gameConfig.id)
            MarineReptileProgress.notifyCompletionIfMarineGame(configId: gameConfig.id)
            PterosaurProgress.notifyCompletionIfPterosaurGame(configId: gameConfig.id)
            isPresented = false
        }
    }

    private var usesMarineGameSpecificFeedback: Bool {
        gameConfig.id == "name-that-marine-reptile"
    }

    private var correctGuessAudioKey: String {
        usesMarineGameSpecificFeedback ? "game-name-that-marine-reptile-thats-right" : "thats-right-you-guessed-it"
    }

    private var tryAgainAudioKey: String {
        usesMarineGameSpecificFeedback ? "game-name-that-marine-reptile-try-again" : "try-again"
    }

    private var victoryGoodJobAudioKey: String {
        usesMarineGameSpecificFeedback ? "game-name-that-marine-reptile-good-job" : "good-job-you-got-them-all"
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
/// Separate from `DinoClade` / `LandDinosaurCladeCatalog` (9 buckets for land games); this is the 5-clade set for Dino Footprints assets.
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
        guard allDinosaurs.count >= 3 else {
            fatalError("Need at least 3 dinosaurs for guess game, but only have \(allDinosaurs.count)")
        }

        // Pool: dinosaurs with dino- image (for silhouette asset name). Exclude previously used so they are not repeated in future games.
        var usedIds = NameThatDinosaurStorage.loadUsedCreatureIds()
        var pool = allDinosaurs.filter { d in
            guard let imageName = d.imageName, imageName.hasPrefix("dino-") else { return false }
            return !usedIds.contains(d.id)
        }
        if pool.count < 3 {
            NameThatDinosaurStorage.clearIfNeeded(availableCount: pool.count)
            usedIds = []
            pool = allDinosaurs.filter { d in
                guard let imageName = d.imageName, imageName.hasPrefix("dino-") else { return false }
                return true
            }
        }
        let questionPool = pool.count >= 3 ? pool : allDinosaurs

        // Pick 3 clades at random; prefer clades not yet used in recent games (maximize variety across 9 clades).
        let byClade = Dictionary(grouping: questionPool) { LandDinosaurCladeCatalog.clade(forCreatureId: $0.id) }
        let allCladesWithDinos = byClade.keys.filter { !(byClade[$0] ?? []).isEmpty }
        var usedClades = NameThatDinosaurStorage.loadUsedCladeRawValues()
        if usedClades.count >= NameThatDinosaurStorage.cladeCount {
            NameThatDinosaurStorage.clearUsedCladesIfAllUsed()
            usedClades = []
        }
        let availableClades = allCladesWithDinos.filter { !usedClades.contains($0.rawValue) }
        let cladesToUse = (availableClades.count >= 3 ? availableClades : allCladesWithDinos).shuffled()
        let questionDinosaurs: [Dinosaur]
        if cladesToUse.count >= 3 {
            questionDinosaurs = (0..<3).compactMap { i in
                let clade = cladesToUse[i]
                return (byClade[clade] ?? []).shuffled().first
            }
        } else {
            questionDinosaurs = Array(questionPool.shuffled().prefix(3))
        }
        guard questionDinosaurs.count == 3,
              Set(questionDinosaurs.map { $0.id }).count == 3 else {
            fatalError("Need at least 3 unique dinosaurs for guess game")
        }
        
        var rounds: [RoundQuestion] = []
        
        for (roundNumber, questionDinosaur) in questionDinosaurs.enumerated() {
            let roundId = roundNumber + 1
            
            // Decoys: never the question’s clade; prefer two different non-question clades when the pool allows.
            let questionClade = LandDinosaurCladeCatalog.clade(forCreatureId: questionDinosaur.id)
            let decoys = LandDinosaurCladeCatalog.pickTwoDecoysDifferentClades(
                question: questionDinosaur,
                questionClade: questionClade,
                pool: questionPool
            )
            
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
            availableDinosaurs: allDinosaurs,
            victorySideEffect: {
                let usedIds = rounds.map { $0.correctAnswerId }
                NameThatDinosaurStorage.appendUsedCreatureIds(usedIds)
                let usedCladeRawValues = usedIds.map { LandDinosaurCladeCatalog.clade(forCreatureId: $0).rawValue }
                NameThatDinosaurStorage.appendUsedCladeRawValues(usedCladeRawValues)
            }
        )
    }
    
    // Name That Pterosaur!: full `AirPterosaurData` pool; `questionImageName` follows `AirPterosaurData.silhouetteAssetName` (bundled silhouette when present, else view uses tinted body).
    static var nameThatPterosaur: GuessGameConfig {
        let pool = MatchingGameConfigs.allPterosaurs
        let roundCount = 3
        guard pool.count >= roundCount else {
            fatalError("Need at least \(roundCount) pterosaurs for guess game, but only have \(pool.count)")
        }
        return makeSilhouetteGuessGame(
            id: "name-that-pterosaur",
            title: "Name That Pterosaur!",
            introAudio: "can-you-name-the-pterosaur",
            pool: pool,
            roundCount: roundCount,
            bodyImagePrefixFor: { AirPterosaurData.bodyImagePrefix(for: $0.imageName ?? "") }
        )
    }

    // MARK: - Marine reptiles (sea category)

    static var nameThatMarineReptile: GuessGameConfig {
        let allMarineReptiles = SeaMarineReptileData.allMarineReptiles
        let roundCount = 3
        guard allMarineReptiles.count >= roundCount else {
            fatalError("Need at least \(roundCount) marine reptiles for guess game, but only have \(allMarineReptiles.count)")
        }

        var usedIds = NameThatMarineReptileStorage.loadUsedCreatureIds()
        var pool = allMarineReptiles.filter { d in
            guard let imageName = d.imageName, imageName.hasPrefix("marine-") else { return false }
            return !usedIds.contains(d.id)
        }
        if pool.count < roundCount {
            NameThatMarineReptileStorage.clearUsedCreaturesIfNeeded(availableCount: pool.count, roundCount: roundCount)
            usedIds = []
            pool = allMarineReptiles.filter { $0.imageName?.hasPrefix("marine-") == true }
        }
        let questionPool = pool.count >= roundCount ? pool : allMarineReptiles
        let byClade = Dictionary(grouping: questionPool) { SeaMarineReptileData.marineCladeRawValue(for: $0) }
        let allCladesWithCreatures = byClade.keys.filter { !(byClade[$0] ?? []).isEmpty }
        let allMarineClades = Set(allMarineReptiles.map { SeaMarineReptileData.marineCladeRawValue(for: $0) })
        var usedClades = NameThatMarineReptileStorage.loadUsedCladeRawValues()
        let maxCladeCount = allMarineClades.count
        if usedClades.count >= maxCladeCount {
            NameThatMarineReptileStorage.clearUsedCladesIfAllUsed(maxCladeCount: maxCladeCount)
            usedClades = []
        }
        let availableClades = allCladesWithCreatures.filter { !usedClades.contains($0) }
        let cladesToUse = (availableClades.count >= roundCount ? availableClades : allCladesWithCreatures).shuffled()

        let questionCreatures: [Dinosaur]
        if cladesToUse.count >= roundCount {
            questionCreatures = (0..<roundCount).compactMap { i in
                let clade = cladesToUse[i]
                return (byClade[clade] ?? []).shuffled().first
            }
        } else {
            questionCreatures = Array(questionPool.shuffled().prefix(roundCount))
        }
        guard questionCreatures.count == roundCount,
              Set(questionCreatures.map(\.id)).count == roundCount else {
            fatalError("Need \(roundCount) unique marine reptiles for guess game")
        }

        var rounds: [RoundQuestion] = []
        for (roundNumber, questionCreature) in questionCreatures.enumerated() {
            let roundId = roundNumber + 1
            let decoys = SeaMarineReptileData.pickTwoDecoysDistinctMarineClades(question: questionCreature, pool: questionPool)

            var options = [questionCreature] + decoys
            options.shuffle()
            let bodyImagePrefix = SeaMarineReptileData.marineBodyImagePrefix(for: questionCreature)
            let baseName = questionCreature.imageName?.replacingOccurrences(of: bodyImagePrefix, with: "") ?? ""
            let silhouetteImageName = "\(bodyImagePrefix.dropLast())-silhouette-\(baseName)"
            rounds.append(RoundQuestion(
                id: roundId,
                questionImageName: silhouetteImageName,
                questionImageFallback: questionCreature.imageName,
                correctAnswerId: questionCreature.id,
                options: options
            ))
        }

        return GuessGameConfig(
            id: "name-that-marine-reptile",
            title: "Name That Marine Reptile!",
            introAudio: "can-you-name-that-marine-reptile",
            rounds: rounds,
            availableDinosaurs: allMarineReptiles,
            victorySideEffect: {
                let usedIds = rounds.map(\.correctAnswerId)
                NameThatMarineReptileStorage.appendUsedCreatureIds(usedIds)
                let usedCladeRawValues = usedIds.compactMap { id in
                    allMarineReptiles.first(where: { $0.id == id }).map { SeaMarineReptileData.marineCladeRawValue(for: $0) }
                }
                NameThatMarineReptileStorage.appendUsedCladeRawValues(usedCladeRawValues, maxCladeCount: maxCladeCount)
            }
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
        guard cladesWithOneOrMore.count >= 3 else {
            fatalError("Need at least 3 clades with 1+ dinosaur for Dino Footprints (have \(cladesWithOneOrMore.count))")
        }
        // One clade per round; show one footprint image per clade. Randomly picks from up to 3 variants per clade to reduce memorization.
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
    // 3 rounds, 3 options per round. Images: dino-bones-{slug}; fallback: dino-silhouette-{slug}. Pool filtered to dinosaurs with dino-bones images.
    // game-dino-bones-identify-the-skeleton.m4a plays at start of each round before options walk.
    static var dinoBones: GuessGameConfig {
        let allDinosaurs = MatchingGameConfigs.allDinosaurs
        guard allDinosaurs.count >= 3 else {
            fatalError("Need at least 3 dinosaurs for Dino Bones, but only have \(allDinosaurs.count)")
        }
        let pool = allDinosaurs.filter { d in
            guard let imageName = d.imageName, imageName.hasPrefix("dino-") else { return false }
            let slug = imageName.replacingOccurrences(of: "dino-", with: "")
            return UIImage(named: "dino-bones-\(slug)") != nil
        }
        guard pool.count >= 3 else {
            fatalError("Need at least 3 dinosaurs with dino-bones-{slug} images for Dino Bones, but only have \(pool.count)")
        }
        let byClade = Dictionary(grouping: pool) { LandDinosaurCladeCatalog.clade(forCreatureId: $0.id) }
        let allCladesWithDinos = byClade.keys.filter { !(byClade[$0] ?? []).isEmpty }
        let roundCount = 3
        let finalQuestionDinosaurs: [Dinosaur]
        if allCladesWithDinos.count >= roundCount {
            let cladesToUse = Array(allCladesWithDinos.shuffled().prefix(roundCount))
            finalQuestionDinosaurs = cladesToUse.compactMap { (byClade[$0] ?? []).shuffled().first }
        } else {
            finalQuestionDinosaurs = Array(pool.shuffled().prefix(roundCount))
        }
        guard finalQuestionDinosaurs.count == roundCount, Set(finalQuestionDinosaurs.map { $0.id }).count == roundCount else {
            fatalError("Need \(roundCount) unique dinosaurs for Dino Bones")
        }
        var rounds: [RoundQuestion] = []
        for (roundNumber, questionDinosaur) in finalQuestionDinosaurs.enumerated() {
            let roundId = roundNumber + 1
            let questionClade = LandDinosaurCladeCatalog.clade(forCreatureId: questionDinosaur.id)
            let decoyCandidates = pool.filter { d in
                d.id != questionDinosaur.id && LandDinosaurCladeCatalog.clade(forCreatureId: d.id) != questionClade
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

    /// Temporarily 2 rounds while `dino-body-*` coverage is limited (e.g. ankylosaur + sauropod). Increase when more clades ship.
    private static let whoseBonesRoundCount = 2

    /// Whose Bones?: main image is `dino-body-{segment}-{clade}`; pick the dinosaur whose clade matches the clue. Options use full-body `dino-{slug}` art (same as Match / Weigh).
    static var whoseBones: GuessGameConfig {
        let allDinosaurs = MatchingGameConfigs.allDinosaurs
        let pool = allDinosaurs.filter { d in
            guard let imageName = d.imageName, imageName.hasPrefix("dino-") else { return false }
            return UIImage(named: imageName) != nil
        }
        guard pool.count >= 3 else {
            fatalError("Need at least 3 dinosaurs with bundled dino- full-body images for Whose Bones, but only have \(pool.count)")
        }
        var clueQueue = shuffledWhoseBonesClues()
        guard clueQueue.count >= whoseBonesRoundCount else {
            fatalError("Need at least \(whoseBonesRoundCount) dino-body-* imagesets for Whose Bones, but only have \(clueQueue.count)")
        }
        var rounds: [RoundQuestion] = []
        var usedCorrectIds: Set<Int> = []
        while rounds.count < whoseBonesRoundCount && !clueQueue.isEmpty {
            let clue = clueQueue.removeFirst()
            let matching = dinoCladesMatchingBodyAssetClade(clue.assetClade)
            guard !matching.isEmpty else { continue }
            let correctPool = pool.filter { matching.contains(LandDinosaurCladeCatalog.clade(forCreatureId: $0.id)) && !usedCorrectIds.contains($0.id) }
            guard let correct = correctPool.shuffled().first else { continue }
            let decoyPool = pool.filter { !matching.contains(LandDinosaurCladeCatalog.clade(forCreatureId: $0.id)) && $0.id != correct.id }
            guard decoyPool.count >= 2 else { continue }
            let decoys = Array(decoyPool.shuffled().prefix(2))
            var options = [correct] + decoys
            options.shuffle()
            rounds.append(RoundQuestion(
                id: rounds.count + 1,
                questionImageName: clue.imageAssetName,
                questionImageFallback: correct.imageName,
                correctAnswerId: correct.id,
                options: options,
                bodySegmentSpeechKey: clue.segment
            ))
            usedCorrectIds.insert(correct.id)
        }
        guard rounds.count == whoseBonesRoundCount else {
            fatalError("Could not build \(whoseBonesRoundCount) Whose Bones rounds (clade/body asset mismatch — add clues or adjust pool)")
        }
        return GuessGameConfig(
            id: "whose-bones",
            title: "Whose Bones?",
            introAudio: "game-whose-bones",
            rounds: rounds,
            availableDinosaurs: allDinosaurs
        )
    }

    private struct WhoseBonesClue {
        let imageAssetName: String
        let segment: String
        let assetClade: String
    }

    private static let whoseBonesSegments = ["skull", "neck", "foreleg", "hindleg", "pelvis", "ribcage", "shoulder", "tail"]

    private static func shuffledWhoseBonesClues() -> [WhoseBonesClue] {
        var clues: [WhoseBonesClue] = []
        for name in ImageAssetNames.knownAssets where name.hasPrefix("dino-body-") {
            guard let parsed = parseDinoBodyAssetName(name) else { continue }
            clues.append(WhoseBonesClue(imageAssetName: name, segment: parsed.segment, assetClade: parsed.clade))
        }
        return clues.shuffled()
    }

    private static func parseDinoBodyAssetName(_ name: String) -> (segment: String, clade: String)? {
        let prefix = "dino-body-"
        guard name.hasPrefix(prefix) else { return nil }
        let rest = String(name.dropFirst(prefix.count))
        for seg in whoseBonesSegments {
            let mid = "\(seg)-"
            guard rest.hasPrefix(mid) else { continue }
            let clade = String(rest.dropFirst(mid.count))
            if clade.isEmpty { continue }
            return (seg, clade)
        }
        return nil
    }

    private static func dinoCladesMatchingBodyAssetClade(_ assetClade: String) -> Set<DinoClade> {
        switch assetClade {
        case "sauropod": return [.sauropod]
        case "ankylosaur": return [.ankylosaurid]
        case "ceratopsian": return [.ceratopsian]
        case "hadrosaur": return [.hadrosaur]
        case "stegosaur": return [.stegosaur]
        case "small-theropod", "large-theropod", "ornithomimid":
            return [.theropod, .spinosaurid]
        case "ornithischian":
            return [.ornithopod, .pachycephalosaur, .stegosaur, .ankylosaurid, .ceratopsian, .hadrosaur]
        default:
            return []
        }
    }
}
