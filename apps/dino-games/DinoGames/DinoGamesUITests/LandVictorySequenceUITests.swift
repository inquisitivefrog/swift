//
//  LandVictorySequenceUITests.swift
//  DinoGamesUITests
//
//  Navigation smoke + victory E2E for land games (Dino Puzzle representative path).
//

import XCTest

final class LandVictorySequenceUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchAppForNavigationSmoke() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTest", "-uiTestSkipSplash", "-uiTestFastNavigation"]
        app.launchEnvironment = [
            "UITEST_ACTIVE": "1",
            "UITEST_SKIP_SPLASH": "1",
            "UITEST_FAST_NAVIGATION": "1",
        ]
        app.launch()
        return app
    }

    private func launchAppForVictoryE2E() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTest",
            "-uiTestSkipSplash",
            "-uiTestFastNavigation",
            "-uiTestSkipAudio",
            "-uiTestInstantVictory",
        ]
        app.launchEnvironment = [
            "UITEST_ACTIVE": "1",
            "UITEST_SKIP_SPLASH": "1",
            "UITEST_FAST_NAVIGATION": "1",
            "UITEST_SKIP_AUDIO": "1",
            "UITEST_INSTANT_VICTORY_GAME": "dino-puzzle",
        ]
        app.launch()
        return app
    }

    private func openDinoPuzzleFromLevel1(from app: XCUIApplication) {
        let dinosaurs = app.buttons["category-dinosaurs"]
        XCTAssertTrue(dinosaurs.waitForExistence(timeout: 5))
        dinosaurs.tap()

        XCTAssertTrue(app.scrollViews["level-picker"].waitForExistence(timeout: 5))
        let levelOne = app.buttons["level-level1"]
        XCTAssertTrue(levelOne.waitForExistence(timeout: 3))
        levelOne.tap()

        let dinoPuzzle = app.buttons["game-dino-puzzle"]
        XCTAssertTrue(dinoPuzzle.waitForExistence(timeout: 5))
        dinoPuzzle.tap()
    }

    @MainActor
    func testSkipSplashReachesCategoryPicker() throws {
        let app = launchAppForNavigationSmoke()
        XCTAssertTrue(app.staticTexts["Choose A Game Type"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["category-dinosaurs"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testDinoPuzzleOpensFromLevel1GameList() throws {
        let app = launchAppForNavigationSmoke()

        openDinoPuzzleFromLevel1(from: app)

        XCTAssertTrue(app.staticTexts["Dino Puzzle"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Round 1 of 3"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.otherElements["dino-puzzle-screen"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testDinoPuzzleVictoryRecapCrowdThenDismissReturnsToGameList() throws {
        let app = launchAppForVictoryE2E()
        openDinoPuzzleFromLevel1(from: app)

        XCTAssertTrue(
            app.buttons["game-dino-puzzle"].waitForExistence(timeout: 15),
            "Victory recap, crowd cheering, and dismiss should return to the level game list"
        )
        XCTAssertTrue(app.otherElements["dino-puzzle-screen"].waitForNonExistence(timeout: 5))
    }
}
