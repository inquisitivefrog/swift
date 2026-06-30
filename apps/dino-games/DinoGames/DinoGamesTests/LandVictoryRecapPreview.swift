//
//  LandVictoryRecapPreview.swift
//  DinoGamesTests
//
//  Config-derived victory recap rows mirroring shipping land game views (smoke tests only).
//

import XCTest
@testable import DinoGames

enum LandVictoryRecapPreview {

    // MARK: - Shared assertions

    static func assertRecapRowsHaveDisplayableContent(
        _ items: [VictoryRecapDisplayItem],
        minimumCount: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertGreaterThanOrEqual(items.count, minimumCount, file: file, line: line)
        XCTAssertEqual(
            Set(items.map(\.id)).count,
            items.count,
            "Recap row ids should be unique",
            file: file,
            line: line
        )
        for item in items {
            XCTAssertFalse(
                item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "Recap row needs a title (id: \(item.id))",
                file: file,
                line: line
            )
            let hasVisual = (item.imageAssetName.map { ImageAssetCache.imageExists(named: $0) } ?? false)
                || item.fallbackEmoji != nil
            XCTAssertTrue(
                hasVisual,
                "Recap row needs bundled art or emoji fallback (id: \(item.id))",
                file: file,
                line: line
            )
        }
    }

    // MARK: - L1 grid games

    static func weighItems(from weighed: [WeighableItem]) -> [VictoryRecapDisplayItem] {
        weighed.map { item in
            let imageName = item.imageName.flatMap { ImageAssetCache.imageExists(named: $0) ? $0 : nil }
            return VictoryRecapDisplayItem(
                id: "\(item.id)",
                title: item.name,
                imageAssetName: imageName,
                fallbackEmoji: item.emoji
            )
        }
    }

    static func tallerItems(from compared: [WhoIsTallerItem]) -> [VictoryRecapDisplayItem] {
        compared.map { item in
            let imageName = tallerRecapImageName(for: item)
            return VictoryRecapDisplayItem(
                id: "\(item.id)",
                title: item.name,
                imageAssetName: imageName,
                fallbackEmoji: item.emoji
            )
        }
    }

    static func puzzleItemsFromCatalog() -> [VictoryRecapDisplayItem] {
        LandGameDisplayMomentCatalog.shippingLandMoments()
            .filter { $0.gameConfigId == "dino-puzzle" && $0.context.contains(" creature") }
            .map { moment in
                VictoryRecapDisplayItem(
                    id: moment.triad.id,
                    title: moment.displayText,
                    imageAssetName: ImageAssetCache.imageExists(named: moment.imageAssetName) ? moment.imageAssetName : nil,
                    fallbackEmoji: "🦕"
                )
            }
    }

    // MARK: - L2 guess / racing / ages

    static func guessItems(from config: GuessGameConfig) -> [VictoryRecapDisplayItem] {
        if config.id == "dino-footprints" {
            return config.rounds.compactMap { round in
                guard let dinosaur = round.options.first(where: { $0.id == round.correctAnswerId }) else { return nil }
                return VictoryRecapDisplayItem(
                    id: "round-\(round.id)",
                    title: dinosaur.name,
                    imageAssetName: footprintVictoryImageName(round: round, dinosaur: dinosaur),
                    fallbackEmoji: dinosaur.icon
                )
            }
        }
        var seen: Set<Int> = []
        var items: [VictoryRecapDisplayItem] = []
        for round in config.rounds {
            guard let dinosaur = round.options.first(where: { $0.id == round.correctAnswerId }) else { continue }
            guard seen.insert(dinosaur.id).inserted else { continue }
            items.append(
                VictoryRecapDisplayItem(
                    id: "\(dinosaur.id)",
                    title: dinosaur.name,
                    imageAssetName: silhouetteVictoryImageName(round: round, dinosaur: dinosaur),
                    fallbackEmoji: dinosaur.icon
                )
            )
        }
        return items
    }

    static func racingItems(winners: [RacingRacer], config: RacingGameConfig) -> [VictoryRecapDisplayItem] {
        var seen: Set<Int> = []
        return winners.filter { seen.insert($0.id).inserted }.map { racer in
            VictoryRecapDisplayItem(
                id: "\(racer.id)",
                title: racer.name,
                subtitle: String(format: "%.1f mph", racer.speed),
                imageAssetName: racingRecapImageName(for: racer, config: config),
                fallbackEmoji: racer.icon
            )
        }
    }

    static func agesItemsSimulatingPerfectGame() -> [VictoryRecapDisplayItem] {
        let pool = MatchingGameConfigs.allDinosaurs.filter { $0.imageName?.hasPrefix("dino-") == true }
        var picked: [Dinosaur] = []
        var seen = Set<Int>()
        for dino in pool {
            guard seen.insert(dino.id).inserted else { continue }
            picked.append(dino)
            if picked.count == DinoAgesMechanics.minimumUniqueDinosPerPeriod { break }
        }
        return picked.map { dino in
            VictoryRecapDisplayItem(
                id: "\(dino.id)",
                title: dino.name,
                imageAssetName: dino.imageName.flatMap { ImageAssetCache.imageExists(named: $0) ? $0 : nil },
                fallbackEmoji: dino.icon
            )
        }
    }

    // MARK: - L3 flora / eggs

    static func floraItems(from plants: [DinoFloraPlant]) -> [VictoryRecapDisplayItem] {
        plants.map { plant in
            VictoryRecapDisplayItem(
                id: plant.id,
                title: plant.displayName,
                imageAssetName: ImageAssetCache.imageExists(named: plant.treeImageName) ? plant.treeImageName : nil,
                fallbackEmoji: "🌿"
            )
        }
    }

    static func eggsItems(from config: EggsGameConfig) -> [VictoryRecapDisplayItem] {
        let morphology = config.settings.morphology
        return config.rounds.enumerated().map { index, round in
            let title = morphology.eggDisplayTitle(for: round.eggType)
            let imageName = DinoEggMorphology.coloredEggAssetName(for: round.eggType)
            return VictoryRecapDisplayItem(
                id: "\(round.eggType)-\(index)",
                title: title,
                imageAssetName: imageName,
                fallbackEmoji: "🥚"
            )
        }
    }

    // MARK: - L4 matrix / diets / smile

    static func matrixItems(from config: DinoMatrixGameConfig) -> [VictoryRecapDisplayItem] {
        config.rounds.compactMap { round in
            guard let material = config.allMaterials.first(where: { $0.id == round.correctMaterialId }) else { return nil }
            let rockName = material.matrixRockImageAssetName(
                assetPrefix: config.assetPrefix,
                tuffRockUsesVolcanicPrefix: config.tuffRockUsesVolcanicPrefix
            )
            let imageName = ImageAssetCache.imageExists(named: rockName) ? rockName : nil
            return VictoryRecapDisplayItem(
                id: "\(material.id)-\(round.id)",
                title: material.name,
                imageAssetName: imageName,
                fallbackEmoji: "🪨"
            )
        }
    }

    static func dietItems(from config: MatchingGameConfig) -> [VictoryRecapDisplayItem] {
        var seenTypes = Set<String>()
        return config.selectedDinosaurs.compactMap { dino -> VictoryRecapDisplayItem? in
            guard let dietType = MatchingGameConfigs.dinosaurDietById[dino.id],
                  let diet = MatchingGameConfigs.dinoDietOptions.first(where: { $0.type == dietType }),
                  seenTypes.insert(diet.type).inserted else { return nil }
            return VictoryRecapDisplayItem(
                id: "\(diet.id)",
                title: diet.type,
                imageAssetName: diet.imageName,
                fallbackEmoji: diet.icon
            )
        }
    }

    static func smileItems(from config: SmilingDinosGameConfig, matchedToothSlugs: [String]) -> [VictoryRecapDisplayItem] {
        let uniqueSlugs = smileVictoryRecapToothSlugs(matchedToothSlugs, line: config.line)
        return uniqueSlugs.map { toothType in
            let imageName = config.toothImageName(for: toothType)
            return VictoryRecapDisplayItem(
                id: toothType,
                title: landSmileToothDisplayName(toothType),
                imageAssetName: ImageAssetCache.imageExists(named: imageName) ? imageName : nil,
                fallbackEmoji: "🦷"
            )
        }
    }

    static func smileMatchedToothSlugs(from config: SmilingDinosGameConfig) -> [String] {
        config.rounds.flatMap { $0.pairs.map(\.toothType) }
    }

    // MARK: - Image helpers (mirrors view private logic)

    private static func tallerRecapImageName(for item: WhoIsTallerItem) -> String? {
        let base = item.imageName ?? "dino-\(item.name.lowercased().replacingOccurrences(of: " ", with: "-"))"
        let measureName = "measure-\(base)"
        if ImageAssetCache.imageExists(named: measureName) { return measureName }
        if ImageAssetCache.imageExists(named: base) { return base }
        return nil
    }

    private static func footprintVictoryImageName(round: RoundQuestion, dinosaur: Dinosaur) -> String? {
        if ImageAssetCache.imageExists(named: round.questionImageName) {
            return round.questionImageName
        }
        if let name = dinosaur.imageName, ImageAssetCache.imageExists(named: name) {
            return name
        }
        return nil
    }

    private static func silhouetteVictoryImageName(round: RoundQuestion, dinosaur: Dinosaur) -> String? {
        if ImageAssetCache.imageExists(named: round.questionImageName) {
            return round.questionImageName
        }
        if let name = dinosaur.imageName, ImageAssetCache.imageExists(named: name) {
            return name
        }
        return nil
    }

    private static func racingRecapImageName(for racer: RacingRacer, config: RacingGameConfig) -> String? {
        if config.assetPrefix == "dino" {
            for base in racer.dinoWinnerRaceAssetNames() {
                if ImageAssetCache.imageExists(named: base) { return base }
            }
            for base in racer.dinoRacerAssetBases() {
                if ImageAssetCache.imageExists(named: base) { return base }
            }
        }
        let ready = racer.readyImageName(prefix: config.assetPrefix)
        if ImageAssetCache.imageExists(named: ready) { return ready }
        let base = racer.racerImageName(prefix: config.assetPrefix)
        return ImageAssetCache.imageExists(named: base) ? base : nil
    }

    private static func landSmileToothDisplayName(_ toothType: String) -> String {
        var slug = toothType
        if let range = slug.range(of: #"-v\d+"#, options: .regularExpression) {
            slug.removeSubrange(range)
        }
        for suffix in ["-ankylosaurid", "-ceratopsian", "-stegosaurid"] {
            slug = slug.replacingOccurrences(of: suffix, with: "")
        }
        return slug.replacingOccurrences(of: "-", with: " ").capitalized
    }
}
