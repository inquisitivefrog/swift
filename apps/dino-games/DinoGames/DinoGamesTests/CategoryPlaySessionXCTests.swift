//
//  CategoryPlaySessionXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class CategoryPlaySessionXCTests: XCTestCase {

    override func tearDown() {
        CategoryPlaySession.clearAll()
        UserDefaults.standard.removeObject(forKey: "landDinosaurPlayedCanonicalGameIds")
        UserDefaults.standard.removeObject(forKey: "pterosaurPlayedCanonicalGameIds")
        UserDefaults.standard.removeObject(forKey: "marineReptilePlayedCanonicalGameIds")
        super.tearDown()
    }

    func testShouldSkipLaunchIntrosWhenGuidedSessionIsResumable() {
        CategoryPlaySession.save(
            category: .air,
            level: .level3,
            gameCanonicalId: "ptero-footprints",
            guidedPlayMode: true
        )
        XCTAssertTrue(CategoryPlaySession.hasResumableGuidedSession)
        XCTAssertTrue(CategoryPlaySession.shouldSkipLaunchIntros)
    }

    func testShouldSkipLaunchIntrosWhenAnyGameWasPlayed() {
        UserDefaults.standard.set(["weigh-dinosaur"], forKey: "landDinosaurPlayedCanonicalGameIds")
        XCTAssertTrue(CategoryPlaySession.hasAnyRecordedPlayProgress)
        XCTAssertTrue(CategoryPlaySession.shouldSkipLaunchIntros)
    }

    func testShouldSkipGuidedLevelIntroOnlyForSavedGuidedSession() {
        CategoryPlaySession.save(
            category: .air,
            level: .level3,
            gameCanonicalId: "ptero-footprints",
            guidedPlayMode: true
        )
        XCTAssertTrue(CategoryPlaySession.shouldSkipGuidedLevelIntro(for: .air))
        XCTAssertFalse(CategoryPlaySession.shouldSkipGuidedLevelIntro(for: .land))
    }

    func testManualCategoryPickClearsLevelSoLevelIntroStillPlays() {
        CategoryPlaySession.save(
            category: .air,
            level: nil,
            gameCanonicalId: nil,
            guidedPlayMode: true
        )
        XCTAssertFalse(CategoryPlaySession.shouldSkipGuidedLevelIntro(for: .air))
    }

    @MainActor
    func testCoverWelcomeAudioResolvesInBundle() {
        XCTAssertNotNil(
            SpeechManager().urlForAudio(key: "cover-welcome-to-dino-games"),
            "Landing page welcome clip should resolve from Audio/Cover/cover-welcome-to-dino-games.m4a"
        )
    }
}
