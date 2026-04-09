//
//  LandDinosaurCladeCatalog.swift
//  DinoGames
//
//  Shared land-dinosaur clade taxonomy for match, guess, weigh, balance, measure, tools, eggs, smiles, etc.
//

import Foundation

/// Broad morphological / phylogenetic bucket for a land dinosaur in the app’s main pool (`MatchingGameLandDinosaurData.allDinosaurs`, ids 1–57).
enum DinoClade: String, CaseIterable {
    case theropod
    case sauropod
    case ceratopsian
    case ankylosaurid
    case hadrosaur
    case spinosaurid
    case stegosaur
    case ornithopod
    case pachycephalosaur
}

enum LandDinosaurCladeCatalog {
    /// Clade for each creature id in the land dinosaur pool. Keys align with `MatchingGameLandDinosaurData.allDinosaurs`.
    static let cladeByCreatureId: [Int: DinoClade] = [
        1: .theropod, 2: .ceratopsian, 3: .stegosaur, 4: .theropod, 5: .theropod, 6: .spinosaurid,
        7: .sauropod, 8: .ankylosaurid, 9: .hadrosaur, 10: .hadrosaur, 11: .ornithopod, 12: .theropod, 13: .hadrosaur,
        14: .sauropod, 15: .ornithopod, 16: .theropod, 17: .pachycephalosaur, 18: .theropod, 19: .theropod, 20: .theropod,
        21: .sauropod, 22: .spinosaurid, 23: .sauropod, 24: .theropod, 25: .ceratopsian, 26: .theropod, 27: .theropod,
        28: .sauropod, 29: .theropod, 30: .theropod, 31: .theropod, 32: .ceratopsian, 33: .theropod, 34: .theropod,
        35: .ceratopsian, 36: .theropod, 37: .theropod, 38: .theropod, 39: .theropod, 40: .sauropod, 41: .theropod,
        42: .theropod, 43: .theropod, 44: .sauropod, 45: .stegosaur, 46: .ankylosaurid, 47: .hadrosaur, 48: .hadrosaur,
        49: .pachycephalosaur, 50: .pachycephalosaur, 51: .ankylosaurid, 52: .stegosaur, 53: .ornithopod,
        54: .spinosaurid, 55: .ankylosaurid, 56: .ankylosaurid, 57: .ceratopsian,
    ]

    /// Fallback `.theropod` when id is missing from the map (defensive; pool ids should all be present).
    static func clade(forCreatureId id: Int) -> DinoClade {
        cladeByCreatureId[id] ?? .theropod
    }
}
