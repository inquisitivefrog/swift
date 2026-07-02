//
//  StandardVictorySequenceXCTests.swift
//  DinoGamesTests
//

import SwiftUI
import XCTest
@testable import DinoGames

@MainActor
final class StandardVictorySequenceXCTests: XCTestCase {

    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "nameThatDinosaurUsedCreatureIds")
        UserDefaults.standard.removeObject(forKey: "nameThatDinosaurUsedCladeRawValues")
        UserDefaults.standard.removeObject(forKey: "dinoFootprintsUsedSlotKeys")
        super.setUp()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "landDinosaurPlayedCanonicalGameIds")
        UserDefaults.standard.removeObject(forKey: "marineReptilePlayedCanonicalGameIds")
        super.tearDown()
    }

    // MARK: - Asset helpers

    func testDefaultSuccessImageCandidates() {
        XCTAssertEqual(
            StandardVictorySequence.defaultSuccessImageCandidates(gameConfigId: "dino-footprints"),
            ["game-dino-footprints-success", "game-dino-footprints"]
        )
        XCTAssertEqual(
            StandardVictorySequence.defaultSuccessImageCandidates(gameConfigId: "marine-footprints"),
            ["game-marine-footprints-success", "game-marine-footprints"]
        )
    }

    // MARK: - Layout

    func testRecapListScrollHeightCapsAtThreeVisibleRows() {
        let three = StandardVictoryLayout.recapListScrollHeight(itemCount: 3)
        let nine = StandardVictoryLayout.recapListScrollHeight(itemCount: 9)
        XCTAssertEqual(three, nine, "Recap viewport should cap at maxVisibleRecapRows")
    }

    func testRecapListScrollHeightUsesAtLeastOneRowSlot() {
        let empty = StandardVictoryLayout.recapListScrollHeight(itemCount: 0)
        let one = StandardVictoryLayout.recapListScrollHeight(itemCount: 1)
        XCTAssertEqual(empty, one)
    }

    func testRecapScrollTarget_staysAtTopForFirstThreeHighlights() {
        for index in 0..<StandardVictoryLayout.maxVisibleRecapRows {
            XCTAssertNil(
                StandardVictoryLayout.recapScrollTargetId(highlightIndex: index, itemCount: 9),
                "Highlight \(index) should not scroll (first viewport page)"
            )
        }
    }

    func testRecapScrollTarget_scrollsFromFourthHighlightForNineItemRecap() {
        XCTAssertEqual(StandardVictoryLayout.recapScrollTargetId(highlightIndex: 3, itemCount: 9), 3)
        XCTAssertEqual(StandardVictoryLayout.recapScrollTargetId(highlightIndex: 4, itemCount: 9), 4)
        XCTAssertEqual(StandardVictoryLayout.recapScrollTargetId(highlightIndex: 8, itemCount: 9), 8)
    }

    func testVictorySplitColumnDefaultsKeepOneScreenLayout() {
        let view = VictorySplitColumnView(
            listScrollHeight: StandardVictoryLayout.recapListScrollHeight(itemCount: 3),
            showSuccessPhase: true,
            endHighlightIndex: 0,
            gameTitle: "Test Game",
            scrollRows: { EmptyView() },
            successPhase: { EmptyView() }
        )
        XCTAssertFalse(view.hideGameTitleDuringSuccessPhase)
        XCTAssertFalse(view.collapseRecapListDuringSuccessPhase)
    }

    // MARK: - beginRecapWalk / advanceRecapHighlight

    func testBeginRecapWalkWithZeroItemsSkipsToSuccessStep() {
        let speech = SpeechManager()
        var step = -1
        var highlight = -1
        var spoken: [Int] = []

        StandardVictorySequence.beginRecapWalk(
            itemCount: 0,
            setEndSequenceStep: { step = $0 },
            setEndHighlightIndex: { highlight = $0 },
            speechManager: speech,
            speakItem: { spoken.append($0) },
            onRecapComplete: {}
        )

        XCTAssertEqual(step, 2)
        XCTAssertEqual(highlight, 0)
        XCTAssertTrue(spoken.isEmpty)
    }

    func testBeginRecapWalkWalksAllItemsThenCompletes() {
        let speech = SpeechManager()
        var step = -1
        var highlight = -1
        var spoken: [Int] = []
        var completed = false

        StandardVictorySequence.beginRecapWalk(
            itemCount: 3,
            setEndSequenceStep: { step = $0 },
            setEndHighlightIndex: { highlight = $0 },
            speechManager: speech,
            speakItem: { spoken.append($0) },
            onRecapComplete: { completed = true }
        )

        XCTAssertEqual(step, 1)
        XCTAssertEqual(highlight, 0)
        XCTAssertEqual(spoken, [0])

        speech.onAudioFinished?()
        XCTAssertEqual(highlight, 1)
        XCTAssertEqual(spoken, [0, 1])

        speech.onAudioFinished?()
        XCTAssertEqual(highlight, 2)
        XCTAssertEqual(spoken, [0, 1, 2])

        speech.onAudioFinished?()
        XCTAssertTrue(completed)
    }

    func testBeginRecapWalkWalksNineItemRecapThenCompletes() {
        let spoken = spokenIndicesAfterFullRecapWalk(itemCount: 9)
        XCTAssertEqual(spoken, Array(0..<9))
    }

    func testNineItemRecapWalkScrollTargetsKickInAfterThirdHighlight() {
        let progress = recapWalkProgress(itemCount: 9)
        XCTAssertTrue(progress.completed)
        XCTAssertEqual(progress.highlightTrail.first, 0)
        XCTAssertEqual(progress.highlightTrail.last, 9, "After final audio, highlight advances past last row")
        for highlight in progress.highlightTrail where highlight < 9 {
            let target = StandardVictoryLayout.recapScrollTargetId(highlightIndex: highlight, itemCount: 9)
            if highlight < StandardVictoryLayout.maxVisibleRecapRows {
                XCTAssertNil(target, "Highlight \(highlight) should stay in first viewport page")
            } else {
                XCTAssertEqual(target, highlight)
            }
        }
    }

    func testLandFootprintsRecapWalkVisitsEveryRowViaSharedHelper() {
        UserDefaults.standard.removeObject(forKey: "dinoFootprintsUsedSlotKeys")
        let config = GuessGameConfigs.dinoFootprints
        let items = LandVictoryRecapPreview.guessItems(from: config)
        LandVictoryRecapPreview.assertRecapRowsHaveDisplayableContent(items, minimumCount: 3)
        let spoken = spokenIndicesAfterFullRecapWalk(itemCount: items.count)
        XCTAssertEqual(spoken, Array(0..<items.count))
    }

    func testLandWeighRecapWalkVisitsEveryRowViaSharedHelper() {
        let config = WeighGameConfigs.weighDinosaurRandomized()
        let items = LandVictoryRecapPreview.weighItems(from: config.items)
        XCTAssertEqual(items.count, 9)
        let spoken = spokenIndicesAfterFullRecapWalk(itemCount: items.count)
        XCTAssertEqual(spoken, Array(0..<9))
    }

    // MARK: - dismissAfterVictory

    func testDismissAfterVictoryClosesSheetAndPostsLandCompletion() {
        var presented = true
        var notifiedId: String?
        let token = NotificationCenter.default.addObserver(
            forName: .landDinosaurGameCompleted,
            object: nil,
            queue: nil
        ) { note in
            notifiedId = note.userInfo?["gameId"] as? String
        }
        defer { NotificationCenter.default.removeObserver(token) }

        let speech = SpeechManager()
        StandardVictorySequence.dismissAfterVictory(
            configId: "weigh-dinosaur",
            isPresented: Binding(get: { presented }, set: { presented = $0 }),
            speechManager: speech
        )

        XCTAssertFalse(presented)
        XCTAssertNil(speech.onAudioFinished)
        XCTAssertEqual(notifiedId, "weigh-dinosaur")
    }

    func testDismissAfterVictoryNormalizesRacingConfigId() {
        var presented = true
        var notifiedId: String?
        let token = NotificationCenter.default.addObserver(
            forName: .landDinosaurGameCompleted,
            object: nil,
            queue: nil
        ) { note in
            notifiedId = note.userInfo?["gameId"] as? String
        }
        defer { NotificationCenter.default.removeObserver(token) }

        StandardVictorySequence.dismissAfterVictory(
            configId: "racing-dinosaurs-cretaceous",
            isPresented: Binding(get: { presented }, set: { presented = $0 }),
            speechManager: SpeechManager()
        )

        XCTAssertFalse(presented)
        XCTAssertEqual(notifiedId, "racing-dinosaurs")
    }

    func testDismissAfterVictoryClosesSheetAndPostsMarineCompletion() {
        var presented = true
        var notifiedId: String?
        let token = NotificationCenter.default.addObserver(
            forName: .marineReptileGameCompleted,
            object: nil,
            queue: nil
        ) { note in
            notifiedId = note.userInfo?["gameId"] as? String
        }
        defer { NotificationCenter.default.removeObserver(token) }

        let speech = SpeechManager()
        StandardVictorySequence.dismissAfterVictory(
            configId: "weigh-marine-reptile",
            isPresented: Binding(get: { presented }, set: { presented = $0 }),
            speechManager: speech
        )

        XCTAssertFalse(presented)
        XCTAssertNil(speech.onAudioFinished)
        XCTAssertEqual(notifiedId, "weigh-marine-reptile")
    }

    func testDismissAfterVictoryNormalizesMarineRacingConfigId() {
        var presented = true
        var notifiedId: String?
        let token = NotificationCenter.default.addObserver(
            forName: .marineReptileGameCompleted,
            object: nil,
            queue: nil
        ) { note in
            notifiedId = note.userInfo?["gameId"] as? String
        }
        defer { NotificationCenter.default.removeObserver(token) }

        StandardVictorySequence.dismissAfterVictory(
            configId: "racing-marine-reptiles-cretaceous",
            isPresented: Binding(get: { presented }, set: { presented = $0 }),
            speechManager: SpeechManager()
        )

        XCTAssertFalse(presented)
        XCTAssertEqual(notifiedId, "racing-marine-reptiles")
    }

    // MARK: - playCrowdCheeringThen

    func testPlayCrowdCheeringThenInvokesCompletionAfterCrowdAudio() {
        let speech = SpeechManager()
        var completed = false
        StandardVictorySequence.playCrowdCheeringThen(speechManager: speech) {
            completed = true
        }

        if speech.urlForAudio(key: "crowd-cheering") != nil {
            XCTAssertFalse(completed, "Completion should wait for crowd audio")
            speech.onAudioFinished?()
        }
        XCTAssertTrue(completed)
    }

    // MARK: - Shipping land games use recap items

    func testShippingLandGamesProduceVictoryRecapItems() {
        // L1 — nine-item grid games (each cell becomes one victory recap row)
        XCTAssertEqual(WeighGameConfigs.weighDinosaurRandomized().items.count, 9)
        XCTAssertEqual(WhoIsTallerGameConfigs.whoIsTallerRandomized().items.count, 9)

        // L1 — Dino Puzzle builds three jigsaw rounds at runtime (one recap row per round)
        let puzzleRecapMoments = LandGameDisplayMomentCatalog.shippingLandMoments()
            .filter { $0.gameConfigId == "dino-puzzle" && $0.context.contains(" creature") }
        XCTAssertGreaterThanOrEqual(puzzleRecapMoments.count, 3)

        // L2 — three-round guess games
        XCTAssertEqual(GuessGameConfigs.nameThatDinosaur.rounds.count, 3)

        // L2 — Racing Dinosaurs: winner recap needs a non-empty period pool
        let racingBoth = RacingGameConfigs.makeConfig(for: .both)
        XCTAssertGreaterThanOrEqual(racingBoth.racers.count, 2)

        // L2 — Dino Ages: three rounds × three correct picks → nine recap dinosaurs
        XCTAssertEqual(DinoAgesMechanics.minimumUniqueDinosPerPeriod, 9)

        // L3 — three-round guess / eggs games
        XCTAssertEqual(GuessGameConfigs.dinoFootprints.rounds.count, 3)
        XCTAssertEqual(DinoEggsGameConfigs.dinoEggs.rounds.count, 3)

        // L3 — Dino Flora: three rounds, one plant per round in the victory walk
        XCTAssertGreaterThanOrEqual(DinoFloraMechanics.registryPlantIds.count, 3)

        // L4 — matrix, diets, smile
        XCTAssertEqual(DinoMatrixGameConfigs.dinoMatrix.rounds.count, 3)
        let diets = MatchingGameConfigs.dinoDietFeatures
        XCTAssertEqual(diets.selectedDinosaurs.count, 3)
        XCTAssertEqual(SmilingDinosGameConfigs.smilingDinos.rounds.count, 3)
    }

    func testShippingLandVictoryRecapContentUsesGameplayConcepts() {
        // L1 — Weigh / Taller: nine weighed or compared creatures with grid art
        let weighConfig = WeighGameConfigs.weighDinosaurRandomized()
        let weighItems = LandVictoryRecapPreview.weighItems(from: weighConfig.items)
        LandVictoryRecapPreview.assertRecapRowsHaveDisplayableContent(weighItems, minimumCount: 9)
        XCTAssertEqual(weighItems.map(\.title), weighConfig.items.map(\.name))

        let tallerConfig = WhoIsTallerGameConfigs.whoIsTallerRandomized()
        let tallerItems = LandVictoryRecapPreview.tallerItems(from: tallerConfig.items)
        LandVictoryRecapPreview.assertRecapRowsHaveDisplayableContent(tallerItems, minimumCount: 9)
        XCTAssertEqual(tallerItems.map(\.title), tallerConfig.items.map(\.name))

        // L1 — Dino Puzzle: one portrait recap row per solved creature
        let puzzleItems = LandVictoryRecapPreview.puzzleItemsFromCatalog()
        LandVictoryRecapPreview.assertRecapRowsHaveDisplayableContent(puzzleItems, minimumCount: 3)
        for item in puzzleItems {
            XCTAssertTrue(item.imageAssetName?.hasPrefix("dino-") == true, "Puzzle recap should use creature portraits")
        }

        // L2 — Name That Dinosaur: silhouette clue art + species name
        let nameThatConfig = GuessGameConfigs.nameThatDinosaur
        let nameThatItems = LandVictoryRecapPreview.guessItems(from: nameThatConfig)
        LandVictoryRecapPreview.assertRecapRowsHaveDisplayableContent(nameThatItems, minimumCount: 3)
        var seenNameThatDinos: Set<Int> = []
        for round in nameThatConfig.rounds {
            guard let dinosaur = round.options.first(where: { $0.id == round.correctAnswerId }) else { continue }
            guard seenNameThatDinos.insert(dinosaur.id).inserted else { continue }
            let item = nameThatItems.first { $0.id == "\(dinosaur.id)" }
            XCTAssertNotNil(item)
            XCTAssertEqual(item?.imageAssetName, round.questionImageName)
        }

        // L2 — Racing Dinosaurs: deduped winners with mph subtitles
        let racingConfig = RacingGameConfigs.makeConfig(for: .both)
        XCTAssertGreaterThanOrEqual(racingConfig.racers.count, 2)
        let sampleWinners = Array(racingConfig.racers.prefix(2))
        let racingItems = LandVictoryRecapPreview.racingItems(winners: sampleWinners + [sampleWinners[0]], config: racingConfig)
        LandVictoryRecapPreview.assertRecapRowsHaveDisplayableContent(racingItems, minimumCount: 2)
        XCTAssertEqual(racingItems.count, 2, "Victory recap should dedupe repeated winners")
        for (item, racer) in zip(racingItems, sampleWinners) {
            XCTAssertEqual(item.title, racer.name)
            XCTAssertEqual(item.subtitle, String(format: "%.1f mph", racer.speed))
        }

        // L2 — Dino Ages: nine matched dinosaurs with portraits
        let agesItems = LandVictoryRecapPreview.agesItemsSimulatingPerfectGame()
        LandVictoryRecapPreview.assertRecapRowsHaveDisplayableContent(
            agesItems,
            minimumCount: DinoAgesMechanics.minimumUniqueDinosPerPeriod
        )

        // L3 — Dino Footprints: footprint clue art + owner name
        let footprintsConfig = GuessGameConfigs.dinoFootprints
        let footprintItems = LandVictoryRecapPreview.guessItems(from: footprintsConfig)
        LandVictoryRecapPreview.assertRecapRowsHaveDisplayableContent(footprintItems, minimumCount: 3)
        for (item, round) in zip(footprintItems, footprintsConfig.rounds) {
            guard let dinosaur = round.options.first(where: { $0.id == round.correctAnswerId }) else { continue }
            XCTAssertEqual(item.title, dinosaur.name)
            if ImageAssetCache.imageExists(named: round.questionImageName) {
                XCTAssertEqual(item.imageAssetName, round.questionImageName)
                XCTAssertTrue(round.questionImageName.contains("footprint"))
            } else {
                XCTAssertEqual(item.imageAssetName, dinosaur.imageName)
            }
        }

        // L3 — Dino Flora: plant display names + habitat art
        let floraSample = Array(dinoFloraPlants.prefix(3))
        let floraItems = LandVictoryRecapPreview.floraItems(from: floraSample)
        LandVictoryRecapPreview.assertRecapRowsHaveDisplayableContent(floraItems, minimumCount: 3)
        XCTAssertEqual(floraItems.map(\.title), floraSample.map(\.displayName))

        // L3 — Dino Eggs: clade morphotype labels (not species names) + colored egg art
        let eggsConfig = DinoEggsGameConfigs.dinoEggs
        let eggItems = LandVictoryRecapPreview.eggsItems(from: eggsConfig)
        LandVictoryRecapPreview.assertRecapRowsHaveDisplayableContent(eggItems, minimumCount: 3)
        for (item, round) in zip(eggItems, eggsConfig.rounds) {
            XCTAssertNotEqual(item.title, round.correctCreature.name, "Dino Eggs recap uses clade labels, not species names")
            XCTAssertEqual(item.title, DinoEggMorphology.morphology.eggDisplayTitle(for: round.eggType))
        }

        // L4 — Dino Matrix: matrix stone name + rock thumbnail per round
        let matrixConfig = DinoMatrixGameConfigs.dinoMatrix
        let matrixItems = LandVictoryRecapPreview.matrixItems(from: matrixConfig)
        LandVictoryRecapPreview.assertRecapRowsHaveDisplayableContent(matrixItems, minimumCount: 3)
        for (item, round) in zip(matrixItems, matrixConfig.rounds) {
            let material = matrixConfig.allMaterials.first { $0.id == round.correctMaterialId }
            XCTAssertEqual(item.title, material?.name)
            XCTAssertTrue(item.imageAssetName?.contains("-material-") == true)
        }

        // L4 — Dino Diets: matched diet types (not dinosaur portraits)
        let dietConfig = MatchingGameConfigs.dinoDietFeatures
        let dietItems = LandVictoryRecapPreview.dietItems(from: dietConfig)
        LandVictoryRecapPreview.assertRecapRowsHaveDisplayableContent(dietItems, minimumCount: 1)
        let dietTypes = Set(MatchingGameConfigs.dinoDietOptions.map(\.type))
        for item in dietItems {
            XCTAssertTrue(dietTypes.contains(item.title))
        }

        // L4 — Smiling Dinos: deduped tooth-shape labels from matched rounds
        let smileConfig = SmilingDinosGameConfigs.smilingDinos
        let matchedSlugs = LandVictoryRecapPreview.smileMatchedToothSlugs(from: smileConfig)
        let smileItems = LandVictoryRecapPreview.smileItems(from: smileConfig, matchedToothSlugs: matchedSlugs)
        LandVictoryRecapPreview.assertRecapRowsHaveDisplayableContent(smileItems, minimumCount: 1)
        XCTAssertLessThanOrEqual(smileItems.count, matchedSlugs.count)
    }

    // MARK: - Shipping marine games use recap items

    func testShippingMarineGamesProduceVictoryRecapItems() {
        let nameThat = GuessGameConfigs.nameThatMarineReptile
        XCTAssertEqual(nameThat.rounds.count, 3)

        if let footprints = GuessGameConfigs.makeMarineFootprints() {
            XCTAssertEqual(footprints.rounds.count, 3)
        }

        if let eggs = MarineEggsGameConfigs.makeMarineEggs() {
            XCTAssertEqual(eggs.totalRounds, 3)
        }

        if let smile = GuessGameConfigs.makeMarineSmile() {
            XCTAssertEqual(smile.rounds.count, 3)
        }
    }

    // MARK: - Shipping air games use recap items

    func testShippingAirGamesProduceVictoryRecapItems() {
        let nameThat = GuessGameConfigs.nameThatPterosaur
        XCTAssertEqual(nameThat.rounds.count, 3)

        let footprints = GuessGameConfigs.pteroFootprints
        XCTAssertEqual(footprints.rounds.count, 3)

        let eggs = PteroEggsGameConfigs.pteroEggs
        XCTAssertEqual(eggs.rounds.count, 3)

        if SmilingDinosGameConfigs.isPteroSmilePlayable {
            let smile = SmilingDinosGameConfigs.pteroSmile
            XCTAssertEqual(smile.rounds.count, 3)
        }
    }

    // MARK: - Recap walk simulation

    @MainActor
    private func spokenIndicesAfterFullRecapWalk(itemCount: Int) -> [Int] {
        let speech = SpeechManager()
        var spoken: [Int] = []
        var completed = false

        StandardVictorySequence.beginRecapWalk(
            itemCount: itemCount,
            setEndSequenceStep: { _ in },
            setEndHighlightIndex: { _ in },
            speechManager: speech,
            speakItem: { spoken.append($0) },
            onRecapComplete: { completed = true }
        )

        while !completed, speech.onAudioFinished != nil {
            speech.onAudioFinished?()
        }
        return spoken
    }

    @MainActor
    private func recapWalkProgress(itemCount: Int) -> (spoken: [Int], highlightTrail: [Int], completed: Bool) {
        let speech = SpeechManager()
        var spoken: [Int] = []
        var highlightTrail: [Int] = []
        var completed = false

        StandardVictorySequence.beginRecapWalk(
            itemCount: itemCount,
            setEndSequenceStep: { _ in },
            setEndHighlightIndex: { highlightTrail.append($0) },
            speechManager: speech,
            speakItem: { spoken.append($0) },
            onRecapComplete: { completed = true }
        )

        while !completed, speech.onAudioFinished != nil {
            speech.onAudioFinished?()
        }
        return (spoken, highlightTrail, completed)
    }
}
