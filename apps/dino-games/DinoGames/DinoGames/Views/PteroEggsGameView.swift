//
//  PteroEggsGameView.swift
//  DinoGames
//
//  Ptero Eggs!: air eggs game using shared EggsGameView (same CT-scanner flow as Dino Eggs).
//  Assets: `ptero-eggs-{clade}`, `ptero-nests-{clade}` (clade = PterosaurGuessGroup raw value).
//

import SwiftUI

typealias PteroEggsRound = EggsGameRound
typealias PteroEggsGameConfig = EggsGameConfig

struct PteroEggsGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: PteroEggsGameConfig

    var body: some View {
        EggsGameView(isPresented: $isPresented, gameConfig: gameConfig)
    }
}

// MARK: - Pterosaur egg morphology

enum PteroEggMorphology {
    /// Clades with bundled `ptero-eggs-*` and `ptero-nests-*` imagesets.
    static let shippedClades: Set<String> = [
        "azhdarchid", "basal", "ornithocheiroid", "specialist", "transitional",
    ]

    static func eggType(for ptero: Dinosaur) -> String? {
        guard let img = ptero.imageName,
              let group = PterosaurGuessGroup.guessGroup(forImageName: img) else { return nil }
        let clade = group.rawValue
        return shippedClades.contains(clade) ? clade : nil
    }

    static func nestingFallback(forClade clade: String) -> String {
        if let group = PterosaurGuessGroup(rawValue: clade) {
            return "\(group.displayName) nest"
        }
        return clade.replacingOccurrences(of: "-", with: " ").capitalized + " nest"
    }

    static let morphology = EggsMorphology(
        assetPrefix: "ptero-eggs",
        nestAssetPrefix: "ptero-nests",
        scannerToolPrefix: "dino-eggs",
        eggType: { PteroEggMorphology.eggType(for: $0) },
        nestingStyle: { eggType in eggType },
        nestingFallbackText: { PteroEggMorphology.nestingFallback(forClade: $0) },
        scanAssetName: { clade in "ptero-eggs-\(clade)" },
        randomColorsAsset: { clade in
            let name = "ptero-eggs-\(clade)"
            return ImageAssetCache.imageExists(named: name) ? name : nil
        }
    )

    static let settings = EggsGameSettings(
        morphology: morphology,
        gameKeyPrefix: "game-ptero-eggs",
        gameplayDirectionsAudioKey: "game-ptero-eggs-gameplay-directions",
        gameplayDirectionsFallback: "Pterosaur eggs can be soft and oddly shaped. When you see the egg, tap the CT scanner to look inside, then tap the pterosaur that laid the egg.",
        beepKey: "game-dino-eggs-beep",
        scanFailedKey: "game-dino-eggs-scan-failed",
        tapCreatureKey: "game-dino-eggs-tap-the-dinosaur",
        successImageName: "game-ptero-eggs-success",
        creatureEmoji: "🦅",
        roundIntroNestAudioKey: nil,
        roundIntroTapScannerAudioKey: nil,
        onVictoryComplete: { PterosaurProgress.notifyCompletionIfPterosaurGame(configId: $0) }
    )
}

// MARK: - Game config

struct PteroEggsGameConfigs {
    private static let pteroEggsRoundCount = 1

    static var pteroEggs: PteroEggsGameConfig {
        let pool = pterosaursWithPortraitAndEgg
        let groupById: [Int: PterosaurGuessGroup] = Dictionary(
            uniqueKeysWithValues: pool.compactMap { p in
                guard let img = p.imageName, let g = PterosaurGuessGroup.guessGroup(forImageName: img) else { return nil }
                return (p.id, g)
            }
        )
        let byGroup = Dictionary(grouping: pool) { groupById[$0.id] ?? .basal }
        let allGroups = Array(byGroup.keys).filter { !(byGroup[$0] ?? []).isEmpty }
        var usedIds: Set<Int> = []
        var rounds: [PteroEggsRound] = []

        for roundId in 1...pteroEggsRoundCount {
            let availableGroups = allGroups.filter { group in
                (byGroup[group] ?? []).contains { p in
                    guard !usedIds.contains(p.id), let clade = PteroEggMorphology.eggType(for: p) else { return false }
                    return eggAndNestReady(clade: clade)
                }
            }
            guard let chosenGroup = availableGroups.randomElement() else { break }
            let groupPool = (byGroup[chosenGroup] ?? []).filter { p in
                guard !usedIds.contains(p.id), let clade = PteroEggMorphology.eggType(for: p) else { return false }
                return eggAndNestReady(clade: clade)
            }
            guard let correct = groupPool.randomElement(),
                  let clade = PteroEggMorphology.eggType(for: correct) else { break }

            let distractorPool = pterosaursForDistractors(excludingGroup: chosenGroup)
                .filter { !usedIds.contains($0.id) && $0.id != correct.id }
            let distractors = Array(distractorPool.shuffled().prefix(2))
            guard distractors.count == 2 else { continue }

            usedIds.insert(correct.id)
            usedIds.formUnion(distractors.map(\.id))
            rounds.append(PteroEggsRound(
                id: roundId,
                correctCreature: correct,
                eggType: clade,
                nestingStyle: clade,
                distractors: distractors
            ))
        }

        guard rounds.count >= pteroEggsRoundCount else {
            fatalError("Need at least \(pteroEggsRoundCount) rounds for Ptero Eggs (pool has \(pool.count) pterosaurs with egg+nest art)")
        }

        return PteroEggsGameConfig(
            settings: PteroEggMorphology.settings,
            totalRounds: pteroEggsRoundCount,
            id: "ptero-eggs",
            title: "Ptero Eggs!",
            introAudio: "game-ptero-eggs",
            gameplayDirectionsAudio: "game-ptero-eggs-gameplay-directions",
            rounds: Array(rounds.prefix(pteroEggsRoundCount))
        )
    }

    private static func eggAndNestReady(clade: String) -> Bool {
        let m = PteroEggMorphology.morphology
        return ImageAssetCache.imageExists(named: m.eggImageName(eggType: clade))
            && ImageAssetCache.imageExists(named: m.nestingImageName(style: clade))
    }

    private static var pterosaursWithPortraitAndEgg: [Dinosaur] {
        basePterosaurs(allowedGroups: nil)
    }

    private static func pterosaursForDistractors(excludingGroup excluded: PterosaurGuessGroup) -> [Dinosaur] {
        basePterosaurs(allowedGroups: nil).filter { p in
            guard let img = p.imageName, let g = PterosaurGuessGroup.guessGroup(forImageName: img) else { return true }
            return g != excluded
        }
    }

    private static func basePterosaurs(allowedGroups: Set<PterosaurGuessGroup>?) -> [Dinosaur] {
        MatchingGameConfigs.allPterosaurs.filter { p in
            guard let img = p.imageName, img.hasPrefix("ptero-") else { return false }
            guard ImageAssetCache.imageExists(named: img) else { return false }
            if let allowed = allowedGroups,
               let g = PterosaurGuessGroup.guessGroup(forImageName: img),
               !allowed.contains(g) { return false }
            guard let clade = PteroEggMorphology.eggType(for: p) else { return false }
            return eggAndNestReady(clade: clade)
        }
    }
}
