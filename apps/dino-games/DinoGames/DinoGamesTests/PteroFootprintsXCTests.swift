//
//  PteroFootprintsXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, audio, and round-mechanic contracts for Ptero Footprints (air L3).
//

import XCTest
@testable import DinoGames

final class PteroFootprintsXCTests: XCTestCase {

    private var config: GuessGameConfig { GuessGameConfigs.pteroFootprints }

    private var footprintMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingAirMoments().filter { $0.gameConfigId == "ptero-footprints" }
    }

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "pteroFootprintsUsedSlotKeys")
    }

    // MARK: - Config / catalog

    func testPteroFootprintsConfigIdTitleAndIntro() {
        XCTAssertEqual(config.id, "ptero-footprints")
        XCTAssertEqual(config.title, "Ptero Footprints!")
        XCTAssertEqual(config.introAudio, "game-ptero-footprints")
    }

    func testPteroFootprintsAppearsOnLevel3() {
        let level3 = PterosaurGameCatalog.games(level: .level3)
        XCTAssertTrue(
            level3.contains { $0.id == "ptero-footprints" },
            "Ptero Footprints should appear on air level 3"
        )
    }

    func testPteroFootprintsProgressCategoryIsAir() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("ptero-footprints"), .air)
    }

    func testPteroFootprintsPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-ptero-footprints"), "Missing picker art: game-ptero-footprints")
        XCTAssertTrue(
            known.contains("game-ptero-footprints-success") || known.contains("game-ptero-footprints"),
            "Missing victory art for ptero-footprints"
        )
    }

    func testPteroFootprintsPlayablePoolIsLargeEnough() {
        XCTAssertGreaterThanOrEqual(config.availableDinosaurs.count, 5)
        for ptero in config.availableDinosaurs {
            XCTAssertTrue(ptero.imageName?.hasPrefix("ptero-") == true)
            XCTAssertNotNil(
                Self.footprintMorphotypeStem(for: ptero),
                "Playable pool pterosaur \(ptero.name) should map to a footprint morphotype"
            )
        }
    }

    // MARK: - Round structure

    func testPteroFootprintsProductionConfigThreeRounds() {
        XCTAssertEqual(config.rounds.count, 3)
        let correctIds = config.rounds.map(\.correctAnswerId)
        XCTAssertEqual(Set(correctIds).count, 3, "Each round should feature a distinct correct pterosaur")
    }

    func testPteroFootprintsRoundOptionsAndQuestionImages() {
        let known = ImageAssetNames.knownAssets
        for round in config.rounds {
            XCTAssertEqual(round.options.count, 3)
            XCTAssertEqual(Set(round.options.map(\.id)).count, 3)
            XCTAssertTrue(round.options.contains { $0.id == round.correctAnswerId })
            XCTAssertTrue(
                round.questionImageName.hasPrefix("ptero-footprint-"),
                "Round \(round.id) question should use ptero footprint art: \(round.questionImageName)"
            )
            XCTAssertTrue(
                known.contains(round.questionImageName),
                "Round \(round.id) missing footprint imageset: \(round.questionImageName)"
            )
            if let fallback = round.questionImageFallback {
                XCTAssertTrue(known.contains(fallback), "Round \(round.id) missing portrait: \(fallback)")
            }
            for option in round.options {
                guard let imageName = option.imageName else {
                    XCTFail("Option \(option.name) missing imageName")
                    continue
                }
                XCTAssertTrue(known.contains(imageName), "Round \(round.id) option missing portrait: \(imageName)")
            }
        }
    }

    func testPteroFootprintsDecoysUseDifferentFootprintMorphotypes() {
        for round in config.rounds {
            guard let correct = round.options.first(where: { $0.id == round.correctAnswerId }) else {
                XCTFail("Round \(round.id) missing correct option")
                continue
            }
            guard let correctMorph = Self.footprintMorphotypeStem(for: correct) else {
                XCTFail("Correct answer \(correct.name) missing footprint morphotype")
                continue
            }
            let decoys = round.options.filter { $0.id != round.correctAnswerId }
            XCTAssertEqual(decoys.count, 2)
            for decoy in decoys {
                guard let decoyMorph = Self.footprintMorphotypeStem(for: decoy) else {
                    XCTFail("Decoy \(decoy.name) missing footprint morphotype")
                    continue
                }
                XCTAssertNotEqual(
                    decoyMorph,
                    correctMorph,
                    "Decoy \(decoy.name) must not share footprint morphotype with question \(correct.name)"
                )
            }
        }
    }

    func testPteroFootprintsQuestionImageMatchesCorrectMorphotype() {
        for round in config.rounds {
            guard let correct = round.options.first(where: { $0.id == round.correctAnswerId }),
                  let morph = Self.footprintMorphotypeStem(for: correct) else {
                XCTFail("Round \(round.id) missing correct morphotype")
                continue
            }
            XCTAssertTrue(
                round.questionImageName.contains("ptero-footprint-\(morph)"),
                "Round \(round.id) footprint \(round.questionImageName) should include morphotype stem `\(morph)` for \(correct.name)"
            )
        }
    }

    // MARK: - Source hints

    func testPteroFootprintsSourceHintMomentsCoverSevenMorphotypes() {
        let hintMoments = footprintMoments.filter { $0.context.hasPrefix("source-hint ") }
        XCTAssertEqual(hintMoments.count, PterosaurGuessGroup.allCases.count)
    }

    // MARK: - Display moments

    func testPteroFootprintsDisplayMomentsIncludeRoundFootprintsAndOptions() {
        let roundFootprints = footprintMoments.filter { $0.context.contains("footprint") && $0.context.hasPrefix("round ") }
        XCTAssertEqual(roundFootprints.count, 3)
        let optionMoments = footprintMoments.filter { $0.context.contains("option") }
        XCTAssertEqual(optionMoments.count, 9, "Expected three rounds × three options")
    }

    func testPteroFootprintsDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = footprintMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testPteroFootprintsDisplayMomentsHaveResolvableAudio() {
        let speech = SpeechManager()
        let missing = footprintMoments.filter { moment in
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

    // MARK: - Audio

    @MainActor
    func testPteroFootprintsGameplayAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            PterosaurGameAudioContracts.allRequiredKeys(forConfigId: "ptero-footprints"),
            messagePrefix: "Ptero Footprints"
        )
    }

    @MainActor
    func testPteroFootprintsGuessFeedbackAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            ["thats-right-you-guessed-it", "try-again"],
            messagePrefix: "Ptero Footprints feedback"
        )
    }

    // MARK: - Footprint morphotype lookup (keep in sync with `PteroFootprintMorphotype` in GuessGameView.swift)

    private static func footprintMorphotypeStem(for pterosaur: Dinosaur) -> String? {
        guard let group = PterosaurGuessGroup.guessGroup(forImageName: pterosaur.imageName ?? "") else { return nil }
        return group == .transitional ? "transition" : group.rawValue
    }
}
