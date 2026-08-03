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
///
/// Kid vocabulary: **Fang** = a few big front teeth (canine / Dracula sense).
/// **Spike** / **Needle** = rows of pointy teeth (Spike = stout points; Needle = slender fence/cage).
/// **Pin** = tiny insect-trap pins.
enum PteroSmilePlayerToothKind: String, CaseIterable {
    case beak
    case spear
    case stub
    case fang
    case spike
    case needle
    case peg
    case comb
    case scoop
    case clip
    case pin
    case tweezers
    case pincer
    case saw

    var displayLabel: String { rawValue.capitalized }

    /// Target clip under `Audio/Ptero-Smile/` (Spike/Needle reuse the needle-spike recording).
    var audioKey: String {
        switch self {
        case .spike, .needle: return "ptero-smile-needle-spike"
        default: return "ptero-smile-\(rawValue)"
        }
    }

    /// Round packing key: kinds that share audio or kid-facing form must not co-appear
    /// (e.g. Spike + Needle both narrate from `ptero-smile-needle-spike` and look like “pointy teeth”).
    var roundUniquenessKey: String { audioKey }

    /// Legacy morphology-family clips shipped before the 14-category refactor.
    var legacyAudioKey: String? {
        switch self {
        case .beak: return "ptero-smile-toothless-beak"
        case .fang: return nil
        case .spike, .needle: return "ptero-smile-fang"
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
    /// Player nicknames: Fang = few front canines; Spike = needle/cage rows (not “fangs” to kids).
    private static let entryByPortraitSlug: [String: SpeciesEntry] = [
        "anhanguera": .init(categorySlug: "classic-pelican-style", toothSlug: "fish-cage-fangs", playerKind: .spike),
        "anurognathus": .init(categorySlug: "interlocking-grapplers", toothSlug: "miniature-insect-trap-pins", playerKind: .pin),
        "arambourgiania": .init(categorySlug: "hyper-elongated-spears", toothSlug: "ultra-elongated-spear", playerKind: .spear),
        "bakonydraco": .init(categorySlug: "fruit-herbaceous-cutters", toothSlug: "tapered-v-crested-blade", playerKind: .beak),
        "bangiadraco": .init(categorySlug: "classic-pelican-style", toothSlug: "notched-crested-beak", playerKind: .beak),
        "boreopterus": .init(categorySlug: "rapid-snapping-predators", toothSlug: "needle-cage-braces", playerKind: .needle),
        "caiuajara": .init(categorySlug: "fruit-herbaceous-cutters", toothSlug: "deep-down-turned-scoop", playerKind: .scoop),
        "campylognathoides": .init(categorySlug: "crushers-peg-specialists", toothSlug: "curved-forward-grapplers", playerKind: .pincer),
        "caupedactylus": .init(categorySlug: "precision-shearing-clips", toothSlug: "straight-slicing-shears", playerKind: .clip),
        // Few big terminal spikes at the snout tip — Fang in the kid sense.
        "coloborhynchus": .init(categorySlug: "heavy-impact-wedges", toothSlug: "crested-terminal-spikes", playerKind: .fang),
        "cryodrakon": .init(categorySlug: "heavy-impact-wedges", toothSlug: "stout-spear-beak", playerKind: .stub),
        "ctenochasma": .init(categorySlug: "needle-comb-filterers", toothSlug: "comb-needles", playerKind: .comb),
        // Smile asset (Peg-Slicer): neatly spaced blunt ivory pegs — not spaced-raptor-fangs.
        "darwinopterus": .init(categorySlug: "interlocking-grapplers", toothSlug: "spaced-vertical-pegs", playerKind: .peg),
        "dimorphodon": .init(categorySlug: "rapid-snapping-predators", toothSlug: "dual-type-pincers", playerKind: .pincer),
        "dsungaripterus": .init(categorySlug: "crushers-peg-specialists", toothSlug: "pebble-crushers", playerKind: .peg),
        "eudimorphodon": .init(categorySlug: "precision-shearing-clips", toothSlug: "multi-cusped-saws", playerKind: .saw),
        "gnathosaurus": .init(categorySlug: "needle-comb-filterers", toothSlug: "filter-tooth-field", playerKind: .comb),
        // Front tangle of long canines — classic kid “fangs.”
        "guidraco": .init(categorySlug: "rapid-snapping-predators", toothSlug: "tangled-interlocking-spikes", playerKind: .fang),
        "hatzegopteryx": .init(categorySlug: "heavy-impact-wedges", toothSlug: "heavy-axe-beak", playerKind: .beak),
        "istiodactylus": .init(categorySlug: "precision-shearing-clips", toothSlug: "duck-razor-bill", playerKind: .clip),
        "jeholopterus": .init(categorySlug: "micro-insect-trappers", toothSlug: "vampire-insect-needles", playerKind: .pin),
        "kariridraco": .init(categorySlug: "scoop-tweezers-specialists", toothSlug: "up-turned-tweezers", playerKind: .tweezers),
        "kunpengopterus": .init(categorySlug: "micro-insect-trappers", toothSlug: "curved-grasping-pins", playerKind: .pin),
        // Smile asset (Needle-Spike): interlocking blunt ivory spikes along the jaw — Spike, not Fang.
        "ludodactylus": .init(categorySlug: "classic-pelican-style", toothSlug: "barbed-spear-tip", playerKind: .spike),
        "nemicolopterus": .init(categorySlug: "micro-insect-trappers", toothSlug: "vampire-insect-needles", playerKind: .pin),
        "noripterus": .init(categorySlug: "crushers-peg-specialists", toothSlug: "shell-crushing-pegs", playerKind: .peg),
        // Smile asset (Cage-Fang): fence-like slender teeth — toothy needle-cage art, not toothless razor needles.
        "nyctosaurus": .init(categorySlug: "raptor-cage-hunters", toothSlug: "needle-cage-braces", playerKind: .needle),
        // Spoon-tipped fangs concentrated at the tip.
        "ornithocheirus": .init(categorySlug: "crested-blade-specialists", toothSlug: "spoon-tipped-fangs", playerKind: .fang),
        "pteranodon": .init(categorySlug: "high-utility-skimmers", toothSlug: "classic-pelican-javelin", playerKind: .spear),
        // Peg-Slicer smile: slender conical pegs, not fangs.
        "pterodactylus": .init(categorySlug: "raptor-cage-hunters", toothSlug: "slender-conical-snappers", playerKind: .peg),
        "pterodaustro": .init(categorySlug: "needle-comb-filterers", toothSlug: "baleen-comb", playerKind: .comb),
        "quetzalcoatlus": .init(categorySlug: "hyper-elongated-spears", toothSlug: "spear-beak", playerKind: .beak),
        "rhamphorhynchus": .init(categorySlug: "interlocking-grapplers", toothSlug: "forward-protruding-spikes", playerKind: .spike),
        "scaphognathus": .init(categorySlug: "rapid-snapping-predators", toothSlug: "spaced-vertical-pegs", playerKind: .peg),
        "sinopterus": .init(categorySlug: "scoop-tweezers-specialists", toothSlug: "pointed-fruit-cutter", playerKind: .clip),
        // Fish-cage dentition (shared tooth card with Anhanguera) — Spike, not kid “Fang.”
        "sordes": .init(categorySlug: "raptor-cage-hunters", toothSlug: "fish-cage-fangs", playerKind: .spike),
        // Smile is toothless Nutcracker-Parrot-Beak; spatula-spoon tooth art shows needle teeth (Gnathosaurus).
        "tapejara": .init(categorySlug: "fruit-herbaceous-cutters", toothSlug: "deep-down-turned-scoop", playerKind: .scoop),
        "thalassodromeus": .init(categorySlug: "crested-blade-specialists", toothSlug: "tapered-v-crested-blade", playerKind: .beak),
        "thanatosdrakon": .init(categorySlug: "hyper-elongated-spears", toothSlug: "colossal-predatory-wedge", playerKind: .spear),
        "tropeognathus": .init(categorySlug: "crested-blade-specialists", toothSlug: "double-crested-fish-snappers", playerKind: .spike),
        "tupandactylus": .init(categorySlug: "scoop-tweezers-specialists", toothSlug: "deep-rounded-clip", playerKind: .scoop),
        "tupuxuara": .init(categorySlug: "high-utility-skimmers", toothSlug: "deep-sub-terminal-notch", playerKind: .clip),
        "wukongopterus": .init(categorySlug: "micro-insect-trappers", toothSlug: "rhythmic-grasping-spikes", playerKind: .peg),
        "zhejiangopterus": .init(categorySlug: "high-utility-skimmers", toothSlug: "slender-javelin-bill", playerKind: .pin),
        "anuanguera": .init(categorySlug: "classic-pelican-style", toothSlug: "fish-cage-fangs", playerKind: .spike),
    ]

    /// Bundled portrait imageset slug when it differs from matrix fossil slug.
    private static let portraitAssetSlugAliases: [String: String] = [
        "anhanguera": "anuanguera",
    ]

    /// Tooth-card arts that are smooth beaks / no visible dentition (kids cannot match them to toothy smile portraits).
    private static let toothlessToothSlugs: Set<String> = [
        "classic-pelican-javelin",
        "notched-crested-beak",
        "slender-javelin-bill",
        "tapered-v-crested-blade",
        "pointed-fruit-cutter",
        "colossal-predatory-wedge",
        "heavy-axe-beak",
        "stout-spear-beak",
        "deep-sub-terminal-notch",
        "hyper-slender-razor-needles",
        "elongated-cutting-wedge",
        "spear-beak",
        "ultra-elongated-spear",
        "microscopic-needle-pin",
        "deep-rounded-clip",
        "straight-slicing-shears",
        "deep-down-turned-scoop",
        "up-turned-tweezers",
    ]

    /// Smile portraits that clearly show teeth / ivory dentition in the bundled art.
    /// Used only to prefer toothy distractors — correct pairs stay morphology-true (e.g. Pteranodon → Spear).
    private static let smilePortraitsWithVisibleTeeth: Set<String> = [
        "anhanguera", "anuanguera", "ludodactylus", "tropeognathus",
        "anurognathus", "jeholopterus", "nemicolopterus", "wukongopterus",
        "ctenochasma", "gnathosaurus", "boreopterus", "dimorphodon",
        "darwinopterus", "scaphognathus", "nyctosaurus", "pterodactylus", "sordes",
        "pterodaustro", "istiodactylus", "ornithocheirus", "guidraco",
        "rhamphorhynchus", "coloborhynchus", "campylognathoides",
        "dsungaripterus", "noripterus", "eudimorphodon", "kunpengopterus",
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

    /// Unique README tooth slugs (43; nemicolopterus and wukongopterus historically shared microscopic-needle-pin).
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

    static func toothArtShowsTeeth(for toothSlug: String) -> Bool {
        !toothlessToothSlugs.contains(toothSlug)
    }

    static func smilePortraitShowsTeeth(for dinosaur: Dinosaur) -> Bool {
        guard let slug = AirPterosaurData.matrixFossilSlug(for: dinosaur) else { return false }
        let assetSlug = portraitAssetSlug(for: slug)
        return smilePortraitsWithVisibleTeeth.contains(slug) || smilePortraitsWithVisibleTeeth.contains(assetSlug)
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
