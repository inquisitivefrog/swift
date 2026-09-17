//
//  DeveloperSessionFlagsXCTests.swift
//  DinoGamesTests
//
//  Walkthrough session expands the picker and unlocks games without changing the shipping 1–4 catalog.
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
        XCTAssertFalse(DeveloperSessionFlags.showAllCatalogLevels)
        XCTAssertEqual(GameCatalog.pickerLevels(for: .land).count, 4)
    }

    func testWalkthroughSessionUnlocksAllCatalogLevelsAndEarlyExit() {
        UserDefaults.standard.set(true, forKey: DeveloperSessionFlags.walkthroughUserDefaultsKey)

        XCTAssertTrue(DeveloperSessionFlags.isWalkthroughSession)
        XCTAssertTrue(DeveloperSessionFlags.showAllCatalogLevels)
        XCTAssertTrue(DeveloperSessionFlags.unlockAllGameLevels)
        XCTAssertTrue(DeveloperSessionFlags.manualGameSelection)
        XCTAssertTrue(DeveloperSessionFlags.showEarlyExitDone)
        XCTAssertTrue(DeveloperSessionFlags.skipGameSelectionIntros)
        XCTAssertTrue(DeveloperSessionFlags.skipLaunchCoverSequence)

        XCTAssertEqual(GameLevel.visibleInGamePicker, Array(GameLevel.allCases))

        let landLevels = GameCatalog.pickerLevels(for: .land)
        XCTAssertTrue(landLevels.contains(.level1))
        XCTAssertTrue(landLevels.contains(.level5), "Walkthrough should list land games past shipping level 4")
        XCTAssertFalse(landLevels.contains(where: { DinosaurGameCatalog.games(level: $0).isEmpty }))

        let marineLevels = GameCatalog.pickerLevels(for: .marineReptiles)
        XCTAssertFalse(marineLevels.contains(.level10), "Empty marine rungs stay off the walkthrough picker")
        XCTAssertTrue(marineLevels.allSatisfy { !MarineReptileGameCatalog.games(level: $0).isEmpty })
    }

    func testUnlockAllDefaultsDoesNotExpandShippingPicker() {
        UserDefaults.standard.set(true, forKey: DeveloperSessionFlags.unlockAllGameLevelsUserDefaultsKey)
        XCTAssertTrue(DeveloperSessionFlags.unlockAllGameLevels)
        XCTAssertFalse(DeveloperSessionFlags.showAllCatalogLevels)
        XCTAssertEqual(GameLevel.visibleInGamePicker, GameLevel.shippingVisibleInGamePicker)
    }
}
