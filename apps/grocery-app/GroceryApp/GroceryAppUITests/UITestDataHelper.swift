//
//  UITestDataHelper.swift
//  GroceryAppUITests
//
//  Helper for setting up test data in UI tests
//  Note: UI tests run in a separate process, so we need to set up data through the app
//

import XCTest

extension XCUIApplication {
    /// Launch the app with test data setup enabled
    func launchWithTestData() {
        // Set launch arguments to indicate test mode
        launchArguments.append("--uitest")
        launchArguments.append("--setup-test-data")
        launch()
    }
    
    /// Launch the app with a specific test scenario
    func launchWithScenario(_ scenario: TestScenario) {
        launchArguments.append("--uitest")
        launchArguments.append("--test-scenario")
        launchArguments.append(scenario.rawValue)
        launch()
    }
}

/// Test scenarios for UI testing
enum TestScenario: String {
    case empty = "empty"
    case basicShopping = "basic-shopping"
    case storeBasedShopping = "store-based-shopping"
    case completedShopping = "completed-shopping"
}
