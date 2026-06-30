//
//  LandDinosaurHeightCatalog.swift
//  DinoGames
//
//  Standing / at-the-hip height (m) for Which Dino Is Taller and Measure the Dinosaur.
//  Hand-tuned educational values for game scaling.
//

import Foundation

enum LandDinosaurHeightCatalog {
    /// Standing / at-the-hip height (m) per creature id in the land dinosaur pool (ids 1–54).
    static let standingHeightMetersById: [Int: Double] = [
        1: 12,  2: 9,   3: 9,   4: 0.55,  5: 12,  6: 15,  7: 22,  8: 8,
        9: 9,   10: 8,  11: 9,  12: 1.5, 13: 9,  14: 18, 15: 2,  16: 5,
        17: 4,  18: 6,  19: 0.25, 20: 0.22, 21: 26, 22: 6,  23: 20, 24: 5,
        25: 7,  26: 0.35, 27: 1.75,  28: 18, 29: 1,  30: 0.22, 31: 16, 32: 6,
        33: 0.32, 34: 0.22, 35: 8,  36: 4,  37: 0.25, 38: 0.6, 39: 6,  40: 18,
        41: 7,  42: 6,  43: 1.2, 44: 20, 45: 6,  46: 7,  47: 9,  48: 7,
        49: 1.2, 50: 2,  51: 7,  52: 5,  53: 6,  54: 7,
    ]

    static func standingHeightMeters(forCreatureId id: Int) -> Double? {
        standingHeightMetersById[id]
    }

    static func standingHeightMeters(forImageName imageName: String, in creatures: [Dinosaur]) -> Double? {
        guard let id = creatures.first(where: { $0.imageName == imageName })?.id else { return nil }
        return standingHeightMeters(forCreatureId: id)
    }

    /// Catalog heights ≤ 1.0 m, sorted shortest first — the tiniest dinosaurs in Which Dino Is Taller.
    static var dinosaurImageNamesAtMostOneMeter: [String] {
        standingHeightMetersById
            .compactMap { id, meters -> (String, Double)? in
                guard let imageName = LandDinosaurData.allDinosaurs.first(where: { $0.id == id })?.imageName else { return nil }
                return (imageName, meters)
            }
            .filter { $0.1 <= 1.0 }
            .sorted { $0.1 < $1.1 || ($0.1 == $1.1 && $0.0 < $1.0) }
            .map(\.0)
    }

    static func dinosaurImageNamesAtMostOneMeter(playableIn creatures: [Dinosaur]) -> [String] {
        let playable = Set(creatures.compactMap(\.imageName))
        return dinosaurImageNamesAtMostOneMeter.filter { playable.contains($0) }
    }

    /// Bundled tall art: `measure-dino-{slug}` for portrait `dino-{slug}`.
    static func measureDinoImageCandidate(forImageName imageName: String) -> String? {
        guard imageName.hasPrefix("dino-") else { return nil }
        return "measure-\(imageName)"
    }

    /// Resolves bundled `measure-dino-*` when present in the asset catalog.
    static func measureDinoImageName(forImageName imageName: String) -> String? {
        guard let candidate = measureDinoImageCandidate(forImageName: imageName),
              ImageAssetCache.imageExists(named: candidate) else { return nil }
        return candidate
    }

    /// True when `second` is an allowed second pick after `first` is locked in.
    static func dinoHeightPairIsPlayable(firstMeters: Double, secondMeters: Double) -> Bool {
        ComparisonGameLogic.heightSecondPickResult(firstMeters: firstMeters, secondMeters: secondMeters) == .allowed
    }

    /// Every grid choice must have at least one other round mate that can be chosen second.
    static func dinoRoundHeightsAreFullyComparable(_ heights: [Double]) -> Bool {
        guard heights.count >= 2 else { return false }
        for first in heights {
            let hasPartner = heights.contains { second in
                second != first && dinoHeightPairIsPlayable(firstMeters: first, secondMeters: second)
            }
            if !hasPartner { return false }
        }
        return true
    }
}
