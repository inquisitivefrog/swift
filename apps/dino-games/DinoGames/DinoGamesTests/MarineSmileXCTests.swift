//
//  MarineSmileXCTests.swift
//  DinoGamesTests
//
//  Catalog + mechanic contracts for Marine Smile (guess layout: tooth + three smiling reptiles).
//

import XCTest
@testable import DinoGames

final class MarineSmileXCTests: XCTestCase {

    func testMarineSmileRegistryHasThreeToothTypes() {
        XCTAssertEqual(MarineSmileToothType.allCases.count, 3)
        XCTAssertEqual(Set(MarineSmileMorphology.slugsByToothType.keys), Set(MarineSmileToothType.allCases))
    }

    func testMarineSmileReferenceToothImagesExistWhenPlayable() throws {
        guard MarineSmileMorphology.isPlayable else {
            throw XCTSkip("Marine Smile reference tooth art not bundled yet")
        }
        for type in MarineSmileToothType.allCases {
            XCTAssertNotNil(
                MarineSmileMorphology.referenceToothImageName(for: type),
                "Missing reference tooth for \(type.rawValue)"
            )
        }
    }

    func testMarineSmileAppearsOnLevel4WhenPlayable() {
        let level4 = MarineReptileGameCatalog.games(level: .level4)
        if MarineSmileMorphology.isPlayable {
            XCTAssertTrue(level4.contains { $0.id == "marine-smile" })
        } else {
            XCTAssertFalse(level4.contains { $0.id == "marine-smile" })
        }
    }

    func testMarineSmileGameCardAssetsExistInCatalog() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-marine-smile"))
        XCTAssertTrue(known.contains("game-marine-smile-success"))
    }

    func testMarineSmileGuessConfigBuildsThreeRoundsWithDistinctToothTypes() throws {
        guard let config = GuessGameConfigs.makeMarineSmile() else {
            throw XCTSkip("Marine Smile not playable yet")
        }
        XCTAssertEqual(config.id, "marine-smile")
        XCTAssertEqual(config.title, "Marine Smile!")
        XCTAssertEqual(config.rounds.count, 3)

        var correctTypes: Set<MarineSmileToothType> = []
        var correctIds: Set<Int> = []
        for round in config.rounds {
            let correct = round.options.first { $0.id == round.correctAnswerId }
            XCTAssertNotNil(correct)
            guard let creature = correct else { continue }
            guard let type = MarineSmileMorphology.toothType(for: creature) else {
                XCTFail("Correct creature missing tooth type")
                continue
            }
            correctTypes.insert(type)
            XCTAssertTrue(correctIds.insert(creature.id).inserted, "Correct creature repeated in one game")
            for option in round.options where option.id != round.correctAnswerId {
                XCTAssertNotEqual(MarineSmileMorphology.toothType(for: option), type)
            }
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(round.questionImageName))
        }
        XCTAssertEqual(correctTypes.count, 3)
    }

    @MainActor
    func testMarineSmileIntroAudioExists() {
        let speech = SpeechManager()
        XCTAssertNotNil(speech.urlForAudio(key: "game-marine-smile"))
    }

    @MainActor
    func testMarineSmilePortraitKeysResolveToMarineReptileBodyAudio() throws {
        guard MarineSmileMorphology.isPlayable else {
            throw XCTSkip("Marine Smile not playable yet")
        }
        let speech = SpeechManager()
        var missing: [String] = []
        for creature in MarineSmileMorphology.playableCreatures {
            guard let smile = creature.imageName else {
                missing.append("\(creature.name) (nil image)")
                continue
            }
            guard let body = MarineSmileMorphology.bodyAudioKey(forSmileAsset: smile) else {
                missing.append("\(smile) → no body key")
                continue
            }
            if speech.urlForAudio(key: smile) == nil {
                missing.append("\(smile) (expected Marine-Reptiles/\(body))")
            }
        }
        XCTAssertTrue(missing.isEmpty, "Marine Smile portraits should resolve body name audio: \(missing.joined(separator: "; "))")
    }
}
