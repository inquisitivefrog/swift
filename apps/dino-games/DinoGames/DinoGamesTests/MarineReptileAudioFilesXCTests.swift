//
//  MarineReptileAudioFilesXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class MarineReptileAudioFilesXCTests: XCTestCase {

    func testMarineReptileAudioDirectoryExistsAndHasAudioFiles() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Marine-Reptiles")
        XCTAssertTrue(TestBundleHelpers.directoryExists(directory), "Missing directory: \(directory.path)")

        let audioFiles = try TestBundleHelpers.recursiveFiles(in: directory, allowedExtensions: TestBundleHelpers.audioExtensions)
        XCTAssertFalse(audioFiles.isEmpty, "Expected marine reptile audio files under \(directory.path)")
    }

    func testMarineReptileAudioExistsForAllMarineBaseAssets() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Marine-Reptiles")
        let availableStems = try TestBundleHelpers.audioStems(in: directory)
        // Creature-name coverage is derived from marine base assets (excluding level-card art),
        // so every playable marine reptile asset must have a matching spoken-name file.
        let expectedStems = Set(
            ImageAssetNames.knownAssets
                .filter {
                    $0.hasPrefix("marine-")
                    && !$0.contains("-silhouette-")
                    && !$0.hasPrefix("marine-level-")
                }
                .map { $0.lowercased() }
        )
        XCTAssertFalse(expectedStems.isEmpty, "Expected marine base asset keys to be present.")

        let missing = expectedStems.subtracting(availableStems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing marine creature audio files: \(missing)")
    }

    func testMarineReptileGameplayAudioExists() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        XCTAssertTrue(TestBundleHelpers.directoryExists(directory), "Missing directory: \(directory.path)")

        let availableStems = try TestBundleHelpers.audioStems(in: directory)
        // Gameplay prompts remain an explicit static list to preserve an intentional narration
        // contract and fail loudly when required files are missing.
        let expectedStems: Set<String> = [
            "game-can-you-name-that-marine-reptile",
            "game-name-that-marine-reptile",
            "game-name-that-marine-reptile-thats-right",
            "game-name-that-marine-reptile-try-again",
            "game-name-that-marine-reptile-good-job",
            "game-weigh-marine-reptile",
            "game-choose-your-first-marine-reptile",
            "game-choose-your-second-marine-reptile",
            "game-marine-reptile-puzzle",
            "game-marine-reptile-puzzle-gameplay-directions",
            "game-marine-reptile-puzzle-guess-the-marine-reptile-in-clade",
            "game-racing-marine-reptiles",
            "game-which-marine-reptile-is-longer",
            "game-marine-eggs",
            "game-marine-eggs-gameplay-directions",
            "game-marine-ages",
            "game-marine-ages-jurassic-marine-reptiles",
            "game-marine-ages-cretaceous-marine-reptiles",
            "game-marine-ages-find-in-jurassic",
            "game-marine-ages-find-in-cretaceous",
            "game-marine-ages-tap-the-period-to-hear-description",
        ]

        let missing = expectedStems.subtracting(availableStems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing marine gameplay audio files in Games/: \(missing)")
    }

    func testMarineReptileLengthComparisonFeedbackAudioExists() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Feedback")
        let availableStems = try TestBundleHelpers.audioStems(in: directory)
        let expectedStems: Set<String> = [
            "is-longer",
            "about-the-same-length",
        ]
        let missing = expectedStems.subtracting(availableStems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing marine length comparison feedback audio: \(missing)")
    }

    func testMarineCladeAudioFilesExist() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Marine-Reptile-Clades")
        XCTAssertTrue(TestBundleHelpers.directoryExists(directory), "Missing directory: \(directory.path)")

        let availableStems = try TestBundleHelpers.audioStems(in: directory)
        let expectedStems: Set<String> = [
            "clade-halisaur",
            "clade-ichthyosaur",
            "clade-mosasaur",
            "clade-nothosaur",
            "clade-plesiosaur",
            "clade-plioplatecarp",
            "clade-pliosaur",
            "clade-teleostei",
            "clade-testudine",
            "clade-thalattosuchia",
            "clade-tylosaur",
        ]
        let missing = expectedStems.subtracting(availableStems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing marine clade audio under Marine-Reptile-Clades/: \(missing)")
    }
}
