//
//  LandDinosaurMechanicCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class LandDinosaurMechanicCatalogXCTests: XCTestCase {

    // MARK: - Weigh

    func testWeighDinosaurConfigIdAndIntro() {
        let config = WeighGameConfigs.weighDinosaur
        XCTAssertEqual(config.id, "weigh-dinosaur")
        XCTAssertFalse(config.introAudio.isEmpty)
    }

    // MARK: - Which Dino Is Taller

    func testWhichDinoIsTallerConfigBuilds() {
        let config = WhoIsTallerGameConfigs.whoIsTaller
        XCTAssertEqual(config.id, "which-dino-is-taller")
        let randomized = WhoIsTallerGameConfigs.whoIsTallerRandomized()
        XCTAssertGreaterThanOrEqual(randomized.items.count, 2)
    }

    // MARK: - Dino Puzzle

    func testDinoPuzzleConfigAndCladePool() {
        let config = DinoPuzzleGameConfigs.dinoPuzzle
        XCTAssertEqual(config.id, "dino-puzzle")
        XCTAssertGreaterThanOrEqual(LandDinosaurData.allDinosaurs.count, 3)
        XCTAssertEqual(DinoClade.allCases.count, 9)
    }

    // MARK: - Name That Dinosaur

    func testNameThatDinosaurProductionConfigThreeRounds() {
        let config = GuessGameConfigs.nameThatDinosaur
        XCTAssertEqual(config.id, "name-that-dinosaur")
        XCTAssertEqual(config.rounds.count, 3)
        let correctIds = config.rounds.map(\.correctAnswerId)
        XCTAssertEqual(Set(correctIds).count, 3)
        let known = ImageAssetNames.knownAssets
        for round in config.rounds {
            XCTAssertTrue(known.contains(round.questionImageName), "Missing silhouette: \(round.questionImageName)")
        }
    }

    // MARK: - Racing Dinosaurs

    func testRacingDinosaursCardConfigUsesPeriodSelection() {
        let config = RacingGameConfigs.racingDinosaursNeedsPeriod
        XCTAssertEqual(config.id, "racing-dinosaurs")
        XCTAssertEqual(config.assetPrefix, "dino")
        XCTAssertTrue(config.racers.isEmpty)
    }

    func testRacingDinosaursProgressCanonicalId() {
        XCTAssertEqual(LandDinosaurProgress.canonicalId(for: "racing-dinosaurs-cretaceous"), "racing-dinosaurs")
    }

    func testRacingDinosaursPeriodConfigBuildsRacers() {
        let config = RacingGameConfigs.makeConfig(for: .cretaceous)
        XCTAssertEqual(config.assetPrefix, "dino")
        XCTAssertFalse(config.racers.isEmpty, "Expected bundled dino racing art for Cretaceous pool")
    }

    @MainActor
    func testRacingDinosaursReadySetGoAudioResolves() {
        let speech = SpeechManager()
        for key in ["game-racing-dinosaurs-ready", "game-racing-dinosaurs-set", "game-racing-dinosaurs-go"] {
            XCTAssertNotNil(speech.urlForAudio(key: key), "Missing racing prompt: \(key)")
        }
    }

    // MARK: - Dino Ages

    func testDinoAgesAppearsOnLevel2() {
        let level2 = DinosaurGameCatalog.games(level: .level2)
        XCTAssertTrue(level2.contains { $0.id == "dino-ages" })
    }

    func testDinoAgesBundledPeriodArtExists() {
        for name in ["game-dino-ages", "game-dino-ages-success"] {
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(name), "Missing: \(name)")
        }
    }

    // MARK: - Dino Flora

    func testDinoFloraConfigId() {
        XCTAssertEqual(DinoFloraGameConfigs.dinoFlora.id, "dino-flora")
    }

    func testDinoFloraPlantAudioKeysListedInContract() {
        let keys = LandDinosaurGameAudioContracts.supplementalAudioKeys(forConfigId: "dino-flora")
        let expected = dinoFloraPlants.map(\.audioKey)
        XCTAssertEqual(keys.count, expected.count)
        XCTAssertEqual(Set(keys), Set(expected))
    }

    func testDinoFloraPlantEaterMapsCoverRegistry() {
        let plantIds = Set(dinoFloraPlants.map(\.id))
        XCTAssertEqual(DinoFloraMechanics.eaterMapPlantIds, plantIds)
        XCTAssertEqual(DinoFloraMechanics.nonEaterMapPlantIds, plantIds)
        for plant in dinoFloraPlants {
            let eaters = DinoFloraMechanics.eaterIds(forPlantId: plant.id)
            let nonEaters = DinoFloraMechanics.nonEaterIds(forPlantId: plant.id)
            XCTAssertFalse(eaters.isEmpty, "Plant `\(plant.id)` needs eaters")
            XCTAssertFalse(nonEaters.isEmpty, "Plant `\(plant.id)` needs non-eaters")
            XCTAssertTrue(
                eaters.isDisjoint(with: nonEaters),
                "Plant `\(plant.id)` eaters and non-eaters must not overlap"
            )
            XCTAssertGreaterThanOrEqual(
                DinoFloraMechanics.poolEaterCount(forPlantId: plant.id),
                3,
                "Plant `\(plant.id)` needs at least 3 pool eaters for a round"
            )
            XCTAssertGreaterThanOrEqual(
                DinoFloraMechanics.poolNonEaterCount(forPlantId: plant.id),
                2,
                "Plant `\(plant.id)` needs at least 2 pool non-eaters for a round"
            )
        }
    }

    // MARK: - Dino Eggs

    func testDinoEggsConfigBuildsThreeRounds() {
        let config = DinoEggsGameConfigs.dinoEggs
        XCTAssertEqual(config.id, "dino-eggs")
        XCTAssertEqual(config.rounds.count, 3)
        let clades = Set(config.rounds.map(\.eggType))
        XCTAssertEqual(clades.count, 3, "Each round should use a distinct egg clade")
    }

    func testDinoEggsPlayableCladesHaveNestAndScanArt() {
        let clades = LandDinosaurGameAudioContracts.supplementalAudioKeys(forConfigId: "dino-eggs")
            .filter { $0.hasPrefix("dino-eggs-") && !$0.contains("scans") && !$0.hasPrefix("game-") }
        XCTAssertFalse(clades.isEmpty)
        for cladeKey in clades {
            let clade = cladeKey.replacingOccurrences(of: "dino-eggs-", with: "")
            XCTAssertTrue(DinoEggMorphology.roundAssetsExist(for: clade), "Missing round assets for clade \(clade)")
        }
    }

    func testDinoEggsVictoryRecapEggDisplayTitlesAreNonEmpty() {
        let morphology = DinoEggMorphology.morphology
        for round in DinoEggsGameConfigs.dinoEggs.rounds {
            let title = morphology.eggDisplayTitle(for: round.eggType)
            XCTAssertFalse(title.isEmpty, "Victory recap needs a label for egg type `\(round.eggType)`")
        }
    }

    // MARK: - Dino Matrix

    func testDinoMatrixConfigBuildsAndAppearsOnLevel4() {
        let config = DinoMatrixGameConfigs.dinoMatrix
        XCTAssertEqual(config.id, "dino-matrix")
        XCTAssertEqual(config.rounds.count, 3)
        let level4 = DinosaurGameCatalog.games(level: .level4)
        XCTAssertTrue(level4.contains { $0.id == "dino-matrix" })
    }

    @MainActor
    func testDinoMatrixMaterialAudioKeysResolveInBundle() {
        let keys = LandDinosaurGameAudioContracts.supplementalAudioKeys(forConfigId: "dino-matrix")
        XCTAssertEqual(keys.count, DinoMatrixGameConfigs.dinoMatrix.allMaterials.count)
        TestBundleHelpers.assertBundleResolvesAudioKeys(keys, messagePrefix: "dino-matrix materials")
    }

    // MARK: - Dino Diets

    func testDinoDietsMatchingConfigIsPlayable() {
        let config = MatchingGameConfigs.dinoDietFeatures
        XCTAssertEqual(config.id, "match-the-diet")
        XCTAssertEqual(config.selectedDinosaurs.count, 3)
        XCTAssertEqual(config.selectedCharacteristics.count, 5, "Dino Diets shows five diet tiles")
        XCTAssertEqual(MatchingGameConfigs.dinoDietOptions.count, 5)
    }

    // MARK: - Dino Smile

    func testDinoSmileConfigBuildsThreeRoundsOnLevel4() {
        let config = SmilingDinosGameConfigs.smilingDinos
        XCTAssertEqual(config.id, "smiling-dinos")
        XCTAssertEqual(config.rounds.count, 3)
        for round in config.rounds {
            XCTAssertEqual(round.pairs.count, SmilingDinosRound.creaturesPerRound)
            XCTAssertEqual(round.distractorToothTypes.count, SmilingDinosRound.distractorTeethPerRound)
            XCTAssertEqual(
                Set(round.pairs.map(\.toothType)).count,
                SmilingDinosRound.creaturesPerRound,
                "Round \(round.id) should use distinct matching tooth types"
            )
            XCTAssertTrue(
                Set(round.distractorToothTypes).isDisjoint(with: Set(round.pairs.map(\.toothType))),
                "Round \(round.id) distractors must not duplicate correct teeth"
            )
        }
        let level4 = DinosaurGameCatalog.games(level: .level4)
        XCTAssertTrue(level4.contains { $0.id == "smiling-dinos" })
    }
}
