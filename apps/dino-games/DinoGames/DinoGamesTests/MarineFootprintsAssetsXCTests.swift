//
//  MarineFootprintsAssetsXCTests.swift
//  DinoGamesTests
//
//  Catalog + audio contracts for Marine Footprints. Parallels Dino/Ptero Footprints coverage.
//

import XCTest
@testable import DinoGames

final class MarineFootprintsAssetsXCTests: XCTestCase {

    private let registrySlots: [(locomotion: String, cladeAssetSlug: String, marineGroupRaw: String)] = [
        ("walk", "thalattosuchian", "thala"),
        ("punt", "nothosaur", "notho"),
        ("swim", "mosasaur", "mosa"),
        ("drag", "testudine", "testu"),
    ]

    private let gameplayGameAudioKeys: [String] = [
        "game-marine-footprints",
        "game-footprints-identify-the-footprint",
        "game-footprints-tap-the-footprint-to-hear-description",
        "game-hint",
    ]

    private let cladeHintAudioKeys: [String] = [
        "marine-clade-thalattosuchia",
        "marine-clade-nothosaur",
        "marine-clade-mosasaur",
        "marine-clade-testudine",
    ]

    func testMarineFootprintsRegistryMatchesMechanics() {
        XCTAssertEqual(MarineFootprintsMechanics.registry.count, 4)
        for (index, expected) in registrySlots.enumerated() {
            let slot = MarineFootprintsMechanics.registry[index]
            XCTAssertEqual(slot.locomotion, expected.locomotion)
            XCTAssertEqual(slot.cladeAssetSlug, expected.cladeAssetSlug)
            XCTAssertEqual(slot.marineGroupRaw, expected.marineGroupRaw)
            XCTAssertEqual(
                slot.imageBaseName,
                "marine-footprints-\(expected.locomotion)-\(expected.cladeAssetSlug)"
            )
        }
    }

    func testMarineFootprintsAppearsOnLevel3WhenPlayable() {
        let level3 = MarineReptileGameCatalog.games(level: .level3)
        if MarineFootprintsMechanics.isPlayable {
            XCTAssertTrue(level3.contains { $0.id == "marine-footprints" })
        } else {
            XCTAssertFalse(level3.contains { $0.id == "marine-footprints" })
        }
    }

    func testMarineFootprintsGameCardAssetsExistInCatalog() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-marine-footprints"))
        XCTAssertTrue(known.contains("game-marine-footprints-success"))
    }

    func testMarineFootprintsGameplayImagesExistWhenPlayable() throws {
        guard MarineFootprintsMechanics.isPlayable else {
            throw XCTSkip("Marine Footprints gameplay art not bundled yet")
        }
        let known = ImageAssetNames.knownAssets
        for slot in MarineFootprintsMechanics.shippedSlots {
            let bundled = MarineFootprintsMechanics.bundledImageNames(for: slot)
            XCTAssertFalse(bundled.isEmpty, "Expected bundled art for \(slot.imageBaseName)")
            for name in bundled {
                XCTAssertTrue(known.contains(name), "Missing gameplay imageset: \(name)")
            }
        }
    }

    func testMarineFootprintsGuessConfigQuestionImagesExistWhenPlayable() throws {
        guard let config = GuessGameConfigs.makeMarineFootprints() else {
            throw XCTSkip("Marine Footprints not playable yet (need ≥3 bundled track imagesets)")
        }
        XCTAssertEqual(config.id, "marine-footprints")
        XCTAssertEqual(config.rounds.count, 3)
        let known = ImageAssetNames.knownAssets
        for round in config.rounds {
            XCTAssertTrue(
                known.contains(round.questionImageName),
                "Round \(round.id) question image not in catalog: \(round.questionImageName)"
            )
            let correct = round.options.first { $0.id == round.correctAnswerId }
            XCTAssertNotNil(correct)
            let questionClade = SeaMarineReptileData.marineCladeRawValue(for: correct!)
            for option in round.options where option.id != round.correctAnswerId {
                XCTAssertNotEqual(
                    SeaMarineReptileData.marineCladeRawValue(for: option),
                    questionClade,
                    "Decoys should be from other clades than the footprint"
                )
            }
        }
    }

    func testMarineFootprintsGameplayGameAudioFilesExist() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        let expected: Set<String> = [
            "game-marine-footprints",
            "game-footprints-identify-the-footprint",
            "game-footprints-tap-the-footprint-to-hear-description",
        ]
        let missing = expected.subtracting(stems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing Marine Footprints gameplay audio under Games/: \(missing)")
    }

    @MainActor
    func testMarineFootprintsGameplayAudioKeysResolveInBundle() {
        let speech = SpeechManager()
        let missing = gameplayGameAudioKeys.filter { speech.urlForAudio(key: $0) == nil }
        XCTAssertTrue(missing.isEmpty, "Missing Marine Footprints gameplay audio keys: \(missing)")
    }

    @MainActor
    func testMarineFootprintsCladeHintAudioKeysResolveInBundle() {
        let speech = SpeechManager()
        let missing = cladeHintAudioKeys.filter { speech.urlForAudio(key: $0) == nil }
        XCTAssertTrue(missing.isEmpty, "Missing Marine Footprints clade hint audio: \(missing)")
    }
}
