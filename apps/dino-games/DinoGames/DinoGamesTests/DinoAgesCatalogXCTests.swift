//
//  DinoAgesCatalogXCTests.swift
//  DinoGamesTests
//
//  Catalog, period pool, asset, and audio contracts for Dino Ages (land level 2).
//

import XCTest
@testable import DinoGames

final class DinoAgesCatalogXCTests: XCTestCase {

    private var config: DinoAgesGameConfig { DinoAgesGameConfigs.dinoAges }

    // MARK: - Config / catalog

    func testDinoAgesConfigIdAndIntro() {
        XCTAssertEqual(config.id, "dino-ages")
        XCTAssertEqual(config.title, "Dino Ages!")
        XCTAssertEqual(config.introAudio, "game-dino-ages")
    }

    func testDinoAgesAppearsOnLevel2() {
        let level2 = DinosaurGameCatalog.games(level: .level2)
        XCTAssertTrue(
            level2.contains { $0.id == "dino-ages" },
            "Dino Ages should appear on land level 2"
        )
    }

    func testDinoAgesProgressCategoryIsLand() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("dino-ages"), .land)
    }

    func testDinoAgesIsPrerequisiteForFloraAndFauna() {
        for dependent in ["dino-flora", "dino-fauna"] {
            XCTAssertTrue(
                LandDinosaurGamePairing.prerequisites(before: dependent).contains("dino-ages"),
                "Expected dino-ages to gate `\(dependent)`"
            )
        }
    }

    func testDinoAgesPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-dino-ages"), "Missing picker art: game-dino-ages")
        XCTAssertTrue(
            known.contains("game-dino-ages-success") || known.contains("game-dino-ages"),
            "Missing victory art for dino-ages"
        )
    }

    // MARK: - Period pool

    func testDinoAgesPeriodSetsAreDisjointAndLargeEnough() {
        let jurassic = DinoAgesMechanics.jurassicImageNames
        let cretaceous = DinoAgesMechanics.cretaceousImageNames
        XCTAssertTrue(jurassic.isDisjoint(with: cretaceous), "Jurassic and Cretaceous sets must not overlap")
        let minimum = DinoAgesMechanics.minimumUniqueDinosPerPeriod
        XCTAssertGreaterThanOrEqual(jurassic.count, minimum, "Need enough Jurassic dinos for three rounds")
        XCTAssertGreaterThanOrEqual(cretaceous.count, minimum, "Need enough Cretaceous dinos for three rounds")
    }

    func testDinoAgesPeriodSetsHaveBundledPortraits() {
        let known = ImageAssetNames.knownAssets
        var missing: [String] = []
        for name in DinoAgesMechanics.jurassicImageNames.union(DinoAgesMechanics.cretaceousImageNames) {
            if !known.contains(name) {
                missing.append(name)
            }
        }
        XCTAssertTrue(missing.isEmpty, "Missing bundled dino portraits for Dino Ages: \(missing)")
    }

    // MARK: - Period + source hint art

    func testDinoAgesPeriodAndSourceHintArtExists() {
        let known = ImageAssetNames.knownAssets
        for name in [
            "period-jurassic",
            "period-cretaceous",
            "dino-ages-jurassic",
            "dino-ages-cretaceous",
            "source-dino-ages-jurassic",
            "source-dino-ages-cretaceous",
        ] {
            XCTAssertTrue(known.contains(name), "Missing bundled asset: \(name)")
        }
    }

    func testDinoAgesSourceHintMomentsMatchCatalog() {
        XCTAssertEqual(LandGameDisplayMomentCatalog.agesSourceHints.count, 2)
        for hint in LandGameDisplayMomentCatalog.agesSourceHints {
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(hint.imageAssetName))
            XCTAssertFalse(hint.displayText.isEmpty)
            XCTAssertTrue(hint.audioKey.hasPrefix("game-dino-ages-"))
        }
        let agesHintMoments = LandGameDisplayMomentCatalog.shippingLandMoments()
            .filter { $0.gameConfigId == "dino-ages" && $0.context.hasPrefix("source-hint") }
        XCTAssertEqual(agesHintMoments.count, 2)
    }

    // MARK: - Audio

    func testDinoAgesGameplayAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for key in [
            "game-dino-ages",
            "game-dino-ages-find-in-jurassic",
            "game-dino-ages-find-in-cretaceous",
            "game-dino-ages-jurassic-dinosaurs",
            "game-dino-ages-cretaceous-dinosaurs",
            "game-dino-ages-tap-the-period-to-hear-description",
        ] {
            XCTAssertTrue(stems.contains(key), "Missing Dino Ages gameplay audio: \(key).m4a")
        }
    }

    @MainActor
    func testDinoAgesGameplayAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            LandDinosaurGameAudioContracts.allRequiredKeys(forConfigId: "dino-ages"),
            messagePrefix: "Dino Ages"
        )
    }

    @MainActor
    func testDinoAgesCoverPeriodAudioResolvesInBundle() {
        let speech = SpeechManager()
        for key in ["cover-jurassic", "cover-cretaceous", "game-hint"] {
            XCTAssertNotNil(speech.urlForAudio(key: key), "Dino Ages round flow expects `\(key)` in bundle")
        }
    }

    @MainActor
    func testDinoAgesDinosaurNameAudioResolvesForPeriodPoolSample() {
        let speech = SpeechManager()
        let sample = [
            DinoAgesMechanics.jurassicImageNames.first,
            DinoAgesMechanics.cretaceousImageNames.first,
        ].compactMap { $0 }
        var missing: [String] = []
        for key in sample {
            if speech.urlForAudio(key: key) == nil {
                missing.append(key)
            }
        }
        XCTAssertTrue(missing.isEmpty, "Missing creature narration for Dino Ages taps: \(missing)")
    }
}
