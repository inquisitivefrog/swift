//
//  FindMamaGameView.swift
//  DinoGames
//
//  Find Mama: A paleontologist found a lost egg. Help return the egg to its worried mother.
//

import SwiftUI
import AVFoundation

// MARK: - Data Models

struct FindMamaRound: Identifiable {
    let id: Int // Round number (1, 2, 3)
    let correctMotherId: Int
    let options: [Dinosaur] // 3 dinosaurs: 1 correct mother + 2 decoys
}

struct FindMamaConfig {
    let id: String
    let title: String
    let introAudio: String
    let rounds: [FindMamaRound]
    let availableDinosaurs: [Dinosaur]
}

// MARK: - Clue table (in-memory: which clue values each dinosaur has)

/// One row per dinosaur: values for the 5 clue types (e.g. egg-size: "large", egg-color: "speckled").
/// Images and audio use (hint, value), e.g. clue-egg-size-large, so a finite set of assets works for all dinosaurs.
struct FindMamaClueSet {
    let eggSize: String           // "small", "medium", "large"
    let eggColor: String          // e.g. "speckled", "white", "green"
    let eggShape: String          // e.g. "oval", "round"
    let clutchArrangement: String // e.g. "circle", "line"
    let nestingType: String       // e.g. "mound", "buried"
}

private let findMamaClueHints = ["egg-size", "egg-color", "egg-shape", "clutch-arrangement", "nesting-type"]

private func valueForHintIndex(_ index: Int, in set: FindMamaClueSet) -> String {
    switch index {
    case 0: return set.eggSize
    case 1: return set.eggColor
    case 2: return set.eggShape
    case 3: return set.clutchArrangement
    case 4: return set.nestingType
    default: return "unknown"
    }
}

/// Lookup clue set for a dinosaur (by id). Add or edit entries to match your data; default used if missing.
private func findMamaClueSet(for dinosaur: Dinosaur) -> FindMamaClueSet {
    let table: [Int: FindMamaClueSet] = [
        1:  FindMamaClueSet(eggSize: "large", eggColor: "speckled", eggShape: "oval", clutchArrangement: "circle", nestingType: "mound"),
        2:  FindMamaClueSet(eggSize: "medium", eggColor: "speckled", eggShape: "oval", clutchArrangement: "circle", nestingType: "mound"),
        3:  FindMamaClueSet(eggSize: "medium", eggColor: "speckled", eggShape: "oval", clutchArrangement: "circle", nestingType: "mound"),
        4:  FindMamaClueSet(eggSize: "medium", eggColor: "speckled", eggShape: "oval", clutchArrangement: "circle", nestingType: "mound"),
        5:  FindMamaClueSet(eggSize: "large", eggColor: "speckled", eggShape: "oval", clutchArrangement: "circle", nestingType: "mound"),
        6:  FindMamaClueSet(eggSize: "large", eggColor: "speckled", eggShape: "oval", clutchArrangement: "circle", nestingType: "mound"),
        7:  FindMamaClueSet(eggSize: "large", eggColor: "speckled", eggShape: "oval", clutchArrangement: "circle", nestingType: "mound"),
        8:  FindMamaClueSet(eggSize: "medium", eggColor: "speckled", eggShape: "oval", clutchArrangement: "circle", nestingType: "mound"),
        9:  FindMamaClueSet(eggSize: "medium", eggColor: "speckled", eggShape: "oval", clutchArrangement: "circle", nestingType: "mound"),
        10: FindMamaClueSet(eggSize: "medium", eggColor: "speckled", eggShape: "oval", clutchArrangement: "circle", nestingType: "mound"),
        11: FindMamaClueSet(eggSize: "medium", eggColor: "speckled", eggShape: "oval", clutchArrangement: "circle", nestingType: "mound"),
        12: FindMamaClueSet(eggSize: "small", eggColor: "speckled", eggShape: "oval", clutchArrangement: "circle", nestingType: "mound"),
        13: FindMamaClueSet(eggSize: "medium", eggColor: "speckled", eggShape: "oval", clutchArrangement: "circle", nestingType: "mound"),
    ]
    return table[dinosaur.id] ?? defaultFindMamaClueSet
}

private let defaultFindMamaClueSet = FindMamaClueSet(
    eggSize: "medium",
    eggColor: "speckled",
    eggShape: "oval",
    clutchArrangement: "circle",
    nestingType: "mound"
)

// MARK: - Main View

struct FindMamaGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: FindMamaConfig

    @State private var speechManager = SpeechManager()
    @State private var currentRound = 1
    @State private var selectedDinosaur: Dinosaur?
    @State private var isAudioPlaying = false
    @State private var wrongGuessesThisRound = 0
    @State private var isGameComplete = false
    @State private var isProcessingAnswer = false
    @State private var showRoundOptions = false

    /// Clue reveal: 5 slots; each starts as question mark, then clue-{dinosaur}-{hint}. Walk one by one with highlight + audio.
    @State private var clueImageNames: [String?] = Array(repeating: nil, count: 5)
    @State private var clueHighlightIndex: Int? = nil

    /// After clues: walk the 3 mother options (highlight + name audio) before enabling tap; nil when not walking.
    @State private var optionsWalkIndex: Int? = nil

    /// End sequence: -1 none, 1 = walking row (highlight + name audio), 2 = good-job + crowd then dismiss
    @State private var endSequenceStep: Int = -1
    @State private var endHighlightIndex: Int = 0

    /// The 3 correct mothers in round order (for end-sequence row)
    private var endSequenceMothers: [Dinosaur] {
        gameConfig.rounds.map { r in r.options.first(where: { $0.id == r.correctMotherId })! }
    }

    private var currentRoundData: FindMamaRound? {
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
        clueImageNames = Array(repeating: nil, count: 5)
        clueHighlightIndex = nil
        showRoundOptions = false
        optionsWalkIndex = nil
    }

    private func playRoundPromptAudio() {
        guard !isGameComplete && currentRoundData != nil else { return }
        guard !isProcessingAnswer && !isAudioPlaying else { return }
        showRoundOptions = false
        clueImageNames = Array(repeating: nil, count: 5)
        clueHighlightIndex = nil
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.startClueRevealSequence()
        }
        speechManager.speak("game-find-mama-return-the-egg")
    }

    /// After gameplay audio, reveal clues one by one: show image (clue-{hint}-{value}), brief pause, play audio (e.g. "These eggs are large!").
    private func startClueRevealSequence() {
        guard let round = currentRoundData,
              let mother = round.options.first(where: { $0.id == round.correctMotherId }) else {
            isAudioPlaying = false
            showRoundOptions = true
            return
        }
        let clueSet = findMamaClueSet(for: mother)
        revealNextClue(index: 0, clueSet: clueSet)
    }

    private func revealNextClue(index: Int, clueSet: FindMamaClueSet) {
        if index >= 5 {
            clueHighlightIndex = nil
            showRoundOptions = true
            speechManager.onAudioFinished = nil
            startOptionsWalk()
            return
        }
        let hint = findMamaClueHints[index]
        let value = valueForHintIndex(index, in: clueSet)
        let imageAndAudioKey = "clue-\(hint)-\(value)"
        clueImageNames[index] = imageAndAudioKey
        clueHighlightIndex = index
        isAudioPlaying = true
        let delay: TimeInterval = 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.speechManager.onAudioFinished = {
                self.revealNextClue(index: index + 1, clueSet: clueSet)
            }
            self.speechManager.speak(imageAndAudioKey)
        }
    }

    /// After clues: walk the 3 mother options (highlight + name audio), then enable tapping.
    private func startOptionsWalk() {
        guard let round = currentRoundData, round.options.count >= 3 else {
            isAudioPlaying = false
            return
        }
        optionsWalkIndex = 0
        isAudioPlaying = true
        speechManager.onAudioFinished = { advanceOptionsWalk() }
        speechManager.speak(round.options[0].name)
    }

    private func advanceOptionsWalk() {
        speechManager.onAudioFinished = nil
        guard let round = currentRoundData else {
            optionsWalkIndex = nil
            isAudioPlaying = false
            return
        }
        let next = (optionsWalkIndex ?? 0) + 1
        if next >= round.options.count {
            optionsWalkIndex = nil
            isAudioPlaying = false
            return
        }
        optionsWalkIndex = next
        speechManager.onAudioFinished = { advanceOptionsWalk() }
        speechManager.speak(round.options[next].name)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(gameConfig.title)
                    .font(.largeTitle)
                    .padding(.top)

                if let round = currentRoundData, !isGameComplete {
                    VStack(spacing: 28) {
                        // Mystery egg + round label
                        VStack(spacing: 12) {
                            eggView
                            Text("Round \(currentRound) of 3")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding()

                        // 5 clue slots: question mark until revealed, then clue-{dinosaur}-{hint}
                        findMamaClueRow

                        // 3 mother options (after clues; walk list with highlight + name then enable tap)
                        if showRoundOptions {
                            HStack(spacing: 12) {
                                ForEach(Array(round.options.enumerated()), id: \.element.id) { index, dinosaur in
                                    DinosaurOptionCard(
                                        dinosaur: dinosaur,
                                        isSelected: selectedDinosaur?.id == dinosaur.id,
                                        isDisabled: isProcessingAnswer || isAudioPlaying,
                                        isHighlighted: optionsWalkIndex == index,
                                        onTap: { handleDinosaurTap(dinosaur, round: round) }
                                    )
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else if isGameComplete {
                    findMamaEndSequenceView
                }
            }
            .padding()
            .onAppear {
                resetGameState()
                showRoundOptions = false
                speechManager.isPlaying = false
                speechManager.onAudioFinished = nil
                speechManager.onAudioFinished = { isAudioPlaying = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    playRoundPromptAudio()
                }
            }
            .onDisappear {
                speechManager.onAudioFinished = nil
                speechManager.stopCurrentAudio()
                isAudioPlaying = false
            }
            .onChange(of: currentRound) { _, _ in
                showRoundOptions = false
                clueImageNames = Array(repeating: nil, count: 5)
                clueHighlightIndex = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    playRoundPromptAudio()
                }
            }
            .allowsHitTesting(!isAudioPlaying && !isProcessingAnswer)
            .opacity((isAudioPlaying || isProcessingAnswer) ? 0.7 : 1.0)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// Row of 5 clue images: each starts as question mark (clue-question-mark imageset), then clue-{hint}-{value}. One highlighted during reveal.
    private var findMamaClueRow: some View {
        HStack(spacing: 10) {
            ForEach(0..<5, id: \.self) { index in
                let imageName = index < clueImageNames.count ? clueImageNames[index] : nil
                let isHighlighted = clueHighlightIndex == index
                Group {
                    if let name = imageName, UIImage(named: name) != nil {
                        Image(name)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if UIImage(named: "clue-question-mark") != nil {
                        Image("clue-question-mark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "questionmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isHighlighted ? Color.accentColor.opacity(0.15) : Color.clear)
                )
            }
        }
        .padding(.horizontal, 8)
    }

    /// Mystery egg: use egg-{dinosaur} for the correct mother this round (e.g. egg-trex), then fallbacks.
    private var eggView: some View {
        Group {
            let eggName = findMamaEggImageName
            if UIImage(named: eggName) != nil {
                Image(eggName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
            } else if UIImage(named: "find-mama-egg") != nil {
                Image("find-mama-egg")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
            } else if UIImage(named: "mama-match-egg") != nil {
                Image("mama-match-egg")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
            } else if UIImage(named: "egg") != nil {
                Image("egg")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
            } else {
                Text("🥚")
                    .font(.system(size: 120))
                    .padding(40)
                    .background(Circle().fill(Color.brown.opacity(0.15)))
            }
        }
    }

    /// Imageset name for the mystery egg this round: egg-{slug} from the correct mother (e.g. egg-trex).
    /// Shared egg images: egg-sauropod for diplodocus/apatosaurus/brachiosaurus; egg-hadrosaur for hadrosaurs (see below).
    private var findMamaEggImageName: String {
        guard let round = currentRoundData,
              let mother = round.options.first(where: { $0.id == round.correctMotherId }) else {
            return "find-mama-egg"
        }
        let slug = mother.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "dino-\(mother.id)"
        // One sauropod egg image for all sauropod species: diplodocus, apatosaurus, brachiosaurus.
        if ["apatosaurus", "brachiosaurus", "diplodocus"].contains(slug) {
            return "egg-sauropod"
        }
        // One hadrosaur egg image for all hadrosaurs (duck-billed dinosaurs): Parasaurolophus, Corythosaurus, Edmontosaurus.
        if ["parasaurolophus", "corythosaurus", "edmontosaurus"].contains(slug) {
            return "egg-hadrosaur"
        }
        return "egg-\(slug)"
    }

    private func handleDinosaurTap(_ dinosaur: Dinosaur, round: FindMamaRound) {
        guard !isProcessingAnswer && !isAudioPlaying else { return }
        selectedDinosaur = dinosaur
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.checkAnswer(dinosaur: dinosaur, round: round)
        }
        speechManager.speak(dinosaur.name)
    }

    private func checkAnswer(dinosaur: Dinosaur, round: FindMamaRound) {
        isProcessingAnswer = true
        let isCorrect = dinosaur.id == round.correctMotherId

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
            // No auto-skip: allow unlimited attempts so kids can match sound ↔ image.
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

    private var findMamaEndSequenceView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                ForEach(Array(endSequenceMothers.enumerated()), id: \.element.id) { index, dinosaur in
                    let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                    HStack(spacing: 16) {
                        findMamaEndImage(dinosaur: dinosaur, isHighlighted: isHighlighted)
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
            if endSequenceMothers.isEmpty {
                playGoodJobAndCrowdThenDismiss()
            } else {
                speechManager.speak(endSequenceMothers[0].name)
                speechManager.onAudioFinished = { advanceFindMamaEndHighlight() }
            }
        }
    }

    private func findMamaEndImage(dinosaur: Dinosaur, isHighlighted: Bool) -> some View {
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

    private func advanceFindMamaEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < endSequenceMothers.count {
            speechManager.speak(endSequenceMothers[endHighlightIndex].name)
            speechManager.onAudioFinished = { advanceFindMamaEndHighlight() }
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
                LandDinosaurProgress.notifyCompletionIfLandGame(configId: self.gameConfig.id)
                self.isPresented = false
            }
        } else if let u = goodJobURL ?? crowdURL {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                LandDinosaurProgress.notifyCompletionIfLandGame(configId: self.gameConfig.id)
                self.isPresented = false
            }
            speechManager.playAudioFile(url: u)
        } else {
            LandDinosaurProgress.notifyCompletionIfLandGame(configId: gameConfig.id)
            isPresented = false
        }
    }
}

// MARK: - Game Configuration

struct FindMamaConfigs {
    static var findMama: FindMamaConfig {
        let allDinosaurs = MatchingGameConfigs.allDinosaurs
        guard allDinosaurs.count >= 3 else {
            fatalError("Need at least 3 dinosaurs for Find Mama, but only have \(allDinosaurs.count)")
        }
        let shuffled = allDinosaurs.shuffled()
        let motherDinosaurs = Array(shuffled.prefix(3))
        guard Set(motherDinosaurs.map { $0.id }).count == 3 else {
            fatalError("Need 3 unique dinosaurs for Find Mama")
        }
        var rounds: [FindMamaRound] = []
        for (roundNumber, mother) in motherDinosaurs.enumerated() {
            let roundId = roundNumber + 1
            let decoyCandidates = allDinosaurs.filter { $0.id != mother.id }
            let decoys = Array(decoyCandidates.shuffled().prefix(2))
            var options = [mother] + decoys
            options.shuffle()
            rounds.append(FindMamaRound(id: roundId, correctMotherId: mother.id, options: options))
        }
        return FindMamaConfig(
            id: "find-mama",
            title: "Find Mama!",
            introAudio: "game-find-mama",
            rounds: rounds,
            availableDinosaurs: allDinosaurs
        )
    }
}
