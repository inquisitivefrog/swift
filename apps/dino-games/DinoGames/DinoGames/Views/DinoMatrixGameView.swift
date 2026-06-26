//
//  DinoMatrixGameView.swift
//  DinoGames
//
//  Dino Matrix: Help the paleontologist identify the matrix material encasing the fossil.
//  Materials: limestone, mudstone, sandstone, siltstone, tuff, shale, ironstone, claystone, lignite, conglomerate.
//  (Bentonite, amber, phosphorite reserved for Ptero Matrix / Marine Matrix.)
//

import SwiftUI
import AVFoundation

// MARK: - Data Models

struct MatrixMaterial: Identifiable {
    let id: Int
    let name: String
    /// Slug for fossil composites and audio (e.g. "limestone", "tuff").
    var materialSlug: String { name.lowercased().replacingOccurrences(of: " ", with: "-") }

    /// Rock option card: `{prefix}-material-{segment}`.
    func matrixRockImageAssetName(assetPrefix: String, tuffRockUsesVolcanicPrefix: Bool) -> String {
        "\(assetPrefix)-material-\(rockSegment(tuffRockUsesVolcanicPrefix: tuffRockUsesVolcanicPrefix))"
    }

    /// Fossil in matrix: `{prefix}-{segment}-{creature}`.
    func fossilMatrixImageAssetName(
        creatureSlug: String,
        assetPrefix: String,
        tuffFossilUsesVolcanicPrefix: Bool
    ) -> String {
        "\(assetPrefix)-\(fossilSegment(tuffFossilUsesVolcanicPrefix: tuffFossilUsesVolcanicPrefix))-\(creatureSlug)"
    }

    func rockSegment(tuffRockUsesVolcanicPrefix: Bool) -> String {
        materialSlug == "tuff" && tuffRockUsesVolcanicPrefix ? "volcanic-tuff" : materialSlug
    }

    func fossilSegment(tuffFossilUsesVolcanicPrefix: Bool) -> String {
        materialSlug == "tuff" && tuffFossilUsesVolcanicPrefix ? "volcanic-tuff" : materialSlug
    }

    /// Bundle audio key for matrix stone narration (e.g. `dino-limestone`, `ptero-chalk`).
    func audioKey(for progressKind: MatrixGameProgressKind) -> String {
        let prefix: String
        switch progressKind {
        case .dino: prefix = "dino"
        case .ptero: prefix = "ptero"
        case .marine: prefix = "marine"
        }
        return "\(prefix)-\(materialSlug)"
    }
}

enum MatrixGameProgressKind {
    case dino
    case ptero
    case marine
}

struct MatrixSourceHint: Identifiable {
    let id: String
    let imageName: String
    let displayName: String
    let audioKey: String
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
    let identifyStoneAudioKey: String
    let rounds: [DinoMatrixRound]
    let allMaterials: [MatrixMaterial]
    let assetPrefix: String
    let fossilCreatureSlug: (Dinosaur) -> String?
    let tuffRockUsesVolcanicPrefix: Bool
    let tuffFossilUsesVolcanicPrefix: Bool
    let progressKind: MatrixGameProgressKind
    let sourceHints: [MatrixSourceHint]
    let sourceHintsTitle: String
    /// Spoken once when the Source Matrix hints grid opens (e.g. `game-dino-matrix-tap-the-image`).
    let sourceHintsGridIntroAudioKey: String?

    init(
        id: String,
        title: String,
        introAudio: String,
        identifyStoneAudioKey: String,
        rounds: [DinoMatrixRound],
        allMaterials: [MatrixMaterial],
        assetPrefix: String,
        fossilCreatureSlug: @escaping (Dinosaur) -> String?,
        tuffRockUsesVolcanicPrefix: Bool,
        tuffFossilUsesVolcanicPrefix: Bool,
        progressKind: MatrixGameProgressKind,
        sourceHints: [MatrixSourceHint],
        sourceHintsTitle: String,
        sourceHintsGridIntroAudioKey: String? = nil
    ) {
        self.id = id
        self.title = title
        self.introAudio = introAudio
        self.identifyStoneAudioKey = identifyStoneAudioKey
        self.rounds = rounds
        self.allMaterials = allMaterials
        self.assetPrefix = assetPrefix
        self.fossilCreatureSlug = fossilCreatureSlug
        self.tuffRockUsesVolcanicPrefix = tuffRockUsesVolcanicPrefix
        self.tuffFossilUsesVolcanicPrefix = tuffFossilUsesVolcanicPrefix
        self.progressKind = progressKind
        self.sourceHints = sourceHints
        self.sourceHintsTitle = sourceHintsTitle
        self.sourceHintsGridIntroAudioKey = sourceHintsGridIntroAudioKey
    }
}

// MARK: - Main View

private enum DinoMatrixLayout {
    /// Fossil-in-matrix prompt image (detailed art — use available width above option cards).
    static let fossilImageMaxWidth: CGFloat = 300
    static let fossilImageMaxHeight: CGFloat = 260
}

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
    @State private var showSourceMatrixHints = false

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

    /// Victory recap shows rock matrix art (`{prefix}-material-{stone}`), not fossil composites.
    private func matrixRecapThumbnailAssetName(round: DinoMatrixRound, material: MatrixMaterial) -> String? {
        _ = round
        let name = material.matrixRockImageAssetName(
            assetPrefix: gameConfig.assetPrefix,
            tuffRockUsesVolcanicPrefix: gameConfig.tuffRockUsesVolcanicPrefix
        )
        guard ImageAssetCache.imageExists(named: name) else { return nil }
        return name
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
                    VStack(spacing: 20) {
                        // Top: Dinosaur (when round has one) or generic fossil prompt + round label
                        VStack(spacing: 10) {
                            roundPromptView(question: question)
                            Text("Round \(currentRound) of 3")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        // Bottom: 3 material options (walk then tap). Use dino-matrix-material-{stone} only so the choices are stones, not dinosaurs.
                        HStack(spacing: 10) {
                            ForEach(Array(question.options.enumerated()), id: \.element.id) { index, material in
                                MatrixMaterialOptionCard(
                                    material: material,
                                    assetPrefix: gameConfig.assetPrefix,
                                    tuffRockUsesVolcanicPrefix: gameConfig.tuffRockUsesVolcanicPrefix,
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
                speechManager.speak(gameConfig.identifyStoneAudioKey)
                speechManager.onAudioFinished = { playHintReminderThenStartOptionsWalk() }
            }
            .onDisappear {
                speechManager.onAudioFinished = nil
                speechManager.stopCurrentAudio()
                isAudioPlaying = false
            }
            .allowsHitTesting(!isAudioPlaying && !isProcessingAnswer && optionsWalkIndex == nil)
            .gameSheetDismissDisabledWhileAudioPlaying(isAudioPlaying || isProcessingAnswer || optionsWalkIndex != nil)
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .topTrailing) {
                if !isGameComplete, !gameConfig.sourceHints.isEmpty {
                    Button {
                        showSourceMatrixHints = true
                    } label: {
                        Text("Hints")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Circle().fill(Color.blue))
                            .frame(width: 72, height: 72)
                    }
                    .disabled(isAudioPlaying || isProcessingAnswer || optionsWalkIndex != nil)
                    .opacity((isAudioPlaying || isProcessingAnswer || optionsWalkIndex != nil) ? 0.45 : 1.0)
                    .padding(.top, 8)
                    .padding(.trailing, 16)
                }
            }
            .fullScreenCover(isPresented: $showSourceMatrixHints) {
                SourceMatrixHintsView(
                    hints: gameConfig.sourceHints,
                    title: gameConfig.sourceHintsTitle,
                    hintGridIntroAudioKey: gameConfig.sourceHintsGridIntroAudioKey,
                    onDismiss: { showSourceMatrixHints = false }
                )
            }
        }
    }

    /// Slug used in fossil composite asset names (e.g. "trex", "mosasaurus").
    private func creatureAssetSlug(_ creature: Dinosaur) -> String? {
        gameConfig.fossilCreatureSlug(creature)
    }

    private func roundPromptView(question: DinoMatrixRound) -> some View {
        Group {
            if let dino = question.dinosaur {
                let correctMaterial = gameConfig.allMaterials.first { $0.id == question.correctMaterialId }
                let compositeName = correctMaterial.flatMap { mat in
                    creatureAssetSlug(dino).map {
                        mat.fossilMatrixImageAssetName(
                            creatureSlug: $0,
                            assetPrefix: gameConfig.assetPrefix,
                            tuffFossilUsesVolcanicPrefix: gameConfig.tuffFossilUsesVolcanicPrefix
                        )
                    }
                }
                VStack(spacing: 8) {
                    if let name = compositeName, UIImage(named: name) != nil {
                        Image(name)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(
                                maxWidth: DinoMatrixLayout.fossilImageMaxWidth,
                                maxHeight: DinoMatrixLayout.fossilImageMaxHeight
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else if let imageName = dino.imageName, UIImage(named: imageName) != nil {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(
                                maxWidth: DinoMatrixLayout.fossilImageMaxWidth,
                                maxHeight: DinoMatrixLayout.fossilImageMaxHeight
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text(dino.icon)
                            .font(.system(size: 100))
                    }
                }
                .id(question.id)
                .onAppear {
                    isAudioPlaying = true
                    speechManager.speak(gameConfig.identifyStoneAudioKey)
                    speechManager.onAudioFinished = { playHintReminderThenStartOptionsWalk() }
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
            speechManager.speak(gameConfig.identifyStoneAudioKey)
            speechManager.onAudioFinished = { playHintReminderThenStartOptionsWalk() }
        }
    }

    /// After “identify the stone”: point to the Hints circle (`game-hint`), then walk matrix options.
    private func playHintReminderThenStartOptionsWalk() {
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
        guard let question = currentQuestion, !question.options.isEmpty, optionsWalkIndex == nil else {
            isAudioPlaying = false
            return
        }
        optionsWalkIndex = 0
        isAudioPlaying = true
        speechManager.onAudioFinished = { advanceOptionsWalk() }
        speechManager.speak(question.options[0].audioKey(for: gameConfig.progressKind))
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
        speechManager.speak(question.options[next].audioKey(for: gameConfig.progressKind))
    }

    private func handleMaterialTap(_ material: MatrixMaterial, question: DinoMatrixRound) {
        guard !isProcessingAnswer && !isAudioPlaying && optionsWalkIndex == nil else { return }
        selectedMaterial = material
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.checkAnswer(material: material, question: question)
        }
        speechManager.speak(material.audioKey(for: gameConfig.progressKind))
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

    private var matrixVictorySuccessImageSide: CGFloat {
        GameCatalogImageMetrics.nameThatVictorySuccessImageSide
    }

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
                    imageSide: matrixVictorySuccessImageSide,
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
                speechManager.speak(endSequenceMaterials[0].audioKey(for: gameConfig.progressKind))
                speechManager.onAudioFinished = { advanceEndHighlight() }
            }
        }
    }

    private func advanceEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < endSequenceMaterials.count {
            speechManager.speak(endSequenceMaterials[endHighlightIndex].audioKey(for: gameConfig.progressKind))
            speechManager.onAudioFinished = { advanceEndHighlight() }
        } else {
            endSequenceStep = 2
        }
    }

    private func playGoodJobAndCrowdThenDismiss() {
        StandardVictorySequence.dismissAfterVictory(
            configId: gameConfig.id,
            isPresented: $isPresented,
            speechManager: speechManager,
            beforeDismiss: { recordCompletedMatrixPairsForVariety() }
        )
    }

    /// Persist the three featured (dino, material) pairs after a full successful run.
    private func recordCompletedMatrixPairsForVariety() {
        var keys: Set<String> = []
        for round in gameConfig.rounds {
            guard let dino = round.dinosaur,
                  let mat = gameConfig.allMaterials.first(where: { $0.id == round.correctMaterialId }),
                  let slug = creatureAssetSlug(dino) else { continue }
            let key = pairProgressKey(materialSlug: mat.materialSlug, creatureSlug: slug)
            keys.insert(key)
        }
        switch gameConfig.progressKind {
        case .dino: DinoMatrixProgress.markPairsPlayed(keys)
        case .ptero: PteroMatrixProgress.markPairsPlayed(keys)
        case .marine: MarineMatrixProgress.markPairsPlayed(keys)
        }
    }

    private func pairProgressKey(materialSlug: String, creatureSlug: String) -> String {
        switch gameConfig.progressKind {
        case .dino:
            return DinoMatrixProgress.pairKey(materialSlug: materialSlug, dinosaurSlug: creatureSlug)
        case .ptero:
            return PteroMatrixProgress.pairKey(materialSlug: materialSlug, pterosaurSlug: creatureSlug)
        case .marine:
            return MarineMatrixProgress.pairKey(materialSlug: materialSlug, marineReptileSlug: creatureSlug)
        }
    }
}

// MARK: - Material Option Card

private enum MatrixMaterialOptionCardLayout {
    static let width: CGFloat = 100
    static let height: CGFloat = 128
    static let imageSide: CGFloat = 70
    /// Fixed label slot so longer names (e.g. volcanic tuff) never resize the stone thumbnails.
    static let labelHeight: CGFloat = 34
}

struct MatrixMaterialOptionCard: View {
    let material: MatrixMaterial
    let assetPrefix: String
    let tuffRockUsesVolcanicPrefix: Bool
    let isSelected: Bool
    let isDisabled: Bool
    var isHighlighted: Bool = false
    /// True when the three options are being walked (audio intro); keep cards bright but taps still disabled.
    var isOptionsWalkInProgress: Bool = false
    let onTap: () -> Void

    private var showHighlight: Bool { isSelected || isHighlighted }

    /// Dim only non-highlighted cards during the options audio walk — not when answering.
    private var dimsForOptionsWalk: Bool {
        isOptionsWalkInProgress && !showHighlight
    }

    /// Display name for the label (Tuff uses “Volcanic Tuff” when rock art uses the volcanic-tuff segment).
    private var displayName: String {
        if material.materialSlug == "tuff", tuffRockUsesVolcanicPrefix {
            return "Volcanic Tuff"
        }
        return material.name
    }

    private var resolvedImageName: String? {
        let name = material.matrixRockImageAssetName(
            assetPrefix: assetPrefix,
            tuffRockUsesVolcanicPrefix: tuffRockUsesVolcanicPrefix
        )
        guard UIImage(named: name) != nil else { return nil }
        return name
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if let imageName = resolvedImageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: MatrixMaterialOptionCardLayout.imageSide,
                            height: MatrixMaterialOptionCardLayout.imageSide
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.brown.opacity(0.35))
                        .frame(
                            width: MatrixMaterialOptionCardLayout.imageSide,
                            height: MatrixMaterialOptionCardLayout.imageSide
                        )
                        .overlay(
                            Text(material.name.prefix(1))
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        )
                }
                Text(displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .multilineTextAlignment(.center)
                    .frame(height: MatrixMaterialOptionCardLayout.labelHeight)
                    .opacity(showHighlight ? 1 : 0)
                    .accessibilityHidden(!showHighlight)
            }
            .frame(
                width: MatrixMaterialOptionCardLayout.width,
                height: MatrixMaterialOptionCardLayout.height
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(showHighlight ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(showHighlight ? Color.blue : Color.clear, lineWidth: 3)
            )
            .opacity(dimsForOptionsWalk ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .animation(.none, value: showHighlight)
        .animation(.none, value: isSelected)
    }
}

// MARK: - Dinosaur → Matrix Material Map

/// Typical matrix material(s) that this dinosaur's fossils are found in (formation-based).
/// Some dinosaurs are associated with more than one stone (different formations); this map
/// picks one correct material per round. Image sets `dino-matrix-{stone}-{dinosaur}` may exist for
/// multiple stones per dinosaur.
/// Matrix material ids: 1 Limestone, 2 Mudstone, 3 Sandstone, 4 Siltstone, 5 Tuff, 6 Shale, 7 Ironstone, 8 Claystone, 9 Lignite, 10 Conglomerate.
private let dinosaurMatrixMap: [Int: Int] = [
    1: 3,   // T-Rex: Hell Creek → Sandstone
    2: 3,   // Triceratops: Hell Creek → Sandstone
    3: 3,   // Stegosaurus: Morrison → Sandstone
    4: 3,   // Velociraptor: Djadochta → Sandstone
    5: 2,   // Therizinosaurus: Nemegt → Mudstone
    6: 3,   // Spinosaurus: North Africa → Sandstone
    7: 3,   // Apatosaurus: Morrison → Sandstone
    8: 6,   // Ankylosaurus: Hell Creek → Shale
    9: 3,   // Corythosaurus: Dinosaur Park → Sandstone
    10: 2,  // Parasaurolophus: Dinosaur Park / mudstone
    11: 3,  // Iguanodon: Wealden → Sandstone
    12: 6,  // Troodon: Hell Creek → Shale
    13: 2,  // Edmontosaurus: Hell Creek → Mudstone
]

// MARK: - Game Configuration

struct DinoMatrixGameConfigs {
    private static let allMaterials: [MatrixMaterial] = [
        MatrixMaterial(id: 1, name: "Limestone"),
        MatrixMaterial(id: 2, name: "Mudstone"),
        MatrixMaterial(id: 3, name: "Sandstone"),
        MatrixMaterial(id: 4, name: "Siltstone"),
        MatrixMaterial(id: 5, name: "Tuff"),
        MatrixMaterial(id: 6, name: "Shale"),
        MatrixMaterial(id: 7, name: "Ironstone"),
        MatrixMaterial(id: 8, name: "Claystone"),
        MatrixMaterial(id: 9, name: "Lignite"),
        MatrixMaterial(id: 10, name: "Conglomerate"),
    ]

    private static let dinoSourceHints: [MatrixSourceHint] = [
        MatrixSourceHint(id: "materials", imageName: "source-dino-matrix-materials", displayName: "Materials", audioKey: "game-dino-matrix-material"),
        MatrixSourceHint(id: "color", imageName: "source-dino-matrix-color", displayName: "Color", audioKey: "game-dino-matrix-color"),
    ]

    private static func fossilSlugFromImagePrefix(_ prefix: String) -> (Dinosaur) -> String? {
        { creature in
            guard let slug = creature.imageName?.replacingOccurrences(of: prefix, with: ""), !slug.isEmpty else { return nil }
            return slug
        }
    }

    /// Materials that have an existing fossil composite image set for this creature.
    private static func materialsWithImageSet(
        for creature: Dinosaur,
        pool: [MatrixMaterial],
        assetPrefix: String,
        fossilCreatureSlug: (Dinosaur) -> String?,
        tuffFossilUsesVolcanicPrefix: Bool
    ) -> [MatrixMaterial] {
        guard let slug = fossilCreatureSlug(creature) else { return [] }
        return pool.filter { mat in
            let name = mat.fossilMatrixImageAssetName(
                creatureSlug: slug,
                assetPrefix: assetPrefix,
                tuffFossilUsesVolcanicPrefix: tuffFossilUsesVolcanicPrefix
            )
            return UIImage(named: name) != nil
        }
    }

    /// All (creature, material) pairs that have a bundled fossil-in-matrix image set.
    private static func roundCandidates(
        creatures: [Dinosaur],
        pool: [MatrixMaterial],
        assetPrefix: String,
        fossilCreatureSlug: (Dinosaur) -> String?,
        tuffFossilUsesVolcanicPrefix: Bool
    ) -> [(Dinosaur, MatrixMaterial)] {
        var pairs: [(Dinosaur, MatrixMaterial)] = []
        for creature in creatures {
            for material in materialsWithImageSet(
                for: creature,
                pool: pool,
                assetPrefix: assetPrefix,
                fossilCreatureSlug: fossilCreatureSlug,
                tuffFossilUsesVolcanicPrefix: tuffFossilUsesVolcanicPrefix
            ) {
                pairs.append((creature, material))
            }
        }
        return pairs
    }

    private static func pairKey(
        creature: Dinosaur,
        material: MatrixMaterial,
        fossilCreatureSlug: (Dinosaur) -> String?,
        progressKind: MatrixGameProgressKind
    ) -> String? {
        guard let slug = fossilCreatureSlug(creature) else { return nil }
        switch progressKind {
        case .dino:
            return DinoMatrixProgress.pairKey(materialSlug: material.materialSlug, dinosaurSlug: slug)
        case .ptero:
            return PteroMatrixProgress.pairKey(materialSlug: material.materialSlug, pterosaurSlug: slug)
        case .marine:
            return MarineMatrixProgress.pairKey(materialSlug: material.materialSlug, marineReptileSlug: slug)
        }
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
        guard let config = buildConfig(
            id: "dino-matrix",
            title: "Dino Matrix!",
            introAudio: "game-dino-matrix",
            identifyStoneAudioKey: "game-dino-matrix-identify-the-stone",
            pool: allMaterials,
            creatures: MatchingGameConfigs.allDinosaurs.filter { $0.id <= 99 },
            assetPrefix: "dino-matrix",
            fossilCreatureSlug: fossilSlugFromImagePrefix("dino-"),
            tuffRockUsesVolcanicPrefix: true,
            tuffFossilUsesVolcanicPrefix: false,
            progressKind: .dino,
            sourceHints: dinoSourceHints,
            sourceHintsTitle: "Source Matrix",
            sourceHintsGridIntroAudioKey: "game-dino-matrix-tap-the-image",
            fatalLabel: "Dino Matrix"
        ) else {
            fatalError("Dino Matrix: need at least 3 distinct stones with dino-matrix-{stone}-{creature} image sets")
        }
        return config
    }

    static func buildConfig(
        id: String,
        title: String,
        introAudio: String,
        identifyStoneAudioKey: String,
        pool: [MatrixMaterial],
        creatures: [Dinosaur],
        assetPrefix: String,
        fossilCreatureSlug: @escaping (Dinosaur) -> String?,
        tuffRockUsesVolcanicPrefix: Bool,
        tuffFossilUsesVolcanicPrefix: Bool,
        progressKind: MatrixGameProgressKind,
        sourceHints: [MatrixSourceHint],
        sourceHintsTitle: String,
        sourceHintsGridIntroAudioKey: String? = nil,
        fatalLabel: String
    ) -> DinoMatrixGameConfig? {
        let allCandidates = roundCandidates(
            creatures: creatures,
            pool: pool,
            assetPrefix: assetPrefix,
            fossilCreatureSlug: fossilCreatureSlug,
            tuffFossilUsesVolcanicPrefix: tuffFossilUsesVolcanicPrefix
        )
        let playedPairKeys: Set<String> = {
            switch progressKind {
            case .dino: return DinoMatrixProgress.loadPlayedPairKeys()
            case .ptero: return PteroMatrixProgress.loadPlayedPairKeys()
            case .marine: return MarineMatrixProgress.loadPlayedPairKeys()
            }
        }()
        let unusedCandidates = allCandidates.filter { pair in
            guard let key = pairKey(creature: pair.0, material: pair.1, fossilCreatureSlug: fossilCreatureSlug, progressKind: progressKind) else { return false }
            return !playedPairKeys.contains(key)
        }

        var selected = selectFeaturedPairs(from: unusedCandidates.shuffled())
        if selected.count < 3 {
            switch progressKind {
            case .dino: DinoMatrixProgress.clearPlayedPairKeys()
            case .ptero: PteroMatrixProgress.clearPlayedPairKeys()
            case .marine: MarineMatrixProgress.clearPlayedPairKeys()
            }
            selected = selectFeaturedPairs(from: allCandidates.shuffled())
        }
        guard selected.count == 3 else {
            return nil
        }

        var rounds: [DinoMatrixRound] = []
        var usedMaterialIdsAcrossRounds: Set<Int> = []
        for (idx, (creature, correct)) in selected.enumerated() {
            let availableForDecoys = pool.filter { $0.id != correct.id && !usedMaterialIdsAcrossRounds.contains($0.id) }
            let decoys: [MatrixMaterial] = Array(availableForDecoys.shuffled().prefix(2))
            let decoysFinal: [MatrixMaterial]
            if decoys.count == 2 {
                decoysFinal = decoys
            } else {
                decoysFinal = Array(pool.filter { $0.id != correct.id }.shuffled().prefix(2))
            }
            var options = [correct] + decoysFinal
            options.shuffle()
            usedMaterialIdsAcrossRounds.formUnion(options.map(\.id))
            rounds.append(DinoMatrixRound(
                id: idx + 1,
                dinosaur: creature,
                correctMaterialId: correct.id,
                options: options
            ))
        }

        return DinoMatrixGameConfig(
            id: id,
            title: title,
            introAudio: introAudio,
            identifyStoneAudioKey: identifyStoneAudioKey,
            rounds: rounds,
            allMaterials: pool,
            assetPrefix: assetPrefix,
            fossilCreatureSlug: fossilCreatureSlug,
            tuffRockUsesVolcanicPrefix: tuffRockUsesVolcanicPrefix,
            tuffFossilUsesVolcanicPrefix: tuffFossilUsesVolcanicPrefix,
            progressKind: progressKind,
            sourceHints: sourceHints,
            sourceHintsTitle: sourceHintsTitle,
            sourceHintsGridIntroAudioKey: sourceHintsGridIntroAudioKey
        )
    }
}

// MARK: - Ptero Matrix Configuration

enum PteroMatrixGameConfigs {
    private static let allMaterials: [MatrixMaterial] = [
        MatrixMaterial(id: 1, name: "Bentonite"),
        MatrixMaterial(id: 2, name: "Chalk"),
        MatrixMaterial(id: 3, name: "Lignite"),
        MatrixMaterial(id: 4, name: "Sandstone"),
        MatrixMaterial(id: 5, name: "Shale"),
        MatrixMaterial(id: 6, name: "Tuff"),
    ]

    private static let pteroSourceHints: [MatrixSourceHint] = [
        MatrixSourceHint(id: "material", imageName: "source-ptero-matrix-material", displayName: "Material", audioKey: "game-ptero-matrix-material"),
        MatrixSourceHint(id: "color", imageName: "source-ptero-matrix-color", displayName: "Color", audioKey: "game-ptero-matrix-color"),
    ]

    static func makePteroMatrix() -> DinoMatrixGameConfig? {
        DinoMatrixGameConfigs.buildConfig(
            id: "ptero-matrix",
            title: "Ptero Matrix!",
            introAudio: "game-ptero-matrix",
            identifyStoneAudioKey: "game-ptero-matrix-identify-the-stone",
            pool: allMaterials,
            creatures: MatchingGameConfigs.allPterosaurs.filter { $0.imageName?.hasPrefix("ptero-") == true },
            assetPrefix: "ptero-matrix",
            fossilCreatureSlug: { AirPterosaurData.matrixFossilSlug(for: $0) },
            tuffRockUsesVolcanicPrefix: false,
            tuffFossilUsesVolcanicPrefix: true,
            progressKind: .ptero,
            sourceHints: pteroSourceHints,
            sourceHintsTitle: "Source Matrix",
            sourceHintsGridIntroAudioKey: "game-ptero-matrix-tap-the-image",
            fatalLabel: "Ptero Matrix"
        )
    }
}

// MARK: - Marine Matrix Configuration

enum MarineMatrixGameConfigs {
    private static let allMaterials: [MatrixMaterial] = [
        MatrixMaterial(id: 1, name: "Chalk"),
        MatrixMaterial(id: 2, name: "Claystone"),
        MatrixMaterial(id: 3, name: "Ironstone"),
        MatrixMaterial(id: 4, name: "Limestone"),
        MatrixMaterial(id: 5, name: "Phosphorite"),
        MatrixMaterial(id: 6, name: "Shale"),
        MatrixMaterial(id: 7, name: "Tuff"),
    ]

    private static let marineSourceHints: [MatrixSourceHint] = [
        MatrixSourceHint(id: "material", imageName: "source-marine-matrix-material", displayName: "Material", audioKey: "game-marine-matrix-material"),
        MatrixSourceHint(id: "color", imageName: "source-marine-matrix-color", displayName: "Color", audioKey: "game-marine-matrix-color"),
    ]

    static func makeMarineMatrix() -> DinoMatrixGameConfig? {
        DinoMatrixGameConfigs.buildConfig(
            id: "marine-matrix",
            title: "Marine Matrix!",
            introAudio: "game-marine-matrix",
            identifyStoneAudioKey: "game-dino-matrix-identify-the-stone",
            pool: allMaterials,
            creatures: SeaMarineReptileData.allMarineReptiles,
            assetPrefix: "marine-matrix",
            fossilCreatureSlug: { SeaMarineReptileData.matrixFossilSlug(for: $0) },
            tuffRockUsesVolcanicPrefix: true,
            tuffFossilUsesVolcanicPrefix: true,
            progressKind: .marine,
            sourceHints: marineSourceHints,
            sourceHintsTitle: "Source Matrix",
            fatalLabel: "Marine Matrix"
        )
    }
}

// MARK: - Source Matrix Hints

struct SourceMatrixHintsView: View {
    let hints: [MatrixSourceHint]
    let title: String
    var hintGridIntroAudioKey: String? = SourceHintsIntroAudioKeys.tapToHearDescription
    let onDismiss: () -> Void
    @StateObject private var speechManager = SpeechManager()
    @State private var selectedHint: MatrixSourceHint?
    @State private var introPlayed = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if selectedHint == nil {
                gridView
            } else {
                detailView
            }

            Button {
                onDismiss()
            } label: {
                Text("<")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
            }
            .disabled(speechManager.isPlaying)
            .opacity(speechManager.isPlaying ? 0.45 : 1.0)
            .padding(.leading, 8)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .allowsHitTesting(!speechManager.isPlaying)
        .opacity(speechManager.isPlaying ? 0.85 : 1.0)
        .onAppear { playIntroOnce() }
    }

    private func playIntroOnce() {
        guard !introPlayed else { return }
        introPlayed = true
        guard let introKey = hintGridIntroAudioKey,
              let url = speechManager.urlForAudio(key: introKey) else { return }
        speechManager.onAudioFinished = nil
        speechManager.playAudioFile(url: url)
    }

    private var gridView: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title2.weight(.semibold))
                .padding(.top, 44)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(hints) { hint in
                    Button {
                        showHintDetail(hint)
                    } label: {
                        if ImageAssetCache.imageExists(named: hint.imageName) {
                            Image(hint.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .clipped()
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 140)
                                .overlay(Text(hint.displayName).font(.title3).foregroundColor(.secondary))
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
        if let hint = selectedHint {
            VStack(spacing: 20) {
                Spacer()
                if ImageAssetCache.imageExists(named: hint.imageName) {
                    Image(hint.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 340, maxHeight: 220)
                }
                Text(hint.displayName)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func showHintDetail(_ hint: MatrixSourceHint) {
        guard !speechManager.isPlaying else { return }
        selectedHint = hint
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            speechManager.onAudioFinished = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                selectedHint = nil
            }
        }
        if let url = speechManager.urlForAudio(key: hint.audioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(hint.displayName)
        }
    }
}

#Preview {
    DinoMatrixGameView(isPresented: .constant(true), gameConfig: DinoMatrixGameConfigs.dinoMatrix)
}
