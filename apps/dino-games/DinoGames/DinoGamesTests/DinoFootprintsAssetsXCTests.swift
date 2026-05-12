//
//  DinoFootprintsAssetsXCTests.swift
//  DinoGamesTests
//
//  Catalog + on-disk audio contracts for Dino Footprints. Keep lists aligned with
//  `GuessGameView` (source hints, `FootprintClade.imageNameForAsset`, `GuessGameConfigs.dinoFootprints`)
//  and `MatchingGameView.audioFilePath` footprint cases.
//

import XCTest
@testable import DinoGames

final class DinoFootprintsAssetsXCTests: XCTestCase {

    /// Imagesets for the Source Footprints full-screen hint grid (`source-footprints-{clade}`).
    private let sourceFootprintHintImagesets: [String] = [
        "source-footprints-ankylosaur",
        "source-footprints-ceratopsian",
        "source-footprints-hadrosaur",
        "source-footprints-ornithischian",
        "source-footprints-ornithomimid",
        "source-footprints-sauropod",
        "source-footprints-spinosaurid",
        "source-footprints-stegosaur",
        "source-footprints-theropod",
    ]

    /// Audio keys for hint tiles → `Footprints/dino-{clade}.m4a` via `SpeechManager` / `audioFilePath`.
    private let footprintCladeHintAudioKeys: [String] = [
        "footprint-ankylosaur",
        "footprint-ceratopsian",
        "footprint-hadrosaur",
        "footprint-ornithischian",
        "footprint-ornithomimid",
        "footprint-sauropod",
        "footprint-spinosaurid",
        "footprint-stegosaur",
        "footprint-therapod",
    ]

    /// Disk stems under `Audio/Footprints/` (theropod narration uses correct spelling in the filename).
    private let footprintCladeNarrationStems: [String] = [
        "dino-ankylosaur",
        "dino-ceratopsian",
        "dino-hadrosaur",
        "dino-ornithischian",
        "dino-ornithomimid",
        "dino-sauropod",
        "dino-spinosaurid",
        "dino-stegosaur",
        "dino-theropod",
    ]

    /// `(FootprintClade.rawValue, asset base string)` — asset base matches `footprint-{base}-{size}` on disk (`theropod` → `therapod`).
    private let footprintGameplayClades: [(clade: String, assetBase: String)] = [
        ("ankylosaur", "ankylosaur"),
        ("ceratopsian", "ceratopsian"),
        ("hadrosaur", "hadrosaur"),
        ("ornithischian", "ornithischian"),
        ("ornithomimid", "ornithomimid"),
        ("sauropod", "sauropod"),
        ("spinosaurid", "spinosaurid"),
        ("stegosaur", "stegosaur"),
        ("theropod", "therapod"),
    ]

    private let footprintSizes = ["small", "medium", "large"]

    /// Logical keys used in code (`GuessGameView`); `SpeechManager` must resolve each to a bundle URL.
    private let gameplayGameAudioKeys: [String] = [
        "game-dino-footprints",
        "game-footprints-identify-the-footprint",
        "game-footprints-tap-the-footprint-to-hear-description",
    ]

    /// Legacy `game-dino-footprints-*` keys still routed in `MatchingGameView` for older builds / bookmarks.
    private let gameplayGameAudioLegacyAliasKeys: [String] = [
        "game-dino-footprints-identify-the-footprint",
        "game-dino-footprints-tap-the-footprint-to-hear-description",
    ]

    /// Actual `.m4a` stems under `Assets/Audio/Games/` (shared generic prompts + dino-specific intro).
    private let gameplayGameAudioOnDiskStems: [String] = [
        "game-dino-footprints",
        "game-footprints-identify-the-footprint",
        "game-footprints-tap-the-footprint-to-hear-description",
    ]

    // MARK: - Images (asset catalog)

    func testSourceFootprintHintImagesetsExistInCatalog() {
        let known = ImageAssetNames.knownAssets
        for name in sourceFootprintHintImagesets {
            XCTAssertTrue(
                known.contains(name),
                "Missing Source Footprints hint imageset (regenerate asset names if added): \(name)"
            )
        }
    }

    func testFootprintGameplayTierImagesExistInCatalog() {
        let known = ImageAssetNames.knownAssets
        for (_, base) in footprintGameplayClades {
            for size in footprintSizes {
                let direct = "footprint-\(base)-\(size)"
                XCTAssertTrue(
                    known.contains(direct),
                    "Missing footprint tier imageset: \(direct)"
                )
            }
        }
    }

    func testDinoFootprintsGameCardAssetsExistInCatalog() {
        let required: Set<String> = [
            "game-dino-footprints",
            "game-dino-footprints-success",
        ]
        let known = ImageAssetNames.knownAssets
        for name in required {
            XCTAssertTrue(known.contains(name), "Missing Dino Footprints card imageset: \(name)")
        }
    }

    func testDinoFootprintsGuessConfigQuestionImagesExistInCatalog() {
        let config = GuessGameConfigs.dinoFootprints
        XCTAssertEqual(config.id, "dino-footprints")
        XCTAssertEqual(config.rounds.count, 3, "Dino Footprints expects three rounds.")
        let known = ImageAssetNames.knownAssets
        for round in config.rounds {
            XCTAssertTrue(
                known.contains(round.questionImageName),
                "Round \(round.id) question image not in generated catalog: \(round.questionImageName) (run Scripts/regenerate-asset-names.sh)"
            )
            if let fallback = round.questionImageFallback {
                XCTAssertTrue(
                    known.contains(fallback),
                    "Round \(round.id) fallback image not in catalog: \(fallback)"
                )
            }
        }
    }

    // MARK: - Audio (repo files)

    func testFootprintsNarrationDirectoryExistsAndHasCladeFiles() throws {
        let directory = footprintsAudioDirectoryURL()
        XCTAssertTrue(directoryExists(directory), "Missing directory: \(directory.path)")

        let audioFiles = try recursiveFiles(in: directory, allowedExtensions: ["m4a", "mp3", "wav"])
        let stems = Set(audioFiles.map { $0.deletingPathExtension().lastPathComponent.lowercased() })
        XCTAssertFalse(stems.isEmpty, "Expected narration files under \(directory.path)")

        let expected = Set(footprintCladeNarrationStems.map { $0.lowercased() })
        let missing = expected.subtracting(stems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing Footprints narration audio: \(missing)")
    }

    func testDinoFootprintsGameplayGameAudioFilesExist() throws {
        let directory = projectRootURL().appendingPathComponent("DinoGames/Assets/Audio/Games")
        XCTAssertTrue(directoryExists(directory), "Missing directory: \(directory.path)")

        let audioFiles = try recursiveFiles(in: directory, allowedExtensions: ["m4a", "mp3", "wav"])
        let stems = Set(audioFiles.map { $0.deletingPathExtension().lastPathComponent.lowercased() })
        let expected = Set(gameplayGameAudioOnDiskStems.map { $0.lowercased() })
        let missing = expected.subtracting(stems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing Dino Footprints gameplay audio under Games/: \(missing)")
    }

    @MainActor
    func testFootprintHintAudioKeysResolveInBundle() {
        let speech = SpeechManager()
        for key in footprintCladeHintAudioKeys {
            XCTAssertNotNil(
                speech.urlForAudio(key: key),
                "Missing bundle audio for footprint hint key \(key) (expect Footprints/dino-*.m4a)"
            )
        }
        for key in gameplayGameAudioKeys {
            XCTAssertNotNil(
                speech.urlForAudio(key: key),
                "Missing bundle audio for gameplay key \(key) (expect Games/game-*.m4a)"
            )
        }
        for key in gameplayGameAudioLegacyAliasKeys {
            XCTAssertNotNil(
                speech.urlForAudio(key: key),
                "Legacy gameplay key should still resolve: \(key)"
            )
        }
    }

    // MARK: - Helpers

    private func footprintsAudioDirectoryURL() -> URL {
        projectRootURL().appendingPathComponent("DinoGames/Assets/Audio/Footprints")
    }

    private func projectRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
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
