//
//  GroceryAppUITestsLaunchTests.swift
//  GroceryAppUITests
//
//  Created by Timothy Stilwell on 1/6/26.
//

import XCTest

final class GroceryAppUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for either landing page or main tabs to appear
        // Note: If hasSeenLanding is true (UserDefaults persisted), the app will skip to MainTabView
        // So we check for either landing page OR main tabs
        let landingPageTitle = app.staticTexts["ShoppingKart"]
        let buildMyListTab = app.tabBars.buttons["Build My List"]
        
        let landingPageExists = landingPageTitle.waitForExistence(timeout: 5)
        let mainTabsExist = buildMyListTab.waitForExistence(timeout: 5)
        
        XCTAssertTrue(landingPageExists || mainTabsExist, "Either landing page or main tabs should appear on launch")

        // Take screenshot of landing page
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen (Landing Page)"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Navigate to main view for additional screenshots
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 2) {
            getStartedButton.tap()
            
            // Wait for main view
            let buildMyListTab = app.tabBars.buttons["Build My List"]
            if buildMyListTab.waitForExistence(timeout: 5) {
                let mainViewAttachment = XCTAttachment(screenshot: app.screenshot())
                mainViewAttachment.name = "Main View (Build My List)"
                mainViewAttachment.lifetime = .keepAlways
                add(mainViewAttachment)
            }
        }
    }
}
