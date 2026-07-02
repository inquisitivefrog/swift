//
//  MarineEggsGameView.swift
//  DinoGames
//
//  Marine Eggs!: match a morphotype (egg/nest, live birth, or spawn) to one of three marine reptiles.
//  Audio: morphotype clips under `Audio/Marine-Eggs/` (hint under `Marine-Eggs/hints/`); gameplay UI under `Audio/Games/`.
//
//  Layout (differs from Marine Flora, which shows habitat+seeds and asks the player to pick three from five):
//  - **Large image:** nest ↔ egg carousel, or fixed live/spawn art when no nest+egg pair exists.
//  - **Three small portraits:** one correct match + two distractors; each portrait should be a different clade.
//  - **Per round:** a new morphotype clade and three fresh reptiles (nine distinct species across a full game when the pool allows).
//  - **Intro each round:** gameplay directions, then scanner or morphotype narration, then each of the three portraits is highlighted and named — no “which three” grid prompt (that belongs to Marine Flora).
//
//  Round kinds:
//  - **Nest + egg** (`marine-eggs-egg-{slug}` + `marine-eggs-nest-{slug}`): main image alternates nest ↔ egg;
//    CT scan reveals interior art when available.
//  - **Specimen only** (`marine-eggs-live-{slug}` or `marine-eggs-spawn-{slug}` without a nest/egg pair):
//    main image stays on that live/spawn art; CT scanner is disabled and morphotype audio explains why.
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

    static func cladeDisplayTitle(for creature: Dinosaur) -> String {
        SeaMarineReptileData.displayTitleForMarineGroup(
            SeaMarineReptileData.marineCladeRawValue(for: creature)
        )
    }

    static func cladeAudioKey(for creature: Dinosaur) -> String {
        let raw = SeaMarineReptileData.marineCladeRawValue(for: creature)
        return "marine-clade-\(SeaMarineReptileData.audioSlugForMarineGroupRaw(raw))"
    }

    static func marineCreature(forCatalogSlug slug: String) -> Dinosaur? {
        SeaMarineReptileData.allMarineReptiles.first { creatureSlug(from: $0) == slug }
    }

    static func morphotypeCladeKey(forCatalogSlug slug: String) -> String {
        let raw = marineCreature(forCatalogSlug: slug)
            .map { SeaMarineReptileData.marineCladeRawValue(for: $0) } ?? "basal"
        return SeaMarineReptileData.audioSlugForMarineGroupRaw(raw)
    }

    static func morphotypeCladeKey(for creature: Dinosaur) -> String {
        guard let slug = marineEggsSlug(for: creature) else {
            return SeaMarineReptileData.audioSlugForMarineGroupRaw(
                SeaMarineReptileData.marineCladeRawValue(for: creature)
            )
        }
        return morphotypeCladeKey(forCatalogSlug: slug)
    }

    /// Victory row label: egg / live / spawn morphotype for this catalog slug — not the matched species body-card group.
    static func morphotypeVictoryDisplayTitle(forCatalogSlug slug: String) -> String {
        switch roundStyle(forSlug: slug) {
        case .specimenOnly:
            if ImageAssetCache.imageExists(named: marineAsset("spawn", slug: slug)) {
                return "Spawn"
            }
            return morphotypeCladeDisplayTitle(morphotypeCladeKey(forCatalogSlug: slug))
        case .nestAndEgg, nil:
            return morphotypeCladeDisplayTitle(morphotypeCladeKey(forCatalogSlug: slug))
        }
    }

    static func morphotypeCladeDisplayTitle(_ cladeKey: String) -> String {
        switch cladeKey {
        case "testudine": return "Testudine"
        case "mosasaur": return "Mosasaur"
        case "nothosaur": return "Nothosaur"
        case "thalattosuchia": return "Thalattosuchian"
        case "basal": return "Basal"
        case "halisaur": return "Halisaur"
        case "ichthyosaur": return "Ichthyosaur"
        case "plesiosaur": return "Plesiosaur"
        case "pliosaur": return "Pliosaur"
        case "tylosaur": return "Tylosaur"
        case "teleostei": return "Teleostei"
        default:
            return cladeKey.replacingOccurrences(of: "-", with: " ").capitalized
        }
    }

    /// Post-scan morphotype narration: `marine-eggs-{clade}`, `marine-live-{clade}`, or `marine-spawn-{clade}`.
    static func morphotypeAudioKey(forCatalogSlug slug: String) -> String {
        let raw = marineCreature(forCatalogSlug: slug)
            .map { SeaMarineReptileData.marineCladeRawValue(for: $0) } ?? "basal"
        let audioSlug = SeaMarineReptileData.audioSlugForMarineGroupRaw(raw)
        switch roundStyle(forSlug: slug) {
        case .specimenOnly:
            let spawnAsset = marineAsset("spawn", slug: slug)
            if ImageAssetCache.imageExists(named: spawnAsset) {
                return "marine-spawn-\(audioSlug)"
            }
            return "marine-live-\(audioSlug)"
        case .nestAndEgg, nil:
            return "marine-eggs-\(audioSlug)"
        }
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
        eggAudioKeyResolver: { slug in morphotypeAudioKey(forCatalogSlug: slug) },
        victoryRecapTitleResolver: { slug, _ in morphotypeVictoryDisplayTitle(forCatalogSlug: slug) },
        victoryRecapAudioKeyResolver: { _, creature in cladeAudioKey(for: creature) }
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
        scannerNotAvailableAudioKey: nil,
        repeatsGameplayDirectionsEachRound: true,
        roundIntroCreatureGridAudioKey: nil,
        playsEggNestNameIntro: false,
        playsTapScannerPrompt: true,
        showsCreatureNameOnCards: false,
        showsCreatureNameDuringIntro: true,
        victoryRecapUsesCreatureName: false,
        victoryRecapLabelUsesCreatureName: false,
        victoryRecapDeduplicatesByAudioKey: true,
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
        let entries: [(creature: Dinosaur, catalogSlug: String, cladeKey: String)] = pool.compactMap { creature in
            guard let slug = MarineEggMorphology.marineEggsSlug(for: creature) else { return nil }
            return (
                creature,
                slug,
                MarineEggMorphology.morphotypeCladeKey(forCatalogSlug: slug)
            )
        }
        let byClade = Dictionary(grouping: entries) { $0.cladeKey }
        let bySlug = Dictionary(grouping: entries) { $0.catalogSlug }
            .mapValues { $0.map(\.creature) }

        let playableClades = Array(byClade.keys)
        var usedIds: Set<Int> = []
        var usedClades: Set<String> = []
        var rounds: [MarineEggsRound] = []

        for roundId in 1...marineEggsRoundCount {
            let availableClades = playableClades.filter { clade in
                !usedClades.contains(clade)
                    && (byClade[clade] ?? []).contains { !usedIds.contains($0.creature.id) }
            }
            guard let clade = availableClades.randomElement(),
                  let cladePool = byClade[clade]?.filter({ !usedIds.contains($0.creature.id) }),
                  let pick = cladePool.randomElement() else { break }

            let slug = pick.catalogSlug
            let correct = pick.creature

            guard let distractors = pickTwoDistractors(
                correctSlug: slug,
                correctCladeKey: clade,
                bySlug: bySlug,
                playableSlugs: Array(bySlug.keys),
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
            usedClades.insert(clade)
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

        let required = min(marineEggsRoundCount, max(1, playableClades.count))
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
        correctCladeKey: String,
        bySlug: [String: [Dinosaur]],
        playableSlugs: [String],
        usedIds: Set<Int>,
        excludingCorrectId: Int
    ) -> [Dinosaur]? {
        var forbiddenClades: Set<String> = [correctCladeKey]
        var distractors: [Dinosaur] = []
        let otherSlugs = playableSlugs.filter { $0 != correctSlug }.shuffled()

        for slug in otherSlugs {
            guard distractors.count < 2 else { break }
            let slugClade = MarineEggMorphology.morphotypeCladeKey(forCatalogSlug: slug)
            guard !forbiddenClades.contains(slugClade) else { continue }
            let candidates = (bySlug[slug] ?? []).filter { creature in
                creature.id != excludingCorrectId
                    && !usedIds.contains(creature.id)
                    && !distractors.contains(where: { $0.id == creature.id })
            }
            if let pick = candidates.randomElement() {
                distractors.append(pick)
                forbiddenClades.insert(slugClade)
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
