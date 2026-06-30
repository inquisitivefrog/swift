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

    /// Egg/nest narration under `Audio/Marine-Eggs/` for nest+egg morphotypes (checked on disk in `MarineEggsCatalogXCTests`).
    static func marineEggsMorphotypeAudioKeysOnDisk() -> [String] {
        let morphology = MarineEggMorphology.morphology
        var keys: [String] = []
        for slug in MarineEggMorphology.playableNestEggSlugs.sorted() {
            keys.append(morphology.eggAudioKey(eggType: slug))
            keys.append(morphology.nestingAudioKey(style: slug))
        }
        return keys
    }
}
