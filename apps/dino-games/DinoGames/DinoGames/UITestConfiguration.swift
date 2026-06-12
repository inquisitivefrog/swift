//
//  UITestConfiguration.swift
//  DinoGames
//
//  Launch-argument hooks for UI tests (no effect in normal app launches).
//

import Foundation

enum UITestConfiguration {
    private static var environment: [String: String] {
        ProcessInfo.processInfo.environment
    }

    private static var arguments: [String] {
        ProcessInfo.processInfo.arguments
    }

    static var isActive: Bool {
        environment["UITEST_ACTIVE"] == "1" || arguments.contains("-uiTest")
    }

    /// Skip splash delay and welcome audio so UI tests reach the main shell quickly.
    static var skipSplash: Bool {
        isActive && (environment["UITEST_SKIP_SPLASH"] == "1" || arguments.contains("-uiTestSkipSplash"))
    }
}
