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

    /// Species slug in `marine-matrix-{material}-{slug}` from `marine-{clade}-{species}` image names.
    nonisolated static func matrixFossilSlug(for creature: Dinosaur) -> String? {
        guard let name = creature.imageName else { return nil }
        let parts = name.split(separator: "-", omittingEmptySubsequences: true)
        guard parts.count >= 3, parts[0] == "marine" else { return nil }
        let slug = parts.dropFirst(2).joined(separator: "-")
        return slug.isEmpty ? nil : slug
    }

    /// Diet option labels for Marine Diets! (five right-column choices every round).
    static let marineDietTypes = ["Herbivore", "Piscivore", "Apex Predator", "Durophage", "Teuthivore"]

    /// Diet per marine reptile for Marine Diets! (built from `allMarineReptiles` at first use).
    static let marineReptileDietById: [Int: String] = {
        Dictionary(uniqueKeysWithValues: allMarineReptiles.map { ($0.id, diet(for: $0)) })
    }()

    /// Asset/audio slug for a diet label (e.g. Apex Predator → apex-predator).
    static func dietAssetSlug(for dietType: String) -> String {
        switch dietType {
        case "Apex Predator": return "apex-predator"
        case "Durophage": return "durophage"
        case "Herbivore": return "herbivore"
        case "Piscivore": return "piscivore"
        case "Teuthivore": return "teuthivore"
        default:
            return dietType.lowercased().replacingOccurrences(of: " ", with: "-")
        }
    }

    /// Spoken diet name under `Audio/Marine-Diets/marine-diets-{slug}.m4a` (TTS fallback when missing).
    static func dietAudioKey(for dietType: String) -> String {
        "marine-diets-\(dietAssetSlug(for: dietType))"
    }

    /// Inferred diet from clade and species slug (educational defaults for the matching game).
    static func diet(for creature: Dinosaur) -> String {
        let slug = matrixFossilSlug(for: creature) ?? ""
        if durophageSlugs.contains(slug) { return "Durophage" }
        if herbivoreSlugs.contains(slug) { return "Herbivore" }
        if teuthivoreSlugs.contains(slug) { return "Teuthivore" }
        if apexPredatorSlugs.contains(slug) { return "Apex Predator" }

        switch marineCladeRawValue(for: creature) {
        case "testu": return "Herbivore"
        case "teleo": return "Piscivore"
        case "mosa", "plio", "pliop", "tylo": return "Apex Predator"
        case "ichthyo": return "Piscivore"
        case "plesio", "notho", "hali", "thala": return "Piscivore"
        case "basal": return slug == "mesosaurus" ? "Herbivore" : "Piscivore"
        default: return "Piscivore"
        }
    }

    private static let durophageSlugs: Set<String> = [
        "globidens", "carinodens", "placodus", "gavialimimus", "khinjaria", "pannoniasaurus",
    ]
    private static let herbivoreSlugs: Set<String> = [
        "archelon", "protostega", "mesosaurus", "hupehsuchus", "attenborosaurus", "henodus",
    ]
    private static let teuthivoreSlugs: Set<String> = [
        "temnodontosaurus", "ophthalmosaurus", "eurhinosaurus", "platypterygius", "grendelius",
        "stenopterygius", "mixosaurus",
    ]
    private static let apexPredatorSlugs: Set<String> = [
        "mosasaurus", "tylosaurus", "hainosaurus", "liopleurodon", "kronosaurus", "pliosaurus",
        "thalassomedon", "shastasaurus", "shonisaurus", "cymbospondylus", "clidastes",
        "megacephalosaurus", "macrospondylus", "brachauchenius",
    ]

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

    // MARK: - Marine Ages (Jurassic / Cretaceous)

    enum MesozoicSpan {
        case jurassic
        case cretaceous
        case both
    }

    /// Species-level overrides for Marine Ages period sorting (image-name slug after `marine-{group}-`).
    private static let marineAgesJurassicSlugs: Set<String> = [
        "aigialosaurus", "dallasaurus", "proganochelys",
        "attenborosaurus", "cryptoclidus", "hauffiosaurus", "hydrotherosaurus",
        "microcleidus", "muraenosaurus", "plesiosaurus", "rhomaleosaurus",
        "brachypterygius", "cymbospondylus", "ichthyosaurus", "kyhytysuka",
        "malawania", "mixosaurus", "shastasaurus", "shonisaurus",
        "dolichosaurus", "hupehsuchus", "judeasaurus", "mesoleptos", "mesosaurus", "tanystropheus",
        "henodus", "nothosaurus", "placodus",
        "dakosaurus", "metriorhynchus", "steneosaurus",
        "brachauchenius", "kronosaurus", "liopleurodon", "megacephalosaurus", "pliosaurus",
    ]

    private static let marineAgesCretaceousSlugs: Set<String> = [
        "aphrosaurus", "dolichorhynchops", "elasmosaurus", "mauisaurus", "polycotylus",
        "styxosaurus", "thalassomedon", "woolungasaurus",
        "caypullisaurus", "eurhinosaurus", "grendelius", "ophthalmosaurus",
        "platypterygius", "stenopterygius", "temnodontosaurus",
        "archelon", "protostega",
        "clidastes", "gavialimimus", "globidens", "hainosaurus", "khinjaria",
        "megapterygius", "mosasaurus", "pannoniasaurus", "plotosaurus", "prognathodon",
        "thalassotitan", "xenodens",
        "halisaurus", "phosphosaurus", "pluridens",
        "platecarpus", "plioplatecarpus", "yaguarasaurus",
        "kaikaifilu", "taniwhasaurus",
        "enchodus", "gillicus", "xiphactinus",
    ]

    /// Jurassic vs Cretaceous for Marine Ages! (same two-period model as Dino/Ptero Ages).
    static func mesozoicSpanForAges(creature: Dinosaur) -> MesozoicSpan? {
        guard let slug = matrixFossilSlug(for: creature) else { return nil }
        if marineAgesCretaceousSlugs.contains(slug) { return .cretaceous }
        if marineAgesJurassicSlugs.contains(slug) { return .jurassic }
        switch marineCladeRawValue(for: creature) {
        case "mosa", "pliop", "tylo", "hali", "teleo": return .cretaceous
        case "notho", "thala", "plio": return .jurassic
        case "plesio", "ichthyo", "basal": return .jurassic
        case "testu": return .cretaceous
        default: return .jurassic
        }
    }

    // MARK: - Racing Marine Reptiles

    struct MarineRacingPoolEntry {
        let creature: Dinosaur
        let speed: Double
        let icon: String
        /// `marine-racer-*` / `marine-racing-*` base when a dedicated pack exists; nil uses catalog body image.
        let racingAssetBase: String?
    }

    private struct MarineRacingCatalogEntry {
        let slug: String
        let mesozoicSpan: MesozoicSpan
    }

    /// Curated playable slugs for Racing Marine Reptiles (Jurassic / Cretaceous only; Permian/Triassic excluded).
    private static let marineRacingCatalog: [MarineRacingCatalogEntry] = [
        MarineRacingCatalogEntry(slug: "dakosaurus", mesozoicSpan: .jurassic),
        MarineRacingCatalogEntry(slug: "ichthyosaurus", mesozoicSpan: .jurassic),
        MarineRacingCatalogEntry(slug: "plesiosaurus", mesozoicSpan: .jurassic),
        MarineRacingCatalogEntry(slug: "pliosaurus", mesozoicSpan: .jurassic),
        MarineRacingCatalogEntry(slug: "platypterygius", mesozoicSpan: .jurassic),
        MarineRacingCatalogEntry(slug: "brachypterygius", mesozoicSpan: .jurassic),
        MarineRacingCatalogEntry(slug: "archelon", mesozoicSpan: .cretaceous),
        MarineRacingCatalogEntry(slug: "elasmosaurus", mesozoicSpan: .cretaceous),
        MarineRacingCatalogEntry(slug: "halisaurus", mesozoicSpan: .cretaceous),
        MarineRacingCatalogEntry(slug: "mosasaurus", mesozoicSpan: .cretaceous),
        MarineRacingCatalogEntry(slug: "platecarpus", mesozoicSpan: .cretaceous),
        MarineRacingCatalogEntry(slug: "tylosaurus", mesozoicSpan: .cretaceous),
    ]

    /// Permian / Triassic catalog species with racer art are excluded from the Mesozoic racing pools.
    static let marineRacingExcludedSlugs: Set<String> = ["mesosaurus", "nothosaurus"]

    static func mesozoicSpanForRacing(slug: String) -> MesozoicSpan? {
        guard !marineRacingExcludedSlugs.contains(slug) else { return nil }
        return marineRacingCatalog.first { $0.slug == slug }?.mesozoicSpan
    }

    private static func marineCreature(forRacingSlug slug: String) -> Dinosaur? {
        allMarineReptiles.first { matrixFossilSlug(for: $0) == slug }
    }

    /// Builds `marine-racer-{slug}` (preferred) or legacy `marine-racer-{group}-{slug}` / `marine-racing-{group}-{slug}` from catalog body keys.
    static func marineRacingAssetBase(fromCatalogImageName imageName: String) -> String? {
        let parts = imageName.split(separator: "-").map(String.init)
        guard parts.count >= 3, parts[0].lowercased() == "marine" else { return nil }
        let group = parts[1].lowercased()
        let tail = parts.dropFirst(2).joined(separator: "-").lowercased()
        guard !group.isEmpty, !tail.isEmpty else { return nil }
        let candidates = [
            "marine-racer-\(tail)",
            "marine-racer-\(group)-\(tail)",
            "marine-racing-\(group)-\(tail)",
        ]
        let known = ImageAssetNames.knownAssets
        return candidates.first { base in
            known.contains(base + "-ready")
                || known.contains(base + "-finished-excited")
                || known.contains(base + "-run")
                || known.contains(base)
        }
    }

    /// Racing Marine Reptiles requires ready + finished excited/exhausted poses (run/trip fall back to ready when missing).
    static func hasCompleteMarineRacingAssetPack(base: String) -> Bool {
        guard ImageAssetCache.imageExists(named: base + "-ready") else { return false }
        let hasExcited = ImageAssetCache.imageExists(named: base + "-finished-excited")
            || ImageAssetCache.imageExists(named: base + "-finish-excited")
        let hasExhausted = ImageAssetCache.imageExists(named: base + "-finished-exhausted")
            || ImageAssetCache.imageExists(named: base + "-finish-exhausted")
        return hasExcited && hasExhausted
    }

    /// Educational speed estimates in mph for marine racing pool entries.
    private static func marineRacingSpeedEstimate(slug: String) -> Double {
        switch slug {
        case "ichthyosaurus", "platypterygius", "brachypterygius": return 35
        case "mosasaurus", "tylosaurus": return 28
        case "platecarpus": return 24
        case "kronosaurus", "halisaurus": return 22
        case "dakosaurus", "pliosaurus", "liopleurodon": return 18
        case "plesiosaurus": return 14
        case "elasmosaurus": return 12
        case "archelon": return 6
        default: return 15
        }
    }

    private static func marineRacingIcon(slug: String) -> String {
        switch slug {
        case "mosasaurus", "tylosaurus", "platecarpus", "halisaurus": return "🐋"
        case "elasmosaurus", "plesiosaurus": return "🦕"
        case "ichthyosaurus", "platypterygius", "brachypterygius": return "🐬"
        case "pliosaurus", "dakosaurus", "kronosaurus": return "🦈"
        case "archelon": return "🐢"
        case "liopleurodon": return "🐊"
        default: return "🌊"
        }
    }

    /// Pool for Racing Marine Reptiles: curated Mesozoic catalog entries with a complete bundled `marine-racer-{slug}-*` pack.
    static func marineRacersForRacing(mesozoicSpan period: MesozoicSpan) -> [MarineRacingPoolEntry] {
        marineRacingCatalog.compactMap { entry in
            let inPeriod: Bool = switch period {
            case .jurassic: entry.mesozoicSpan == .jurassic
            case .cretaceous: entry.mesozoicSpan == .cretaceous
            case .both: true
            }
            guard inPeriod,
                  let creature = marineCreature(forRacingSlug: entry.slug),
                  let imageName = creature.imageName,
                  ImageAssetCache.imageExists(named: imageName),
                  let base = marineRacingAssetBase(fromCatalogImageName: imageName),
                  hasCompleteMarineRacingAssetPack(base: base) else { return nil }
            return MarineRacingPoolEntry(
                creature: creature,
                speed: marineRacingSpeedEstimate(slug: entry.slug),
                icon: marineRacingIcon(slug: entry.slug),
                racingAssetBase: base
            )
        }
    }
}
