//
//  LandGameDisplayMoment.swift
//  DinoGames
//
//  Image + display text + audio keys shown together during land (L1–4) gameplay.
//  Single source of truth for CI triad tests and hint grids in game views.
//

import Foundation

/// One on-screen moment: readable label, bundled image, and narration key (same lookup as `SpeechManager`).
struct LandGameDisplayTriad: Identifiable, Equatable {
    let id: String
    let displayText: String
    let imageAssetName: String
    let audioKey: String
}

/// A triad in the context of a shipping land game (for test reporting).
struct LandGameDisplayMoment: Equatable {
    let gameConfigId: String
    let context: String
    let triad: LandGameDisplayTriad

    var displayText: String { triad.displayText }
    var imageAssetName: String { triad.imageAssetName }
    var audioKey: String { triad.audioKey }
}

enum LandGameDisplayMomentCatalog {

    // MARK: - Source hint grids (shared by views + tests)

    static let footprintSourceHints: [LandGameDisplayTriad] = [
        LandGameDisplayTriad(id: "ankylosaur", displayText: "Ankylosaur", imageAssetName: "source-footprints-ankylosaur", audioKey: "footprint-ankylosaur"),
        LandGameDisplayTriad(id: "ceratopsian", displayText: "Ceratopsian", imageAssetName: "source-footprints-ceratopsian", audioKey: "footprint-ceratopsian"),
        LandGameDisplayTriad(id: "hadrosaur", displayText: "Hadrosaur", imageAssetName: "source-footprints-hadrosaur", audioKey: "footprint-hadrosaur"),
        LandGameDisplayTriad(id: "ornithischian", displayText: "Ornithischian", imageAssetName: "source-footprints-ornithischian", audioKey: "footprint-ornithischian"),
        LandGameDisplayTriad(id: "ornithomimid", displayText: "Ornithomimid", imageAssetName: "source-footprints-ornithomimid", audioKey: "footprint-ornithomimid"),
        LandGameDisplayTriad(id: "sauropod", displayText: "Sauropod", imageAssetName: "source-footprints-sauropod", audioKey: "footprint-sauropod"),
        LandGameDisplayTriad(id: "spinosaurid", displayText: "Spinosaurid", imageAssetName: "source-footprints-spinosaurid", audioKey: "footprint-spinosaurid"),
        LandGameDisplayTriad(id: "stegosaur", displayText: "Stegosaur", imageAssetName: "source-footprints-stegosaur", audioKey: "footprint-stegosaur"),
        LandGameDisplayTriad(id: "theropod", displayText: "Theropod", imageAssetName: "source-footprints-theropod", audioKey: "footprint-therapod"),
    ]

    static let agesSourceHints: [LandGameDisplayTriad] = [
        LandGameDisplayTriad(id: "jurassic", displayText: "Jurassic", imageAssetName: "source-dino-ages-jurassic", audioKey: "game-dino-ages-jurassic-dinosaurs"),
        LandGameDisplayTriad(id: "cretaceous", displayText: "Cretaceous", imageAssetName: "source-dino-ages-cretaceous", audioKey: "game-dino-ages-cretaceous-dinosaurs"),
    ]

    static let dinoFloraCategoryHints: [LandGameDisplayTriad] = [
        LandGameDisplayTriad(id: "browsers", displayText: "Browsers", imageAssetName: "source-flora-browsers", audioKey: "dino-hint-browsers"),
        LandGameDisplayTriad(id: "periods", displayText: "Periods", imageAssetName: "source-flora-periods", audioKey: "dino-hint-periods"),
        LandGameDisplayTriad(id: "diets", displayText: "Diets", imageAssetName: "source-flora-diets", audioKey: "dino-hint-diets"),
    ]

    static let pteroFloraCategoryHints: [LandGameDisplayTriad] = [
        LandGameDisplayTriad(id: "size", displayText: "Size", imageAssetName: "source-flora-size", audioKey: "ptero-hint-size"),
        LandGameDisplayTriad(id: "period", displayText: "Period", imageAssetName: "source-flora-periods", audioKey: "ptero-hint-period"),
        LandGameDisplayTriad(id: "diets", displayText: "Diets", imageAssetName: "source-flora-diets", audioKey: "ptero-hint-diets"),
    ]

    static let marineFloraCategoryHints: [LandGameDisplayTriad] = [
        LandGameDisplayTriad(id: "protection", displayText: "Protection", imageAssetName: "source-flora-protection", audioKey: "marine-hint-protection"),
        LandGameDisplayTriad(id: "periods", displayText: "Periods", imageAssetName: "source-flora-periods", audioKey: "marine-hint-periods"),
        LandGameDisplayTriad(id: "diets", displayText: "Diets", imageAssetName: "source-flora-diets", audioKey: "marine-hint-diets"),
    ]

    /// Dino Flora category hints (`dinoFloraCategoryHints`).
    static var floraCategoryHints: [LandGameDisplayTriad] { dinoFloraCategoryHints }

    /// Audio keys where the bundle filename intentionally differs from the hint `id` slug (document for CI).
    static let audioKeySlugExceptions: [String: String] = [
        "theropod": "therapod",
    ]

    /// Land Dino Smile tooth narration tries these keys in order (`SmilingDinosGameView.playToothAudio`).
    static func landToothAudioCandidateKeys(for toothType: String) -> [String] {
        let base = "dino-smile-\(toothType)"
        return [base, "\(base)-v1", "\(base)-v2", "dino-smile-tooth-\(toothType)"]
    }

    /// Keys to try when resolving bundle audio for a moment (gameplay fallbacks).
    static func audioCandidateKeys(for moment: LandGameDisplayMoment) -> [String] {
        if moment.gameConfigId == "smiling-dinos", moment.context.contains("tooth") {
            let toothType = moment.triad.id
            return landToothAudioCandidateKeys(for: toothType)
        }
        return [moment.audioKey]
    }

    // MARK: - Aggregated shipping land moments

    static func shippingLandMoments() -> [LandGameDisplayMoment] {
        var moments: [LandGameDisplayMoment] = []
        moments += weighMoments()
        moments += tallerMoments()
        moments += puzzleMoments()
        moments += racingMoments()
        moments += hintMoments(gameId: "dino-footprints", hints: footprintSourceHints, prefix: "source-hint")
        moments += hintMoments(gameId: "dino-ages", hints: agesSourceHints, prefix: "source-hint")
        moments += hintMoments(gameId: "dino-flora", hints: dinoFloraCategoryHints, prefix: "category-hint")
        moments += floraPlantMoments()
        moments += matrixMoments()
        moments += eggsMoments()
        moments += nameThatMoments()
        moments += footprintRoundMoments()
        moments += dietOptionMoments()
        moments += smileMoments()
        return moments
    }

    // MARK: - Display image helpers (mirror gameplay views)

    /// Prefer `weigh-{base}` when bundled; else base creature asset (`WeighGameView.weighImageName`).
    static func weighDisplayImageName(for baseImageName: String) -> String {
        let weighName = "weigh-\(baseImageName)"
        return ImageAssetCache.imageExists(named: weighName) ? weighName : baseImageName
    }

    /// Grid cell uses square `dino-*` (`WhoIsTallerGameView.gridImageName`).
    static func tallerGridImageName(for item: WhoIsTallerItem) -> String? {
        let base = item.imageName ?? tallerNameFallbackStem(for: item)
        return ImageAssetCache.imageExists(named: base) ? base : nil
    }

    /// Comparison slots use `measure-{base}` when bundled (`WhoIsTallerGameView.measureDinoImageName`).
    static func tallerMeasureImageName(for item: WhoIsTallerItem) -> String? {
        let base = item.imageName ?? tallerNameFallbackStem(for: item)
        let measureName = "measure-\(base)"
        if ImageAssetCache.imageExists(named: measureName) { return measureName }
        return ImageAssetCache.imageExists(named: base) ? base : nil
    }

    static func tallerAudioStem(for item: WhoIsTallerItem) -> String {
        item.imageName ?? tallerNameFallbackStem(for: item)
    }

    private static func tallerNameFallbackStem(for item: WhoIsTallerItem) -> String {
        let slug = item.name.lowercased().replacingOccurrences(of: " ", with: "-")
        return "dino-\(slug)"
    }

    /// Ready pose for racing grid (`RacingGameView.racerDisplayImageName`, dino start pose).
    static func racingRacerReadyImageName(for racer: RacingRacer, assetPrefix: String) -> String? {
        guard assetPrefix == "dino" else { return nil }
        for base in racer.dinoRacerAssetBases() {
            let ready = base + "-ready"
            if ImageAssetCache.imageExists(named: ready) { return ready }
        }
        if let base = racer.dinoRacerAssetBases().first(where: { ImageAssetCache.imageExists(named: $0) }) {
            return base
        }
        let fallback = racer.effectiveFallbackImageName(prefix: assetPrefix)
        return ImageAssetCache.imageExists(named: fallback) ? fallback : nil
    }

    // MARK: - Builders

    private static func weighMoments() -> [LandGameDisplayMoment] {
        let pool = MatchingGameConfigs.allDinosaurs.filter { dino in
            guard let imageName = dino.imageName, imageName.hasPrefix("dino-"),
                  MatchingGameConfigs.dinosaurEstimatedWeightKgById[dino.id] != nil else { return false }
            return true
        }
        return pool.compactMap { dino in
            guard let base = dino.imageName else { return nil }
            let displayImage = weighDisplayImageName(for: base)
            return LandGameDisplayMoment(
                gameConfigId: "weigh-dinosaur",
                context: "grid \(dino.name)",
                triad: LandGameDisplayTriad(
                    id: "weigh-\(dino.id)",
                    displayText: dino.name,
                    imageAssetName: displayImage,
                    audioKey: base
                )
            )
        }
    }

    private static func tallerMoments() -> [LandGameDisplayMoment] {
        let items = WhoIsTallerGameConfigs.allEligibleDinosaurItems()
        var moments: [LandGameDisplayMoment] = []
        for item in items {
            let audio = tallerAudioStem(for: item)
            if let gridImage = tallerGridImageName(for: item) {
                moments.append(
                    LandGameDisplayMoment(
                        gameConfigId: "which-dino-is-taller",
                        context: "grid \(item.name)",
                        triad: LandGameDisplayTriad(
                            id: "taller-grid-\(item.id)",
                            displayText: item.name,
                            imageAssetName: gridImage,
                            audioKey: audio
                        )
                    )
                )
            }
            if let measureImage = tallerMeasureImageName(for: item) {
                moments.append(
                    LandGameDisplayMoment(
                        gameConfigId: "which-dino-is-taller",
                        context: "comparison \(item.name)",
                        triad: LandGameDisplayTriad(
                            id: "taller-measure-\(item.id)",
                            displayText: item.name,
                            imageAssetName: measureImage,
                            audioKey: audio
                        )
                    )
                )
            }
        }
        return moments
    }

    private static func puzzleMoments() -> [LandGameDisplayMoment] {
        let pool = LandDinosaurData.allDinosaurs
        return DinoClade.allCases.compactMap { clade in
            let inClade = pool
                .filter { LandDinosaurCladeCatalog.clade(forCreatureId: $0.id) == clade }
                .sorted { $0.name < $1.name }
            guard let dino = inClade.first(where: { ($0.imageName).map { ImageAssetCache.imageExists(named: $0) } ?? false }) else {
                return nil
            }
            return creatureMoment(gameId: "dino-puzzle", context: "clade \(clade.rawValue) creature", dinosaur: dino)
        }
    }

    private static func racingMoments() -> [LandGameDisplayMoment] {
        let periodHints: [LandGameDisplayTriad] = [
            LandGameDisplayTriad(id: "jurassic", displayText: "Jurassic", imageAssetName: "period-jurassic", audioKey: "cover-jurassic"),
            LandGameDisplayTriad(id: "cretaceous", displayText: "Cretaceous", imageAssetName: "period-cretaceous", audioKey: "cover-cretaceous"),
        ]
        var moments = hintMoments(gameId: "racing-dinosaurs", hints: periodHints, prefix: "period")
        for period in [RacingPeriod.jurassic, .cretaceous] {
            let config = RacingGameConfigs.makeConfig(for: period)
            for racer in config.racers {
                guard let image = racingRacerReadyImageName(for: racer, assetPrefix: config.assetPrefix) else { continue }
                let audio = racer.effectiveFallbackImageName(prefix: config.assetPrefix)
                moments.append(
                    LandGameDisplayMoment(
                        gameConfigId: "racing-dinosaurs",
                        context: "\(period.rawValue) racer \(racer.name)",
                        triad: LandGameDisplayTriad(
                            id: "racer-\(period.rawValue)-\(racer.id)",
                            displayText: racer.name,
                            imageAssetName: image,
                            audioKey: audio
                        )
                    )
                )
            }
        }
        return moments
    }

    private static func hintMoments(gameId: String, hints: [LandGameDisplayTriad], prefix: String) -> [LandGameDisplayMoment] {
        hints.map { hint in
            LandGameDisplayMoment(
                gameConfigId: gameId,
                context: "\(prefix) \(hint.id)",
                triad: hint
            )
        }
    }

    private static func floraPlantMoments() -> [LandGameDisplayMoment] {
        dinoFloraPlants.map { plant in
            LandGameDisplayMoment(
                gameConfigId: "dino-flora",
                context: "plant \(plant.id)",
                triad: LandGameDisplayTriad(
                    id: plant.id,
                    displayText: plant.displayName,
                    imageAssetName: plant.treeImageName,
                    audioKey: plant.audioKey
                )
            )
        }
    }

    /// Category hints + every registry plant for Ptero Flora CI (air L3).
    static func shippingPteroFloraMoments() -> [LandGameDisplayMoment] {
        var moments = hintMoments(gameId: "ptero-flora", hints: pteroFloraCategoryHints, prefix: "category-hint")
        moments += pteroFloraPlantMoments()
        return moments
    }

    /// Category hints + every registry plant for Marine Flora CI (sea L3).
    static func shippingMarineFloraMoments() -> [LandGameDisplayMoment] {
        var moments = hintMoments(gameId: "marine-flora", hints: marineFloraCategoryHints, prefix: "category-hint")
        moments += marineFloraPlantMoments()
        return moments
    }

    private static func pteroFloraPlantMoments() -> [LandGameDisplayMoment] {
        pteroFloraPlants.map { plant in
            LandGameDisplayMoment(
                gameConfigId: "ptero-flora",
                context: "plant \(plant.id)",
                triad: LandGameDisplayTriad(
                    id: plant.id,
                    displayText: plant.displayName,
                    imageAssetName: plant.treeImageName,
                    audioKey: plant.audioKey
                )
            )
        }
    }

    private static func marineFloraPlantMoments() -> [LandGameDisplayMoment] {
        marineFloraPlants.map { plant in
            LandGameDisplayMoment(
                gameConfigId: "marine-flora",
                context: "plant \(plant.id)",
                triad: LandGameDisplayTriad(
                    id: plant.id,
                    displayText: plant.displayName,
                    imageAssetName: plant.treeImageName,
                    audioKey: plant.audioKey
                )
            )
        }
    }

    private static func matrixMoments() -> [LandGameDisplayMoment] {
        let config = DinoMatrixGameConfigs.dinoMatrix
        var moments = config.sourceHints.map { hint in
            LandGameDisplayMoment(
                gameConfigId: config.id,
                context: "source-hint \(hint.id)",
                triad: LandGameDisplayTriad(
                    id: hint.id,
                    displayText: hint.displayName,
                    imageAssetName: hint.imageName,
                    audioKey: hint.audioKey
                )
            )
        }
        for round in config.rounds {
            guard let dino = round.dinosaur else { continue }
            if let moment = creatureMoment(gameId: config.id, context: "round \(round.id) creature", dinosaur: dino) {
                moments.append(moment)
            }
        }
        return moments
    }

    private static func eggsMoments() -> [LandGameDisplayMoment] {
        var moments = DinoEggMorphology.sourceHints.map { hint in
            LandGameDisplayMoment(
                gameConfigId: "dino-eggs",
                context: "source-hint \(hint.id)",
                triad: LandGameDisplayTriad(
                    id: hint.id,
                    displayText: hint.displayName,
                    imageAssetName: hint.imageName,
                    audioKey: hint.audioKey
                )
            )
        }
        let config = DinoEggsGameConfigs.dinoEggs
        let morphology = DinoEggMorphology.morphology
        for round in config.rounds {
            if let moment = creatureMoment(
                gameId: "dino-eggs",
                context: "round \(round.id) creature",
                dinosaur: round.correctCreature
            ) {
                moments.append(moment)
            }
            let eggImage = morphology.eggImageName(eggType: round.eggType)
            moments.append(
                LandGameDisplayMoment(
                    gameConfigId: "dino-eggs",
                    context: "round \(round.id) egg \(round.eggType)",
                    triad: LandGameDisplayTriad(
                        id: round.eggType,
                        displayText: round.eggType.replacingOccurrences(of: "-", with: " ").capitalized,
                        imageAssetName: eggImage,
                        audioKey: morphology.eggAudioKey(eggType: round.eggType)
                    )
                )
            )
            let nestImage = morphology.nestingImageName(style: round.nestingStyle)
            let nestAudio = DinoEggMorphology.settings.roundIntroNestAudioKey?(round.nestingStyle)
                ?? "game-dino-eggs-nest-\(round.nestingStyle)"
            moments.append(
                LandGameDisplayMoment(
                    gameConfigId: "dino-eggs",
                    context: "round \(round.id) nest \(round.nestingStyle)",
                    triad: LandGameDisplayTriad(
                        id: "\(round.nestingStyle)-nest",
                        displayText: morphology.nestingFallbackText(round.nestingStyle),
                        imageAssetName: nestImage,
                        audioKey: nestAudio
                    )
                )
            )
        }
        return moments
    }

    private static func nameThatMoments() -> [LandGameDisplayMoment] {
        let config = GuessGameConfigs.nameThatDinosaur
        var moments: [LandGameDisplayMoment] = []
        for round in config.rounds {
            for option in round.options {
                if let moment = creatureMoment(gameId: config.id, context: "round \(round.id) option \(option.name)", dinosaur: option) {
                    moments.append(moment)
                }
            }
        }
        return moments
    }

    private static func footprintRoundMoments() -> [LandGameDisplayMoment] {
        let config = GuessGameConfigs.dinoFootprints
        var moments: [LandGameDisplayMoment] = []
        for round in config.rounds {
            moments.append(
                LandGameDisplayMoment(
                    gameConfigId: config.id,
                    context: "round \(round.id) footprint",
                    triad: LandGameDisplayTriad(
                        id: "round-\(round.id)-footprint",
                        displayText: "Footprint",
                        imageAssetName: round.questionImageName,
                        audioKey: "game-footprints-identify-the-footprint"
                    )
                )
            )
            for option in round.options {
                if let moment = creatureMoment(gameId: config.id, context: "round \(round.id) option \(option.name)", dinosaur: option) {
                    moments.append(moment)
                }
            }
        }
        return moments
    }

    private static func dietOptionMoments() -> [LandGameDisplayMoment] {
        MatchingGameConfigs.dinoDietOptions.compactMap { diet in
            guard let imageName = diet.imageName, !diet.type.isEmpty else { return nil }
            return LandGameDisplayMoment(
                gameConfigId: "match-the-diet",
                context: "diet \(diet.type)",
                triad: LandGameDisplayTriad(
                    id: diet.type.lowercased(),
                    displayText: diet.type,
                    imageAssetName: imageName,
                    audioKey: LandDinosaurData.dinosaurDietAudioKey(for: diet.type)
                )
            )
        }
    }

    private static func smileMoments() -> [LandGameDisplayMoment] {
        let config = SmilingDinosGameConfigs.smilingDinos
        var moments: [LandGameDisplayMoment] = []
        for round in config.rounds {
            for (index, pair) in round.pairs.enumerated() {
                let slug = pair.dinosaur.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(pair.dinosaur.id)"
                let smileImage = "dino-smile-\(slug)"
                guard let dinoImage = pair.dinosaur.imageName, !pair.dinosaur.name.isEmpty else { continue }
                moments.append(
                    LandGameDisplayMoment(
                        gameConfigId: config.id,
                        context: "round \(round.id) smile \(index)",
                        triad: LandGameDisplayTriad(
                            id: "smile-\(pair.dinosaur.id)",
                            displayText: pair.dinosaur.name,
                            imageAssetName: smileImage,
                            audioKey: dinoImage
                        )
                    )
                )
                let toothImage = config.toothImageName(for: pair.toothType)
                let toothText = pair.toothType.replacingOccurrences(of: "-", with: " ").capitalized
                moments.append(
                    LandGameDisplayMoment(
                        gameConfigId: config.id,
                        context: "round \(round.id) tooth \(pair.toothType)",
                        triad: LandGameDisplayTriad(
                            id: pair.toothType,
                            displayText: toothText,
                            imageAssetName: toothImage,
                            audioKey: "dino-smile-\(pair.toothType)"
                        )
                    )
                )
            }
            for distractor in round.distractorToothTypes {
                let distractorImage = config.toothImageName(for: distractor)
                moments.append(
                    LandGameDisplayMoment(
                        gameConfigId: config.id,
                        context: "round \(round.id) distractor tooth \(distractor)",
                        triad: LandGameDisplayTriad(
                            id: distractor,
                            displayText: distractor.replacingOccurrences(of: "-", with: " ").capitalized,
                            imageAssetName: distractorImage,
                            audioKey: "dino-smile-\(distractor)"
                        )
                    )
                )
            }
        }
        return moments
    }

    static func creatureMoment(
        gameId: String,
        context: String,
        dinosaur: Dinosaur,
        imageOverride: String? = nil
    ) -> LandGameDisplayMoment? {
        guard !dinosaur.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let image = imageOverride ?? dinosaur.imageName
        guard let image, !image.isEmpty else { return nil }
        return LandGameDisplayMoment(
            gameConfigId: gameId,
            context: context,
            triad: LandGameDisplayTriad(
                id: "creature-\(dinosaur.id)",
                displayText: dinosaur.name,
                imageAssetName: image,
                audioKey: image
            )
        )
    }
}

// MARK: - Dino Flora plants (habitat pick rounds)

/// Plants for Dino Flora rounds — kept here so tests and `DinoFloraGameView` share one list.
let dinoFloraPlants: [DinoFloraPlant] = [
    DinoFloraPlant(id: "araucaria", formation: "morrison", formationFolder: "Morrison", taxon: "araucaria", displayName: "Araucaria"),
    DinoFloraPlant(id: "azolla", formation: "horseshoe-canyon", formationFolder: "Horseshoe_Canyon", taxon: "azolla", displayName: "Azolla"),
    DinoFloraPlant(id: "bennettitales", formation: "lance-hell-creek", formationFolder: "Lance_Hell_Creek", taxon: "bennettitales", displayName: "Bennettitales"),
    DinoFloraPlant(id: "birch", formation: "jiufotang", formationFolder: "Jiufotang", taxon: "birch", displayName: "Birch"),
    DinoFloraPlant(id: "brachyphyllum", formation: "shaximiao", formationFolder: "Shaximiao", taxon: "brachyphyllum", displayName: "Brachyphyllum"),
    DinoFloraPlant(id: "charophytes", formation: "jiufotang", formationFolder: "Jiufotang", taxon: "charophytes", displayName: "Charophytes"),
    DinoFloraPlant(id: "clubmoss", formation: "la-amarga", formationFolder: "La_Amarga", taxon: "clubmoss", displayName: "Clubmoss"),
    DinoFloraPlant(id: "cycads", formation: "morrison", formationFolder: "Morrison", taxon: "cycad", displayName: "Cycads"),
    DinoFloraPlant(id: "cypress", formation: "wealden", formationFolder: "Wealden", taxon: "cypress", displayName: "Cypress"),
    DinoFloraPlant(id: "equisetites", formation: "jiufotang", formationFolder: "Jiufotang", taxon: "equisetites", displayName: "Equisetites"),
    DinoFloraPlant(id: "fern", formation: "morrison", formationFolder: "Morrison", taxon: "herbaceous-fern", displayName: "Fern"),
    DinoFloraPlant(id: "fungi", formation: "la-amarga", formationFolder: "La_Amarga", taxon: "fungi", displayName: "Fungi"),
    DinoFloraPlant(id: "ginkgo", formation: "morrison", formationFolder: "Morrison", taxon: "ginkgo", displayName: "Ginkgo"),
    DinoFloraPlant(id: "ginkgoites", formation: "la-amarga", formationFolder: "La_Amarga", taxon: "ginkgoites", displayName: "Ginkgoites"),
    DinoFloraPlant(id: "horsetails", formation: "kem-kem", formationFolder: "Kem_Kem", taxon: "horsetail", displayName: "Horsetails"),
    DinoFloraPlant(id: "kauri", formation: "huincul", formationFolder: "Huincul", taxon: "kauri", displayName: "Kauri"),
    DinoFloraPlant(id: "kelp", formation: "tahora", formationFolder: "Tahora", taxon: "kelp", displayName: "Kelp"),
    DinoFloraPlant(id: "laurel", formation: "lance-hell-creek", formationFolder: "Lance_Hell_Creek", taxon: "laurel", displayName: "Laurel"),
    DinoFloraPlant(id: "liverwort", formation: "jiufotang", formationFolder: "Jiufotang", taxon: "liverwort", displayName: "Liverwort"),
    DinoFloraPlant(id: "magnolia", formation: "lance-hell-creek", formationFolder: "Lance_Hell_Creek", taxon: "magnolia", displayName: "Magnolia"),
    DinoFloraPlant(id: "magnoliid", formation: "tahora", formationFolder: "Tahora", taxon: "magnoliid", displayName: "Magnoliid"),
    DinoFloraPlant(id: "mamaku", formation: "jiufotang", formationFolder: "Jiufotang", taxon: "mamaku", displayName: "Mamaku"),
    DinoFloraPlant(id: "metasequoia", formation: "horseshoe-canyon", formationFolder: "Horseshoe_Canyon", taxon: "metasequoia", displayName: "Metasequoia"),
    DinoFloraPlant(id: "moss", formation: "morrison", formationFolder: "Morrison", taxon: "moss", displayName: "Moss"),
    DinoFloraPlant(id: "oak", formation: "lance-hell-creek", formationFolder: "Lance_Hell_Creek", taxon: "oak", displayName: "Oak"),
    DinoFloraPlant(id: "paleopus", formation: "tahora", formationFolder: "Tahora", taxon: "paleopus", displayName: "Paleopus"),
    DinoFloraPlant(id: "palm", formation: "solnhofen", formationFolder: "Solnhofen", taxon: "palm", displayName: "Palm"),
    DinoFloraPlant(id: "ponga", formation: "la-amarga", formationFolder: "La_Amarga", taxon: "ponga", displayName: "Ponga"),
    DinoFloraPlant(id: "redwood", formation: "horseshoe-canyon", formationFolder: "Horseshoe_Canyon", taxon: "redwood", displayName: "Redwood"),
    DinoFloraPlant(id: "rimu", formation: "la-amarga", formationFolder: "La_Amarga", taxon: "rimu", displayName: "Rimu"),
    DinoFloraPlant(id: "sycamore", formation: "kem-kem", formationFolder: "Kem_Kem", taxon: "sycamore", displayName: "Sycamore"),
    DinoFloraPlant(id: "taxodium", formation: "horseshoe-canyon", formationFolder: "Horseshoe_Canyon", taxon: "taxodium", displayName: "Taxodium"),
    DinoFloraPlant(id: "totara", formation: "la-amarga", formationFolder: "La_Amarga", taxon: "totara", displayName: "Totara"),
    DinoFloraPlant(id: "tree-fern", formation: "morrison", formationFolder: "Morrison", taxon: "tree-fern", displayName: "Tree Fern"),
    DinoFloraPlant(id: "walnut", formation: "iren-dabasu", formationFolder: "Iren_Dabasu", taxon: "walnut", displayName: "Walnut"),
    DinoFloraPlant(id: "water-lilies", formation: "jiufotang", formationFolder: "Jiufotang", taxon: "water-lilies", displayName: "Water Lilies"),
]

// MARK: - Ptero Flora plants

/// Plants for Ptero Flora rounds — kept here so tests and `PteroFloraGameView` share one list.
let pteroFloraPlants: [PteroFloraPlant] = [
    PteroFloraPlant(id: "densus-ciula-hateg-tree-fern", formation: "densus-ciula", formationFolder: "Densus_Ciula", taxon: "hateg-tree-fern", displayName: "Hateg Tree Fern"),
    PteroFloraPlant(id: "densus-ciula-magnoliid", formation: "densus-ciula", formationFolder: "Densus_Ciula", taxon: "magnoliid", displayName: "Magnoliid"),
    PteroFloraPlant(id: "densus-ciula-small-araucariacea", formation: "densus-ciula", formationFolder: "Densus_Ciula", taxon: "small-araucariacea", displayName: "Small Araucariacea"),
    PteroFloraPlant(id: "densus-ciula-zizyphus-scrub", formation: "densus-ciula", formationFolder: "Densus_Ciula", taxon: "zizyphus-scrub", displayName: "Zizyphus Scrub"),
    PteroFloraPlant(id: "dinosaur-park-fern-undergrowth", formation: "dinosaur-park", formationFolder: "Dinosaur_Park", taxon: "fern-undergrowth", displayName: "Fern Undergrowth"),
    PteroFloraPlant(id: "dinosaur-park-platanoid-leaves", formation: "dinosaur-park", formationFolder: "Dinosaur_Park", taxon: "platanoid-leaves", displayName: "Platanoid Leaves"),
    PteroFloraPlant(id: "dinosaur-park-taxodiaceous-conifers", formation: "dinosaur-park", formationFolder: "Dinosaur_Park", taxon: "taxodiaceous-conifers", displayName: "Taxodiaceous Conifers"),
    PteroFloraPlant(id: "javelina-conifer", formation: "javelina", formationFolder: "Javelina", taxon: "conifer", displayName: "Conifer"),
    PteroFloraPlant(id: "javelina-early-angiosperm", formation: "javelina", formationFolder: "Javelina", taxon: "early-angiosperm", displayName: "Early Angiosperm"),
    PteroFloraPlant(id: "javelina-palm-like-leaves", formation: "javelina", formationFolder: "Javelina", taxon: "palm-like-leaves", displayName: "Palm-like Leaves"),
    PteroFloraPlant(id: "cycad", formation: "karabastau", formationFolder: "Karabastau", taxon: "cycad", displayName: "Cycads"),
    PteroFloraPlant(id: "ginkgoales", formation: "karabastau", formationFolder: "Karabastau", taxon: "ginkgoales", displayName: "Ginkgoales"),
    PteroFloraPlant(id: "equisetites", formation: "karabastau", formationFolder: "Karabastau", taxon: "equisetites", displayName: "Equisetites"),
    PteroFloraPlant(id: "araucariaceae", formation: "karabastau", formationFolder: "Karabastau", taxon: "araucariacea", displayName: "Araucariaceae"),
    PteroFloraPlant(id: "palm-like-leaves", formation: "karabastau", formationFolder: "Karabastau", taxon: "palm-like-leaves", displayName: "Palm-like Leaves"),
    PteroFloraPlant(id: "conifer", formation: "karabastau", formationFolder: "Karabastau", taxon: "conifer", displayName: "Conifer"),
    PteroFloraPlant(id: "early-angiosperm", formation: "karabastau", formationFolder: "Karabastau", taxon: "early-angiosperm", displayName: "Early Angiosperm"),
    PteroFloraPlant(id: "lagarcito-cheirolepidiaceae", formation: "lagarcito", formationFolder: "Lagarcito", taxon: "cheirolepidiaceae", displayName: "Cheirolepidiaceae"),
    PteroFloraPlant(id: "lagarcito-gnetales", formation: "lagarcito", formationFolder: "Lagarcito", taxon: "gnetales", displayName: "Gnetales"),
    PteroFloraPlant(id: "lagarcito-microscopic-algae", formation: "lagarcito", formationFolder: "Lagarcito", taxon: "microscopic-algae", displayName: "Microscopic Algae"),
    PteroFloraPlant(id: "muwaqqar-chalk-coccolith-bloom", formation: "muwaqqar-chalk", formationFolder: "Muwaqqar_Chalk", taxon: "coccolith-bloom", displayName: "Coccolith Bloom"),
    PteroFloraPlant(id: "muwaqqar-chalk-diatoms", formation: "muwaqqar-chalk", formationFolder: "Muwaqqar_Chalk", taxon: "diatoms", displayName: "Diatoms"),
    PteroFloraPlant(id: "muwaqqar-chalk-dinoflagellates", formation: "muwaqqar-chalk", formationFolder: "Muwaqqar_Chalk", taxon: "dinoflagellates", displayName: "Dinoflagellates"),
    PteroFloraPlant(id: "muwaqqar-chalk-radiolarians", formation: "muwaqqar-chalk", formationFolder: "Muwaqqar_Chalk", taxon: "radiolarians", displayName: "Radiolarians"),
    PteroFloraPlant(id: "plottier-hardy-fern", formation: "plottier", formationFolder: "Plottier", taxon: "hardy-fern", displayName: "Hardy Fern"),
    PteroFloraPlant(id: "plottier-equisetites", formation: "plottier", formationFolder: "Plottier", taxon: "equisetites", displayName: "Equisetites"),
    PteroFloraPlant(id: "plottier-podocarp-conifer", formation: "plottier", formationFolder: "Plottier", taxon: "podocarp-conifer", displayName: "Podocarp Conifer"),
    PteroFloraPlant(id: "santana-romualdo-araucariaceae", formation: "santana-romualdo", formationFolder: "Santana_Romualdo", taxon: "araucariaceae", displayName: "Araucariaceae"),
    PteroFloraPlant(id: "santana-romualdo-bennettitales-shrub", formation: "santana-romualdo", formationFolder: "Santana_Romualdo", taxon: "bennettitales-shrub", displayName: "Bennettitales Shrub"),
    PteroFloraPlant(id: "santana-romualdo-brachyphyllum-conifer", formation: "santana-romualdo", formationFolder: "Santana_Romualdo", taxon: "brachyphyllum-conifer", displayName: "Brachyphyllum Conifer"),
    PteroFloraPlant(id: "santana-romualdo-early-angiosperm-lilypads", formation: "santana-romualdo", formationFolder: "Santana_Romualdo", taxon: "early-angiosperm-lilypads", displayName: "Early Angiosperm Lilypads"),
    PteroFloraPlant(id: "tangshang-early-hardwood", formation: "tangshang", formationFolder: "Tangshang", taxon: "early-hardwood", displayName: "Early Hardwood"),
    PteroFloraPlant(id: "tangshang-ferns", formation: "tangshang", formationFolder: "Tangshang", taxon: "ferns", displayName: "Ferns"),
    PteroFloraPlant(id: "tangshang-ginkgo", formation: "tangshang", formationFolder: "Tangshang", taxon: "ginkgo", displayName: "Ginkgo"),
    PteroFloraPlant(id: "tangshang-conifer", formation: "tangshang", formationFolder: "Tangshang", taxon: "conifer", displayName: "Conifer"),
    PteroFloraPlant(id: "tiaojishan-cycadophytes", formation: "tiaojishan", formationFolder: "Tiaojishan", taxon: "cycadophytes", displayName: "Cycadophytes"),
    PteroFloraPlant(id: "tiaojishan-dense-conifer-forest", formation: "tiaojishan", formationFolder: "Tiaojishan", taxon: "dense-conifer-forest", displayName: "Dense Conifer Forest"),
    PteroFloraPlant(id: "tiaojishan-dicksoniaceous-ferns", formation: "tiaojishan", formationFolder: "Tiaojishan", taxon: "dicksoniaceous-ferns", displayName: "Dicksoniaceous Ferns"),
    PteroFloraPlant(id: "tiaojishan-giant-horsetails", formation: "tiaojishan", formationFolder: "Tiaojishan", taxon: "giant-horsetails", displayName: "Giant Horsetails"),
    PteroFloraPlant(id: "tiaojishan-ginkgoites", formation: "tiaojishan", formationFolder: "Tiaojishan", taxon: "ginkgoites", displayName: "Ginkgoites"),
]

// MARK: - Marine Flora plants

/// Plants for Marine Flora rounds — kept here so tests and `MarineFloraGameView` share one list.
let marineFloraPlants: [MarineFloraPlant] = [
    MarineFloraPlant(id: "blue-lias-crinoid", formation: "blue-lias", formationFolder: "Blue_Lias", taxon: "crinoid", displayName: "Crinoid"),
    MarineFloraPlant(id: "cambridge-greensand-thalassotaenia-seagrass", formation: "cambridge-greensand", formationFolder: "Cambridge_Greensand", taxon: "thalassotaenia-seagrass", displayName: "Thalassotaenia Seagrass"),
    MarineFloraPlant(id: "carlile-shale-brown-algae", formation: "carlile-shale", formationFolder: "Carlile_Shale", taxon: "brown-algae", displayName: "Brown Algae"),
    MarineFloraPlant(id: "conway-seaweed", formation: "conway", formationFolder: "Conway", taxon: "seaweed", displayName: "Seaweed"),
    MarineFloraPlant(id: "muwaqqar-chalk-seagrass", formation: "muwaqqar-chalk", formationFolder: "Muwaqqar_Chalk", taxon: "seagrass", displayName: "Seagrass"),
    MarineFloraPlant(id: "navesink-seagrass", formation: "navesink", formationFolder: "Navesink", taxon: "seagrass", displayName: "Seagrass"),
    MarineFloraPlant(id: "nkporo-shale-mangrove", formation: "nkporo-shale", formationFolder: "Nkporo_Shale", taxon: "mangrove", displayName: "Mangrove"),
    MarineFloraPlant(id: "ouled-abdoun-seagrass", formation: "ouled-abdoun", formationFolder: "Ouled_Abdoun_Basin", taxon: "seagrass", displayName: "Seagrass"),
    MarineFloraPlant(id: "pierre-shale-algae", formation: "pierre-shale", formationFolder: "Pierre_Shale", taxon: "algae", displayName: "Algae"),
    MarineFloraPlant(id: "poseidon-shale-crinoid", formation: "poseidon-shale", formationFolder: "Poseidon_Shale", taxon: "crinoid", displayName: "Crinoid"),
]
