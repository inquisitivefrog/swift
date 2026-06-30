//
//  DinoDietsXCTests.swift
//  DinoGamesTests
//
//  Catalog + asset/audio/mechanic contracts for Dino Diets (land L4). Parallels Ptero/Marine Diets coverage.
//

import XCTest
@testable import DinoGames

final class DinoDietsXCTests: XCTestCase {

    private var dietMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingLandMoments().filter { $0.gameConfigId == "match-the-diet" }
    }

    func testDinoDietsConfigIdAndIntro() {
        let config = MatchingGameConfigs.dinoDietFeatures
        XCTAssertEqual(config.id, "match-the-diet")
        XCTAssertEqual(config.title, "Dino Diets!")
        XCTAssertEqual(config.introAudio, "game-intro-dino-diets")
    }

    func testDinoDietsAppearsOnLevel4() {
        let level4 = DinosaurGameCatalog.games(level: .level4)
        XCTAssertTrue(level4.contains { $0.id == "match-the-diet" })
    }

    func testDinoDietsPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-dino-diets"), "Missing picker art: game-dino-diets")
        XCTAssertTrue(
            known.contains("game-dino-diets-success") || known.contains("game-dino-diets"),
            "Missing victory art for match-the-diet"
        )
    }

    func testDinoDietTypesAreFiveStandardLabels() {
        XCTAssertEqual(LandDinosaurData.dinosaurDietTypes.count, 5)
        XCTAssertEqual(
            Set(LandDinosaurData.dinosaurDietTypes),
            Set(["Herbivore", "Carnivore", "Piscivore", "Insectivore", "Omnivore"])
        )
    }

    func testDinoDietOptionImagesBundled() {
        let known = ImageAssetNames.knownAssets
        for dietType in LandDinosaurData.dinosaurDietTypes {
            let asset = "dino-diets-\(dietType.lowercased())"
            XCTAssertTrue(known.contains(asset), "Missing dinosaur diet imageset: \(asset)")
        }
    }

    func testDinoDietOptionsAlwaysFiveTiles() {
        XCTAssertEqual(MatchingGameConfigs.dinoDietOptions.count, 5)
        XCTAssertEqual(
            Set(MatchingGameConfigs.dinoDietOptions.map(\.type)),
            Set(LandDinosaurData.dinosaurDietTypes)
        )
        for option in MatchingGameConfigs.dinoDietOptions {
            XCTAssertEqual(option.imageName, "dino-diets-\(option.type.lowercased())")
        }
    }

    func testDinosaurAssignedDietsAreOnlyDinoDietTypes() {
        let allowed = Set(LandDinosaurData.dinosaurDietTypes)
        for (id, diet) in LandDinosaurData.dinosaurDietById {
            XCTAssertTrue(
                allowed.contains(diet),
                "Dinosaur \(id) has diet \(diet), which is not one of the five Dino Diets options"
            )
        }
        for dino in LandDinosaurData.allDinosaurs {
            XCTAssertNotNil(
                LandDinosaurData.dinosaurDietById[dino.id],
                "Land pool dinosaur \(dino.name) (id \(dino.id)) needs a diet assignment for Dino Diets"
            )
        }
    }

    func testSpinosaurusIsPiscivoreInDinoDiets() {
        let spinosaurus = LandDinosaurData.allDinosaurs.first { $0.imageName == "dino-spinosaurus" }
        XCTAssertNotNil(spinosaurus, "Expected Spinosaurus in land dinosaur catalog")
        XCTAssertEqual(LandDinosaurData.dinosaurDietById[spinosaurus!.id], "Piscivore")
    }

    func testDinoDietRoundIsPlayable() {
        let config = MatchingGameConfigs.dinoDietFeatures
        XCTAssertEqual(config.selectedDinosaurs.count, 3)
        XCTAssertEqual(config.selectedCharacteristics.count, 5)
        let roundDiets = Set(config.selectedCharacteristics.map(\.type))
        XCTAssertEqual(roundDiets, Set(LandDinosaurData.dinosaurDietTypes))
        let creatureDiets = Set(config.selectedDinosaurs.compactMap { LandDinosaurData.dinosaurDietById[$0.id] })
        XCTAssertEqual(creatureDiets.count, 3)
        XCTAssertTrue(creatureDiets.isSubset(of: roundDiets))
    }

    func testDinoDietAudioKeys() {
        XCTAssertEqual(LandDinosaurData.dinosaurDietAudioKey(for: "Herbivore"), "dino-diet-herbivore")
        XCTAssertEqual(LandDinosaurData.dinosaurDietAudioKey(for: "Carnivore"), "dino-diet-carnivore")
        XCTAssertEqual(LandDinosaurData.dinosaurDietAudioKey(for: "Piscivore"), "dino-diet-piscivore")
        XCTAssertEqual(LandDinosaurData.dinosaurDietAudioKey(for: "Insectivore"), "dino-diet-insectivore")
        XCTAssertEqual(LandDinosaurData.dinosaurDietAudioKey(for: "Omnivore"), "dino-diet-omnivore")
    }

    func testDinoDietAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Dino-Diets")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for dietType in LandDinosaurData.dinosaurDietTypes {
            let key = LandDinosaurData.dinosaurDietAudioKey(for: dietType)
            XCTAssertTrue(stems.contains(key), "Missing Dino Diets audio: \(key).m4a")
        }
    }

    @MainActor
    func testDinoDietAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            LandDinosaurData.dinosaurDietTypes.map { LandDinosaurData.dinosaurDietAudioKey(for: $0) },
            messagePrefix: "Dino Diets"
        )
    }

    func testDinoDietsDisplayMomentsAreNonEmpty() {
        XCTAssertFalse(dietMoments.isEmpty)
        let dietTiles = dietMoments.filter { $0.context.hasPrefix("diet ") }
        XCTAssertEqual(dietTiles.count, 5)
    }

    func testDinoDietsDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = dietMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testDinoDietsDisplayMomentsHaveResolvableAudio() {
        let speech = SpeechManager()
        let missing = dietMoments.filter { moment in
            LandGameDisplayMomentCatalog.audioCandidateKeys(for: moment)
                .compactMap { speech.urlForAudio(key: $0) }
                .isEmpty
        }
        let labels = missing.map { moment in
            let keys = LandGameDisplayMomentCatalog.audioCandidateKeys(for: moment).joined(separator: "|")
            return "\(moment.context) → audio `\(keys)`"
        }
        XCTAssertTrue(labels.isEmpty, "Missing bundle audio: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testDinoDietsGameplayInstructionAudioResolvesInBundle() {
        let speech = SpeechManager()
        XCTAssertNotNil(
            speech.urlForAudio(key: "game-dino-diets-match-each-dinosaur"),
            "Dino Diets round intro expects game-dino-diets-match-each-dinosaur in bundle"
        )
    }
}
