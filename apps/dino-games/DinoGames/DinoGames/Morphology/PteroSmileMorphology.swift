//
//  PteroSmileMorphology.swift
//  DinoGames
//
//  Pterosaur portrait → beak/tooth shape mapping for Ptero Smile!
//  Morphology families: json/ptero-smile/teeth/README.teeth.md (14 categories).
//  Portrait→tooth pairing follows bundled art (tooth JSON prompts name the depicted species),
//  which can differ from README line assignments when assets were generated out of sync.
//  Portrait art: ptero-smile-{slug}. Tooth art: ptero-smile-tooth-{toothSlug}.
//  Pre-reader labels/audio: simple player-facing words (Beak, Fang, Peg, …).
//

import Foundation

/// Short words for narration and on-screen fallback text (pre-readers).
enum PteroSmilePlayerToothKind: String, CaseIterable {
    case beak
    case spear
    case stub
    case fang
    case peg
    case comb
    case scoop
    case clip
    case pin
    case tweezers
    case pincer
    case saw

    var displayLabel: String { rawValue.capitalized }

    /// Target clip name: `ptero-smile-beak.m4a` under `Audio/Ptero-Smile/`.
    var audioKey: String { "ptero-smile-\(rawValue)" }

    /// Legacy morphology-family clips shipped before the 14-category refactor.
    var legacyAudioKey: String? {
        switch self {
        case .beak: return "ptero-smile-toothless-beak"
        case .fang: return "ptero-smile-needle-spike"
        case .peg: return "ptero-smile-peg-slicer"
        case .pin: return "ptero-smile-micro-peg"
        case .comb: return "ptero-smile-comb-filter"
        case .scoop: return "ptero-smile-fruit-nut-cracker"
        default: return nil
        }
    }
}

enum PteroSmileMorphology {
    /// Fourteen morphology families (matches json/ptero-smile folder names).
    static let allCategorySlugs: [String] = [
        "hyper-elongated-spears",
        "heavy-impact-wedges",
        "classic-pelican-style",
        "crested-blade-specialists",
        "rapid-snapping-predators",
        "needle-comb-filterers",
        "micro-insect-trappers",
        "fruit-herbaceous-cutters",
        "scoop-tweezers-specialists",
        "crushers-peg-specialists",
        "precision-shearing-clips",
        "interlocking-grapplers",
        "raptor-cage-hunters",
        "high-utility-skimmers",
    ]

    private struct SpeciesEntry {
        let categorySlug: String
        let toothSlug: String
        let playerKind: PteroSmilePlayerToothKind
    }

    /// Species slug (`AirPterosaurData.matrixFossilSlug`) → morphology family + bundled tooth art slug.
    private static let entryByPortraitSlug: [String: SpeciesEntry] = [
        "anhanguera": .init(categorySlug: "classic-pelican-style", toothSlug: "fish-cage-fangs", playerKind: .fang),
        "anurognathus": .init(categorySlug: "interlocking-grapplers", toothSlug: "miniature-insect-trap-pins", playerKind: .pin),
        "arambourgiania": .init(categorySlug: "hyper-elongated-spears", toothSlug: "ultra-elongated-spear", playerKind: .spear),
        "bakonydraco": .init(categorySlug: "fruit-herbaceous-cutters", toothSlug: "tapered-v-crested-blade", playerKind: .beak),
        "bangiadraco": .init(categorySlug: "classic-pelican-style", toothSlug: "notched-crested-beak", playerKind: .beak),
        "boreopterus": .init(categorySlug: "rapid-snapping-predators", toothSlug: "needle-cage-braces", playerKind: .fang),
        "caiuajara": .init(categorySlug: "fruit-herbaceous-cutters", toothSlug: "deep-down-turned-scoop", playerKind: .scoop),
        "campylognathoides": .init(categorySlug: "crushers-peg-specialists", toothSlug: "curved-forward-grapplers", playerKind: .pincer),
        "caupedactylus": .init(categorySlug: "precision-shearing-clips", toothSlug: "straight-slicing-shears", playerKind: .clip),
        "coloborhynchus": .init(categorySlug: "heavy-impact-wedges", toothSlug: "crested-terminal-spikes", playerKind: .fang),
        "cryodrakon": .init(categorySlug: "heavy-impact-wedges", toothSlug: "stout-spear-beak", playerKind: .stub),
        "ctenochasma": .init(categorySlug: "needle-comb-filterers", toothSlug: "comb-needles", playerKind: .comb),
        "darwinopterus": .init(categorySlug: "interlocking-grapplers", toothSlug: "spaced-raptor-fangs", playerKind: .fang),
        "dimorphodon": .init(categorySlug: "rapid-snapping-predators", toothSlug: "dual-type-pincers", playerKind: .pincer),
        "dsungaripterus": .init(categorySlug: "crushers-peg-specialists", toothSlug: "pebble-crushers", playerKind: .peg),
        "eudimorphodon": .init(categorySlug: "precision-shearing-clips", toothSlug: "multi-cusped-saws", playerKind: .saw),
        "gnathosaurus": .init(categorySlug: "needle-comb-filterers", toothSlug: "filter-tooth-field", playerKind: .comb),
        "guidraco": .init(categorySlug: "rapid-snapping-predators", toothSlug: "tangled-interlocking-spikes", playerKind: .fang),
        "hatzegopteryx": .init(categorySlug: "heavy-impact-wedges", toothSlug: "heavy-axe-beak", playerKind: .beak),
        "istiodactylus": .init(categorySlug: "precision-shearing-clips", toothSlug: "duck-razor-bill", playerKind: .clip),
        "jeholopterus": .init(categorySlug: "micro-insect-trappers", toothSlug: "vampire-insect-needles", playerKind: .pin),
        "kariridraco": .init(categorySlug: "scoop-tweezers-specialists", toothSlug: "up-turned-tweezers", playerKind: .tweezers),
        "kunpengopterus": .init(categorySlug: "micro-insect-trappers", toothSlug: "curved-grasping-pins", playerKind: .pin),
        "ludodactylus": .init(categorySlug: "classic-pelican-style", toothSlug: "barbed-spear-tip", playerKind: .beak),
        "nemicolopterus": .init(categorySlug: "micro-insect-trappers", toothSlug: "microscopic-needle-pin", playerKind: .pin),
        "noripterus": .init(categorySlug: "crushers-peg-specialists", toothSlug: "shell-crushing-pegs", playerKind: .peg),
        "nyctosaurus": .init(categorySlug: "raptor-cage-hunters", toothSlug: "hyper-slender-razor-needles", playerKind: .pin),
        "ornithocheirus": .init(categorySlug: "crested-blade-specialists", toothSlug: "spoon-tipped-fangs", playerKind: .fang),
        "pteranodon": .init(categorySlug: "high-utility-skimmers", toothSlug: "classic-pelican-javelin", playerKind: .spear),
        "pterodactylus": .init(categorySlug: "raptor-cage-hunters", toothSlug: "slender-conical-snappers", playerKind: .fang),
        "pterodaustro": .init(categorySlug: "needle-comb-filterers", toothSlug: "baleen-comb", playerKind: .comb),
        "quetzalcoatlus": .init(categorySlug: "hyper-elongated-spears", toothSlug: "spear-beak", playerKind: .beak),
        "rhamphorhynchus": .init(categorySlug: "interlocking-grapplers", toothSlug: "forward-protruding-spikes", playerKind: .fang),
        "scaphognathus": .init(categorySlug: "rapid-snapping-predators", toothSlug: "spaced-vertical-pegs", playerKind: .peg),
        "sinopterus": .init(categorySlug: "scoop-tweezers-specialists", toothSlug: "pointed-fruit-cutter", playerKind: .clip),
        "sordes": .init(categorySlug: "raptor-cage-hunters", toothSlug: "fish-cage-fangs", playerKind: .fang),
        "tapejara": .init(categorySlug: "fruit-herbaceous-cutters", toothSlug: "spatula-spoon", playerKind: .scoop),
        "thalassodromeus": .init(categorySlug: "crested-blade-specialists", toothSlug: "tapered-v-crested-blade", playerKind: .beak),
        "thanatosdrakon": .init(categorySlug: "hyper-elongated-spears", toothSlug: "colossal-predatory-wedge", playerKind: .spear),
        "tropeognathus": .init(categorySlug: "crested-blade-specialists", toothSlug: "double-crested-fish-snappers", playerKind: .fang),
        "tupandactylus": .init(categorySlug: "scoop-tweezers-specialists", toothSlug: "deep-rounded-clip", playerKind: .scoop),
        "tupuxuara": .init(categorySlug: "high-utility-skimmers", toothSlug: "deep-sub-terminal-notch", playerKind: .clip),
        "wukongopterus": .init(categorySlug: "micro-insect-trappers", toothSlug: "rhythmic-grasping-spikes", playerKind: .peg),
        "zhejiangopterus": .init(categorySlug: "high-utility-skimmers", toothSlug: "slender-javelin-bill", playerKind: .pin),
        "anuanguera": .init(categorySlug: "classic-pelican-style", toothSlug: "fish-cage-fangs", playerKind: .fang),
    ]

    /// Bundled portrait imageset slug when it differs from matrix fossil slug.
    private static let portraitAssetSlugAliases: [String: String] = [
        "anhanguera": "anuanguera",
    ]

    private static let playerKindByToothSlug: [String: PteroSmilePlayerToothKind] = {
        var map: [String: PteroSmilePlayerToothKind] = [:]
        for entry in entryByPortraitSlug.values {
            map[entry.toothSlug] = entry.playerKind
        }
        return map
    }()

    static var allPlayerToothKinds: [PteroSmilePlayerToothKind] {
        PteroSmilePlayerToothKind.allCases
    }

    /// Unique README tooth slugs (43; nemicolopterus and wukongopterus share microscopic-needle-pin).
    static var allToothSlugs: [String] {
        Array(Set(entryByPortraitSlug.values.map(\.toothSlug))).sorted()
    }

    static func smileToothType(for dinosaur: Dinosaur) -> String? {
        entry(for: dinosaur)?.toothSlug
    }

    static func morphologyCategory(for dinosaur: Dinosaur) -> String? {
        entry(for: dinosaur)?.categorySlug
    }

    static func playerKind(for toothSlug: String) -> PteroSmilePlayerToothKind? {
        playerKindByToothSlug[toothSlug]
    }

    static func playerKind(for dinosaur: Dinosaur) -> PteroSmilePlayerToothKind? {
        guard let toothSlug = smileToothType(for: dinosaur) else { return nil }
        return playerKind(for: toothSlug)
    }

    /// Pre-reader label for narration fallback and on-screen text (e.g. "Fang", not "Crested Terminal Spikes").
    static func playerLabel(for toothSlug: String) -> String {
        playerKind(for: toothSlug)?.displayLabel ?? "Tooth"
    }

    /// Primary contract key: `ptero-smile-fang.m4a` under `Audio/Ptero-Smile/`.
    static func toothAudioKey(for toothSlug: String) -> String {
        playerKind(for: toothSlug)?.audioKey ?? "ptero-smile-\(toothSlug)"
    }

    /// Keys tried in order during gameplay (primary kind clip, then legacy morphology clip).
    static func playerAudioCandidateKeys(for toothSlug: String) -> [String] {
        guard let kind = playerKind(for: toothSlug) else {
            return ["ptero-smile-tooth-\(toothSlug)", "ptero-smile-\(toothSlug)"]
        }
        var keys = [kind.audioKey]
        if let legacy = kind.legacyAudioKey {
            keys.append(legacy)
        }
        return keys
    }

    /// Player kinds used by species with bundled portrait + tooth art (playable pool).
    static func playerKindsUsedByPlayablePool() -> [PteroSmilePlayerToothKind] {
        let slugs = AirPterosaurData.allPterosaurs.compactMap { ptero -> String? in
            guard smilePortraitAssetName(for: ptero) != nil,
                  let toothSlug = smileToothType(for: ptero),
                  ImageAssetCache.imageExists(named: toothImageAssetName(for: toothSlug)) else { return nil }
            return toothSlug
        }
        return Array(Set(slugs.compactMap { playerKind(for: $0) })).sorted { $0.rawValue < $1.rawValue }
    }

    private static func entry(for dinosaur: Dinosaur) -> SpeciesEntry? {
        guard let slug = AirPterosaurData.matrixFossilSlug(for: dinosaur) else { return nil }
        return entryByPortraitSlug[slug]
    }

    private static func portraitAssetSlug(for matrixSlug: String) -> String {
        portraitAssetSlugAliases[matrixSlug] ?? matrixSlug
    }

    static func toothImageAssetName(for toothSlug: String) -> String {
        "ptero-smile-tooth-\(toothSlug)"
    }

    static func smilePortraitAssetName(for dinosaur: Dinosaur) -> String? {
        guard let matrixSlug = AirPterosaurData.matrixFossilSlug(for: dinosaur) else { return nil }
        let assetSlug = portraitAssetSlug(for: matrixSlug)
        let name = "ptero-smile-\(assetSlug)"
        return ImageAssetCache.imageExists(named: name) ? name : nil
    }
}
