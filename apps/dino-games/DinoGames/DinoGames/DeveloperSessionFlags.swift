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
    }

    /// Manual level + game selection for QA (same switch as `unlockAllGameLevels`).
    static var manualGameSelection: Bool {
        unlockAllGameLevels
    }
}
