//
//  PteroSmileMorphology.swift
//  DinoGames
//
//  Pterosaur portrait → beak/tooth shape mapping for Ptero Smile!
//  Portrait art: ptero-smile-{slug}. Tooth art: ptero-smile-tooth-{toothType}.
//

import Foundation

enum PteroSmileMorphology {
    /// Species slug (from `AirPterosaurData.matrixFossilSlug`) → tooth type slug.
    private static let toothTypeByPortraitSlug: [String: String] = [
        "quetzalcoatlus": "beak-spear",
        "anhanguera": "needle-spike",
        "anuanguera": "needle-spike",
        "dimorphodon": "peg-slicer",
        "tupandactylus": "nutcracker",
        "anurognathus": "micro-peg",
        "pterodaustro": "comb-filter",
    ]

    /// Morphology family per tooth type (used to pick distractors from a different beak style).
    private static let morphologyGroupByToothType: [String: String] = [
        "beak-spear": "toothless_beak",
        "needle-spike": "needle_spike",
        "peg-slicer": "generalist",
        "nutcracker": "fruit_nut_cracker",
        "micro-peg": "froghopper_jaws",
        "comb-filter": "comb_filter",
    ]

    /// Portrait imageset slug (handles bundled typo `anuanguera` for Anhanguera).
    static func smilePortraitSlug(for matrixSlug: String) -> String {
        if matrixSlug == "anhanguera" { return "anuanguera" }
        return matrixSlug
    }

    static func smilePortraitAssetName(for creature: Dinosaur) -> String? {
        guard let matrixSlug = AirPterosaurData.matrixFossilSlug(for: creature) else { return nil }
        let portraitSlug = smilePortraitSlug(for: matrixSlug)
        let name = "ptero-smile-\(portraitSlug)"
        return ImageAssetCache.imageExists(named: name) ? name : nil
    }

    static func smileToothType(for creature: Dinosaur) -> String? {
        guard let matrixSlug = AirPterosaurData.matrixFossilSlug(for: creature) else { return nil }
        if let tooth = toothTypeByPortraitSlug[matrixSlug] { return tooth }
        return toothTypeByPortraitSlug[smilePortraitSlug(for: matrixSlug)]
    }

    static func toothImageAssetName(for toothType: String) -> String {
        "ptero-smile-tooth-\(toothType)"
    }

    static func morphologyGroup(for toothType: String) -> String {
        morphologyGroupByToothType[toothType] ?? toothType
    }

    /// Audio key stem bundled under `Audio/Ptero-Smile/` (morphology slug, e.g. `ptero-smile-toothless-beak`).
    static func toothAudioKey(for toothType: String) -> String {
        let morphologySlug = morphologyGroup(for: toothType).replacingOccurrences(of: "_", with: "-")
        return "ptero-smile-\(morphologySlug)"
    }
}
