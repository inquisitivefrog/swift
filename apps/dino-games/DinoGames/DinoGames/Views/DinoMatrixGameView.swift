//
//  DinoMatrixGameView.swift
//  DinoGames
//
//  Dino Matrix: Help the paleontologist identify the matrix material encasing the fossil.
//  Materials: limestone, mudstone, bentonite, sandstone, siltstone, tuff, amber, shale, ironstone, claystone, lignite, phosphorite, conglomerate.
//

import SwiftUI
import AVFoundation

// MARK: - Data Models

struct MatrixMaterial: Identifiable {
    let id: Int
    let name: String
    /// Slug for fossil composites and audio (e.g. "limestone", "tuff").
    var materialSlug: String { name.lowercased().replacingOccurrences(of: " ", with: "-") }
    /// Rock option card: `dino-matrix-material-{stone}` (Tuff → `volcanic-tuff` on disk).
    var matrixRockImageAssetName: String { "dino-matrix-material-\(matrixRockAssetSlug)" }
    /// Fossil in matrix: `dino-matrix-{stone}-{dinosaur}`.
    func fossilMatrixImageAssetName(dinosaurSlug: String) -> String {
        "dino-matrix-\(materialSlug)-\(dinosaurSlug)"
    }

    /// Legacy alias used by option cards.
    var imageName: String? { matrixRockImageAssetName }

    func imageName(dinosaurSlug: String?) -> String? {
        guard let slug = dinosaurSlug, !slug.isEmpty else { return imageName }
        return fossilMatrixImageAssetName(dinosaurSlug: slug)
    }

    /// Imageset slug under `dino-matrix-material-*` (differs from fossil segment for Tuff).
    private var matrixRockAssetSlug: String {
        materialSlug == "tuff" ? "volcanic-tuff" : materialSlug
    }
}

struct DinoMatrixRound: Identifiable {
    let id: Int
    /// When set, this round shows the dinosaur and asks which matrix its fossils are typically found in.
    let dinosaur: Dinosaur?
    let correctMaterialId: Int
    let options: [MatrixMaterial] // 3 options: 1 correct + 2 decoys
}

struct DinoMatrixGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let rounds: [DinoMatrixRound]
    let allMaterials: [MatrixMaterial]
}

// MARK: - Main View

struct DinoMatrixGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: DinoMatrixGameConfig

    @State private var speechManager = SpeechManager()
    @State private var currentRound = 1
    @State private var selectedMaterial: MatrixMaterial?
    @State private var isAudioPlaying = false
    @State private var isGameComplete = false
    @State private var isProcessingAnswer = false
    @State private var optionsWalkIndex: Int? = nil
    @State private var endSequenceStep: Int = -1
    @State private var endHighlightIndex: Int = 0

    private var currentQuestion: DinoMatrixRound? {
        gameConfig.rounds.first { $0.id == currentRound }
    }

    /// Correct material per round (same order as `gameConfig.rounds`) for recap audio and labels.
    private var endSequenceMaterials: [MatrixMaterial] {
        gameConfig.rounds.compactMap { r in
            gameConfig.allMaterials.first { $0.id == r.correctMaterialId }
        }
    }

    /// Round + material for victory recap thumbnails (composite `dino-matrix-{stone}-{dino}` when bundled).
    private var endRecapRows: [(round: DinoMatrixRound, material: MatrixMaterial)] {
        gameConfig.rounds.compactMap { r in
            guard let mat = gameConfig.allMaterials.first(where: { $0.id == r.correctMaterialId }) else { return nil }
            return (r, mat)
        }
    }

    /// Victory recap shows rock matrix art (`dino-matrix-material-{stone}`), not fossil composites.
    private func matrixRecapThumbnailAssetName(round: DinoMatrixRound, material: MatrixMaterial) -> String? {
        _ = round
        guard ImageAssetCache.imageExists(named: material.matrixRockImageAssetName) else { return nil }
        return material.matrixRockImageAssetName
    }

    private func resetGameState() {
        currentRound = 1
        selectedMaterial = nil
        isGameComplete = false
        isProcessingAnswer = false
        optionsWalkIndex = nil
        endSequenceStep = -1
        endHighlightIndex = 0
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if !isGameComplete {
                    Text(gameConfig.title)
                        .font(.largeTitle)
                        .padding(.top)
                }

                if let question = currentQuestion, !isGameComplete {
                    VStack(spacing: 28) {
                        // Top: Dinosaur (when round has one) or generic fossil prompt + round label
                        VStack(spacing: 12) {
                            roundPromptView(question: question)
                            Text("Round \(currentRound) of 3")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding()

                        // Invitation to guess (on-screen only, no audio)
                        if optionsWalkIndex == nil && !isProcessingAnswer {
                            Text("Which one is it?")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                        }

                        // Bottom: 3 material options (walk then tap). Use dino-matrix-material-{stone} only so the choices are stones, not dinosaurs.
                        HStack(spacing: 10) {
                            ForEach(Array(question.options.enumerated()), id: \.element.id) { index, material in
                                MatrixMaterialOptionCard(
                                    material: material,
                                    isSelected: selectedMaterial?.id == material.id,
                                    isDisabled: isProcessingAnswer || isAudioPlaying || optionsWalkIndex != nil,
                                    isHighlighted: optionsWalkIndex == index,
                                    isOptionsWalkInProgress: optionsWalkIndex != nil,
                                    onTap: { handleMaterialTap(material, question: question) }
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .frame(maxWidth: .infinity)
                } else if isGameComplete {
                    dinoMatrixEndSequenceView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .onAppear {
                resetGameState()
                speechManager.onAudioFinished = nil
                speechManager.onAudioFinished = { isAudioPlaying = false }
                // Options walk starts after game-dino-matrix-identify-the-stone finishes (see round prompt onAppear).
            }
            .onChange(of: currentRound) { _, newRound in
                guard newRound >= 2, newRound <= 3, currentQuestion != nil else { return }
                isAudioPlaying = true
                speechManager.speak("game-dino-matrix-identify-the-stone")
                speechManager.onAudioFinished = { startOptionsWalkIfNeeded() }
            }
            .onDisappear {
                speechManager.onAudioFinished = nil
                speechManager.stopCurrentAudio()
                isAudioPlaying = false
            }
            .allowsHitTesting(!isAudioPlaying && !isProcessingAnswer && optionsWalkIndex == nil)
            .opacity((isAudioPlaying || isProcessingAnswer) && optionsWalkIndex == nil ? 0.7 : 1.0)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// Slug used in asset names (e.g. "trex", "velociraptor"). From Dinosaur.imageName "dino-{slug}".
    private func dinosaurAssetSlug(_ dino: Dinosaur) -> String? {
        dino.imageName?.replacingOccurrences(of: "dino-", with: "")
    }

    private func roundPromptView(question: DinoMatrixRound) -> some View {
        Group {
            if let dino = question.dinosaur {
                let correctMaterial = gameConfig.allMaterials.first { $0.id == question.correctMaterialId }
                let compositeName = correctMaterial.flatMap { mat in
                    dinosaurAssetSlug(dino).map { mat.fossilMatrixImageAssetName(dinosaurSlug: $0) }
                }
                VStack(spacing: 8) {
                    if let name = compositeName, UIImage(named: name) != nil {
                        Image(name)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 180, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else if let imageName = dino.imageName, UIImage(named: imageName) != nil {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 180, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text(dino.icon)
                            .font(.system(size: 100))
                    }
                }
                .id(question.id)
                .onAppear {
                    isAudioPlaying = true
                    speechManager.speak("game-dino-matrix-identify-the-stone")
                    speechManager.onAudioFinished = { startOptionsWalkIfNeeded() }
                }
            } else {
                matrixPromptView
            }
        }
    }

    private var matrixPromptView: some View {
        Group {
            if UIImage(named: "matrix-fossil") != nil {
                Image("matrix-fossil")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brown.opacity(0.35))
                    .frame(width: 220, height: 220)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("Fossil in matrix")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
        .onAppear {
            isAudioPlaying = true
            speechManager.speak("game-dino-matrix-identify-the-stone")
            speechManager.onAudioFinished = { startOptionsWalkIfNeeded() }
        }
    }

    private func startOptionsWalkIfNeeded() {
        guard let question = currentQuestion, !question.options.isEmpty, optionsWalkIndex == nil else {
            isAudioPlaying = false
            return
        }
        optionsWalkIndex = 0
        isAudioPlaying = true
        speechManager.onAudioFinished = { advanceOptionsWalk() }
        speechManager.speak(question.options[0].name)
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
            // Walk finished: show invitation on screen only (no audio)
            optionsWalkIndex = nil
            isAudioPlaying = false
            return
        }
        optionsWalkIndex = next
        speechManager.onAudioFinished = { advanceOptionsWalk() }
        speechManager.speak(question.options[next].name)
    }

    private func handleMaterialTap(_ material: MatrixMaterial, question: DinoMatrixRound) {
        guard !isProcessingAnswer && !isAudioPlaying && optionsWalkIndex == nil else { return }
        selectedMaterial = material
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.checkAnswer(material: material, question: question)
        }
        speechManager.speak(material.name)
    }

    private func checkAnswer(material: MatrixMaterial, question: DinoMatrixRound) {
        isProcessingAnswer = true
        let isCorrect = material.id == question.correctMaterialId

        if isCorrect {
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                DispatchQueue.main.async {
                    self.selectedMaterial = nil
                    if self.currentRound < 3 {
                        self.currentRound += 1
                        self.isProcessingAnswer = false
                        self.isAudioPlaying = false
                    } else {
                        self.isGameComplete = true
                    }
                }
            }
            if let url = speechManager.urlForAudio(key: "congratulations") {
                speechManager.playAudioFile(url: url)
            } else {
                speechManager.speak("congratulations")
            }
        } else {
            speechManager.speak("try-again")
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                DispatchQueue.main.async {
                    self.isAudioPlaying = false
                    self.selectedMaterial = nil
                    self.isProcessingAnswer = false
                }
            }
        }
    }

    // MARK: - End sequence

    private var dinoMatrixEndSequenceView: some View {
        VictorySplitColumnView(
            listScrollHeight: StandardVictoryLayout.recapListScrollHeight(itemCount: endSequenceMaterials.count),
            showSuccessPhase: endSequenceStep == 2,
            endHighlightIndex: endHighlightIndex,
            gameTitle: gameConfig.title,
            scrollRows: {
                ForEach(Array(endRecapRows.enumerated()), id: \.offset) { index, row in
                    let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                    StandardVictoryRecapRowView(
                        item: VictoryRecapDisplayItem(
                            id: "\(row.material.id)-\(row.round.id)",
                            title: row.material.name,
                            imageAssetName: matrixRecapThumbnailAssetName(round: row.round, material: row.material),
                            fallbackEmoji: "🪨"
                        ),
                        isHighlighted: isHighlighted
                    )
                    .id(index)
                }
            },
            successPhase: {
                LandGameVictorySuccessStingerThenContinue(
                    gameConfigId: gameConfig.id,
                    speechManager: speechManager,
                    onContinue: playGoodJobAndCrowdThenDismiss
                )
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            if endSequenceMaterials.isEmpty {
                endSequenceStep = 2
            } else {
                speechManager.speak(endSequenceMaterials[0].name)
                speechManager.onAudioFinished = { advanceEndHighlight() }
            }
        }
    }

    private func advanceEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < endSequenceMaterials.count {
            speechManager.speak(endSequenceMaterials[endHighlightIndex].name)
            speechManager.onAudioFinished = { advanceEndHighlight() }
        } else {
            endSequenceStep = 2
        }
    }

    private func playGoodJobAndCrowdThenDismiss() {
        recordCompletedMatrixPairsForVariety()
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

    /// Persist the three featured (dino, material) pairs after a full successful run.
    private func recordCompletedMatrixPairsForVariety() {
        var keys: Set<String> = []
        for round in gameConfig.rounds {
            guard let dino = round.dinosaur,
                  let mat = gameConfig.allMaterials.first(where: { $0.id == round.correctMaterialId }),
                  let slug = dinosaurAssetSlug(dino) else { continue }
            keys.insert(DinoMatrixProgress.pairKey(materialSlug: mat.materialSlug, dinosaurSlug: slug))
        }
        DinoMatrixProgress.markPairsPlayed(keys)
    }
}

// MARK: - Material Option Card

struct MatrixMaterialOptionCard: View {
    let material: MatrixMaterial
    let isSelected: Bool
    let isDisabled: Bool
    var isHighlighted: Bool = false
    /// True when the three options are being walked (audio intro); keep cards bright but taps still disabled.
    var isOptionsWalkInProgress: Bool = false
    let onTap: () -> Void

    private var showHighlight: Bool { isSelected || isHighlighted }

    /// Use `dino-matrix-material-{stone}` so the three choices show stones, not dinosaur composites.
    private var resolvedImageName: String? {
        let name = material.matrixRockImageAssetName
        guard UIImage(named: name) != nil else { return nil }
        return name
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                if let imageName = resolvedImageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.brown.opacity(0.35))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Text(material.name.prefix(1))
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        )
                }
                if showHighlight {
                    Text(material.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: showHighlight ? 110 : 95, height: showHighlight ? 140 : 115)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(showHighlight ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(showHighlight ? Color.blue : Color.clear, lineWidth: 3)
            )
            .opacity(isDisabled ? (isOptionsWalkInProgress ? 0.9 : 0.5) : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

// MARK: - Dinosaur → Matrix Material Map

/// Typical matrix material(s) that this dinosaur's fossils are found in (formation-based).
/// Some dinosaurs are associated with more than one stone (different formations); this map
/// picks one correct material per round. Image sets `dino-matrix-{stone}-{dinosaur}` may exist for
/// multiple stones per dinosaur.
/// Matrix material ids: 1 Limestone, 2 Mudstone, 3 Bentonite, 4 Sandstone, 5 Siltstone, 6 Tuff, 7 Amber, 8 Shale, 9 Ironstone, 10 Claystone, 11 Lignite, 12 Phosphorite, 13 Conglomerate.
private let dinosaurMatrixMap: [Int: Int] = [
    1: 4,   // T-Rex: Hell Creek → Sandstone
    2: 4,   // Triceratops: Hell Creek → Sandstone
    3: 4,   // Stegosaurus: Morrison → Sandstone
    4: 4,   // Velociraptor: Djadochta → Sandstone
    5: 2,   // Therizinosaurus: Nemegt → Mudstone
    6: 4,   // Spinosaurus: North Africa → Sandstone
    7: 4,   // Apatosaurus: Morrison → Sandstone
    8: 8,   // Ankylosaurus: Hell Creek → Shale
    9: 4,   // Corythosaurus: Dinosaur Park → Sandstone
    10: 2,  // Parasaurolophus: Dinosaur Park / mudstone
    11: 4,  // Iguanodon: Wealden → Sandstone
    12: 8,  // Troodon: Hell Creek → Shale
    13: 2,  // Edmontosaurus: Hell Creek → Mudstone
]

// MARK: - Game Configuration

struct DinoMatrixGameConfigs {
    private static let allMaterials: [MatrixMaterial] = [
        MatrixMaterial(id: 1, name: "Limestone"),
        MatrixMaterial(id: 2, name: "Mudstone"),
        MatrixMaterial(id: 3, name: "Bentonite"),
        MatrixMaterial(id: 4, name: "Sandstone"),
        MatrixMaterial(id: 5, name: "Siltstone"),
        MatrixMaterial(id: 6, name: "Tuff"),
        MatrixMaterial(id: 7, name: "Amber"),
        MatrixMaterial(id: 8, name: "Shale"),
        MatrixMaterial(id: 9, name: "Ironstone"),
        MatrixMaterial(id: 10, name: "Claystone"),
        MatrixMaterial(id: 11, name: "Lignite"),
        MatrixMaterial(id: 12, name: "Phosphorite"),
        MatrixMaterial(id: 13, name: "Conglomerate"),
    ]

    /// Dinosaur slug for asset names (e.g. "trex", "velociraptor").
    private static func dinosaurAssetSlug(_ dino: Dinosaur) -> String? {
        dino.imageName?.replacingOccurrences(of: "dino-", with: "")
    }

    /// Materials that have an existing `dino-matrix-{stone}-{dinosaur}` image set for this dinosaur.
    private static func materialsWithImageSet(for dino: Dinosaur) -> [MatrixMaterial] {
        guard let slug = dinosaurAssetSlug(dino) else { return [] }
        return allMaterials.filter { mat in
            UIImage(named: mat.fossilMatrixImageAssetName(dinosaurSlug: slug)) != nil
        }
    }

    /// All (dinosaur, material) pairs that have a `dino-matrix-{stone}-{dinosaur}` image set.
    private static var roundCandidates: [(Dinosaur, MatrixMaterial)] {
        let landDinosaurs = MatchingGameConfigs.allDinosaurs.filter { $0.id <= 99 }
        var pairs: [(Dinosaur, MatrixMaterial)] = []
        for dino in landDinosaurs {
            for material in materialsWithImageSet(for: dino) {
                pairs.append((dino, material))
            }
        }
        return pairs
    }

    private static func pairKey(dino: Dinosaur, material: MatrixMaterial) -> String? {
        guard let slug = dinosaurAssetSlug(dino) else { return nil }
        return DinoMatrixProgress.pairKey(materialSlug: material.materialSlug, dinosaurSlug: slug)
    }

    /// Picks three pairs whose correct materials are all different (one per round).
    private static func selectFeaturedPairs(from candidates: [(Dinosaur, MatrixMaterial)]) -> [(Dinosaur, MatrixMaterial)] {
        var usedMaterialIds: Set<Int> = []
        var selected: [(Dinosaur, MatrixMaterial)] = []
        for pair in candidates {
            guard selected.count < 3 else { break }
            if !usedMaterialIds.contains(pair.1.id) {
                usedMaterialIds.insert(pair.1.id)
                selected.append(pair)
            }
        }
        return selected
    }

    static var dinoMatrix: DinoMatrixGameConfig {
        let pool = allMaterials
        let allCandidates = roundCandidates
        let playedPairKeys = DinoMatrixProgress.loadPlayedPairKeys()
        let unusedCandidates = allCandidates.filter { pair in
            guard let key = pairKey(dino: pair.0, material: pair.1) else { return false }
            return !playedPairKeys.contains(key)
        }

        var selected = selectFeaturedPairs(from: unusedCandidates.shuffled())
        if selected.count < 3 {
            DinoMatrixProgress.clearPlayedPairKeys()
            selected = selectFeaturedPairs(from: allCandidates.shuffled())
        }
        guard selected.count == 3 else {
            fatalError("Dino Matrix: need at least 3 distinct stones with dino-matrix-{stone}-{dinosaur} image sets (found \(selected.count) distinct)")
        }

        var rounds: [DinoMatrixRound] = []
        var usedMaterialIdsAcrossRounds: Set<Int> = []
        for (idx, (dino, correct)) in selected.enumerated() {
            // One option must match the dinosaur image (`dino-matrix-{stone}-{dinosaur}`); the other two are decoys.
            let availableForDecoys = pool.filter { $0.id != correct.id && !usedMaterialIdsAcrossRounds.contains($0.id) }
            let decoys: [MatrixMaterial] = Array(availableForDecoys.shuffled().prefix(2))
            let decoysFinal: [MatrixMaterial]
            if decoys.count == 2 {
                decoysFinal = decoys
            } else {
                // Fallback: allow reuse if we don't have enough unused materials
                decoysFinal = Array(pool.filter { $0.id != correct.id }.shuffled().prefix(2))
            }
            var options = [correct] + decoysFinal
            options.shuffle()
            usedMaterialIdsAcrossRounds.formUnion(options.map(\.id))
            rounds.append(DinoMatrixRound(
                id: idx + 1,
                dinosaur: dino,
                correctMaterialId: correct.id,
                options: options
            ))
        }

        return DinoMatrixGameConfig(
            id: "dino-matrix",
            title: "Dino Matrix!",
            introAudio: "game-dino-matrix",
            rounds: rounds,
            allMaterials: pool
        )
    }
}

#Preview {
    DinoMatrixGameView(isPresented: .constant(true), gameConfig: DinoMatrixGameConfigs.dinoMatrix)
}
