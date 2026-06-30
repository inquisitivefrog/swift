//
//  PteroPuzzleXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, audio, and clade-pool contracts for Ptero Puzzle (air level 1).
//

import XCTest
@testable import DinoGames

final class PteroPuzzleXCTests: XCTestCase {

    private var config: PteroPuzzleGameConfig { PteroPuzzleGameConfigs.pteroPuzzle }

    private var puzzleLine: PortraitJigsawPuzzleLine {
        .pterosaur(config)
    }

    // MARK: - Config / catalog

    func testPteroPuzzleConfigIdAndIntro() {
        XCTAssertEqual(config.id, "ptero-puzzle")
        XCTAssertEqual(config.title, "Ptero Puzzle")
        XCTAssertEqual(config.introAudio, "game-ptero-puzzle")
    }

    func testPteroPuzzleAppearsOnLevel1() {
        let level1 = PterosaurGameCatalog.games(level: .level1)
        XCTAssertTrue(
            level1.contains { $0.id == "ptero-puzzle" },
            "Ptero Puzzle should appear on air level 1"
        )
    }

    func testPteroPuzzleProgressCategoryIsAir() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("ptero-puzzle"), .air)
    }

    func testPteroPuzzlePickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-ptero-puzzle"), "Missing picker art: game-ptero-puzzle")
        XCTAssertTrue(
            known.contains("game-ptero-puzzle-success") || known.contains("game-ptero-puzzle"),
            "Missing victory art for ptero-puzzle"
        )
    }

    func testPteroPuzzleLineExposesGameplayAndVictoryKeys() {
        XCTAssertEqual(puzzleLine.catalogGameId, "ptero-puzzle")
        XCTAssertEqual(puzzleLine.guessPromptAudioKey, "game-ptero-puzzle-guess-the-pterosaur-in-clade")
        XCTAssertEqual(puzzleLine.directionsAudioKey, "game-ptero-puzzle-gameplay-directions")
        XCTAssertEqual(puzzleLine.successImagePrimary, "game-ptero-puzzle-success")
        XCTAssertEqual(puzzleLine.successImageFallback, "game-ptero-puzzle")
        XCTAssertEqual(
            puzzleLine.successImageCandidateNames,
            ["game-ptero-puzzle-success", "game-ptero-puzzle"]
        )
    }

    // MARK: - Guess-group pool (three distinct groups per game)

    func testEveryGuessGroupHasPlayablePortraitForPuzzleRound() {
        let pool = AirPterosaurData.allPterosaurs
        var groupsMissingPortrait: [String] = []
        for group in PterosaurGuessGroup.allCases {
            let hasPortrait = pool.contains { ptero in
                PterosaurGuessGroup.guessGroup(forImageName: ptero.imageName ?? "") == group
                    && (ptero.imageName.map { ImageAssetCache.imageExists(named: $0) } ?? false)
            }
            if !hasPortrait {
                groupsMissingPortrait.append(group.rawValue)
            }
        }
        XCTAssertTrue(
            groupsMissingPortrait.isEmpty,
            "Each guess group needs at least one bundled portrait for jigsaw rounds: \(groupsMissingPortrait)"
        )
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

    func testPteroPuzzleGameplayAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for key in [
            "game-ptero-puzzle",
            "game-ptero-puzzle-gameplay-directions",
            "game-ptero-puzzle-guess-the-pterosaur-in-clade",
        ] {
            XCTAssertTrue(stems.contains(key), "Missing Ptero Puzzle gameplay audio: \(key).m4a")
        }
    }

    @MainActor
    func testPteroPuzzleGameplayAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            PterosaurGameAudioContracts.allRequiredKeys(forConfigId: "ptero-puzzle"),
            messagePrefix: "Ptero Puzzle"
        )
    }

    @MainActor
    func testPteroPuzzleCladeAudioResolvesForEveryGuessGroup() {
        let speech = SpeechManager()
        var missing: [String] = []
        for group in PterosaurGuessGroup.allCases {
            let key = "ptero-clade-\(group.cladeAudioSlug)"
            if speech.urlForAudio(key: key) == nil {
                missing.append("\(group.rawValue) (tried: \(key))")
            }
        }
        XCTAssertTrue(missing.isEmpty, "Missing clade narration for Ptero Puzzle rounds: \(missing)")
    }
}
