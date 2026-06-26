//
//  MarineSmileMorphology.swift
//  DinoGames
//
//  Marine Smile!: smiling portrait → tooth type (crusher, needle-spike, slicer).
//  Portrait art: `marine-smile-{slug}`. Reference tooth art: `marine-smile-{type}-{exampleSlug}`.
//

import Foundation

enum MarineSmileToothType: String, CaseIterable, Equatable {
    case crusher
    case needleSpike = "needle-spike"
    case slicer

    var displayName: String {
        switch self {
        case .crusher: return "Crusher"
        case .needleSpike: return "Needle Spike"
        case .slicer: return "Slicer"
        }
    }

    /// Asset stem for the bundled reference tooth (`marine-smile-{stem}-…`).
    var referenceToothStem: String {
        switch self {
        case .crusher: return "crusher-globidens"
        case .needleSpike: return "grabber-elasmosaurus"
        case .slicer: return "slicer-mosasaurus"
        }
    }

    /// Narration key under `Audio/Marine-Smile/` when bundled.
    var toothAudioKey: String {
        switch self {
        case .crusher: return "marine-smile-crusher"
        case .needleSpike: return "marine-smile-grabber"
        case .slicer: return "marine-smile-slicer"
        }
    }
}

enum MarineSmileMorphology {
    /// Species slugs with smiling portrait art under `images/marine-smile/animals/{type}/`.
    static let slugsByToothType: [MarineSmileToothType: [String]] = [
        .crusher: [
            "archelon", "globidens", "henodus", "placodus", "proganochelys", "protostega", "xenodens",
        ],
        .needleSpike: [
            "aphrosaurus", "cryptoclidus", "dallasaurus", "dolichorhynchops", "dolichosaurus", "elasmosaurus",
            "eurhinosaurus", "gavialimimus", "gendelius", "gillicus", "halisaurus", "hauffiosaurus",
            "hupenhsuchus", "hydrotherosaurus", "ichthyosaurus", "judeasaurus", "malawania", "mauisaurus",
            "microcleidus", "muraenosaurus", "nothosaurus", "ophthalmosaurus", "peloneustes", "plesiosaurus",
            "plioplatecarpus", "polycotylus", "shastasaurus", "stenopterygius", "styxosaurus", "taniwhasaurus",
            "tanystropheus", "temnodontosaurus", "thalassomedon", "woolungasaurus",
        ],
        .slicer: [
            "aigialosaurus", "attenborosaurus", "brachauchenius", "brachypterygius", "caypullisaurus", "clidastes",
            "cymbospondylus", "dakosaurus", "enchodus", "hainosaurus", "kaikaifilu", "khinjaria", "kronosaurus",
            "kyhytysuka", "liopleurodon", "mesoleptos", "mesosaurus", "metriorhynchus", "mixosaurus", "mosasaurus",
            "pannoniasaurus", "phosphosaurus", "platecarpus", "platypterygius", "pliosaurus", "plotosaurus",
            "pluridens", "prognathodon", "rhomaleosaurus", "sachicasaurus", "simolestes", "steneosaurus",
            "thalassotitan", "tylosaurus", "xiphactinus", "yaguarasaurus",
        ],
    ]

    /// Catalog imageset typo: disk slug `plioplatecarpus` ships as `marine-smile-pllioplatecarpus`.
    private static let portraitAssetSlugAliases: [String: String] = [
        "plioplatecarpus": "pllioplatecarpus",
    ]

    static func toothType(forSlug slug: String) -> MarineSmileToothType? {
        for (type, slugs) in slugsByToothType where slugs.contains(slug) {
            return type
        }
        return nil
    }

    static func displayName(forSlug slug: String) -> String {
        slug
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { word in
                let lower = word.lowercased()
                return lower.prefix(1).uppercased() + lower.dropFirst()
            }
            .joined(separator: " ")
    }

    static func smilePortraitAssetName(forSlug slug: String) -> String? {
        let candidates = [slug, portraitAssetSlugAliases[slug]].compactMap { $0 }
        for candidate in candidates {
            let name = "marine-smile-\(candidate)"
            if ImageAssetCache.imageExists(named: name), !isReferenceToothAsset(name) {
                return name
            }
        }
        return nil
    }

    static func referenceToothImageName(for type: MarineSmileToothType) -> String? {
        let stem = type.referenceToothStem
        let direct = "marine-smile-\(stem)"
        if ImageAssetCache.imageExists(named: direct) { return direct }
        let variants = (1...4).map { "marine-smile-\(stem)-v\($0)" }
        return variants.first { ImageAssetCache.imageExists(named: $0) }
    }

    static var playableCreatures: [Dinosaur] {
        var creatures: [Dinosaur] = []
        var nextId = 5000
        for type in MarineSmileToothType.allCases {
            for slug in slugsByToothType[type] ?? [] {
                guard let asset = smilePortraitAssetName(forSlug: slug) else { continue }
                creatures.append(
                    Dinosaur(
                        id: nextId,
                        name: displayName(forSlug: slug),
                        icon: "😁",
                        imageName: asset,
                        characteristicIds: []
                    )
                )
                nextId += 1
            }
        }
        return creatures
    }

    static func toothType(for creature: Dinosaur) -> MarineSmileToothType? {
        guard let imageName = creature.imageName else { return nil }
        let slug = imageName.replacingOccurrences(of: "marine-smile-", with: "")
        for (registrySlug, alias) in portraitAssetSlugAliases where alias == slug {
            return toothType(forSlug: registrySlug)
        }
        return toothType(forSlug: slug)
    }

    static func creaturesByToothType(in pool: [Dinosaur]) -> [MarineSmileToothType: [Dinosaur]] {
        Dictionary(grouping: pool.compactMap { creature -> (MarineSmileToothType, Dinosaur)? in
            guard let type = toothType(for: creature) else { return nil }
            return (type, creature)
        }) { $0.0 }
            .mapValues { $0.map(\.1) }
    }

    static func pickTwoDecoysOtherToothTypes(
        correct: Dinosaur,
        poolByType: [MarineSmileToothType: [Dinosaur]],
        excludedIds: Set<Int>
    ) -> [Dinosaur] {
        guard let questionType = toothType(for: correct) else { return [] }
        let otherTypes = MarineSmileToothType.allCases.filter { $0 != questionType }
        var decoys: [Dinosaur] = []
        var excluded = excludedIds
        for type in otherTypes {
            let candidates = (poolByType[type] ?? []).filter { !excluded.contains($0.id) }
            guard let pick = candidates.shuffled().first else { return [] }
            decoys.append(pick)
            excluded.insert(pick.id)
        }
        return decoys
    }

    static var isPlayable: Bool {
        GuessGameConfigs.makeMarineSmile() != nil
    }

    private static func isReferenceToothAsset(_ name: String) -> Bool {
        for type in MarineSmileToothType.allCases {
            if name.hasPrefix("marine-smile-\(type.referenceToothStem)") { return true }
        }
        return false
    }
}
