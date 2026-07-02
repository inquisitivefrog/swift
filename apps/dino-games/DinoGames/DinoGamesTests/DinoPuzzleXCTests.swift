//
//  DinoPuzzleXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, audio, and clade-pool contracts for Dino Puzzle (land level 1).
//

import XCTest
@testable import DinoGames

final class DinoPuzzleXCTests: XCTestCase {

    private var config: DinoPuzzleGameConfig { DinoPuzzleGameConfigs.dinoPuzzle }

    private var puzzleLine: PortraitJigsawPuzzleLine {
        .dinosaur(config)
    }

    private var puzzleMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingLandMoments()
            .filter { $0.gameConfigId == "dino-puzzle" }
    }

    // MARK: - Config / catalog

    func testDinoPuzzleConfigIdAndIntro() {
        XCTAssertEqual(config.id, "dino-puzzle")
        XCTAssertEqual(config.title, "Dino Puzzle")
        XCTAssertEqual(config.introAudio, "game-dino-puzzle")
    }

    func testDinoPuzzleAppearsOnLevel1() {
        let level1 = DinosaurGameCatalog.games(level: .level1)
        XCTAssertTrue(
            level1.contains { $0.id == "dino-puzzle" },
            "Dino Puzzle should appear on land level 1"
        )
    }

    func testDinoPuzzleProgressCategoryIsLand() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("dino-puzzle"), .land)
    }

    func testDinoPuzzlePickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-dino-puzzle"), "Missing picker art: game-dino-puzzle")
        XCTAssertTrue(
            known.contains("game-dino-puzzle-success") || known.contains("game-dino-puzzle"),
            "Missing victory art for dino-puzzle"
        )
    }

    func testDinoPuzzleLineExposesGameplayAndVictoryKeys() {
        XCTAssertEqual(puzzleLine.catalogGameId, "dino-puzzle")
        XCTAssertEqual(puzzleLine.guessPromptAudioKey, "game-dino-puzzle-guess-the-dinosaur-in-clade")
        XCTAssertEqual(puzzleLine.directionsAudioKey, "game-dino-puzzle-gameplay-directions")
        XCTAssertEqual(puzzleLine.successImagePrimary, "game-dino-puzzle-success")
        XCTAssertEqual(puzzleLine.successImageFallback, "game-dino-puzzle")
        XCTAssertEqual(
            puzzleLine.successImageCandidateNames,
            ["game-dino-puzzle-success", "game-dino-puzzle"]
        )
    }

    // MARK: - Clade pool (three distinct clades per game)

    func testEveryCladeHasPlayablePortraitForPuzzleRound() {
        let pool = LandDinosaurData.allDinosaurs
        var cladesMissingPortrait: [String] = []
        for clade in DinoClade.allCases {
            let hasPortrait = pool.contains { dino in
                LandDinosaurCladeCatalog.clade(forCreatureId: dino.id) == clade
                    && (dino.imageName.map { ImageAssetCache.imageExists(named: $0) } ?? false)
            }
            if !hasPortrait {
                cladesMissingPortrait.append(clade.rawValue)
            }
        }
        XCTAssertTrue(
            cladesMissingPortrait.isEmpty,
            "Each clade needs at least one bundled portrait for jigsaw rounds: \(cladesMissingPortrait)"
        )
    }

    func testDinoPuzzleDisplayMomentsCoverEveryCladeWithPortrait() {
        let cladesWithPortrait = DinoClade.allCases.filter { clade in
            LandDinosaurData.allDinosaurs.contains { dino in
                LandDinosaurCladeCatalog.clade(forCreatureId: dino.id) == clade
                    && (dino.imageName.map { ImageAssetCache.imageExists(named: $0) } ?? false)
            }
        }
        let puzzleMoments = LandGameDisplayMomentCatalog.shippingLandMoments()
            .filter { $0.gameConfigId == "dino-puzzle" }
        XCTAssertEqual(
            puzzleMoments.count,
            cladesWithPortrait.count,
            "Expected one display moment per clade with bundled portrait"
        )
        for clade in cladesWithPortrait {
            XCTAssertTrue(
                puzzleMoments.contains { $0.context == "clade \(clade.rawValue) creature" },
                "Missing display moment for clade \(clade.rawValue)"
            )
        }
    }

    func testDinoPuzzleDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = puzzleMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testDinoPuzzleDisplayMomentsHaveResolvableAudio() {
        let speech = SpeechManager()
        let missing = puzzleMoments.filter { moment in
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

    // MARK: - Jigsaw patterns

    func testPortraitJigsawPuzzlePatternsShipTenDistinctSplits() {
        XCTAssertEqual(PortraitJigsawPuzzlePattern.allCases.count, 10)
        let dimensionPairs = Set(
            PortraitJigsawPuzzlePattern.allCases.map { "\($0.rows)x\($0.cols)" }
        )
        XCTAssertEqual(dimensionPairs.count, 10, "Each pattern should use a distinct row×column split")
        for pattern in PortraitJigsawPuzzlePattern.allCases {
            XCTAssertGreaterThanOrEqual(pattern.pieceCount, 4)
            XCTAssertLessThanOrEqual(pattern.pieceCount, 20)
            XCTAssertEqual(pattern.pieceCount, pattern.rows * pattern.cols)
        }
    }

    // MARK: - Audio

    func testDinoPuzzleGameplayAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for key in [
            "game-dino-puzzle",
            "game-dino-puzzle-gameplay-directions",
            "game-dino-puzzle-guess-the-dinosaur-in-clade",
        ] {
            XCTAssertTrue(stems.contains(key), "Missing Dino Puzzle gameplay audio: \(key).m4a")
        }
    }

    @MainActor
    func testDinoPuzzleGameplayAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            LandDinosaurGameAudioContracts.allRequiredKeys(forConfigId: "dino-puzzle"),
            messagePrefix: "Dino Puzzle"
        )
    }

    @MainActor
    func testDinoPuzzleCladeAudioResolvesForEveryClade() {
        let speech = SpeechManager()
        var missing: [String] = []
        for clade in DinoClade.allCases {
            let candidateKeys = dinoPuzzleCladeAudioCandidateKeys(for: clade)
            let resolved = candidateKeys.contains { speech.urlForAudio(key: $0) != nil }
            if !resolved {
                missing.append("\(clade.rawValue) (tried: \(candidateKeys.joined(separator: ", ")))")
            }
        }
        XCTAssertTrue(missing.isEmpty, "Missing clade narration for Dino Puzzle rounds: \(missing)")
    }

    /// Mirrors `PortraitJigsawPuzzleGameView` clade + footprint fallback keys for land puzzle rounds.
    private func dinoPuzzleCladeAudioCandidateKeys(for clade: DinoClade) -> [String] {
        switch clade {
        case .stegosaur:
            return ["dino-clade-stegosaurid", "dino-clade-stegosaur"]
        default:
            var keys = ["dino-clade-\(clade.rawValue)"]
            if let footprint = dinoPuzzleFootprintFallbackCladeAudioKey(for: clade) {
                keys.append(footprint)
            }
            return keys
        }
    }

    private func dinoPuzzleFootprintFallbackCladeAudioKey(for clade: DinoClade) -> String? {
        switch clade {
        case .theropod: return "footprint-therapod"
        case .sauropod: return "footprint-sauropod"
        case .hadrosaur: return "footprint-hadrosaur"
        case .ceratopsian: return "footprint-ceratopsian"
        case .ankylosaurid: return "footprint-ankylosaur"
        case .spinosaurid, .stegosaur, .ornithopod, .pachycephalosaur:
            return nil
        }
    }
}
