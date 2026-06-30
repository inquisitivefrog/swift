//
//  LandDinosaurWeighCatalog.swift
//  DinoGames
//
//  Estimated masses (kg) for Weigh the Dinosaur — sourced from `LandDinosaurData.dinosaurEstimatedWeightKgById`.
//

import Foundation

enum LandDinosaurWeighCatalog {
    struct Entry: Hashable {
        let stableId: Int
        let imageAssetName: String
        let displayName: String
        let weightKg: Double

        var clade: DinoClade {
            LandDinosaurCladeCatalog.clade(forCreatureId: stableId)
        }
    }

    /// Playable weigh pool: bundled `dino-*` portrait with a catalog mass.
    static let allEntries: [Entry] = LandDinosaurData.allDinosaurs.compactMap { d in
        guard let imageName = d.imageName,
              imageName.hasPrefix("dino-"),
              let kg = LandDinosaurData.dinosaurEstimatedWeightKgById[d.id] else { return nil }
        return Entry(stableId: d.id, imageAssetName: imageName, displayName: d.name, weightKg: kg)
    }

    static let weightKgByStableId: [Int: Double] = Dictionary(uniqueKeysWithValues: allEntries.map { ($0.stableId, $0.weightKg) })

    static let weightKgByImageAsset: [String: Double] = Dictionary(uniqueKeysWithValues: allEntries.map { ($0.imageAssetName, $0.weightKg) })
}
