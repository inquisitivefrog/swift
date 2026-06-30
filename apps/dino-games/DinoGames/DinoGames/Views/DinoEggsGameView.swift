//
//  DinoEggsGameView.swift
//  DinoGames
//
//  Dino Eggs: land eggs game using shared EggsGameView framework.
//  Audio: morphotype clips under `Audio/Dino-Eggs/`; gameplay UI under `Audio/Games/`.
//

import SwiftUI

typealias DinoEggsRound = EggsGameRound
typealias DinoEggsGameConfig = EggsGameConfig

struct DinoEggsGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: DinoEggsGameConfig

    var body: some View {
        EggsGameView(isPresented: $isPresented, gameConfig: gameConfig)
    }
}

// MARK: - Dino egg morphology

enum DinoEggMorphology {
    /// Egg morphotype clades used by Dino Eggs rounds and victory recap audio.
    static let eggMorphotypeClades: [String] = [
        "ankylosaur", "ceratopsian", "hadrosaur", "large-theropod", "ornithischian",
        "ornithomimid", "sauropod", "small-theropod", "stegosaur",
    ]

    static var playableEggClades: Set<String> {
        Set(eggMorphotypeClades.filter { roundAssetsExist(for: $0) })
    }

    private static let eggTypeBySlug: [String: String] = [
        "trex": "large-theropod", "triceratops": "ceratopsian", "stegosaurus": "stegosaur", "velociraptor": "small-theropod",
        "therizinosaurus": "ornithischian", "spinosaurus": "large-theropod", "apatosaurus": "sauropod", "ankylosaurus": "ankylosaur",
        "corythosaurus": "hadrosaur", "parasaurolophus": "hadrosaur", "iguanodon": "ornithischian", "troodon": "small-theropod",
        "edmontosaurus": "hadrosaur", "camarasaurus": "sauropod", "dryosaurus": "ornithischian", "gallimimus": "ornithomimid",
        "pachycephalosaurus": "ornithischian", "albertosaurus": "large-theropod", "anchiornis": "small-theropod",
        "archaeopteryx": "small-theropod", "argentinosaurus": "sauropod", "baryonyx": "large-theropod", "brachiosaurus": "sauropod",
        "ceratosaurus": "large-theropod", "chasmosaurus": "ceratopsian", "compsognathus": "small-theropod", "deinonychus": "small-theropod",
        "diplodocus": "sauropod", "dromaeosaurus": "small-theropod", "eosinopteryx": "small-theropod", "giganotosaurus": "large-theropod",
        "kosmoceratops": "ceratopsian", "microraptor": "small-theropod", "pedopenna": "small-theropod", "torosaurus": "ceratopsian",
        "utahraptor": "small-theropod", "xiaotingia": "small-theropod", "masiakasaurus": "small-theropod", "torvosaurus": "large-theropod",
        "rapetosaurus": "sauropod", "majungasaurus": "large-theropod", "allosaurus": "large-theropod", "oviraptor": "ornithomimid",
        "brontosaurus": "sauropod", "kentrosaurus": "stegosaur", "edmontonia": "ankylosaur", "lambeosaurus": "hadrosaur",
        "maiasaura": "hadrosaur", "stegoceras": "ornithischian", "stygimoloch": "ornithischian", "nodosaurus": "ankylosaur",
        "euoplocephalus": "ankylosaur", "polacanthus": "ankylosaur", "styracosaurus": "ceratopsian", "huayangosaurus": "stegosaur",
        "ouranosaurus": "ornithischian", "suchomimus": "large-theropod", "acrocanthosaurus": "large-theropod",
        "amargasaurus": "sauropod", "australovenator": "large-theropod", "carcharodontosaurus": "large-theropod",
        "deinocheirus": "ornithomimid", "fukuiraptor": "small-theropod", "gasparinisaura": "ornithischian",
        "mamenchisaurus": "sauropod", "gigantoraptor": "ornithomimid", "gigantosaurus": "large-theropod",
        "ornithomimus": "ornithomimid", "struthiomimus": "ornithomimid",
    ]

    static let morphology = EggsMorphology(
        assetPrefix: "dino-eggs",
        nestAssetPrefix: "dino-nest",
        scannerToolPrefix: nil,
        eggType: { dino in
            let slug = dino.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(dino.id)"
            return eggTypeBySlug[slug]
        },
        nestingStyle: { eggClade in eggClade },
        nestingFallbackText: { eggClade in
            eggClade.replacingOccurrences(of: "-", with: " ").capitalized + " nest"
        },
        scanAssetName: { eggClade in scanAssetName(for: eggClade) },
        randomColorsAsset: { eggClade in coloredEggAssetName(for: eggClade) }
    )

    static let sourceHints: [EggsSourceHint] = [
        EggsSourceHint(id: "shape", imageName: "source-dino-eggs-shape", displayName: "Shape", audioKey: "game-dino-eggs-shape"),
        EggsSourceHint(id: "color", imageName: "source-dino-eggs-color", displayName: "Color", audioKey: "game-dino-eggs-color"),
    ]

    static let settings = EggsGameSettings(
        morphology: morphology,
        gameKeyPrefix: "game-dino-eggs",
        gameplayDirectionsAudioKey: "game-dino-eggs-gameplay-directions",
        gameplayDirectionsFallback: "When you see the egg, tap the CT scanner to look inside.",
        beepKey: "game-dino-eggs-beep",
        scanFailedKey: "game-dino-eggs-scan-failed",
        tapCreatureAfterScanKey: nil,
        successImageName: "game-dino-eggs-success",
        creatureEmoji: "🦖",
        roundIntroNestAudioKey: { clade in "game-dino-eggs-nest-\(clade)" },
        roundIntroTapScannerAudioKey: "game-dino-eggs-tap-the-scanner",
        playsEggNestNameIntro: false,
        playsTapScannerPrompt: true,
        showsCreatureNameOnCards: false,
        victoryRecapUsesCreatureName: false,
        victoryRecapLabelUsesCreatureName: false,
        sourceHints: sourceHints,
        sourceHintsTitle: "Source Eggs",
        sourceHintsGridIntroAudioKey: nil,
        playsHintsButtonIntro: false,
        onVictoryComplete: { LandDinosaurProgress.notifyCompletionIfLandGame(configId: $0) }
    )

    static func coloredEggAssetName(for eggClade: String) -> String? {
        let name = "dino-egg-colors-\(eggClade)"
        return ImageAssetCache.imageExists(named: name) ? name : nil
    }

    static func nestAssetName(for eggClade: String) -> String? {
        let name = morphology.nestingImageName(style: eggClade)
        return ImageAssetCache.imageExists(named: name) ? name : nil
    }

    static func scanAssetName(for eggClade: String) -> String {
        let candidates = [
            "dino-eggs-scans-\(eggClade)",
            eggClade == "ankylosaur" ? "dino-eggs-scans-ankylosaurid" : nil,
            eggClade == "stegosaur" ? "dino-eggs-scans-stegosaurid" : nil,
        ].compactMap { $0 }
        return candidates.first(where: { ImageAssetCache.imageExists(named: $0) })
            ?? "dino-eggs-scans-\(eggClade)"
    }

    static func roundAssetsExist(for eggClade: String) -> Bool {
        coloredEggAssetName(for: eggClade) != nil
            && nestAssetName(for: eggClade) != nil
            && ImageAssetCache.imageExists(named: scanAssetName(for: eggClade))
    }
}

// MARK: - Game config

struct DinoEggsGameConfigs {
    private static let dinoEggsRoundCount = 3

    static var dinoEggs: DinoEggsGameConfig {
        let pool = dinosaursWithDinoAndEgg
        let byEggClade = Dictionary(grouping: pool.compactMap { dino -> (Dinosaur, String)? in
            guard let clade = DinoEggMorphology.morphology.eggType(dino) else { return nil }
            return (dino, clade)
        }) { $0.1 }
        .mapValues { $0.map(\.0) }

        let playableClades = byEggClade.keys.filter { DinoEggMorphology.roundAssetsExist(for: $0) }
        var usedIds: Set<Int> = []
        var usedEggClades: Set<String> = []
        var rounds: [DinoEggsRound] = []

        for roundId in 1...dinoEggsRoundCount {
            let availableClades = playableClades.filter { clade in
                !usedEggClades.contains(clade)
                    && (byEggClade[clade] ?? []).contains { !usedIds.contains($0.id) }
            }
            guard let eggClade = availableClades.randomElement() else { break }

            let cladePool = (byEggClade[eggClade] ?? []).filter { !usedIds.contains($0.id) }
            guard let correctDino = cladePool.randomElement() else { continue }

            guard let distractors = pickTwoDistractorsDifferentEggClades(
                correctEggClade: eggClade,
                byEggClade: byEggClade,
                playableClades: playableClades,
                usedIds: usedIds,
                excludingCorrectId: correctDino.id
            ) else { continue }

            usedIds.insert(correctDino.id)
            usedIds.formUnion(distractors.map(\.id))
            usedEggClades.insert(eggClade)
            rounds.append(DinoEggsRound(
                id: roundId,
                correctCreature: correctDino,
                eggType: eggClade,
                nestingStyle: eggClade,
                distractors: distractors
            ))
        }

        guard rounds.count >= dinoEggsRoundCount else {
            fatalError("Need at least \(dinoEggsRoundCount) rounds for Dino Eggs (pool has \(pool.count) playable dinosaurs, \(playableClades.count) egg clades)")
        }

        return DinoEggsGameConfig(
            settings: DinoEggMorphology.settings,
            totalRounds: dinoEggsRoundCount,
            id: "dino-eggs",
            title: "Dino Eggs!",
            introAudio: "game-dino-eggs",
            gameplayDirectionsAudio: "game-dino-eggs-gameplay-directions",
            rounds: Array(rounds.prefix(dinoEggsRoundCount))
        )
    }

    /// Two dinosaurs from two different egg clades than the round’s correct clade.
    private static func pickTwoDistractorsDifferentEggClades(
        correctEggClade: String,
        byEggClade: [String: [Dinosaur]],
        playableClades: [String],
        usedIds: Set<Int>,
        excludingCorrectId: Int
    ) -> [Dinosaur]? {
        let otherClades = playableClades.filter { $0 != correctEggClade }.shuffled()
        guard otherClades.count >= 2 else { return nil }

        var distractors: [Dinosaur] = []
        for clade in otherClades {
            guard distractors.count < 2 else { break }
            let candidates = (byEggClade[clade] ?? []).filter { dino in
                dino.id != excludingCorrectId && !usedIds.contains(dino.id)
                    && !distractors.contains(where: { $0.id == dino.id })
            }
            if let dino = candidates.randomElement() {
                distractors.append(dino)
            }
        }
        return distractors.count == 2 ? distractors : nil
    }

    private static var dinosaursWithDinoAndEgg: [Dinosaur] {
        baseDinosaursWithDinoAndEgg()
    }

    private static func baseDinosaursWithDinoAndEgg() -> [Dinosaur] {
        let excludedClades: Set<DinoClade> = [.spinosaurid, .pachycephalosaur]
        let cladeById = LandDinosaurCladeCatalog.cladeByCreatureId
        return MatchingGameConfigs.allDinosaurs.filter { dino in
            let clade = cladeById[dino.id] ?? .theropod
            guard !excludedClades.contains(clade) else { return false }
            let dinoName = dino.imageName ?? "dino-\(dino.id)"
            guard ImageAssetCache.imageExists(named: dinoName),
                  let eggClade = DinoEggMorphology.morphology.eggType(dino) else { return false }
            return DinoEggMorphology.roundAssetsExist(for: eggClade)
        }
    }
}
