//
//  DeveloperSessionFlags.swift
//  DinoGames
//
//  Opt-in flags for development / QA (not shown in the child UI). Toggle via UserDefaults without rebuilding.
//

import Foundation

enum DeveloperSessionFlags {
    /// `UserDefaults` key. When `true`:
    /// - Every difficulty level is unlocked (Land, Air, Marine).
    /// - Land **concept prerequisites** (`LandDinosaurGamePairing`) are ignored so any listed game is playable.
    /// - Guided auto-play is off — pick a level, then tap any game.
    ///
    /// Enable (Simulator or device):
    /// `defaults write com.inquisitivefrog.DinoGames devUnlockAllGameLevels -bool YES`
    /// Disable:
    /// `defaults write com.inquisitivefrog.DinoGames devUnlockAllGameLevels -bool NO`
    /// or `defaults delete com.inquisitivefrog.DinoGames devUnlockAllGameLevels`
    static let unlockAllGameLevelsUserDefaultsKey = "devUnlockAllGameLevels"

    static var unlockAllGameLevels: Bool {
        UserDefaults.standard.bool(forKey: unlockAllGameLevelsUserDefaultsKey)
            || UITestConfiguration.unlockAllLevels
    }

    /// Manual level + game selection for QA (same switch as `unlockAllGameLevels`).
    static var manualGameSelection: Bool {
        unlockAllGameLevels
    }

    /// `UserDefaults` key. When `true` (Debug builds only): show a toolbar **Done** on Weigh / Who Is Taller / Balance so you can leave mid-game.
    /// Off by default so free-browse and device play look like production.
    ///
    /// Enable: `defaults write com.inquisitivefrog.DinoGames devShowEarlyExitDone -bool YES`
    /// Disable: `defaults delete com.inquisitivefrog.DinoGames devShowEarlyExitDone`
    static let showEarlyExitDoneUserDefaultsKey = "devShowEarlyExitDone"

    static var showEarlyExitDone: Bool {
        UserDefaults.standard.bool(forKey: showEarlyExitDoneUserDefaultsKey)
    }
}
