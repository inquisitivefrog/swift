//
//  MarineEggsAudioContract.swift
//  DinoGamesTests
//
//  Required narration keys for Marine Eggs gameplay (intro, directions, scanner SFX, source hints).
//  Morphotype egg/nest clips stay on the dedicated on-disk contract under `Audio/Marine-Eggs/`.
//

import Foundation
@testable import DinoGames

struct MarineGameAudioContract {
    let configId: String
    let displayName: String
    /// Logical audio keys spoken during this game (intro, directions, hints, SFX).
    let requiredAudioKeys: [String]
}

enum MarineEggsAudioContracts {

    static let all: [MarineGameAudioContract] = [
        MarineGameAudioContract(
            configId: "marine-eggs",
            displayName: "Marine Eggs",
            requiredAudioKeys: [
                "game-marine-eggs",
                "game-marine-eggs-gameplay-directions",
                "game-dino-eggs-beep",
                "game-dino-eggs-scan-failed",
                "game-dino-eggs-tap-the-scanner",
                "marine-eggs-shape",
            ]
        ),
    ]

    static func contract(forConfigId id: String) -> MarineGameAudioContract? {
        all.first { $0.configId == id }
    }

    static func allRequiredKeys(forConfigId id: String) -> [String] {
        contract(forConfigId: id)?.requiredAudioKeys ?? []
    }

    /// Clade morphotype narration under `Audio/Marine-Eggs/` (checked on disk in `MarineEggsCatalogXCTests`).
    static func marineEggsMorphotypeAudioKeysOnDisk() -> [String] {
        let eggClades = ["basal", "mosasaur", "nothosaur", "testudine", "thalattosuchia"]
        let liveClades = ["halisaur", "ichthyosaur", "plesiosaur", "pliosaur", "tylosaur"]
        let spawnClades = ["teleostei"]
        return eggClades.map { "marine-eggs-\($0)" }
            + liveClades.map { "marine-live-\($0)" }
            + spawnClades.map { "marine-spawn-\($0)" }
    }
}
