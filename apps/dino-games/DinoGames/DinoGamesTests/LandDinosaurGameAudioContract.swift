//
//  LandDinosaurGameAudioContract.swift
//  DinoGamesTests
//
//  Required narration keys for each land (dinosaur) game in `DinosaurGameCatalog` / `GameCatalog`.
//  Keys are resolved with `SpeechManager.urlForAudio` (same as gameplay). Update when adding games or clips.
//

import Foundation
@testable import DinoGames

struct LandDinosaurGameAudioContract {
    let configId: String
    let displayName: String
    /// Logical audio keys spoken during this game (intro, directions, hints, SFX).
    let requiredAudioKeys: [String]
}

enum LandDinosaurGameAudioContracts {

    /// One contract per config id placed in `GameLevel.visibleInGamePicker` land rows.
    static let all: [LandDinosaurGameAudioContract] = [
        LandDinosaurGameAudioContract(
            configId: "weigh-dinosaur",
            displayName: "Weigh the Dinosaur",
            requiredAudioKeys: [
                "game-intro-weigh-dinosaur",
                "game-weigh-dinosaur",
                "game-choose-your-first-dinosaur",
                "game-choose-your-second-dinosaur",
            ]
        ),
        LandDinosaurGameAudioContract(
            configId: "which-dino-is-taller",
            displayName: "Which Dino Is Taller",
            requiredAudioKeys: [
                "game-which-dino-is-taller",
            ]
        ),
        LandDinosaurGameAudioContract(
            configId: "dino-puzzle",
            displayName: "Dino Puzzle",
            requiredAudioKeys: [
                "game-dino-puzzle",
                "game-dino-puzzle-gameplay-directions",
                "game-dino-puzzle-guess-the-dinosaur-in-clade",
            ]
        ),
        LandDinosaurGameAudioContract(
            configId: "name-that-dinosaur",
            displayName: "Name That Dinosaur",
            requiredAudioKeys: [
                "can-you-name-the-dinosaur",
            ]
        ),
        LandDinosaurGameAudioContract(
            configId: "racing-dinosaurs",
            displayName: "Racing Dinosaurs",
            requiredAudioKeys: [
                "racing-dinosaurs",
                "game-racing-dinosaurs",
                "game-racing-dinosaurs-ready",
                "game-racing-dinosaurs-set",
                "game-racing-dinosaurs-go",
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
        LandDinosaurGameAudioContract(
            configId: "dino-ages",
            displayName: "Dino Ages",
            requiredAudioKeys: [
                "game-dino-ages",
                "game-dino-ages-jurassic-dinosaurs",
                "game-dino-ages-cretaceous-dinosaurs",
                "game-dino-ages-find-in-jurassic",
                "game-dino-ages-find-in-cretaceous",
                "game-dino-ages-tap-the-period-to-hear-description",
            ]
        ),
        LandDinosaurGameAudioContract(
            configId: "dino-footprints",
            displayName: "Dino Footprints",
            requiredAudioKeys: [
                "game-dino-footprints",
                "game-footprints-identify-the-footprint",
                "game-footprints-tap-the-footprint-to-hear-description",
            ]
        ),
        LandDinosaurGameAudioContract(
            configId: "dino-flora",
            displayName: "Dino Flora",
            requiredAudioKeys: [
                "game-dino-flora",
                "game-dino-flora-which-three-dinosaurs",
                "game-dino-flora-tap-the-image",
                "flora-hint-browsers",
                "flora-hint-periods",
                "flora-hint-diets",
            ]
        ),
        LandDinosaurGameAudioContract(
            configId: "dino-eggs",
            displayName: "Dino Eggs",
            requiredAudioKeys: [
                "game-dino-eggs",
                "game-dino-eggs-gameplay-directions",
                "game-dino-eggs-beep",
                "game-dino-eggs-scan-failed",
                "game-dino-eggs-shape",
                "game-dino-eggs-color",
            ]
        ),
        LandDinosaurGameAudioContract(
            configId: "dino-matrix",
            displayName: "Dino Matrix",
            requiredAudioKeys: [
                "game-dino-matrix",
                "game-dino-matrix-identify-the-stone",
                "game-dino-matrix-material",
                "game-dino-matrix-color",
            ]
        ),
        LandDinosaurGameAudioContract(
            configId: "match-the-diet",
            displayName: "Dino Diets",
            requiredAudioKeys: [
                "game-dino-diets",
                "game-dino-diets-match-each-dinosaur",
            ]
        ),
        LandDinosaurGameAudioContract(
            configId: "smiling-dinos",
            displayName: "Dino Smile",
            requiredAudioKeys: [
                "game-dino-smile",
                "game-dino-smile-gameplay-directions",
            ]
        ),
    ]

    static func contract(forConfigId id: String) -> LandDinosaurGameAudioContract? {
        all.first { $0.configId == id }
    }

    /// Extra keys derived from live configs (clades, plants, matrix stones, scans).
    static func supplementalAudioKeys(forConfigId id: String) -> [String] {
        switch id {
        case "dino-eggs":
            return dinoEggsSupplementalKeys()
        case "dino-flora":
            return dinoFloraPlantAudioKeys()
        case "dino-matrix":
            return dinoMatrixMaterialAudioKeys()
        case "dino-footprints":
            return dinoFootprintsCladeAudioKeys()
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

    private static let dinoFloraPlantAudioKeysList: [String] = [
        "flora-horsetails", "flora-moss", "flora-araucaria", "flora-ginkgo", "flora-cycads",
        "flora-tree-fern", "flora-fern", "flora-charophytes", "flora-clubmoss", "flora-equisetites",
        "flora-fungi", "flora-ginkgoites", "flora-liverwort", "flora-magnoliid", "flora-paleopus",
        "flora-taxodium", "flora-totara", "flora-walnut", "flora-water-lilies",
    ]

    private static func dinoFloraPlantAudioKeys() -> [String] {
        dinoFloraPlantAudioKeysList
    }

    private static func dinoMatrixMaterialAudioKeys() -> [String] {
        DinoMatrixGameConfigs.dinoMatrix.allMaterials.map { $0.name.lowercased() }
    }

    private static func dinoFootprintsCladeAudioKeys() -> [String] {
        [
            "footprint-ankylosaur", "footprint-ceratopsian", "footprint-hadrosaur",
            "footprint-ornithischian", "footprint-ornithomimid", "footprint-sauropod",
            "footprint-spinosaurid", "footprint-stegosaur", "footprint-therapod",
        ]
    }

    private static let dinoEggMorphotypeClades: [String] = [
        "ankylosaur", "ceratopsian", "hadrosaur", "large-theropod", "ornithischian",
        "ornithomimid", "sauropod", "small-theropod", "stegosaur",
    ]

    private static func dinoEggsSupplementalKeys() -> [String] {
        var keys: [String] = []
        for clade in dinoEggMorphotypeClades where DinoEggMorphology.roundAssetsExist(for: clade) {
            keys.append("dino-eggs-\(clade)")
            keys.append("game-dino-eggs-nest-\(clade)")
            let scan = DinoEggMorphology.scanAssetName(for: clade)
            keys.append(scan)
        }
        keys.append("dino-eggs-scans-empty")
        return keys
    }
}
