//
//  DentalMorphology.swift
//  DinoGames
//
//  Shared dinosaur → tooth morphology mapping. Used by Dino Toothache and Smiling Dinos.
//  Source of truth: see DENTAL_MORPHOLOGY_SOURCE_OF_TRUTH.md (currently Google Gemini 3 Flash).
//

import Foundation

/// Maps dinosaur slug (from dino-{slug}) to tooth type slug. Tooth images: dino-toothache-tooth-{toothType}.
enum DentalMorphology {
    private static let toothTypeBySlug: [String: String] = [
        "trex": "banana",
        "triceratops": "forked-grinder",
        "stegosaurus": "fluted-leaf-v1",
        "velociraptor": "hooked-blade",
        "therizinosaurus": "leaf-slicer",
        "spinosaurus": "smooth-cone",
        "apatosaurus": "pencil-peg",
        "ankylosaurus": "large-ridged-leaf",
        "corythosaurus": "honeycomb-battery",
        "parasaurolophus": "honeycomb-battery",
        "iguanodon": "diamond-battery-v1",
        "troodon": "hooked-needle",
        "edmontosaurus": "honeycomb-battery",
        "camarasaurus": "silver-spoon",
        "dryosaurus": "small-scalloped-leaf",
        "gallimimus": "nipping-beak-v1",
        "pachycephalosaurus": "scalloped-blade",
        "albertosaurus": "banana",
        "anchiornis": "sharp-serrated-leaf",
        "archaeopteryx": "needle-spike",
        "argentinosaurus": "heavy-peg",
        "baryonyx": "hooked-needle",
        "brachiosaurus": "silver-spoon",
        "ceratosaurus": "hooked-slicer",
        "chasmosaurus": "forked-battery",
        "compsognathus": "needle-spike",
        "deinonychus": "hooked-blade",
        "diplodocus": "pencil-peg",
        "dromaeosaurus": "hooked-blade",
        "eosinopteryx": "needle-spike",
        "giganotosaurus": "grand-blade",
        "kosmoceratops": "forked-battery",
        "microraptor": "needle-spike",
        "pedopenna": "needle-spike",
        "torosaurus": "forked-battery",
        "utahraptor": "hooked-blade",
        "xiaotingia": "needle-spike",
        "masiakasaurus": "forward-spear",
        "torvosaurus": "hooked-slicer",
        "rapetosaurus": "heavy-peg",
        "majungasaurus": "banana",
        "allosaurus": "hooked-slicer",
        "oviraptor": "nipping-beak-v2",
        "brontosaurus": "pencil-peg",
        "kentrosaurus": "fluted-leaf-v2",
        "edmontonia": "large-ridged-leaf",
        "lambeosaurus": "honeycomb-battery",
        "maiasaura": "honeycomb-battery",
        "stegoceras": "nutcracker",
        "stygimoloch": "nutcracker",
        "nodosaurus": "large-ridged-leaf",
        "euoplocephalus": "large-ridged-leaf",
        "polacanthus": "large-ridged-leaf",
        "styracosaurus": "forked-battery",
        "huayangosaurus": "fluted-leaf-v2",
        "ouranosaurus": "diamond-battery-v1",
        "suchomimus": "smooth-cone",
        "acrocanthosaurus": "grand-blade",
        "amargasaurus": "pencil-peg",
        "australovenator": "hooked-slicer",
        "carcharodontosaurus": "grand-blade",
        "deinocheirus": "nipping-beak-v2",
        "fukuiraptor": "hooked-needle",
        "gasparinisaura": "small-scalloped-leaf",
        "mamenchisaurus": "pencil-peg",
        "gigantoraptor": "nipping-beak-v2",
        "gigantosaurus": "grand-blade",
        "ornithomimus": "nipping-beak-v2",
        "struthiomimus": "nipping-beak-v2",
    ]

    static func toothType(for dino: Dinosaur) -> String? {
        let slug = dino.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(dino.id)"
        return toothTypeBySlug[slug]
    }

    /// Tooth type for Dino Smile (dino-smile-tooth-{toothType}). Uses game-specific overrides where dino-smile-tooth-* assets differ from dino-toothache-tooth-*.
    static func smileToothType(for dino: Dinosaur) -> String? {
        let slug = dino.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(dino.id)"
        guard let base = toothTypeBySlug[slug] else { return nil }
        // Explicit overrides for Dino Smile
        switch slug {
        case "stegosaurus", "kentrosaurus", "huayangosaurus": return "flute-leaf"
        case "gallimimus", "ornithomimus", "struthiomimus": return "nipping-beak"
        case "oviraptor", "deinocheirus", "gigantoraptor": return "nutcracker"
        case "triceratops": return "forked-battery"
        case "iguanodon", "ouranosaurus": return "diamond-battery"
        default:
            switch base {
            case "fluted-leaf-v1", "fluted-leaf-v2": return "flute-leaf"
            case "nipping-beak-v1", "nipping-beak-v2": return "nipping-beak"
            case "forked-grinder": return "forked-battery"
            case "diamond-battery-v1": return "diamond-battery"
            default: return base
            }
        }
    }
}
