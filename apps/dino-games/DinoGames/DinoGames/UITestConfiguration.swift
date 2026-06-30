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

    /// Unlock every level and use manual game selection (no guided auto-play).
    static var unlockAllLevels: Bool {
        fastNavigation
    }

    /// Skip spoken intros, level intermission, game-card walk, and transition delays.
    static var skipGameSelectionIntros: Bool {
        fastNavigation
    }

    /// `-uiTestFastNavigation` / `UITEST_FAST_NAVIGATION=1` enables unlock + skip intros together.
    static var fastNavigation: Bool {
        isActive && (environment["UITEST_FAST_NAVIGATION"] == "1" || arguments.contains("-uiTestFastNavigation"))
    }

    /// Clear saved guided-play session so UI tests start from the category picker.
    static func applyLaunchOverridesIfNeeded() {
        guard fastNavigation else { return }
        CategoryPlaySession.clearAll()
    }
}
