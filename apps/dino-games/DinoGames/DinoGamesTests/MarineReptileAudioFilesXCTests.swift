//
//  MarineReptileAudioFilesXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class MarineReptileAudioFilesXCTests: XCTestCase {

    func testMarineReptileAudioDirectoryExistsAndHasAudioFiles() throws {
        let directory = marineAudioDirectoryURL()
        XCTAssertTrue(directoryExists(directory), "Missing directory: \(directory.path)")

        let audioFiles = try recursiveFiles(in: directory, allowedExtensions: ["m4a", "mp3", "wav"])
        XCTAssertFalse(audioFiles.isEmpty, "Expected marine reptile audio files under \(directory.path)")
    }

    func testMarineReptileAudioExistsForAllMarineBaseAssets() throws {
        let directory = marineAudioDirectoryURL()
        let audioFiles = try recursiveFiles(in: directory, allowedExtensions: ["m4a", "mp3", "wav"])
        let availableStems = Set(audioFiles.map { $0.deletingPathExtension().lastPathComponent.lowercased() })

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
        let directory = projectRootURL().appendingPathComponent("DinoGames/Assets/Audio/Games")
        XCTAssertTrue(directoryExists(directory), "Missing directory: \(directory.path)")

        let audioFiles = try recursiveFiles(in: directory, allowedExtensions: ["m4a", "mp3", "wav"])
        let availableStems = Set(audioFiles.map { $0.deletingPathExtension().lastPathComponent.lowercased() })
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
        ]

        let missing = expectedStems.subtracting(availableStems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing marine gameplay audio files in Games/: \(missing)")
    }

    func testMarineCladeAudioFilesExist() throws {
        let directory = projectRootURL().appendingPathComponent("DinoGames/Assets/Audio/Marine-Clades")
        XCTAssertTrue(directoryExists(directory), "Missing directory: \(directory.path)")

        let audioFiles = try recursiveFiles(in: directory, allowedExtensions: ["m4a", "mp3", "wav"])
        let availableStems = Set(audioFiles.map { $0.deletingPathExtension().lastPathComponent.lowercased() })
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
        XCTAssertTrue(missing.isEmpty, "Missing marine clade audio under Marine-Clades/: \(missing)")
    }

    private func marineAudioDirectoryURL() -> URL {
        projectRootURL().appendingPathComponent("DinoGames/Assets/Audio/Marine-Reptiles")
    }

    private func projectRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // DinoGamesTests
            .deletingLastPathComponent() // DinoGames project root
    }

    private func directoryExists(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func recursiveFiles(in root: URL, allowedExtensions: Set<String>) throws -> [URL] {
        let keys: [URLResourceKey] = [.isRegularFileKey]
        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys)
        var output: [URL] = []
        while let item = enumerator?.nextObject() as? URL {
            let values = try item.resourceValues(forKeys: Set(keys))
            guard values.isRegularFile == true else { continue }
            if allowedExtensions.contains(item.pathExtension.lowercased()) {
                output.append(item)
            }
        }
        return output
    }
}
