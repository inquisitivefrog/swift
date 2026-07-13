//
//  CategoryProgressXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

@MainActor
final class CategoryProgressXCTests: XCTestCase {

    override func setUp() {
        super.setUp()
        resetCatalogProgress()
    }

    override func tearDown() {
        resetCatalogProgress()
        super.tearDown()
    }

    private func resetCatalogProgress() {
        UserDefaults.standard.removeObject(forKey: "landDinosaurPlayedCanonicalGameIds")
        UserDefaults.standard.removeObject(forKey: "pterosaurPlayedCanonicalGameIds")
        UserDefaults.standard.removeObject(forKey: "marineReptilePlayedCanonicalGameIds")
        LandDinosaurProgress.shared.reloadStoredProgressForTesting()
        PterosaurProgress.shared.reloadStoredProgressForTesting()
        MarineReptileProgress.shared.reloadStoredProgressForTesting()
    }

    func testLandCategoryHasTwelvePlayableGames() {
        XCTAssertEqual(GameCatalog.totalGameCount(for: .land), 12)
    }

    func testVictoryProgressSnapshotIncludesCurrentGameBeforePersist() {
        LandDinosaurProgress.shared.markPlayed(canonicalGameId: "weigh-dinosaur")
        let snapshot = GameCatalog.victoryProgressSnapshot(forConfigId: "name-that-dinosaur")
        XCTAssertEqual(snapshot?.completed, 2)
        XCTAssertEqual(snapshot?.total, 12)
        XCTAssertEqual(snapshot?.displayText, "Completed 2 of 12 games")
    }

    func testVictoryProgressSnapshotDoesNotIncrementOnReplay() {
        LandDinosaurProgress.shared.markPlayed(canonicalGameId: "weigh-dinosaur")
        let snapshot = GameCatalog.victoryProgressSnapshot(forConfigId: "weigh-dinosaur")
        XCTAssertEqual(snapshot?.completed, 1)
    }

    func testProgressAudioKeyUsesCompletedAndTotal() {
        XCTAssertEqual(CategoryProgressCopy.audioKey(completed: 5, total: 12), "games-completed-5-of-12")
    }

    func testGuidedCompletionArtAndAudioResolveForEachCategory() {
        for category in GameCategory.allCases {
            let image = CategoryGuidedCompletion.imageName(for: category)
            XCTAssertTrue(
                ImageAssetCache.imageExists(named: image),
                "Missing guided completion art: \(image)"
            )
        }
        let speech = SpeechManager()
        XCTAssertNotNil(
            speech.urlForAudio(key: CategoryGuidedCompletion.congratulationsAudioKey),
            "Missing Feedback/congratulations-you-completed-all-games"
        )
        XCTAssertNotNil(
            speech.urlForAudio(key: CategoryGuidedCompletion.crowdAudioKey),
            "Missing Feedback/crowd-cheering"
        )
    }

    // MARK: - Guided category celebration guardrails

    func testCelebrationAudioKeysPlayCongratulationsBeforeCrowd() {
        XCTAssertEqual(
            CategoryGuidedCompletion.celebrationAudioKeys,
            [
                CategoryGuidedCompletion.congratulationsAudioKey,
                CategoryGuidedCompletion.crowdAudioKey,
            ]
        )
    }

    func testShouldSkipPostGameSheetAudioResetOnlyForGuidedCategoryComplete() {
        XCTAssertTrue(
            CategoryGuidedCompletion.shouldSkipPostGameSheetAudioReset(
                guidedPlayMode: true,
                categoryFullyPlayed: true
            )
        )
        XCTAssertFalse(
            CategoryGuidedCompletion.shouldSkipPostGameSheetAudioReset(
                guidedPlayMode: false,
                categoryFullyPlayed: true
            )
        )
        XCTAssertFalse(
            CategoryGuidedCompletion.shouldSkipPostGameSheetAudioReset(
                guidedPlayMode: true,
                categoryFullyPlayed: false
            )
        )
        XCTAssertFalse(
            CategoryGuidedCompletion.shouldSkipPostGameSheetAudioReset(
                guidedPlayMode: false,
                categoryFullyPlayed: false
            )
        )
    }

    func testShouldReplayLevelIntroAfterGameDismissedInvertsCategoryCompleteSkip() {
        XCTAssertFalse(
            CategoryGuidedCompletion.shouldReplayLevelIntroAfterGameDismissed(
                guidedPlayMode: true,
                categoryFullyPlayed: true
            )
        )
        XCTAssertTrue(
            CategoryGuidedCompletion.shouldReplayLevelIntroAfterGameDismissed(
                guidedPlayMode: true,
                categoryFullyPlayed: false
            )
        )
        XCTAssertTrue(
            CategoryGuidedCompletion.shouldReplayLevelIntroAfterGameDismissed(
                guidedPlayMode: false,
                categoryFullyPlayed: true
            )
        )
    }

    func testCelebrationAudioSequencePlaysBothClipsBeforeCompleting() {
        let speech = SpeechManager()
        var completed = false

        CategoryGuidedCompletionAudio.playCelebrationSequence(speechManager: speech) {
            completed = true
        }

        if speech.urlForAudio(key: CategoryGuidedCompletion.congratulationsAudioKey) != nil {
            XCTAssertFalse(completed, "Crowd should play after congratulations")
            XCTAssertNotNil(speech.onAudioFinished)
            speech.onAudioFinished?()
        }

        if speech.urlForAudio(key: CategoryGuidedCompletion.crowdAudioKey) != nil {
            XCTAssertFalse(completed, "Completion should wait for crowd audio")
            XCTAssertNotNil(speech.onAudioFinished)
            speech.onAudioFinished?()
        }

        XCTAssertTrue(completed)
    }

    func testCelebrationAudioSequenceDoesNotCompleteIfStoppedMidClip() {
        let speech = SpeechManager()
        var completed = false

        CategoryGuidedCompletionAudio.playCelebrationSequence(speechManager: speech) {
            completed = true
        }

        XCTAssertNotNil(speech.onAudioFinished)
        speech.stopCurrentAudio()

        XCTAssertFalse(completed, "Stopping audio mid-sequence must not fire completion early")
        XCTAssertNotNil(speech.onAudioFinished, "Callback should remain until clip finishes normally")
    }
}
