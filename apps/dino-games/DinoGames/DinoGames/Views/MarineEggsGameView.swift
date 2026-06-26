//
//  MarineEggsGameView.swift
//  DinoGames
//
//  Marine Eggs!: sea eggs game using shared EggsGameView (same CT-scanner flow as Dino/Ptero Eggs).
//
//  Round kinds:
//  - **Nest + egg** (`marine-eggs-egg-{slug}` + `marine-eggs-nest-{slug}`): main image alternates nest ↔ egg;
//    after CT scan, spawn/live art when bundled, else the matching `marine-{group}-{slug}` body card.
//  - **Specimen only** (`marine-eggs-live-{slug}` or `marine-eggs-spawn-{slug}` without a nest/egg pair):
//    main image stays on that live/spawn art — no nest/egg flashing.
//

import SwiftUI

typealias MarineEggsRound = EggsGameRound
typealias MarineEggsGameConfig = EggsGameConfig

struct MarineEggsGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: MarineEggsGameConfig

    var body: some View {
        EggsGameView(isPresented: $isPresented, gameConfig: gameConfig)
    }
}

// MARK: - Marine egg morphology

enum MarineEggsRoundStyle {
    /// Classic: egg + nest for the same slug; optional spawn/live on scan.
    case nestAndEgg
    /// Live or spawn only (e.g. fish, or species without nest art); fixed main image, no nest↔egg carousel.
    case specimenOnly
}

enum MarineEggMorphology {
    private static let eggPrefix = "marine-eggs-egg-"
    private static let nestPrefix = "marine-eggs-nest-"
    private static let livePrefix = "marine-eggs-live-"
    private static let spawnPrefix = "marine-eggs-spawn-"

    /// Catalog slugs with bundled `marine-eggs-egg-*` + `marine-eggs-nest-*`.
    static var playableNestEggSlugs: Set<String> {
        let nestSlugs = assetSlugs(withPrefix: nestPrefix)
        return Set(
            nestSlugs.filter { slug in
                ImageAssetCache.imageExists(named: eggAssetName(forCatalogSlug: slug))
                    && ImageAssetCache.imageExists(named: marineAsset("nest", slug: slug))
            }
        )
    }

    /// Slugs with spawn or live art and a matching marine body card, but no nest+egg pair.
    static var playableSpecimenOnlySlugs: Set<String> {
        let candidates = assetSlugs(withPrefix: spawnPrefix).union(assetSlugs(withPrefix: livePrefix))
        return Set(
            candidates.filter { slug in
                !playableNestEggSlugs.contains(slug)
                    && specimenDisplayAssetName(forCatalogSlug: slug) != nil
                    && SeaMarineReptileData.allMarineReptiles.contains { creatureSlug(from: $0) == slug }
            }
        )
    }

    static var allPlayableSlugs: Set<String> {
        playableNestEggSlugs.union(playableSpecimenOnlySlugs)
    }

    private static func assetSlugs(withPrefix prefix: String) -> Set<String> {
        Set(
            ImageAssetNames.knownAssets.compactMap { name -> String? in
                guard name.hasPrefix(prefix) else { return nil }
                let slug = String(name.dropFirst(prefix.count))
                return slug.isEmpty ? nil : slug
            }
        )
    }

    static func creatureSlug(from marine: Dinosaur) -> String? {
        guard let imageName = marine.imageName, imageName.hasPrefix("marine-") else { return nil }
        let parts = imageName.split(separator: "-", omittingEmptySubsequences: true)
        guard parts.count >= 3 else { return nil }
        return parts.dropFirst(2).joined(separator: "-")
    }

    static func roundStyle(forSlug slug: String) -> MarineEggsRoundStyle? {
        if playableNestEggSlugs.contains(slug) { return .nestAndEgg }
        if playableSpecimenOnlySlugs.contains(slug) { return .specimenOnly }
        return nil
    }

    /// Resolves which catalog slug this creature uses in Marine Eggs, if any.
    static func marineEggsSlug(for marine: Dinosaur) -> String? {
        guard let slug = creatureSlug(from: marine) else { return nil }
        return roundStyle(forSlug: slug) != nil ? slug : nil
    }

    static func nestingFallback(forSlug slug: String) -> String {
        slug.replacingOccurrences(of: "-", with: " ").capitalized + " nest"
    }

    private static func marineAsset(_ segment: String, slug: String) -> String {
        "marine-eggs-\(segment)-\(slug)"
    }

    static let morphology = EggsMorphology(
        assetPrefix: "marine-eggs",
        nestAssetPrefix: nil,
        scannerToolPrefix: "dino-eggs",
        assetStyle: .marineSegments(),
        eggType: { marineEggsSlug(for: $0) },
        nestingStyle: { slug in slug },
        nestingFallbackText: { nestingFallback(forSlug: $0) },
        scanAssetName: { slug in scanAssetName(forCatalogSlug: slug) },
        randomColorsAsset: { slug in
            if let live = liveAssetName(forCatalogSlug: slug) { return live }
            let egg = eggAssetName(forCatalogSlug: slug)
            return ImageAssetCache.imageExists(named: egg) ? egg : nil
        },
        eggImageNameResolver: { slug in eggAssetName(forCatalogSlug: slug) },
        eggAudioKeyResolver: { slug in "marine-eggs-\(slug)" }
    )

    static let sourceHints: [EggsSourceHint] = [
        EggsSourceHint(id: "shape", imageName: "source-marine-eggs-shape", displayName: "Shape", audioKey: "marine-eggs-shape"),
    ]

    static let settings = EggsGameSettings(
        morphology: morphology,
        gameKeyPrefix: "game-marine-eggs",
        gameplayDirectionsAudioKey: "game-marine-eggs-gameplay-directions",
        gameplayDirectionsFallback: "When you see the egg, tap the CT scanner to look inside.",
        beepKey: "game-dino-eggs-beep",
        scanFailedKey: "game-dino-eggs-scan-failed",
        tapCreatureAfterScanKey: nil,
        successImageName: "game-marine-eggs-success",
        creatureEmoji: "🌊",
        roundIntroNestAudioKey: nil,
        roundIntroTapScannerAudioKey: "game-dino-eggs-tap-the-scanner",
        playsEggNestNameIntro: false,
        playsTapScannerPrompt: true,
        showsCreatureNameOnCards: false,
        victoryRecapUsesCreatureName: true,
        victoryRecapLabelUsesCreatureName: false,
        sourceHints: sourceHints,
        sourceHintsTitle: "Source Eggs",
        sourceHintsGridIntroAudioKey: nil,
        playsHintsButtonIntro: false,
        onVictoryComplete: { MarineReptileProgress.notifyCompletionIfMarineGame(configId: $0) }
    )

    static func eggAssetName(forCatalogSlug slug: String) -> String {
        marineAsset("egg", slug: slug)
    }

    static func liveAssetName(forCatalogSlug slug: String) -> String? {
        let name = marineAsset("live", slug: slug)
        return ImageAssetCache.imageExists(named: name) ? name : nil
    }

    /// Main + scan art for specimen-only rounds (spawn preferred over live).
    static func specimenDisplayAssetName(forCatalogSlug slug: String) -> String? {
        let spawn = marineAsset("spawn", slug: slug)
        if ImageAssetCache.imageExists(named: spawn) { return spawn }
        return liveAssetName(forCatalogSlug: slug)
    }

    /// Bundled `marine-{group}-{slug}` body card for this catalog slug (first match in the marine pool).
    static func marineBodyAssetName(forCatalogSlug slug: String) -> String? {
        for marine in SeaMarineReptileData.allMarineReptiles {
            guard creatureSlug(from: marine) == slug,
                  let name = marine.imageName,
                  name.hasPrefix("marine-"),
                  ImageAssetCache.imageExists(named: name) else { continue }
            return name
        }
        return nil
    }

    /// CT scan reveal for nest+egg rounds: dedicated scan art → spawn → live → body card → egg.
    static func scanAssetName(forCatalogSlug slug: String) -> String {
        let dedicated = marineAsset("scan", slug: slug)
        if ImageAssetCache.imageExists(named: dedicated) { return dedicated }
        let spawn = marineAsset("spawn", slug: slug)
        if ImageAssetCache.imageExists(named: spawn) { return spawn }
        if let live = liveAssetName(forCatalogSlug: slug) { return live }
        let egg = eggAssetName(forCatalogSlug: slug)
        if let body = marineBodyAssetName(forCatalogSlug: slug), body != egg {
            return body
        }
        return egg
    }

    static func roundAssetsExist(forSlug slug: String) -> Bool {
        roundStyle(forSlug: slug) != nil
    }

    // MARK: - Legacy aliases

    static var playableEggSlugs: Set<String> { playableNestEggSlugs }

    static func eggSlug(for marine: Dinosaur) -> String? {
        guard let slug = marineEggsSlug(for: marine),
              roundStyle(forSlug: slug) == .nestAndEgg else { return nil }
        return slug
    }
}

// MARK: - Game config

struct MarineEggsGameConfigs {
    private static let marineEggsRoundCount = 3

    static var isPlayable: Bool {
        makeMarineEggs() != nil
    }

    static func makeMarineEggs() -> MarineEggsGameConfig? {
        let pool = marineReptilesForEggsGame
        let bySlug = Dictionary(grouping: pool.compactMap { creature -> (Dinosaur, String)? in
            guard let slug = MarineEggMorphology.marineEggsSlug(for: creature) else { return nil }
            return (creature, slug)
        }) { $0.1 }
        .mapValues { $0.map(\.0) }

        let playableSlugs = Array(bySlug.keys)
        var usedIds: Set<Int> = []
        var usedSlugs: Set<String> = []
        var rounds: [MarineEggsRound] = []

        for roundId in 1...marineEggsRoundCount {
            let availableSlugs = playableSlugs.filter { slug in
                !usedSlugs.contains(slug)
                    && (bySlug[slug] ?? []).contains { !usedIds.contains($0.id) }
            }
            guard let slug = availableSlugs.randomElement() else { break }

            let slugPool = (bySlug[slug] ?? []).filter { !usedIds.contains($0.id) }
            guard let correct = slugPool.randomElement() else { continue }

            guard let distractors = pickTwoDistractors(
                correctSlug: slug,
                bySlug: bySlug,
                playableSlugs: playableSlugs,
                usedIds: usedIds,
                excludingCorrectId: correct.id
            ) else { continue }

            let style = MarineEggMorphology.roundStyle(forSlug: slug) ?? .nestAndEgg
            let alternatesNestAndEgg = style == .nestAndEgg
            let fixedAsset = alternatesNestAndEgg
                ? nil
                : MarineEggMorphology.specimenDisplayAssetName(forCatalogSlug: slug)

            usedIds.insert(correct.id)
            usedIds.formUnion(distractors.map(\.id))
            usedSlugs.insert(slug)
            rounds.append(MarineEggsRound(
                id: roundId,
                correctCreature: correct,
                eggType: slug,
                nestingStyle: slug,
                distractors: distractors,
                alternatesNestAndEgg: alternatesNestAndEgg,
                fixedMainImageAssetName: fixedAsset
            ))
        }

        let required = min(marineEggsRoundCount, max(1, playableSlugs.count))
        guard rounds.count >= required else { return nil }

        return MarineEggsGameConfig(
            settings: MarineEggMorphology.settings,
            totalRounds: min(marineEggsRoundCount, rounds.count),
            id: "marine-eggs",
            title: "Marine Eggs!",
            introAudio: "game-marine-eggs",
            gameplayDirectionsAudio: "game-marine-eggs-gameplay-directions",
            rounds: Array(rounds.prefix(marineEggsRoundCount))
        )
    }

    static var marineEggs: MarineEggsGameConfig {
        guard let config = makeMarineEggs() else {
            preconditionFailure(
                "Marine Eggs is not playable (pool \(marineReptilesForEggsGame.count) creatures). " +
                "Bundle nest+egg pairs and/or live/spawn specimen art with matching marine body cards."
            )
        }
        return config
    }

    private static func pickTwoDistractors(
        correctSlug: String,
        bySlug: [String: [Dinosaur]],
        playableSlugs: [String],
        usedIds: Set<Int>,
        excludingCorrectId: Int
    ) -> [Dinosaur]? {
        let otherSlugs = playableSlugs.filter { $0 != correctSlug }.shuffled()
        guard otherSlugs.count >= 2 else { return nil }

        var distractors: [Dinosaur] = []
        for slug in otherSlugs {
            guard distractors.count < 2 else { break }
            let candidates = (bySlug[slug] ?? []).filter { creature in
                creature.id != excludingCorrectId
                    && !usedIds.contains(creature.id)
                    && !distractors.contains(where: { $0.id == creature.id })
            }
            if let pick = candidates.randomElement() {
                distractors.append(pick)
            }
        }
        return distractors.count == 2 ? distractors : nil
    }

    private static var marineReptilesForEggsGame: [Dinosaur] {
        SeaMarineReptileData.allMarineReptiles.filter { creature in
            guard let imageName = creature.imageName, imageName.hasPrefix("marine-"),
                  ImageAssetCache.imageExists(named: imageName) else { return false }
            guard let slug = MarineEggMorphology.marineEggsSlug(for: creature) else { return false }
            return MarineEggMorphology.roundAssetsExist(forSlug: slug)
        }
    }
}
