//
//  AirPterosaurData.swift
//  DinoGames
//
//  Air (pterosaur) creature pool shared by Match the Pterosaur, Name That Pterosaur, measure, racing, balance, weigh, and other games.
//

import Foundation

/// Morphological / asset-family bucket for guess-game reference grids (maps to `ptero-{bucket}-*` image names).
enum PterosaurGuessGroup: String, CaseIterable {
    case azhdarchid
    case basal
    case ornithocheiroid
    case specialist
    case tapejarid
    case thalassodromid
    case transitional

    var displayName: String {
        switch self {
        case .azhdarchid: return "Azhdarchid"
        case .basal: return "Basal"
        case .ornithocheiroid: return "Ornithocheiroid"
        case .specialist: return "Specialist"
        case .tapejarid: return "Tapejarid"
        case .thalassodromid: return "Thalassodromid"
        case .transitional: return "Transitional"
        }
    }

    /// Stem for `Pterosaur-Clades/clade-{stem}.m4a` (matches bundled `clade-*.m4a` names).
    var cladeAudioSlug: String {
        switch self {
        case .transitional: return "transition"
        default:
            return rawValue
        }
    }

    static func guessGroup(forImageName imageName: String) -> PterosaurGuessGroup? {
        let b = imageName.lowercased()
        if b.hasPrefix("ptero-azhd-") { return .azhdarchid }
        if b.hasPrefix("ptero-basal-") { return .basal }
        if b.hasPrefix("ptero-ornitho-") { return .ornithocheiroid }
        if b.hasPrefix("ptero-spec-") { return .specialist }
        if b.hasPrefix("ptero-tape-") { return .tapejarid }
        if b.hasPrefix("ptero-thala-") { return .thalassodromid }
        if b.hasPrefix("ptero-trans-") { return .transitional }
        return nil
    }
}

enum AirPterosaurData {
    enum MesozoicSpan {
        case jurassic
        case cretaceous
        case both
    }

    /// Full pool of available pterosaurs (flying reptiles).
    static let allPterosaurs: [Dinosaur] = [
        Dinosaur(id: 101, name: "Arambourgiania", icon: "🦅", imageName: "ptero-azhd-arambourgiania", characteristicIds: [501, 502, 503]),
        Dinosaur(id: 102, name: "Cryodrakon", icon: "🦅", imageName: "ptero-azhd-cryodrakon", characteristicIds: [504, 505, 506]),
        Dinosaur(id: 103, name: "Hatzegopteryx", icon: "🦅", imageName: "ptero-azhd-hatzegopteryx", characteristicIds: [507, 508, 509]),
        Dinosaur(id: 104, name: "Quetzalcoatlus", icon: "🦅", imageName: "ptero-azhd-quetzalcoatlus", characteristicIds: [510, 511, 512]),
        Dinosaur(id: 105, name: "Thanatosdrakon", icon: "🦅", imageName: "ptero-azhd-thanatosdrakon", characteristicIds: [513, 514, 515]),
        Dinosaur(id: 106, name: "Zhejiangopterus", icon: "🦅", imageName: "ptero-azhd-zhejiangopterus", characteristicIds: [516, 517, 518]),
        Dinosaur(id: 107, name: "Anurognathus", icon: "🦅", imageName: "ptero-basal-anurognathus", characteristicIds: [519, 520, 521]),
        Dinosaur(id: 108, name: "Campylognathoides", icon: "🦅", imageName: "ptero-basal-campylognathoides", characteristicIds: [522, 523, 524]),
        Dinosaur(id: 109, name: "Dimorphodon", icon: "🦅", imageName: "ptero-basal-dimorphodon", characteristicIds: [525, 526, 527]),
        Dinosaur(id: 110, name: "Eudimorphodon", icon: "🦅", imageName: "ptero-basal-eudimorphodon", characteristicIds: [528, 529, 530]),
        Dinosaur(id: 111, name: "Jeholopterus", icon: "🦅", imageName: "ptero-basal-jeholopterus", characteristicIds: [531, 532, 533]),
        Dinosaur(id: 112, name: "Rhamphorhynchus", icon: "🦅", imageName: "ptero-basal-rhamphorhynchus", characteristicIds: [534, 535, 536]),
        Dinosaur(id: 113, name: "Scaphognathus", icon: "🦅", imageName: "ptero-basal-scaphognathus", characteristicIds: [537, 538, 539]),
        Dinosaur(id: 114, name: "Sordes", icon: "🦅", imageName: "ptero-basal-sordes", characteristicIds: [540, 541, 542]),
        Dinosaur(id: 115, name: "Anhanguera", icon: "🦅", imageName: "ptero-ornitho-anhanguera", characteristicIds: [543, 544, 545]),
        Dinosaur(id: 116, name: "Boreopterus", icon: "🦅", imageName: "ptero-ornitho-boreopterus", characteristicIds: [546, 547, 548]),
        Dinosaur(id: 117, name: "Coloborhynchus", icon: "🦅", imageName: "ptero-ornitho-coloborhynchus", characteristicIds: [549, 550, 551]),
        Dinosaur(id: 118, name: "Guidraco", icon: "🦅", imageName: "ptero-ornitho-guidraco", characteristicIds: [552, 553, 554]),
        Dinosaur(id: 119, name: "Istiodactylus", icon: "🦅", imageName: "ptero-ornitho-istiodactylus", characteristicIds: [555, 556, 557]),
        Dinosaur(id: 120, name: "Ludodactylus", icon: "🦅", imageName: "ptero-ornitho-ludodactylus", characteristicIds: [558, 559, 560]),
        Dinosaur(id: 121, name: "Nyctosaurus", icon: "🦅", imageName: "ptero-ornitho-nyctosaurus", characteristicIds: [561, 562, 563]),
        Dinosaur(id: 122, name: "Ornithocheirus", icon: "🦅", imageName: "ptero-ornitho-ornithocheirus", characteristicIds: [564, 565, 566]),
        Dinosaur(id: 123, name: "Pteranodon", icon: "🦅", imageName: "ptero-ornitho-pteranodon", characteristicIds: [567, 568, 569]),
        Dinosaur(id: 124, name: "Tropeognathus", icon: "🦅", imageName: "ptero-ornitho-tropeognathus", characteristicIds: [570, 571, 572]),
        Dinosaur(id: 125, name: "Ctenochasma", icon: "🦅", imageName: "ptero-spec-ctenochasma", characteristicIds: [573, 574, 575]),
        Dinosaur(id: 126, name: "Dsungaripterus", icon: "🦅", imageName: "ptero-spec-dsungaripterus", characteristicIds: [576, 577, 578]),
        Dinosaur(id: 127, name: "Gnathosaurus", icon: "🦅", imageName: "ptero-spec-gnathosaurus", characteristicIds: [579, 580, 581]),
        Dinosaur(id: 128, name: "Noripterus", icon: "🦅", imageName: "ptero-spec-noripterus", characteristicIds: [582, 583, 584]),
        Dinosaur(id: 129, name: "Pterodactylus", icon: "🦅", imageName: "ptero-spec-pterodactylus", characteristicIds: [585, 586, 587]),
        Dinosaur(id: 130, name: "Pterodaustro", icon: "🦅", imageName: "ptero-spec-pterodaustro", characteristicIds: [588, 589, 590]),
        Dinosaur(id: 131, name: "Bakonydraco", icon: "🦅", imageName: "ptero-tape-bakonydraco", characteristicIds: [591, 592, 593]),
        Dinosaur(id: 132, name: "Caiuajara", icon: "🦅", imageName: "ptero-tape-caiuajara", characteristicIds: [594, 595, 596]),
        Dinosaur(id: 133, name: "Caupedactylus", icon: "🦅", imageName: "ptero-tape-caupedactylus", characteristicIds: [597, 598, 599]),
        Dinosaur(id: 134, name: "Sinopterus", icon: "🦅", imageName: "ptero-tape-sinopterus", characteristicIds: [600, 601, 602]),
        Dinosaur(id: 135, name: "Tapejara", icon: "🦅", imageName: "ptero-tape-tapejara", characteristicIds: [603, 604, 605]),
        Dinosaur(id: 136, name: "Tupandactylus", icon: "🦅", imageName: "ptero-tape-tupandactylus", characteristicIds: [606, 607, 608]),
        Dinosaur(id: 137, name: "Bangiadraco", icon: "🦅", imageName: "ptero-thala-bangiadraco", characteristicIds: [609, 610, 611]),
        Dinosaur(id: 138, name: "Kariridraco", icon: "🦅", imageName: "ptero-thala-kariridraco", characteristicIds: [612, 613, 614]),
        Dinosaur(id: 139, name: "Thalassodromeus", icon: "🦅", imageName: "ptero-thala-thalassodromeus", characteristicIds: [615, 616, 617]),
        Dinosaur(id: 140, name: "Tupuxuara", icon: "🦅", imageName: "ptero-thala-tupuxuara", characteristicIds: [618, 619, 620]),
        Dinosaur(id: 141, name: "Darwinopterus", icon: "🦅", imageName: "ptero-trans-darwinopterus", characteristicIds: [621, 622, 623]),
        Dinosaur(id: 142, name: "Kunpengopterus", icon: "🦅", imageName: "ptero-trans-kunpengopterus", characteristicIds: [624, 625, 626]),
        Dinosaur(id: 143, name: "Nemicolopterus", icon: "🦅", imageName: "ptero-trans-nemicolopterus", characteristicIds: [627, 628, 629]),
        Dinosaur(id: 144, name: "Wukongopterus", icon: "🦅", imageName: "ptero-trans-wukongopterus", characteristicIds: [630, 631, 632]),
    ]

    /// Five diet option labels for Ptero Diets! (matches `ptero-diets-*` imagesets).
    /// Uses **Filter Feeder** (not Omnivore — there is no `ptero-diets-omnivore` art).
    static let pterosaurDietTypes = ["Frugivore", "Carnivore", "Piscivore", "Insectivore", "Filter Feeder"]

    /// Asset slug for a pterosaur diet label (e.g. Filter Feeder → filter-feeder).
    static func pterosaurDietAssetSlug(for dietType: String) -> String {
        switch dietType {
        case "Filter Feeder": return "filter-feeder"
        default:
            return dietType.lowercased()
        }
    }

    /// Spoken diet name under `Audio/Ptero-Diets/` (e.g. `ptero-diet-carnivore.m4a`, `ptero-diets-frugivore.m4a`).
    static func pterosaurDietAudioKey(for dietType: String) -> String {
        let slug = pterosaurDietAssetSlug(for: dietType)
        switch dietType {
        case "Frugivore", "Filter Feeder":
            return "ptero-diets-\(slug)"
        default:
            return "ptero-diet-\(slug)"
        }
    }

    /// Diet per pterosaur for Ptero Diets! (Frugivore, Carnivore, Piscivore, Insectivore, Filter Feeder).
    static let pterosaurDietById: [Int: String] = [
        101: "Carnivore", 102: "Carnivore", 103: "Carnivore", 104: "Carnivore", 105: "Carnivore", 106: "Carnivore",
        107: "Insectivore", 108: "Insectivore", 109: "Carnivore", 110: "Insectivore", 111: "Insectivore", 112: "Piscivore",
        113: "Carnivore", 114: "Insectivore",
        115: "Piscivore", 116: "Piscivore", 117: "Piscivore", 118: "Piscivore", 119: "Carnivore", 120: "Piscivore",
        121: "Piscivore", 122: "Piscivore", 123: "Piscivore", 124: "Piscivore",
        125: "Filter Feeder", 126: "Carnivore", 127: "Filter Feeder", 128: "Frugivore", 129: "Carnivore", 130: "Filter Feeder",
        131: "Frugivore", 132: "Frugivore", 133: "Frugivore", 134: "Frugivore", 135: "Frugivore", 136: "Frugivore",
        137: "Piscivore", 138: "Piscivore", 139: "Carnivore", 140: "Carnivore",
        141: "Insectivore", 142: "Insectivore", 143: "Insectivore", 144: "Carnivore",
    ]

    /// Estimated adult body mass in kg per pterosaur id (101+). Used by Weigh and Balance.
    static let pterosaurEstimatedWeightKgById: [Int: Double] = [
        101: 60000,
        102: 25000,
        103: 65000,
        104: 200000,
        105: 30000,
        106: 20000,
        107: 0.2,
        108: 0.5,
        109: 2,
        110: 0.3,
        111: 0.05,
        112: 1.5,
        113: 0.8,
        114: 0.05,
        115: 40,
        116: 15,
        117: 25,
        118: 20,
        119: 4,
        120: 8,
        121: 2,
        122: 35,
        123: 25,
        124: 45,
        125: 2.5,
        126: 20,
        127: 3,
        128: 8,
        129: 2,
        130: 2.5,
        131: 30,
        132: 12,
        133: 10,
        134: 8,
        135: 15,
        136: 15,
        137: 18,
        138: 12,
        139: 22,
        140: 25,
        141: 1.5,
        142: 2,
        143: 0.25,
        144: 1,
    ]

    /// Approximate standing height (m) for Which Ptero Is Taller.
    /// These are hand-tuned educational values based on commonly cited adult reconstruction ranges
    /// so giant azhdarchids clearly tower over a human while small basal forms remain small.
    static let pterosaurStandingHeightMetersById: [Int: Double] = [
        101: 4.8,  // Arambourgiania
        102: 4.2,  // Cryodrakon
        103: 5.2,  // Hatzegopteryx
        104: 5.5,  // Quetzalcoatlus
        105: 4.6,  // Thanatosdrakon
        106: 3.5,  // Zhejiangopterus
        107: 0.25, // Anurognathus
        108: 0.6,  // Campylognathoides
        109: 1.0,  // Dimorphodon
        110: 0.35, // Eudimorphodon
        111: 0.2,  // Jeholopterus
        112: 0.55, // Rhamphorhynchus
        113: 0.45, // Scaphognathus
        114: 0.22, // Sordes
        115: 1.6,  // Anhanguera
        116: 1.1,  // Boreopterus
        117: 1.5,  // Coloborhynchus
        118: 1.4,  // Guidraco
        119: 1.0,  // Istiodactylus
        120: 1.2,  // Ludodactylus
        121: 1.3,  // Nyctosaurus
        122: 1.8,  // Ornithocheirus
        123: 1.7,  // Pteranodon
        124: 1.9,  // Tropeognathus
        125: 0.5,  // Ctenochasma
        126: 1.3,  // Dsungaripterus
        127: 0.6,  // Gnathosaurus
        128: 0.9,  // Noripterus
        129: 0.45, // Pterodactylus
        130: 0.8,  // Pterodaustro
        131: 1.2,  // Bakonydraco
        132: 1.0,  // Caiuajara
        133: 1.1,  // Caupedactylus
        134: 0.9,  // Sinopterus
        135: 1.3,  // Tapejara
        136: 1.4,  // Tupandactylus
        137: 1.4,  // Bangiadraco
        138: 1.2,  // Kariridraco
        139: 1.8,  // Thalassodromeus
        140: 1.9,  // Tupuxuara
        141: 0.55, // Darwinopterus
        142: 0.6,  // Kunpengopterus
        143: 0.2,  // Nemicolopterus
        144: 0.65, // Wukongopterus
    ]

    /// Trait rows for Match the Pterosaur (`ptero-char-*` images).
    static let allPterosaurCharacteristics: [Characteristic] = [
        Characteristic(id: 501, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 101),
        Characteristic(id: 502, type: "Small", icon: "🐦", imageName: "ptero-char-small", dinosaurId: 101),
        Characteristic(id: 503, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 101),
        Characteristic(id: 504, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 102),
        Characteristic(id: 505, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 102),
        Characteristic(id: 506, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 102),
        Characteristic(id: 507, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 103),
        Characteristic(id: 508, type: "Huge", icon: "🐘", imageName: "ptero-char-huge", dinosaurId: 103),
        Characteristic(id: 509, type: "Long Neck", icon: "🦒", imageName: "ptero-char-long-neck", dinosaurId: 103),
        Characteristic(id: 510, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 104),
        Characteristic(id: 511, type: "Long Tail", icon: "🦎", imageName: "ptero-char-long-tail", dinosaurId: 104),
        Characteristic(id: 512, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 104),
        Characteristic(id: 513, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 105),
        Characteristic(id: 514, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 105),
        Characteristic(id: 515, type: "No Teeth", icon: "🦷", imageName: "ptero-char-no-teeth", dinosaurId: 105),
        Characteristic(id: 516, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 106),
        Characteristic(id: 517, type: "Big Head", icon: "🧠", imageName: "ptero-char-big-head", dinosaurId: 106),
        Characteristic(id: 518, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 106),
        Characteristic(id: 519, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 107),
        Characteristic(id: 520, type: "Small", icon: "🐦", imageName: "ptero-char-small", dinosaurId: 107),
        Characteristic(id: 521, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 107),
        Characteristic(id: 522, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 108),
        Characteristic(id: 523, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 108),
        Characteristic(id: 524, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 108),
        Characteristic(id: 525, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 109),
        Characteristic(id: 526, type: "Huge", icon: "🐘", imageName: "ptero-char-huge", dinosaurId: 109),
        Characteristic(id: 527, type: "Long Neck", icon: "🦒", imageName: "ptero-char-long-neck", dinosaurId: 109),
        Characteristic(id: 528, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 110),
        Characteristic(id: 529, type: "Long Tail", icon: "🦎", imageName: "ptero-char-long-tail", dinosaurId: 110),
        Characteristic(id: 530, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 110),
        Characteristic(id: 531, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 111),
        Characteristic(id: 532, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 111),
        Characteristic(id: 533, type: "No Teeth", icon: "🦷", imageName: "ptero-char-no-teeth", dinosaurId: 111),
        Characteristic(id: 534, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 112),
        Characteristic(id: 535, type: "Big Head", icon: "🧠", imageName: "ptero-char-big-head", dinosaurId: 112),
        Characteristic(id: 536, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 112),
        Characteristic(id: 537, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 113),
        Characteristic(id: 538, type: "Small", icon: "🐦", imageName: "ptero-char-small", dinosaurId: 113),
        Characteristic(id: 539, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 113),
        Characteristic(id: 540, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 114),
        Characteristic(id: 541, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 114),
        Characteristic(id: 542, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 114),
        Characteristic(id: 543, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 115),
        Characteristic(id: 544, type: "Huge", icon: "🐘", imageName: "ptero-char-huge", dinosaurId: 115),
        Characteristic(id: 545, type: "Long Neck", icon: "🦒", imageName: "ptero-char-long-neck", dinosaurId: 115),
        Characteristic(id: 546, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 116),
        Characteristic(id: 547, type: "Long Tail", icon: "🦎", imageName: "ptero-char-long-tail", dinosaurId: 116),
        Characteristic(id: 548, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 116),
        Characteristic(id: 549, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 117),
        Characteristic(id: 550, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 117),
        Characteristic(id: 551, type: "No Teeth", icon: "🦷", imageName: "ptero-char-no-teeth", dinosaurId: 117),
        Characteristic(id: 552, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 118),
        Characteristic(id: 553, type: "Big Head", icon: "🧠", imageName: "ptero-char-big-head", dinosaurId: 118),
        Characteristic(id: 554, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 118),
        Characteristic(id: 555, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 119),
        Characteristic(id: 556, type: "Small", icon: "🐦", imageName: "ptero-char-small", dinosaurId: 119),
        Characteristic(id: 557, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 119),
        Characteristic(id: 558, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 120),
        Characteristic(id: 559, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 120),
        Characteristic(id: 560, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 120),
        Characteristic(id: 561, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 121),
        Characteristic(id: 562, type: "Huge", icon: "🐘", imageName: "ptero-char-huge", dinosaurId: 121),
        Characteristic(id: 563, type: "Long Neck", icon: "🦒", imageName: "ptero-char-long-neck", dinosaurId: 121),
        Characteristic(id: 564, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 122),
        Characteristic(id: 565, type: "Long Tail", icon: "🦎", imageName: "ptero-char-long-tail", dinosaurId: 122),
        Characteristic(id: 566, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 122),
        Characteristic(id: 567, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 123),
        Characteristic(id: 568, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 123),
        Characteristic(id: 569, type: "No Teeth", icon: "🦷", imageName: "ptero-char-no-teeth", dinosaurId: 123),
        Characteristic(id: 570, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 124),
        Characteristic(id: 571, type: "Big Head", icon: "🧠", imageName: "ptero-char-big-head", dinosaurId: 124),
        Characteristic(id: 572, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 124),
        Characteristic(id: 573, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 125),
        Characteristic(id: 574, type: "Small", icon: "🐦", imageName: "ptero-char-small", dinosaurId: 125),
        Characteristic(id: 575, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 125),
        Characteristic(id: 576, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 126),
        Characteristic(id: 577, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 126),
        Characteristic(id: 578, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 126),
        Characteristic(id: 579, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 127),
        Characteristic(id: 580, type: "Huge", icon: "🐘", imageName: "ptero-char-huge", dinosaurId: 127),
        Characteristic(id: 581, type: "Long Neck", icon: "🦒", imageName: "ptero-char-long-neck", dinosaurId: 127),
        Characteristic(id: 582, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 128),
        Characteristic(id: 583, type: "Long Tail", icon: "🦎", imageName: "ptero-char-long-tail", dinosaurId: 128),
        Characteristic(id: 584, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 128),
        Characteristic(id: 585, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 129),
        Characteristic(id: 586, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 129),
        Characteristic(id: 587, type: "No Teeth", icon: "🦷", imageName: "ptero-char-no-teeth", dinosaurId: 129),
        Characteristic(id: 588, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 130),
        Characteristic(id: 589, type: "Big Head", icon: "🧠", imageName: "ptero-char-big-head", dinosaurId: 130),
        Characteristic(id: 590, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 130),
        Characteristic(id: 591, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 131),
        Characteristic(id: 592, type: "Small", icon: "🐦", imageName: "ptero-char-small", dinosaurId: 131),
        Characteristic(id: 593, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 131),
        Characteristic(id: 594, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 132),
        Characteristic(id: 595, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 132),
        Characteristic(id: 596, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 132),
        Characteristic(id: 597, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 133),
        Characteristic(id: 598, type: "Huge", icon: "🐘", imageName: "ptero-char-huge", dinosaurId: 133),
        Characteristic(id: 599, type: "Long Neck", icon: "🦒", imageName: "ptero-char-long-neck", dinosaurId: 133),
        Characteristic(id: 600, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 134),
        Characteristic(id: 601, type: "Long Tail", icon: "🦎", imageName: "ptero-char-long-tail", dinosaurId: 134),
        Characteristic(id: 602, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 134),
        Characteristic(id: 603, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 135),
        Characteristic(id: 604, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 135),
        Characteristic(id: 605, type: "No Teeth", icon: "🦷", imageName: "ptero-char-no-teeth", dinosaurId: 135),
        Characteristic(id: 606, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 136),
        Characteristic(id: 607, type: "Big Head", icon: "🧠", imageName: "ptero-char-big-head", dinosaurId: 136),
        Characteristic(id: 608, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 136),
        Characteristic(id: 609, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 137),
        Characteristic(id: 610, type: "Small", icon: "🐦", imageName: "ptero-char-small", dinosaurId: 137),
        Characteristic(id: 611, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 137),
        Characteristic(id: 612, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 138),
        Characteristic(id: 613, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 138),
        Characteristic(id: 614, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 138),
        Characteristic(id: 615, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 139),
        Characteristic(id: 616, type: "Huge", icon: "🐘", imageName: "ptero-char-huge", dinosaurId: 139),
        Characteristic(id: 617, type: "Long Neck", icon: "🦒", imageName: "ptero-char-long-neck", dinosaurId: 139),
        Characteristic(id: 618, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 140),
        Characteristic(id: 619, type: "Long Tail", icon: "🦎", imageName: "ptero-char-long-tail", dinosaurId: 140),
        Characteristic(id: 620, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 140),
        Characteristic(id: 621, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 141),
        Characteristic(id: 622, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 141),
        Characteristic(id: 623, type: "No Teeth", icon: "🦷", imageName: "ptero-char-no-teeth", dinosaurId: 141),
        Characteristic(id: 624, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 142),
        Characteristic(id: 625, type: "Big Head", icon: "🧠", imageName: "ptero-char-big-head", dinosaurId: 142),
        Characteristic(id: 626, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 142),
        Characteristic(id: 627, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 143),
        Characteristic(id: 628, type: "Small", icon: "🐦", imageName: "ptero-char-small", dinosaurId: 143),
        Characteristic(id: 629, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 143),
        Characteristic(id: 630, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 144),
        Characteristic(id: 631, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 144),
        Characteristic(id: 632, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 144),
    ]

    /// Body-image prefix for silhouette naming (thalassodromids / transitionals use grouped `ptero-thala-` / `ptero-trans-` silhouettes).
    static func bodyImagePrefix(for imageName: String) -> String {
        let b = imageName.lowercased()
        if b.hasPrefix("ptero-thala-") { return "ptero-thala-" }
        if b.hasPrefix("ptero-trans-") { return "ptero-trans-" }
        return "ptero-"
    }

    /// Bundled silhouette imageset name for a body `imageName` (e.g. `ptero-trans-darwinopterus` → `ptero-trans-silhouette-darwinopterus`).
    static func silhouetteAssetName(forBodyImage base: String) -> String {
        let b = base.lowercased()
        if b.hasPrefix("ptero-thala-") {
            return "ptero-thala-silhouette-" + String(b.dropFirst("ptero-thala-".count))
        }
        if b.hasPrefix("ptero-trans-") {
            return "ptero-trans-silhouette-" + String(b.dropFirst("ptero-trans-".count))
        }
        if b.hasPrefix("ptero-") {
            return "ptero-silhouette-" + String(b.dropFirst("ptero-".count))
        }
        return "ptero-silhouette-\(b)"
    }

    /// Species slug for `ptero-matrix-{stone}-{slug}` fossil composites (e.g. `ptero-basal-dimorphodon` → `dimorphodon`).
    static func matrixFossilSlug(for creature: Dinosaur) -> String? {
        guard let name = creature.imageName else { return nil }
        let parts = name.split(separator: "-", omittingEmptySubsequences: true)
        guard parts.count >= 3, parts[0] == "ptero" else { return nil }
        let slug = parts.dropFirst(2).joined(separator: "-")
        return slug.isEmpty ? nil : slug
    }

    /// Two decoys for Name That Pterosaur: not the question’s guess group, and from two different non-question groups when the pool allows.
    static func pickTwoDecoysDistinctGuessGroups(question: Dinosaur, pool: [Dinosaur]) -> [Dinosaur] {
        guard let qGroup = PterosaurGuessGroup.guessGroup(forImageName: question.imageName ?? "") else {
            return Array(pool.filter { $0.id != question.id }.shuffled().prefix(2))
        }
        let decoyCandidates = pool.filter { cand in
            guard cand.id != question.id else { return false }
            guard let g = PterosaurGuessGroup.guessGroup(forImageName: cand.imageName ?? "") else { return false }
            return g != qGroup
        }
        guard decoyCandidates.count >= 2 else {
            return Array(pool.filter { $0.id != question.id }.shuffled().prefix(2))
        }
        let byGroup = Dictionary(grouping: decoyCandidates) { PterosaurGuessGroup.guessGroup(forImageName: $0.imageName ?? "")! }
        let otherKeys = byGroup.keys.shuffled()
        if otherKeys.count >= 2 {
            let firstDecoy = (byGroup[otherKeys[0]] ?? []).shuffled().first!
            let secondPool = decoyCandidates.filter {
                PterosaurGuessGroup.guessGroup(forImageName: $0.imageName ?? "") != otherKeys[0]
            }
            if let secondDecoy = secondPool.shuffled().first {
                return [firstDecoy, secondDecoy]
            }
        }
        return Array(decoyCandidates.shuffled().prefix(2))
    }

    /// Subset of `allPterosaurs` that have a bundled silhouette imageset (tests and asset checks). Name That Pterosaur uses the full `allPterosaurs` pool and tints the body when no silhouette exists.
    static var nameThatPterosaurPool: [Dinosaur] {
        allPterosaurs.filter { d in
            guard let base = d.imageName else { return false }
            return ImageAssetNames.knownAssets.contains(silhouetteAssetName(forBodyImage: base))
        }
    }

    /// Racing period grouping for pterosaurs (used by Racing Pterosaurs period picker).
    /// `both` means the species appears in Late Jurassic and Early Cretaceous windows.
    static func mesozoicSpanForRacing(pterosaurId: Int) -> MesozoicSpan? {
        switch pterosaurId {
        case 107, 108, 109, 110, 111, 112, 113, 114, 125, 127, 129, 141, 142, 144:
            return .jurassic
        case 106, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 128, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 143:
            return .cretaceous
        case 101, 102, 103, 104, 105, 126:
            return .both
        default:
            return nil
        }
    }

    /// Builds a Racing Pterosaurs imageset base from catalog keys such as `ptero-azhd-hatzegopteryx`.
    /// Canonical racing base is `ptero-racer-{group}-{speciesTail}`.
    /// Group matches the middle segment (`azhd`, `basal`, `ornitho`, …); tail preserves spelling from the asset catalog.
    static func pteroRacingAssetBase(fromCatalogImageName imageName: String) -> String? {
        let parts = imageName.split(separator: "-").map(String.init)
        guard parts.count >= 3 else { return nil }
        guard parts[0].caseInsensitiveCompare("ptero") == .orderedSame else { return nil }
        let group = parts[1].lowercased()
        let tail = parts.dropFirst(2).joined(separator: "-").lowercased()
        guard !group.isEmpty, !tail.isEmpty else { return nil }
        let legacyBase = "ptero-racer-\(group)-\(tail)"
        let modernBase = "ptero-racing-\(group)-\(tail)"

        let knownAssets = ImageAssetNames.knownAssets
        if knownAssets.contains(legacyBase + "-ready") || knownAssets.contains(legacyBase) {
            return legacyBase
        }
        if knownAssets.contains(modernBase + "-ready") || knownAssets.contains(modernBase) {
            return modernBase
        }

        /// Portrait catalog keys occasionally differ from bundled racer filenames (historical spelling in assets).
        let tailAliases: [String] = {
            switch (group, tail) {
            case ("azhd", "quetzacoatlus"):
                return ["quetzalcoatlus"]
            case ("spec", "pterodactylus"):
                return ["pteradactylus"]
            default:
                return []
            }
        }()
        for alt in tailAliases {
            let altLegacy = "ptero-racer-\(group)-\(alt)"
            let altModern = "ptero-racing-\(group)-\(alt)"
            if knownAssets.contains(altLegacy + "-ready") || knownAssets.contains(altLegacy) {
                return altLegacy
            }
            if knownAssets.contains(altModern + "-ready") || knownAssets.contains(altModern) {
                return altModern
            }
        }

        // Default to canonical `ptero-racer-*` base when generated assets are stale.
        return legacyBase
    }
}
