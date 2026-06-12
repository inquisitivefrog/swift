//
//  OrderedTouchFeedbackAudioXCTests.swift
//  DinoGamesTests
//
//  CI: ordered-touch handrail clips exist and resolve for pre-reader land games.
//

import XCTest
@testable import DinoGames

final class OrderedTouchFeedbackAudioXCTests: XCTestCase {

    /// Games that require pick-first + slow-response feedback (land L2–4).
    private let orderedTouchLandGameIds: Set<String> = [
        "dino-ages",
        "dino-flora",
        "smiling-dinos",
        "match-the-diet",
        "dino-eggs",
    ]

    private let requiredFeedbackStems: Set<String> = [
        "pick-a-dinosaur-first",
        "wow-that-was-tricky",
        "great-match",
        "try-again",
        "pick-another-one",
        "thats-right-you-guessed-it",
    ]

    func testFeedbackAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Feedback")
        XCTAssertTrue(TestBundleHelpers.directoryExists(directory), "Missing Feedback audio directory: \(directory.path)")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        let missing = requiredFeedbackStems.subtracting(stems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing Feedback audio files: \(missing.map { "\($0).m4a" }.joined(separator: ", "))")
    }

    @MainActor
    func testFeedbackAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(Array(requiredFeedbackStems).sorted())
    }

    func testOrderedTouchLandGamesAreInShippingCatalog() {
        let catalogIds = Set(LandDinosaurGameAudioContracts.all.map(\.configId))
        let undocumented = orderedTouchLandGameIds.subtracting(catalogIds).sorted()
        XCTAssertTrue(undocumented.isEmpty, "Ordered-touch game ids not in land audio catalog: \(undocumented)")
    }

    func testGuessChoiceTimerPausesWhileHintsOpen() {
        let t0 = Date(timeIntervalSinceReferenceDate: 100)
        var timer = GuessChoiceTimer()
        timer.start(at: t0)

        let beforeHints = t0.addingTimeInterval(3)
        XCTAssertEqual(timer.elapsed(at: beforeHints), 3, accuracy: 0.001)

        timer.pauseForHints(at: beforeHints)
        let duringHints = beforeHints.addingTimeInterval(10)
        XCTAssertEqual(timer.elapsed(at: duringHints), 3, accuracy: 0.001)

        timer.resumeAfterHints(at: duringHints)
        let afterHints = duringHints.addingTimeInterval(2)
        XCTAssertEqual(timer.elapsed(at: afterHints), 5, accuracy: 0.001)
    }

    func testGuessChoiceTimerIgnoresPauseBeforeStart() {
        var timer = GuessChoiceTimer()
        timer.pauseForHints()
        XCTAssertEqual(timer.elapsed(), 0)
    }
}
