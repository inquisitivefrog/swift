//
//  MarineReptilePuzzleXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, audio, and marine-group pool contracts for Marine Reptile Puzzle (sea level 1).
//

import XCTest
@testable import DinoGames

final class MarineReptilePuzzleXCTests: XCTestCase {

    private var config: MarineReptilePuzzleGameConfig { MarineReptilePuzzleGameConfigs.marinePuzzle }

    private var puzzleLine: PortraitJigsawPuzzleLine {
        .marineReptile(config)
    }

    private var marineGroupsWithPortrait: [String] {
        let pool = SeaMarineReptileData.allMarineReptiles
        return Array(
            Set(
                pool.compactMap { marine -> String? in
                    guard marine.imageName.map({ ImageAssetCache.imageExists(named: $0) }) == true else { return nil }
                    return SeaMarineReptileData.marineCladeRawValue(for: marine)
                }
            )
        ).sorted()
    }

    // MARK: - Config / catalog

    func testMarineReptilePuzzleConfigIdAndIntro() {
        XCTAssertEqual(config.id, "marine-reptile-puzzle")
        XCTAssertEqual(config.title, "Marine Reptile Puzzle")
        XCTAssertEqual(config.introAudio, "game-marine-reptile-puzzle")
    }

    func testMarineReptilePuzzleAppearsOnLevel1() {
        let level1 = MarineReptileGameCatalog.games(level: .level1)
        XCTAssertTrue(
            level1.contains { $0.id == "marine-reptile-puzzle" },
            "Marine Reptile Puzzle should appear on marine level 1"
        )
    }

    func testMarineReptilePuzzleProgressCategoryIsMarine() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("marine-reptile-puzzle"), .marineReptiles)
    }

    func testMarineReptilePuzzlePickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-marine-reptile-puzzle"), "Missing picker art: game-marine-reptile-puzzle")
        XCTAssertTrue(
            known.contains("game-marine-reptile-puzzle-success") || known.contains("game-marine-reptile-puzzle"),
            "Missing victory art for marine-reptile-puzzle"
        )
    }

    func testMarineReptilePuzzleLineExposesGameplayAndVictoryKeys() {
        XCTAssertEqual(puzzleLine.catalogGameId, "marine-reptile-puzzle")
        XCTAssertEqual(puzzleLine.guessPromptAudioKey, "game-marine-reptile-puzzle-guess-the-marine-reptile-in-clade")
        XCTAssertEqual(puzzleLine.directionsAudioKey, "game-marine-reptile-puzzle-gameplay-directions")
        XCTAssertEqual(puzzleLine.successImagePrimary, "game-marine-reptile-puzzle-success")
        XCTAssertEqual(puzzleLine.successImageFallback, "game-marine-reptile-puzzle")
        XCTAssertEqual(
            puzzleLine.successImageCandidateNames,
            ["game-marine-reptile-puzzle-success", "game-marine-reptile-puzzle"]
        )
    }

    // MARK: - Marine group pool (three distinct groups per game)

    func testEveryMarineGroupHasPlayablePortraitForPuzzleRound() {
        let pool = SeaMarineReptileData.allMarineReptiles
        var groupsMissingPortrait: [String] = []
        for group in marineGroupsWithPortrait {
            let hasPortrait = pool.contains { marine in
                SeaMarineReptileData.marineCladeRawValue(for: marine) == group
                    && (marine.imageName.map { ImageAssetCache.imageExists(named: $0) } ?? false)
            }
            if !hasPortrait {
                groupsMissingPortrait.append(group)
            }
        }
        XCTAssertFalse(marineGroupsWithPortrait.isEmpty)
        XCTAssertTrue(
            groupsMissingPortrait.isEmpty,
            "Each marine image group needs at least one bundled portrait for jigsaw rounds: \(groupsMissingPortrait)"
        )
        XCTAssertGreaterThanOrEqual(marineGroupsWithPortrait.count, 3, "Need at least three marine groups for puzzle rounds")
    }

    func testMarineReptilePuzzleDisplayMomentsCoverEveryGroupWithPortrait() {
        let puzzleMoments = LandGameDisplayMomentCatalog.shippingMarineMoments()
            .filter { $0.gameConfigId == "marine-reptile-puzzle" }
        XCTAssertEqual(
            puzzleMoments.count,
            marineGroupsWithPortrait.count,
            "Expected one display moment per marine group with bundled portrait"
        )
        for group in marineGroupsWithPortrait {
            XCTAssertTrue(
                puzzleMoments.contains { $0.context == "group \(group) creature" },
                "Missing display moment for marine group \(group)"
            )
        }
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

    func testMarineReptilePuzzleGameplayAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for key in [
            "game-marine-reptile-puzzle",
            "game-marine-reptile-puzzle-gameplay-directions",
            "game-marine-reptile-puzzle-guess-the-marine-reptile-in-clade",
        ] {
            XCTAssertTrue(stems.contains(key), "Missing Marine Reptile Puzzle gameplay audio: \(key).m4a")
        }
    }

    @MainActor
    func testMarineReptilePuzzleGameplayAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            [
                "game-marine-reptile-puzzle",
                "game-marine-reptile-puzzle-gameplay-directions",
                "game-marine-reptile-puzzle-guess-the-marine-reptile-in-clade",
            ],
            messagePrefix: "Marine Reptile Puzzle"
        )
    }

    @MainActor
    func testMarineReptilePuzzleCladeAudioResolvesForEveryGroupWithPortrait() {
        let speech = SpeechManager()
        var missing: [String] = []
        for group in marineGroupsWithPortrait {
            let candidateKeys = marinePuzzleCladeAudioCandidateKeys(for: group)
            let resolved = candidateKeys.contains { speech.urlForAudio(key: $0) != nil }
            if !resolved {
                missing.append("\(group) (tried: \(candidateKeys.joined(separator: ", ")))")
            }
        }
        XCTAssertTrue(missing.isEmpty, "Missing clade narration for Marine Reptile Puzzle rounds: \(missing)")
    }

    /// Mirrors `PortraitJigsawPuzzleGameView.cladeAudioKeys` for marine puzzle rounds.
    private func marinePuzzleCladeAudioCandidateKeys(for groupRaw: String) -> [String] {
        let slug = SeaMarineReptileData.audioSlugForMarineGroupRaw(groupRaw)
        return ["marine-clade-\(slug)"]
    }
}
