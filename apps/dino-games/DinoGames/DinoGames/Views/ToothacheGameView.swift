//
//  ToothacheGameView.swift
//  DinoGames
//
//  Dino Toothache: Opposite of Dino Flora. Each round shows a dinosaur with a toothache (dino-toothache-search-{slug})
//  desperately searching for its tooth. Five paleontologists each hold a different tooth type (dino-toothache-tooth-{toothType}).
//  Player picks the paleontologist with the matching tooth. Dinosaur slug → tooth type via dinoToothacheToothTypeBySlug.
//

import SwiftUI
import AVFoundation
import UIKit

// MARK: - Star layout angles (same as Dino Flora / Dino Formations)

private let dinoToothacheStarAngles: [Double] = [
    -Double.pi / 2,
    -Double.pi / 2 + 2 * Double.pi / 5,
    -Double.pi / 2 + 4 * Double.pi / 5,
    -Double.pi / 2 + 6 * Double.pi / 5,
    -Double.pi / 2 + 8 * Double.pi / 5
]

private func dinoToothacheTimeSeed() -> UInt64 {
    UInt64(bitPattern: Int64(Date().timeIntervalSince1970 * 1_000_000))
}

private struct DinoToothacheSeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

private let dinoToothacheCircleSize: CGFloat = 96

// MARK: - Data Models

struct ToothacheRound: Identifiable {
    let id: Int // Round number (1..5)
    /// Dinosaur with toothache (search image); correct answer is this dinosaur's tooth.
    let correctDinosaur: Dinosaur
    /// 5 dinosaurs: 1 correct + 4 decoys. Each slot shows paleontologist with tooth dino-toothache-tooth-{slug}.
    let slots: [Dinosaur]
}

// MARK: - Game Configuration

struct ToothacheGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let rounds: [ToothacheRound]
    let availableDinosaurs: [Dinosaur]
}

// MARK: - Main View

struct ToothacheGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: ToothacheGameConfig

    @State private var speechManager = SpeechManager()
    @State private var currentRound = 1
    @State private var selectedDinosaur: Dinosaur?
    @State private var isAudioPlaying = false
    @State private var isGameComplete = false
    @State private var victoryWalkDinosaurs: [Dinosaur] = []
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var displayedDinoName: String? = nil
    @State private var hasStartedGame = false
    /// When non-nil, we're walking the tooth options (highlight + dinosaur name); index 0..<5. When nil, selection allowed.
    @State private var introWalkIndex: Int? = nil

    private var currentQuestion: ToothacheRound? {
        gameConfig.rounds.first { $0.id == currentRound }
    }

    private let totalRounds = 3

    var body: some View {
        NavigationView {
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    guard !hasStartedGame else { return }
                    hasStartedGame = true
                    startGame()
                }
                .onDisappear {
                    hasStartedGame = false
                    speechManager.onAudioFinished = nil
                    speechManager.stopCurrentAudio()
                }
                .allowsHitTesting(!isAudioPlaying)
                .opacity(isAudioPlaying ? 0.85 : 1.0)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 20) {
            Text(gameConfig.title)
                .font(.largeTitle)
                .padding(.top, 8)
            gameBody
        }
    }

    @ViewBuilder
    private var gameBody: some View {
        if let question = currentQuestion, !isGameComplete {
            VStack(spacing: 6) {
                // Top: Dinosaur with toothache desperately searching
                dinosaurSearchImage(question.correctDinosaur)
                    .id(question.correctDinosaur.id)
                Text(question.correctDinosaur.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("Round \(currentRound) of \(totalRounds)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                ZStack {
                    if let name = displayedDinoName {
                        Text(name)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .lineLimit(1)
                    }
                }
                .frame(height: 32)
                fiveStarLayout(question: question)
            }
        } else if isGameComplete {
            endSequenceView
                .id("dino-toothache-victory")
        } else {
            VStack(spacing: 16) {
                ProgressView()
                Text("Loading…")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Dinosaur with toothache searching for its tooth. Image: dino-toothache-search-{slug}.
    private func dinosaurSearchImage(_ dino: Dinosaur) -> some View {
        let slug = dino.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(dino.id)"
        let imageName = "dino-toothache-search-\(slug)"
        return Group {
            if ImageAssetCache.imageExists(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 340, maxHeight: 220)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 260, height: 130)
                    .overlay(Text(dino.name).font(.title2))
            }
        }
        .padding(.horizontal)
    }

    private func fiveStarLayout(question: ToothacheRound) -> some View {
        DinoToothacheStarLayoutView(
            slots: question.slots,
            selectedDinosaur: selectedDinosaur,
            correctAnswerId: question.correctDinosaur.id,
            introHighlightIndex: introWalkIndex,
            tapHandler: DinoToothacheTapHandler(perform: { handleTap($0, question: question) })
        )
        .frame(height: 320)
        .padding(.horizontal)
    }

    private func handleTap(_ dino: Dinosaur, question: ToothacheRound) {
        guard !isAudioPlaying else { return }
        selectedDinosaur = dino
        let isCorrect = dino.id == question.correctDinosaur.id
        let (audioKey, displayText) = toothAudioKeyAndDisplay(for: dino)
        displayedDinoName = displayText
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playFeedbackAfterTap(correct: isCorrect, question: question)
        }
        speechManager.speak(audioKey: audioKey, fallbackText: displayText)
    }

    private func playFeedbackAfterTap(correct: Bool, question: ToothacheRound) {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.displayedDinoName = nil
            self.selectedDinosaur = nil
            self.isAudioPlaying = false
            if correct {
                self.finishRound(question: question)
            }
        }
        if correct {
            if let url = speechManager.urlForAudio(key: "thats-right-you-guessed-it") {
                speechManager.playAudioFile(url: url)
            } else {
                speechManager.speak("thats-right-you-guessed-it")
            }
        } else {
            if let url = speechManager.urlForAudio(key: "try-again") {
                speechManager.playAudioFile(url: url)
            } else {
                speechManager.speak("try-again")
            }
        }
    }

    private func finishRound(question: ToothacheRound) {
        victoryWalkDinosaurs.append(question.correctDinosaur)
        selectedDinosaur = nil
        if currentRound >= totalRounds {
            isGameComplete = true
            return
        }
        currentRound += 1
        guard let nextQuestion = currentQuestion else {
            isGameComplete = true
            return
        }
        isAudioPlaying = true
        playHintThenStartWalk(nextQuestion: nextQuestion)
    }

    private func playHintThenStartWalk(nextQuestion: ToothacheRound) {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playDinosaurIntroThenStartWalk(question: nextQuestion)
        }
        if let url = speechManager.urlForAudio(key: "games-dino-toothache-this-dinosaur-lost-its-tooth") {
            speechManager.playAudioFile(url: url)
        } else {
            playDinosaurIntroThenStartWalk(question: nextQuestion)
        }
    }

    private func startIntroWalk(question: ToothacheRound) {
        guard question.slots.count >= 5 else {
            isAudioPlaying = false
            return
        }
        introWalkIndex = 0
        let (audioKey, displayText) = toothAudioKeyAndDisplay(for: question.slots[0])
        displayedDinoName = displayText
        isAudioPlaying = true
        speechManager.onAudioFinished = { advanceIntroWalk(question: question) }
        speechManager.speak(audioKey: audioKey, fallbackText: displayText)
    }

    private func advanceIntroWalk(question: ToothacheRound) {
        speechManager.onAudioFinished = nil
        let next = (introWalkIndex ?? 0) + 1
        if next >= 5 {
            introWalkIndex = nil
            displayedDinoName = nil
            isAudioPlaying = false
            return
        }
        introWalkIndex = next
        let (audioKey, displayText) = toothAudioKeyAndDisplay(for: question.slots[next])
        displayedDinoName = displayText
        speechManager.onAudioFinished = { advanceIntroWalk(question: question) }
        speechManager.speak(audioKey: audioKey, fallbackText: displayText)
    }

    /// Tooth audio key (Audio/Toothache/dino-toothache-{toothType}.m4a) and display text for a slot.
    private func toothAudioKeyAndDisplay(for dino: Dinosaur) -> (audioKey: String, displayText: String) {
        guard let toothType = DentalMorphology.toothType(for: dino) else {
            return (dino.imageName ?? dino.name, dino.name)
        }
        let key = "dino-toothache-\(toothType)"
        let displayText = toothType.replacingOccurrences(of: "-", with: " ").capitalized
        return (key, displayText)
    }

    private func startGame() {
        currentRound = 1
        victoryWalkDinosaurs = []
        isGameComplete = false
        endSequenceStep = -1
        endHighlightIndex = 0
        guard let question = currentQuestion else { return }
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playCanYouReturnTheToothThenStartWalk(question: question)
        }
        speechManager.speak("games-dino-toothache-this-dinosaur-lost-its-tooth")
    }

    /// Round 1: games file already played in startGame; go straight to dinosaur intro then walk.
    private func playCanYouReturnTheToothThenStartWalk(question: ToothacheRound) {
        playDinosaurIntroThenStartWalk(question: question)
    }

    /// Play dinosaur name (dino-{slug}) then start the tooth-option walk.
    private func playDinosaurIntroThenStartWalk(question: ToothacheRound) {
        let dinoKey = question.correctDinosaur.imageName ?? "dino-\(question.correctDinosaur.id)"
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.startIntroWalk(question: question)
        }
        speechManager.speak(audioKey: dinoKey, fallbackText: question.correctDinosaur.name)
    }

    // MARK: - End sequence

    private let victoryRowHeight: CGFloat = 72
    private var victoryListVisibleHeight: CGFloat { 16 + 3 * victoryRowHeight + 2 * 12 + 16 }

    private var endSequenceView: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(victoryWalkDinosaurs.enumerated()), id: \.element.id) { index, dino in
                                DinoToothacheEndRowView(dino: dino, isHighlighted: endHighlightIndex == index)
                                    .id(index)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .frame(height: min(CGFloat(victoryWalkDinosaurs.count) * (victoryRowHeight + 12) + 32, victoryListVisibleHeight))
                    .onChange(of: endHighlightIndex) { _, newValue in
                        if newValue >= 0, newValue < victoryWalkDinosaurs.count {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Group {
                    if endSequenceStep == 2 {
                        dinoToothacheSuccessImageView
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
            if victoryWalkDinosaurs.isEmpty {
                endSequenceStep = 2
            } else {
                let d = victoryWalkDinosaurs[0]
                speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
                speechManager.onAudioFinished = { self.advanceEndHighlight() }
            }
        }
    }

    private var dinoToothacheSuccessImageView: some View {
        Group {
            if ImageAssetCache.imageExists(named: "game-dino-toothache-success") {
                Image("game-dino-toothache-success")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else {
                Text("🦷")
                    .font(.system(size: 100))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func advanceEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < victoryWalkDinosaurs.count {
            let d = victoryWalkDinosaurs[endHighlightIndex]
            speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
            speechManager.onAudioFinished = { advanceEndHighlight() }
        } else {
            endSequenceStep = 2
        }
    }

    private func playGoodJobAndCrowdThenDismiss() {
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

// MARK: - Star layout

private struct DinoToothacheTapHandler {
    let perform: (Dinosaur) -> Void
}

private struct DinoToothacheStarLayoutView: View {
    let slots: [Dinosaur]
    let selectedDinosaur: Dinosaur?
    let correctAnswerId: Int
    let introHighlightIndex: Int?
    let tapHandler: DinoToothacheTapHandler

    private let radius: CGFloat = 100

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                ForEach(Array(slots.enumerated()), id: \.offset) { index, dino in
                    DinoToothacheToothCircleView(
                        dino: dino,
                        isSelected: selectedDinosaur?.id == dino.id,
                        isCorrect: dino.id == correctAnswerId,
                        isIntroHighlighted: introHighlightIndex == index
                    )
                    .position(
                        x: geo.size.width / 2 + radius * CGFloat(cos(dinoToothacheStarAngles[index])),
                        y: geo.size.height / 2 + 20 + radius * CGFloat(sin(dinoToothacheStarAngles[index]))
                    )
                    .onTapGesture { tapHandler.perform(dino) }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// Paleontologist with tooth. Image: dino-toothache-tooth-{toothType} from dinosaur→tooth mapping.
private struct DinoToothacheToothCircleView: View {
    let dino: Dinosaur
    let isSelected: Bool
    let isCorrect: Bool
    var isIntroHighlighted: Bool = false

    private var toothImageName: String? {
        guard let toothType = DentalMorphology.toothType(for: dino) else { return nil }
        return "dino-toothache-tooth-\(toothType)"
    }

    var body: some View {
        Group {
            if let name = toothImageName, ImageAssetCache.imageExists(named: name) {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: dinoToothacheCircleSize, height: dinoToothacheCircleSize)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: dinoToothacheCircleSize, height: dinoToothacheCircleSize)
                    .overlay(Text(dino.icon).font(.system(size: 32)))
            }
        }
        .scaleEffect(isIntroHighlighted ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isIntroHighlighted)
        .overlay(Circle().stroke(strokeColor, lineWidth: isSelected || isIntroHighlighted ? 4 : 2).frame(width: dinoToothacheCircleSize, height: dinoToothacheCircleSize))
        .opacity(isSelected ? 0.9 : 1.0)
    }

    private var strokeColor: Color {
        if isSelected { return isCorrect ? .green : .red }
        if isIntroHighlighted { return Color.accentColor }
        return Color.gray.opacity(0.4)
    }
}

private struct DinoToothacheEndRowView: View {
    let dino: Dinosaur
    let isHighlighted: Bool
    private let rowHeight: CGFloat = 92

    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let name = dino.imageName, ImageAssetCache.imageExists(named: name) {
                    Image(name)
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
                    Text(dino.icon)
                        .font(.system(size: 40))
                        .frame(width: 72, height: 72)
                        .opacity(isHighlighted ? 1.0 : 0.4)
                }
            }
            Text(dino.name)
                .font(.title2)
                .fontWeight(isHighlighted ? .semibold : .regular)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(isHighlighted ? 1.0 : 0.5)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(height: rowHeight)
        .background(RoundedRectangle(cornerRadius: 12).fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2))
    }
}

// MARK: - Game Configurations

struct ToothacheGameConfigs {
    /// Dinosaurs that have dino-toothache-search-{slug} and a mapped tooth type whose dino-toothache-tooth-{toothType} exists.
    private static var dinosaursWithSearchAndToothImages: [Dinosaur] {
        MatchingGameConfigs.allDinosaurs.filter { dino in
            let slug = dino.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(dino.id)"
            let searchName = "dino-toothache-search-\(slug)"
            guard ImageAssetCache.imageExists(named: searchName),
                  let toothType = DentalMorphology.toothType(for: dino) else { return false }
            let toothName = "dino-toothache-tooth-\(toothType)"
            return ImageAssetCache.imageExists(named: toothName)
        }
    }

    /// Dino Toothache: dinosaur with toothache searching; player picks paleontologist with matching tooth. Three rounds; star layout.
    /// When fewer than 3 dinosaurs have both search and tooth images, falls back to all dinosaurs with dino-* images so the game can run (shows placeholders until assets are added).
    static var toothache: ToothacheGameConfig {
        var pool = dinosaursWithSearchAndToothImages
        if pool.count < 3 {
            pool = MatchingGameConfigs.allDinosaurs.filter { $0.imageName?.hasPrefix("dino-") == true }
        }
        guard pool.count >= 3 else {
            fatalError("Need at least 3 dinosaurs for Dino Toothache (have \(pool.count) with dino-* images). Add dinosaurs to MatchingGameConfigs.allDinosaurs.")
        }

        var rng = DinoToothacheSeededRandomNumberGenerator(seed: dinoToothacheTimeSeed())
        let shuffled = pool.shuffled(using: &rng)
        let correctDinosaurs = Array(shuffled.prefix(3))
        guard correctDinosaurs.count == 3, Set(correctDinosaurs.map { $0.id }).count == 3 else {
            fatalError("Need at least 3 unique dinosaurs for Dino Toothache")
        }

        var rounds: [ToothacheRound] = []
        for (roundNumber, correctDinosaur) in correctDinosaurs.enumerated() {
            guard let correctToothType = DentalMorphology.toothType(for: correctDinosaur) else { continue }
            // Decoys must have different tooth types so each paleontologist shows a distinct tooth.
            let decoyCandidates = pool.filter { d in
                d.id != correctDinosaur.id &&
                (DentalMorphology.toothType(for: d) ?? "") != correctToothType
            }
            guard decoyCandidates.count >= 4 else { continue }
            // Pick 4 decoys with distinct tooth types (avoid two decoys sharing same tooth image).
            var chosen: [Dinosaur] = []
            var usedToothTypes: Set<String> = [correctToothType]
            for d in decoyCandidates.shuffled(using: &rng) {
                guard chosen.count < 4, let tt = DentalMorphology.toothType(for: d), !usedToothTypes.contains(tt) else { continue }
                chosen.append(d)
                usedToothTypes.insert(tt)
            }
            guard chosen.count == 4 else { continue }
            var slots = [correctDinosaur] + chosen
            slots.shuffle(using: &rng)
            rounds.append(ToothacheRound(id: roundNumber + 1, correctDinosaur: correctDinosaur, slots: slots))
        }

        guard rounds.count == 3 else {
            fatalError("Could not build 3 rounds for Dino Toothache: need pool with at least 3 dinosaurs having both search and tooth images")
        }

        return ToothacheGameConfig(
            id: "dino-toothache",
            title: "Dino Toothache!",
            introAudio: "dino-toothache",
            rounds: rounds,
            availableDinosaurs: pool
        )
    }
}
