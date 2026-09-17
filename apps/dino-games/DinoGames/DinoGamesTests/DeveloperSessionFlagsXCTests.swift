//
//  DeveloperSessionFlagsXCTests.swift
//  DinoGamesTests
//
//  Walkthrough session unlocks free navigation (no forced completion order) within the shipping 1–4
//  catalog — it does not expose levels 5+, whose games depend on art parked on `future-games` and can
//  crash (fatalError) when their round builder can't find enough qualifying creatures.
//

import XCTest
@testable import DinoGames

final class DeveloperSessionFlagsXCTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: DeveloperSessionFlags.walkthroughUserDefaultsKey)
        UserDefaults.standard.removeObject(forKey: DeveloperSessionFlags.unlockAllGameLevelsUserDefaultsKey)
        UserDefaults.standard.removeObject(forKey: DeveloperSessionFlags.showEarlyExitDoneUserDefaultsKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: DeveloperSessionFlags.walkthroughUserDefaultsKey)
        UserDefaults.standard.removeObject(forKey: DeveloperSessionFlags.unlockAllGameLevelsUserDefaultsKey)
        UserDefaults.standard.removeObject(forKey: DeveloperSessionFlags.showEarlyExitDoneUserDefaultsKey)
        super.tearDown()
    }

    func testShippingPickerStaysLevelsOneThroughFour() {
        XCTAssertEqual(
            GameLevel.shippingVisibleInGamePicker,
            [.level1, .level2, .level3, .level4]
        )
        XCTAssertEqual(GameLevel.visibleInGamePicker, GameLevel.shippingVisibleInGamePicker)
        XCTAssertFalse(DeveloperSessionFlags.isWalkthroughSession)
        XCTAssertEqual(GameCatalog.pickerLevels(for: .land).count, 4)
    }

    func testWalkthroughSessionUnlocksFreeNavigationWithoutExpandingLevels() {
        UserDefaults.standard.set(true, forKey: DeveloperSessionFlags.walkthroughUserDefaultsKey)

        XCTAssertTrue(DeveloperSessionFlags.isWalkthroughSession)
        XCTAssertTrue(DeveloperSessionFlags.unlockAllGameLevels)
        XCTAssertTrue(DeveloperSessionFlags.manualGameSelection)
        XCTAssertTrue(DeveloperSessionFlags.showEarlyExitDone)
        XCTAssertTrue(DeveloperSessionFlags.skipGameSelectionIntros)
        XCTAssertTrue(DeveloperSessionFlags.skipLaunchCoverSequence)

        // Free navigation, not more levels: walkthrough still stays on the shipping 1–4 set.
        XCTAssertEqual(GameLevel.visibleInGamePicker, GameLevel.shippingVisibleInGamePicker)

        let landLevels = GameCatalog.pickerLevels(for: .land)
        XCTAssertEqual(landLevels, [.level1, .level2, .level3, .level4])
        XCTAssertFalse(landLevels.contains(.level5), "Walkthrough must not surface land levels 5+ (parked art, some fatalError)")
        XCTAssertFalse(landLevels.contains(where: { DinosaurGameCatalog.games(level: $0).isEmpty }))
    }

    func testUnlockAllDefaultsDoesNotExpandShippingPicker() {
        UserDefaults.standard.set(true, forKey: DeveloperSessionFlags.unlockAllGameLevelsUserDefaultsKey)
        XCTAssertTrue(DeveloperSessionFlags.unlockAllGameLevels)
        XCTAssertEqual(GameLevel.visibleInGamePicker, GameLevel.shippingVisibleInGamePicker)
    }
}
