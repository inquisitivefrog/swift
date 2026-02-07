//
//  DinoLunchGameView.swift
//  DinoGames
//
//  Dino Lunch!: A lunch tray is shown (image + tray contents audio). Three young dinosaurs (teen-{diet}-{dinosaur}); match the tray with the correct dinosaur. Three unique diets per round.
//

import SwiftUI
import AVFoundation

// MARK: - Data Models

struct DinoLunchRound: Identifiable {
    let id: Int // Round number (1, 2, 3)
    /// Diet key for this round: "herbivore", "carnivore", "omnivore", "insectivore". Tray image: lunch-{dietKey}-{slug}; teen images: teen-{dietKey}-{slug}.
    let dietKey: String
    let correctDinosaurId: Int
    let options: [Dinosaur] // 3 dinosaurs: 3 unique diets, one matching the tray
}

struct DinoLunchConfig {
    let id: String
    let title: String
    let introAudio: String
    let rounds: [DinoLunchRound]
    let availableDinosaurs: [Dinosaur]
}

// MARK: - Main View

struct DinoLunchGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: DinoLunchConfig

    @State private var speechManager = SpeechManager()
    @State private var currentRound = 1
    @State private var selectedDinosaur: Dinosaur?
    @State private var isAudioPlaying = false
    @State private var wrongGuessesThisRound = 0
    @State private var isGameComplete = false
    @State private var isProcessingAnswer = false

    /// End sequence: -1 none, 1 = walking row (highlight + name audio), 2 = good-job + crowd then dismiss
    @State private var endSequenceStep: Int = -1
    @State private var endHighlightIndex: Int = 0
    /// Play tray contents audio once per round when tray is shown
    @State private var lastPlayedTrayRound: Int? = nil

    /// The 3 correct dinosaurs in round order (for end-sequence row)
    private var endSequenceDinosaurs: [Dinosaur] {
        gameConfig.rounds.map { r in r.options.first(where: { $0.id == r.correctDinosaurId })! }
    }

    private var currentRoundData: DinoLunchRound? {
        gameConfig.rounds.first { $0.id == currentRound }
    }

    private func resetGameState() {
        currentRound = 1
        selectedDinosaur = nil
        wrongGuessesThisRound = 0
        isGameComplete = false
        isProcessingAnswer = false
        endSequenceStep = -1
        endHighlightIndex = 0
        lastPlayedTrayRound = nil
    }

    /// Slug for asset names: "Triceratops" -> "triceratops", "T-Rex" -> "t-rex"
    private func slug(for dinosaur: Dinosaur) -> String {
        dinosaur.name.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    /// Slug used in lunch/teen image set names (Assets.xcassets). T-Rex assets use "trex" (no hyphen).
    private func lunchTeenAssetSlug(for dinosaur: Dinosaur) -> String {
        if dinosaur.name.lowercased() == "t-rex" { return "trex" }
        return slug(for: dinosaur)
    }

    /// Display label for diet in teen intro text (e.g. "herbivore" -> "herbivore", for "Young herbivore")
    private static func dietIntroLabel(_ dietKey: String) -> String {
        switch dietKey {
        case "herbivore": return "herbivore"
        case "carnivore": return "carnivore"
        case "omnivore": return "omnivore"
        case "insectivore": return "insectivore"
        default: return dietKey
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(gameConfig.title)
                    .font(.largeTitle)
                    .padding(.top)

                if let round = currentRoundData, !isGameComplete {
                    VStack(spacing: 28) {
                        // Lunch tray only (no text); tray contents audio plays on appear (each round)
                        let correctDino = round.options.first(where: { $0.id == round.correctDinosaurId })!
                        let trayImageName = "lunch-\(round.dietKey)-\(lunchTeenAssetSlug(for: correctDino))"
                        lunchTrayView(imageName: trayImageName)
                            .padding()
                            .id(currentRound)
                            .onAppear {
                                if lastPlayedTrayRound != currentRound {
                                    lastPlayedTrayRound = currentRound
                                    isAudioPlaying = true
                                    // 1) Gameplay message (Games/game-give-this-nutritious-lunch); 2) then tray contents (Trays/contents-{diet}-{slug}) with gap to avoid clicks
                                    let contentsKey = "contents-\(round.dietKey)-\(lunchTeenAssetSlug(for: correctDino))"
                                    speechManager.onAudioFinished = {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                            self.speechManager.onAudioFinished = {
                                                DispatchQueue.main.async { self.isAudioPlaying = false }
                                            }
                                            self.speechManager.speak(contentsKey)
                                        }
                                    }
                                    speechManager.speak("game-give-this-nutritious-lunch")
                                }
                            }

                        // 3 young dinosaurs (teen-{diet}-{dinosaur}); three unique diets; introduce via text + audio when tapped
                        HStack(spacing: 12) {
                            ForEach(round.options) { dinosaur in
                                TeenDinoOptionCard(
                                    dinosaur: dinosaur,
                                    dietKey: DinoLunchConfigs.dietKey(for: dinosaur.id),
                                    slug: lunchTeenAssetSlug(for: dinosaur),
                                    introLabel: Self.dietIntroLabel(DinoLunchConfigs.dietKey(for: dinosaur.id)),
                                    isSelected: selectedDinosaur?.id == dinosaur.id,
                                    isDisabled: isProcessingAnswer || isAudioPlaying,
                                    onTap: { handleDinosaurTap(dinosaur, round: round) }
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .frame(maxWidth: .infinity)
                } else if isGameComplete {
                    dinoLunchEndSequenceView
                }
            }
            .padding()
            .onAppear {
                resetGameState()
                speechManager.isPlaying = false
                speechManager.onAudioFinished = nil
                speechManager.onAudioFinished = { isAudioPlaying = false }
            }
            .onDisappear {
                speechManager.onAudioFinished = nil
                speechManager.stopCurrentAudio()
                isAudioPlaying = false
            }
            .allowsHitTesting(!isAudioPlaying && !isProcessingAnswer)
            .opacity((isAudioPlaying || isProcessingAnswer) ? 0.7 : 1.0)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// Lunch tray: image lunch-{diet}-{dinosaur}; no text (tray contents audio plays separately)
    private func lunchTrayView(imageName: String) -> some View {
        Group {
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
            } else {
                let emoji: String = {
                    if imageName.contains("carnivore") { return "🥩" }
                    if imageName.contains("omnivore") { return "🥗" }
                    if imageName.contains("insectivore") { return "🐜" }
                    return "🥬"
                }()
                Text(emoji)
                    .font(.system(size: 120))
                    .padding(40)
                    .background(Circle().fill(Color.orange.opacity(0.15)))
            }
        }
    }

    // MARK: - Teen dinosaur option card (young dinosaur image: teen-{diet}-{dinosaur})

    private struct TeenDinoOptionCard: View {
        let dinosaur: Dinosaur
        let dietKey: String
        let slug: String
        /// Intro text when selected, e.g. "Young herbivore"
        let introLabel: String
        let isSelected: Bool
        let isDisabled: Bool
        let onTap: () -> Void

        private var teenImageName: String { "teen-\(dietKey)-\(slug)" }

        var body: some View {
            Button(action: onTap) {
                VStack(spacing: 10) {
                    if UIImage(named: teenImageName) != nil {
                        Image(teenImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 90, height: 90)
                    } else {
                        Text(dinosaur.icon)
                            .font(.system(size: 60))
                    }
                    if isSelected {
                        VStack(spacing: 4) {
                            Text(dinosaur.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)
                                .allowsTightening(true)
                                .multilineTextAlignment(TextAlignment.center)
                            Text("Young \(introLabel)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .allowsTightening(true)
                                .multilineTextAlignment(TextAlignment.center)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .frame(width: isSelected ? 120 : 100, height: isSelected ? 170 : 120)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                .opacity(isDisabled ? 0.5 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isDisabled)
        }
    }

    private func handleDinosaurTap(_ dinosaur: Dinosaur, round: DinoLunchRound) {
        guard !isProcessingAnswer && !isAudioPlaying else { return }
        selectedDinosaur = dinosaur
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.checkAnswer(dinosaur: dinosaur, round: round)
        }
        // Introduce teen via audio file (Teens/teen-{diet}-{slug}.m4a); fallback to dinosaur name if no file
        let introKey = "teen-\(DinoLunchConfigs.dietKey(for: dinosaur.id))-\(slug(for: dinosaur))"
        if speechManager.urlForAudio(key: introKey) != nil {
            speechManager.speak(introKey)
        } else {
            speechManager.speak(audioKey: dinosaur.imageName ?? dinosaur.name, fallbackText: dinosaur.name)
        }
    }

    private func checkAnswer(dinosaur: Dinosaur, round: DinoLunchRound) {
        isProcessingAnswer = true
        let isCorrect = dinosaur.id == round.correctDinosaurId

        if isCorrect {
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
                    } else {
                        self.isGameComplete = true
                    }
                }
            }
            speechManager.speak("thats-right-you-guessed-it")
        } else {
            wrongGuessesThisRound += 1
            isAudioPlaying = true
            // No auto-skip: younger kids can keep tapping options to hear names and try again.
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

    private var dinoLunchEndSequenceView: some View {
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
                        dinoLunchEndImage(dinosaur: dinosaur, isHighlighted: isHighlighted)
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
                let d = endSequenceDinosaurs[0]
                speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
                speechManager.onAudioFinished = { advanceDinoLunchEndHighlight() }
            }
        }
    }

    private func dinoLunchEndImage(dinosaur: Dinosaur, isHighlighted: Bool) -> some View {
        let teenImageName = "teen-\(DinoLunchConfigs.dietKey(for: dinosaur.id))-\(lunchTeenAssetSlug(for: dinosaur))"
        return Group {
            if UIImage(named: teenImageName) != nil {
                Image(teenImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .opacity(isHighlighted ? 1.0 : 0.4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
            } else if let imageName = dinosaur.imageName, UIImage(named: imageName) != nil {
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

    private func advanceDinoLunchEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < endSequenceDinosaurs.count {
            let d = endSequenceDinosaurs[endHighlightIndex]
            speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
            speechManager.onAudioFinished = { advanceDinoLunchEndHighlight() }
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

// MARK: - Game Configuration

struct DinoLunchConfigs {
    /// Herbivores: Triceratops, Stegosaurus, Therizinosaurus, Apatosaurus, Ankylosaurus, Corythosaurus, Parasaurolophus, Iguanodon, Edmontosaurus
    private static let herbivoreIds: Set<Int> = [2, 3, 5, 7, 8, 9, 10, 11, 13]
    /// Carnivores: T-Rex, Velociraptor (Spinosaurus/Baryonyx classed as omnivores per current research)
    private static let carnivoreIds: Set<Int> = [1, 4]
    /// Omnivores (e.g. mixed diet / piscivore-derived): Troodon, Spinosaurus
    private static let omnivoreIds: Set<Int> = [6, 12]
    /// Insectivores: (add dinosaur ids when available)
    private static let insectivoreIds: Set<Int> = []

    /// Diet keys used for the three rounds and for asset names
    private static let dietKeysForRounds = ["herbivore", "carnivore", "omnivore"]

    /// Diet key for asset names: lunch-{dietKey}-{slug}, teen-{dietKey}-{slug}
    static func dietKey(for dinosaurId: Int) -> String {
        if herbivoreIds.contains(dinosaurId) { return "herbivore" }
        if carnivoreIds.contains(dinosaurId) { return "carnivore" }
        if omnivoreIds.contains(dinosaurId) { return "omnivore" }
        if insectivoreIds.contains(dinosaurId) { return "insectivore" }
        return "herbivore"
    }

    static var dinoLunch: DinoLunchConfig {
        let allDinosaurs = MatchingGameConfigs.allDinosaurs
        guard allDinosaurs.count >= 3 else {
            fatalError("Need at least 3 dinosaurs for Dino Lunch, but only have \(allDinosaurs.count)")
        }
        var rounds: [DinoLunchRound] = []
        let dietRounds: [(String, Set<Int>)] = [
            ("herbivore", herbivoreIds),
            ("carnivore", carnivoreIds),
            ("omnivore", omnivoreIds),
        ]
        for (roundNumber, (dietKey, dietIds)) in dietRounds.enumerated() {
            let roundId = roundNumber + 1
            let correctCandidates = allDinosaurs.filter { dietIds.contains($0.id) }
            guard let correct = correctCandidates.randomElement() else { continue }
            // Two decoys: one from each of the other two diets (three unique diets)
            let otherDietKeys = dietKeysForRounds.filter { $0 != dietKey }
            let otherDietIdSets: [Set<Int>] = otherDietKeys.map { key in
                switch key {
                case "herbivore": return herbivoreIds
                case "carnivore": return carnivoreIds
                case "omnivore": return omnivoreIds
                case "insectivore": return insectivoreIds
                default: return []
                }
            }
            let decoy1Candidates = allDinosaurs.filter { otherDietIdSets[0].contains($0.id) }
            let decoy2Candidates = allDinosaurs.filter { otherDietIdSets[1].contains($0.id) }
            guard let decoy1 = decoy1Candidates.randomElement(),
                  let decoy2 = decoy2Candidates.randomElement(),
                  decoy1.id != decoy2.id else { continue }
            var options = [correct, decoy1, decoy2]
            options.shuffle()
            rounds.append(DinoLunchRound(id: roundId, dietKey: dietKey, correctDinosaurId: correct.id, options: options))
        }
        guard rounds.count == 3 else {
            fatalError("Dino Lunch needs exactly 3 rounds; got \(rounds.count)")
        }
        return DinoLunchConfig(
            id: "dino-lunch",
            title: "Dino Lunch!",
            introAudio: "game-dino-lunch",
            rounds: rounds,
            availableDinosaurs: allDinosaurs
        )
    }
}
