//
//  DeveloperSessionFlags.swift
//  DinoGames
//
//  Opt-in flags for development / QA / TestFlight walkthrough (not shown in the child UI).
//

import Foundation

enum DeveloperSessionFlags {
    /// Compile-time walkthrough (`DINO_WALKTHROUGH`) or `UserDefaults` `devWalkthrough`.
    /// When true: free navigation within the same shipping levels (1–4) — every game unlocked, no forced
    /// completion order, picker/cover audio skipped, guided auto-play off, and an Exit control on every game
    /// cover. Does **not** expose levels 5+: those games' art is parked on `future-games` and several
    /// `fatalError()` when their round builder can't find enough qualifying creatures.
    ///
    /// TestFlight / archive: use scheme **DinoGames-Walkthrough** (see `docs/development/WALKTHROUGH_TESTFLIGHT.md`).
    /// Simulator without that scheme:
    /// `defaults write com.inquisitivefrog.DinoGames devWalkthrough -bool YES`
    static let walkthroughUserDefaultsKey = "devWalkthrough"

    static var isWalkthroughSession: Bool {
        #if DINO_WALKTHROUGH
        true
        #else
        UserDefaults.standard.bool(forKey: walkthroughUserDefaultsKey)
        #endif
    }

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
        isWalkthroughSession
            || UserDefaults.standard.bool(forKey: unlockAllGameLevelsUserDefaultsKey)
            || UITestConfiguration.unlockAllLevels
    }

    /// Manual level + game selection for QA (same switch as `unlockAllGameLevels`).
    static var manualGameSelection: Bool {
        unlockAllGameLevels
    }

    /// Skip spoken cover/level intros, intermission, game-card walk, and transition delays.
    static var skipGameSelectionIntros: Bool {
        isWalkthroughSession || UITestConfiguration.skipGameSelectionIntros
    }

    /// Skip splash welcome and the category cover walk.
    static var skipLaunchCoverSequence: Bool {
        isWalkthroughSession || UITestConfiguration.skipSplash
    }

    /// `UserDefaults` key. When `true`: show early-exit chrome (Walkthrough uses this automatically).
    /// Enable: `defaults write com.inquisitivefrog.DinoGames devShowEarlyExitDone -bool YES`
    /// Disable: `defaults delete com.inquisitivefrog.DinoGames devShowEarlyExitDone`
    static let showEarlyExitDoneUserDefaultsKey = "devShowEarlyExitDone"

    static var showEarlyExitDone: Bool {
        isWalkthroughSession
            || UserDefaults.standard.bool(forKey: showEarlyExitDoneUserDefaultsKey)
    }
}
