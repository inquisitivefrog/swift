//
//  SeaMarineReptileData.swift
//  DinoGames
//
//  Sea (marine reptile) creature pool for Name That Marine Reptile and other games. Built from bundled
//  `marine-<group>-<slug>` body imagesets that have a matching `marine-<group>-silhouette-<slug>` so the
//  catalog grows automatically when new paired assets ship (same idea as `ImageAssetNames` elsewhere).
//

import Foundation

enum SeaMarineReptileData {
    /// All marine creatures with both base + silhouette assets in `ImageAssetNames.knownAssets`.
    static let allMarineReptiles: [Dinosaur] = {
        let allAssets = Set(ImageAssetNames.knownAssets)
        let baseAssets = allAssets
            .filter { assetName in
                guard assetName.hasPrefix("marine-"), !assetName.contains("-silhouette-"), !assetName.hasPrefix("marine-level-") else { return false }
                let parts = assetName.split(separator: "-", omittingEmptySubsequences: true)
                guard parts.count >= 3 else { return false }
                let silhouetteName = "marine-\(parts[1])-silhouette-\(parts.dropFirst(2).joined(separator: "-"))"
                return allAssets.contains(silhouetteName)
            }
            .sorted()
        return baseAssets.enumerated().map { index, assetName in
            Dinosaur(
                id: 2000 + index,
                name: displayName(from: assetName),
                icon: "🌊",
                imageName: assetName,
                characteristicIds: []
            )
        }
    }()

    private static func displayName(from imageName: String) -> String {
        let parts = imageName.split(separator: "-", omittingEmptySubsequences: true)
        guard parts.count >= 3 else { return imageName }
        return parts
            .dropFirst(2)
            .map { token in
                let lower = token.lowercased()
                return lower.prefix(1).uppercased() + lower.dropFirst()
            }
            .joined(separator: " ")
    }

    /// Maps `marine-<group>-*` segment (e.g. `mosa`) to spoken-name audio stem under `Marine-Reptile-Clades/clade-{stem}.m4a`.
    static func audioSlugForMarineGroupRaw(_ raw: String) -> String {
        switch raw.lowercased() {
        case "mosa": return "mosasaur"
        case "plesio": return "plesiosaur"
        case "ichthyo": return "ichthyosaur"
        case "plio": return "pliosaur"
        case "pliop": return "plioplatecarp"
        case "hali": return "halisaur"
        case "notho": return "nothosaur"
        case "thala": return "thalattosuchia"
        case "tylo": return "tylosaur"
        case "teleo": return "teleostei"
        case "testu": return "testudine"
        default:
            return raw.lowercased()
        }
    }

    /// Marine group segment from `marine-<group>-…` image names (e.g. `mosa`, `plesio`).
    static func marineCladeRawValue(for creature: Dinosaur) -> String {
        guard let name = creature.imageName else { return "mosa" }
        let parts = name.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count >= 3, parts[0] == "marine" else { return "mosa" }
        return String(parts[1])
    }

    /// Short UI label for the `marine-<group>-*` segment (puzzle rounds, etc.).
    static func displayTitleForMarineGroup(_ raw: String) -> String {
        switch raw.lowercased() {
        case "mosa": return "Mosasaur"
        case "plesio": return "Plesiosaur"
        case "ichthyo": return "Ichthyosaur"
        case "plio": return "Pliosaur"
        case "pliop": return "Plioplatecarpine"
        case "hali": return "Halisaur"
        case "notho": return "Nothosaur"
        case "thala": return "Thalattosuchian"
        case "tylo": return "Tylosaur"
        case "teleo": return "Teleost fish"
        case "testu": return "Sea turtle"
        case "basal": return "Basal"
        default:
            return raw.replacingOccurrences(of: "-", with: " ").capitalized
        }
    }

    static func marineBodyImagePrefix(for creature: Dinosaur) -> String {
        "marine-\(marineCladeRawValue(for: creature))-"
    }

    /// Two wrong options from different marine groups when possible (same idea as land clades / pterosaur guess groups).
    static func pickTwoDecoysDistinctMarineClades(question: Dinosaur, pool: [Dinosaur]) -> [Dinosaur] {
        let questionClade = marineCladeRawValue(for: question)
        let decoyCandidates = pool.filter { d in
            d.id != question.id && marineCladeRawValue(for: d) != questionClade
        }
        if decoyCandidates.count >= 2 {
            let byCladeForDecoys = Dictionary(grouping: decoyCandidates) { marineCladeRawValue(for: $0) }
            let otherClades = byCladeForDecoys.keys.filter { $0 != questionClade }.shuffled()
            if otherClades.count >= 2 {
                let firstDecoy = (byCladeForDecoys[otherClades[0]] ?? []).shuffled().first!
                let secondCladeCandidates = decoyCandidates.filter { marineCladeRawValue(for: $0) != otherClades[0] }
                let secondDecoy = secondCladeCandidates.shuffled().first!
                return [firstDecoy, secondDecoy]
            }
            return Array(decoyCandidates.shuffled().prefix(2))
        }
        let fallbackCandidates = pool.filter { $0.id != question.id }
        guard fallbackCandidates.count >= 2 else {
            fatalError("Not enough marine reptiles for decoys")
        }
        return Array(fallbackCandidates.shuffled().prefix(2))
    }
}
