//
//  DinoFormationsCatalog.swift
//  DinoGames
//
//  Playable fossil formations: `json/dino-formations/*_formation.json` + species from
//  `json/dinosaurs/**/char_*.json` `formation_id` (grouped at runtime).
//

import Foundation

struct DinoFormation: Identifiable {
    let id: String
    /// Display name, e.g. "Hell Creek"
    let name: String
    /// Asset name for formation image, e.g. "formation-hell-creek"
    let imageName: String
    /// Dino image set names (dino-*) found in this formation.
    let dinoImageNames: Set<String>
    /// Hint: state(s)/province and country, e.g. "Montana, Wyoming, USA"
    let hintLocation: String?
    /// Hint: Mesozoic period, e.g. "Late Cretaceous"
    let hintPeriod: String?
}

enum DinoFormationsCatalog {
    private static let formationsSubdir = "json/dino-formations"
    private static let dinosaursSubdir = "json/dinosaurs"

    /// Formations with ≥3 `dino-*` species in the playable pool (see `DinoFormationsGameView`).
    static let playableFormations: [DinoFormation] = {
        let root = Bundle.main.resourceURL
        let loaded = root.map { loadFormations(resourceRoot: $0) } ?? []
        return loaded.isEmpty ? fallbackFormations : loaded
    }()

    /// Builds formations from repo/bundle JSON. Used by unit tests with `TestBundleHelpers.projectRootURL()`.
    static func loadFormations(resourceRoot: URL) -> [DinoFormation] {
        let formationFiles = jsonFiles(
            under: resourceRoot.appendingPathComponent(formationsSubdir),
            matching: { $0.lastPathComponent.hasSuffix("_formation.json") }
        )
        let charFiles = jsonFiles(
            under: resourceRoot.appendingPathComponent(dinosaursSubdir),
            matching: { $0.lastPathComponent.hasPrefix("char_") }
        )

        var speciesByFormationID: [String: Set<String>] = [:]
        for file in charFiles {
            guard let data = try? Data(contentsOf: file),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let formationID = formationID(from: object),
                  let imageName = dinoImageName(fromCharFile: file) else { continue }
            speciesByFormationID[formationID, default: []].insert(imageName)
        }

        var formations: [DinoFormation] = []
        for file in formationFiles.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            guard let data = try? Data(contentsOf: file),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let fileFormationID = object["formation_id"] as? String else { continue }

            let slug = slugFromFormationFilename(file.lastPathComponent)
            let dinoImageNames = matchedDinoImageNames(
                fileFormationID: fileFormationID,
                speciesByFormationID: speciesByFormationID
            )
            guard dinoImageNames.count >= 3 else { continue }

            formations.append(
                DinoFormation(
                    id: slug,
                    name: displayName(fromSlug: slug),
                    imageName: "formation-\(slug)",
                    dinoImageNames: dinoImageNames,
                    hintLocation: object["hint_location"] as? String,
                    hintPeriod: displayPeriod(from: object["period"] as? String)
                )
            )
        }
        return formations
    }

    // MARK: - JSON helpers

    private static func jsonFiles(under directory: URL, matching: (URL) -> Bool) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var files: [URL] = []
        for case let file as URL in enumerator {
            let values = try? file.resourceValues(forKeys: [.isRegularFileKey])
            guard values?.isRegularFile == true, file.pathExtension.lowercased() == "json" else { continue }
            if matching(file) { files.append(file) }
        }
        return files
    }

    private static func formationID(from charJSON: [String: Any]) -> String? {
        if let app = charJSON["app_image_config"] as? [String: Any],
           let layer2 = app["layer_2_setting"] as? [String: Any],
           let formationID = layer2["formation_id"] as? String {
            return formationID
        }
        if let layer2 = charJSON["layer_2_setting"] as? [String: Any],
           let formationID = layer2["formation_id"] as? String {
            return formationID
        }
        return charJSON["formation_id"] as? String
    }

    private static func dinoImageName(fromCharFile file: URL) -> String? {
        let stem = file.deletingPathExtension().lastPathComponent
        guard stem.hasPrefix("char_") else { return nil }
        let slug = String(stem.dropFirst("char_".count)).replacingOccurrences(of: "_", with: "-")
        return "dino-\(slug)"
    }

    private static func matchedDinoImageNames(
        fileFormationID: String,
        speciesByFormationID: [String: Set<String>]
    ) -> Set<String> {
        var names: Set<String> = []
        for (charFormationID, imageNames) in speciesByFormationID {
            if charFormationIDMatchesFile(charFormationID: charFormationID, fileFormationID: fileFormationID) {
                names.formUnion(imageNames)
            }
        }
        return names
    }

    /// `MORRISON` on a char file matches `MORRISON_LJ` in `morrison_formation.json`.
    private static func charFormationIDMatchesFile(charFormationID: String, fileFormationID: String) -> Bool {
        if charFormationID == fileFormationID { return true }
        return fileFormationID.hasPrefix(charFormationID + "_")
    }

    private static func slugFromFormationFilename(_ filename: String) -> String {
        var base = filename
        if base.hasSuffix(".json") { base = String(base.dropLast(5)) }
        if base.hasSuffix("_formation") { base = String(base.dropLast("_formation".count)) }
        return base.replacingOccurrences(of: "_", with: "-")
    }

    private static func displayName(fromSlug slug: String) -> String {
        slug.split(separator: "-")
            .map { part in
                let word = String(part)
                return word.prefix(1).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }

    private static func displayPeriod(from raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        return raw.lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { part in
                let word = String(part)
                return word.prefix(1).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }

    private static let fallbackFormations: [DinoFormation] = [
        DinoFormation(
            id: "hell-creek",
            name: "Hell Creek",
            imageName: "formation-hell-creek",
            dinoImageNames: ["dino-trex", "dino-triceratops", "dino-ankylosaurus", "dino-edmontosaurus", "dino-pachycephalosaurus", "dino-torosaurus"],
            hintLocation: "Montana, North Dakota, South Dakota, Wyoming, USA",
            hintPeriod: "Late Cretaceous"
        ),
        DinoFormation(
            id: "morrison",
            name: "Morrison",
            imageName: "formation-morrison",
            dinoImageNames: ["dino-stegosaurus", "dino-apatosaurus", "dino-brachiosaurus", "dino-diplodocus", "dino-camarasaurus", "dino-dryosaurus", "dino-ceratosaurus"],
            hintLocation: "Colorado, Utah, Wyoming, Montana, USA",
            hintPeriod: "Late Jurassic"
        ),
        DinoFormation(
            id: "cloverly",
            name: "Cloverly",
            imageName: "formation-cloverly",
            dinoImageNames: ["dino-deinonychus", "dino-apatosaurus", "dino-edmontosaurus"],
            hintLocation: "Montana, Wyoming, USA",
            hintPeriod: "Early Cretaceous"
        ),
    ]
}
