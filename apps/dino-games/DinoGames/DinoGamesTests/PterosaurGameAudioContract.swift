//
//  PterosaurGameAudioContract.swift
//  DinoGamesTests
//
//  Required narration keys for each pterosaur (air) game in `PterosaurGameCatalog` / `GameCatalog`.
//  Keys are resolved with `SpeechManager.urlForAudio` (same as gameplay). Update when adding games or clips.
//

import Foundation
@testable import DinoGames

struct PterosaurGameAudioContract {
    let configId: String
    let displayName: String
    /// Logical audio keys spoken during this game (intro, directions, hints, SFX).
    let requiredAudioKeys: [String]
}

enum PterosaurGameAudioContracts {

    /// One contract per config id placed in `GameLevel.visibleInGamePicker` air rows.
    static let all: [PterosaurGameAudioContract] = [
        PterosaurGameAudioContract(
            configId: "weigh-pterosaur",
            displayName: "Weigh the Pterosaur",
            requiredAudioKeys: [
                "game-intro-weigh-pterosaur",
                "game-weigh-pterosaur",
                "game-choose-your-first-pterosaur",
                "game-choose-your-second-pterosaur",
            ]
        ),
        PterosaurGameAudioContract(
            configId: "which-ptero-is-taller",
            displayName: "Which Ptero Is Taller",
            requiredAudioKeys: [
                "game-which-ptero-is-taller",
                "is-longer",
                "about-the-same-length",
            ]
        ),
        PterosaurGameAudioContract(
            configId: "ptero-puzzle",
            displayName: "Ptero Puzzle",
            requiredAudioKeys: [
                "game-ptero-puzzle",
                "game-ptero-puzzle-gameplay-directions",
                "game-ptero-puzzle-guess-the-pterosaur-in-clade",
            ]
        ),
        PterosaurGameAudioContract(
            configId: "name-that-pterosaur",
            displayName: "Name That Pterosaur",
            requiredAudioKeys: [
                "can-you-name-the-pterosaur",
            ]
        ),
        PterosaurGameAudioContract(
            configId: "racing-pterosaurs",
            displayName: "Racing Pterosaurs",
            requiredAudioKeys: [
                "racing-pterosaurs",
                "game-racing-pterosaurs",
                "game-racing-pterosaurs-ready",
                "game-racing-pterosaurs-set",
                "game-racing-pterosaurs-go",
                "game-racing-first-position",
                "game-racing-second-position",
                "game-racing-outside-track",
                "game-racing-inside-track",
                "game-racing-its-a-tie",
                "game-racing-the-winner-is",
                "starting-whistle",
                "crowd-cheering",
            ]
        ),
        PterosaurGameAudioContract(
            configId: "ptero-ages",
            displayName: "Ptero Ages",
            requiredAudioKeys: [
                "game-ptero-ages",
                "game-hint",
                "game-ptero-ages-jurassic-pterosaurs",
                "game-ptero-ages-cretaceous-pterosaurs",
                "game-ptero-ages-find-in-jurassic",
                "game-ptero-ages-find-in-cretaceous",
                "game-ptero-ages-tap-the-period-to-hear-description",
            ]
        ),
        PterosaurGameAudioContract(
            configId: "ptero-footprints",
            displayName: "Ptero Footprints",
            requiredAudioKeys: [
                "game-ptero-footprints",
                "game-footprints-identify-the-footprint",
                "game-footprints-tap-the-footprint-to-hear-description",
            ]
        ),
        PterosaurGameAudioContract(
            configId: "ptero-flora",
            displayName: "Ptero Flora",
            requiredAudioKeys: [
                "game-ptero-flora",
                "game-ptero-flora-which-three-pterosaurs",
                "game-ptero-flora-tap-the-plant-to-hear-description",
                "ptero-hint-size",
                "ptero-hint-period",
                "ptero-hint-diets",
            ]
        ),
        PterosaurGameAudioContract(
            configId: "ptero-eggs",
            displayName: "Ptero Eggs",
            requiredAudioKeys: [
                "game-ptero-eggs",
                "game-ptero-eggs-gameplay-directions",
                "game-dino-eggs-beep",
                "game-dino-eggs-scan-failed",
            ]
        ),
        PterosaurGameAudioContract(
            configId: "ptero-matrix",
            displayName: "Ptero Matrix",
            requiredAudioKeys: [
                "game-ptero-matrix",
                "game-ptero-matrix-identify-the-stone",
                "game-ptero-matrix-material",
                "game-ptero-matrix-color",
            ]
        ),
        PterosaurGameAudioContract(
            configId: "ptero-diets",
            displayName: "Ptero Diets",
            requiredAudioKeys: [
                "game-ptero-diets",
            ]
        ),
        PterosaurGameAudioContract(
            configId: "ptero-smile",
            displayName: "Ptero Smile",
            requiredAudioKeys: [
                "game-ptero-smile",
                "game-ptero-smile-gameplay-directions",
            ]
        ),
        PterosaurGameAudioContract(
            configId: "balance-the-pterosaur",
            displayName: "Balance the Pterosaurs",
            requiredAudioKeys: [
                "game-can-you-balance-the-pterosaurs",
                "game-balance-choose-a-heavy-pterosaur",
                "game-balance-now-choose-pterosaurs",
            ]
        ),
        PterosaurGameAudioContract(
            configId: "match-the-pterosaur",
            displayName: "Match the Pterosaur",
            requiredAudioKeys: [
                "game-can-you-match-each-pterosaur",
            ]
        ),
    ]

    static func contract(forConfigId id: String) -> PterosaurGameAudioContract? {
        all.first { $0.configId == id }
    }

    /// Extra keys derived from live configs (plants, matrix stones, footprints, diets, eggs).
    static func supplementalAudioKeys(forConfigId id: String) -> [String] {
        switch id {
        case "ptero-flora":
            return pteroFloraPlantAudioKeys()
        case "ptero-footprints":
            return pteroFootprintsCladeAudioKeys()
        case "ptero-diets":
            return pteroDietOptionAudioKeys()
        case "ptero-smile":
            return pteroSmileBeakAudioKeys()
        case "ptero-matrix":
            return pteroMatrixMaterialAudioKeys()
        default:
            return []
        }
    }

    static func allRequiredKeys(forConfigId id: String) -> [String] {
        let base = contract(forConfigId: id)?.requiredAudioKeys ?? []
        let extra = supplementalAudioKeys(forConfigId: id)
        return Array(Set(base + extra)).sorted()
    }

    // MARK: - Dynamic supplements

    private static func pteroFloraPlantAudioKeys() -> [String] {
        pteroFloraPlants.map(\.audioKey)
    }

    private static func pteroFootprintsCladeAudioKeys() -> [String] {
        PterosaurGuessGroup.allCases.map { "ptero-clade-\($0.cladeAudioSlug)" }
    }

    private static func pteroDietOptionAudioKeys() -> [String] {
        AirPterosaurData.pterosaurDietTypes.map { AirPterosaurData.pterosaurDietAudioKey(for: $0) }
    }

    private static func pteroSmileBeakAudioKeys() -> [String] {
        [
            "beak-spear",
            "needle-spike",
            "peg-slicer",
            "nutcracker",
            "micro-peg",
            "comb-filter",
        ].map { PteroSmileMorphology.toothAudioKey(for: $0) }
    }

    private static func pteroMatrixMaterialAudioKeys() -> [String] {
        guard let config = PteroMatrixGameConfigs.makePteroMatrix() else { return [] }
        return config.allMaterials.map { $0.audioKey(for: .ptero) }
    }

    /// Egg/nest narration under `Audio/Eggs/Pterosaurs/` (checked on disk in `PterosaurGameAudioFilesXCTests`).
    static func pteroEggsMorphotypeAudioKeysOnDisk() -> [String] {
        var keys: [String] = []
        for clade in PteroEggMorphology.shippedClades {
            let bundled = PteroEggMorphology.bundledImageKey(forClade: clade)
            keys.append("ptero-eggs-\(bundled)")
            keys.append("ptero-nests-\(bundled)")
            if bundled != clade {
                keys.append("ptero-eggs-\(clade)")
                keys.append("ptero-nests-\(clade)")
            }
        }
        return keys
    }
}
