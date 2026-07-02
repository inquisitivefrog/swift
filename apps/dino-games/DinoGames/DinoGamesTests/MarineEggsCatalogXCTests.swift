//
//  MarineEggsCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class MarineEggsCatalogXCTests: XCTestCase {

    private var eggsMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingMarineMoments().filter { $0.gameConfigId == "marine-eggs" }
    }

    /// Slugs referenced by bundled `marine-eggs-{egg|nest|live|spawn}-*` imagesets.
    private var discoveredCatalogSlugs: Set<String> {
        let prefixes = [
            "marine-eggs-egg-",
            "marine-eggs-nest-",
            "marine-eggs-live-",
            "marine-eggs-spawn-",
        ]
        var slugs: Set<String> = []
        for name in ImageAssetNames.knownAssets {
            for prefix in prefixes {
                guard name.hasPrefix(prefix) else { continue }
                let slug = String(name.dropFirst(prefix.count))
                if !slug.isEmpty { slugs.insert(slug) }
            }
        }
        return slugs
    }

    func testMarineCatalogBuildsWithoutFatalErrorWhenEggsUnavailable() {
        XCTAssertNoThrow({
            _ = MarineReptileGameCatalog.games
            _ = MarineReptileProgress.allMarineGameCanonicalIds
        }())
    }

    func testMarineEggsConfigMapsToMarineReptilesCategory() {
        guard MarineEggsGameConfigs.makeMarineEggs() != nil else {
            XCTFail("Expected Marine Eggs to be playable for category mapping")
            return
        }
        XCTAssertEqual(GameCategory.forCatalogConfigId("marine-eggs"), .marineReptiles)
    }

    func testMarineEggAssetsEnablePlayableGame() {
        XCTAssertFalse(MarineEggMorphology.playableNestEggSlugs.isEmpty, "Expected marine-eggs-egg + nest pairs in the catalog")
        XCTAssertTrue(MarineEggsGameConfigs.isPlayable, "Marine Eggs should register on level 3 when egg/nest art is bundled")
        XCTAssertTrue(
            MarineReptileGameCatalog.games(level: .level3).contains { $0.id == "marine-eggs" },
            "Marine Eggs should appear in the marine level-3 picker"
        )
    }

    func testMesoleptosHasMatchingEggAndNest() {
        XCTAssertTrue(MarineEggMorphology.playableNestEggSlugs.contains("mesoleptos"))
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("marine-eggs-egg-mesoleptos"))
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("marine-eggs-nest-mesoleptos"))
    }

    func testMarineEggsVictoryUsesCladeRecapNotSpeciesNames() {
        XCTAssertFalse(MarineEggMorphology.settings.victoryRecapUsesCreatureName)
        XCTAssertFalse(MarineEggMorphology.settings.victoryRecapLabelUsesCreatureName)
        XCTAssertEqual(
            MarineEggMorphology.morphotypeAudioKey(forCatalogSlug: "archelon"),
            "marine-eggs-testudine"
        )
        XCTAssertEqual(
            MarineEggMorphology.morphotypeAudioKey(forCatalogSlug: "halisaurus"),
            "marine-live-halisaur"
        )
        XCTAssertEqual(
            MarineEggMorphology.morphotypeAudioKey(forCatalogSlug: "enchodus"),
            "marine-spawn-teleostei"
        )
    }

    @MainActor
    func testMarineEggsVictoryRecapUsesCladeLabelsAndAudio() {
        guard let config = MarineEggsGameConfigs.makeMarineEggs() else {
            XCTFail("Expected Marine Eggs config")
            return
        }
        let settings = MarineEggMorphology.settings
        let morphology = MarineEggMorphology.morphology
        let speech = SpeechManager()

        for round in config.rounds {
            let creature = round.correctCreature
            let morphotypeTitle = MarineEggMorphology.morphotypeVictoryDisplayTitle(forCatalogSlug: round.eggType)
            let cladeAudioKey = MarineEggMorphology.cladeAudioKey(for: creature)
            let speciesAudioKey = creature.imageName ?? creature.name

            let displayTitle = settings.victoryRecapLabelUsesCreatureName
                ? creature.name
                : morphology.victoryRecapTitle(forEggType: round.eggType, creature: creature)
            let victoryAudioKey = settings.victoryRecapUsesCreatureName
                ? speciesAudioKey
                : morphology.victoryRecapAudioKey(forEggType: round.eggType, creature: creature)

            XCTAssertFalse(morphotypeTitle.isEmpty)
            XCTAssertEqual(displayTitle, morphotypeTitle, "Recap row text should use morphotype labels")
            XCTAssertEqual(victoryAudioKey, cladeAudioKey, "Recap narration should use marine clade audio")
            XCTAssertNotEqual(
                victoryAudioKey,
                speciesAudioKey,
                "Recap audio should name the clade (`\(cladeAudioKey)`), not species (`\(speciesAudioKey)`)"
            )
            XCTAssertTrue(
                victoryAudioKey.hasPrefix("marine-clade-"),
                "Expected marine clade audio key, got `\(victoryAudioKey)`"
            )
            XCTAssertNotNil(
                speech.urlForAudio(key: victoryAudioKey),
                "Missing bundled marine clade clip: \(victoryAudioKey)"
            )
        }
    }

    func testMarineEggsMorphotypeVictoryDisplayTitles() {
        XCTAssertEqual(MarineEggMorphology.morphotypeVictoryDisplayTitle(forCatalogSlug: "archelon"), "Testudine")
        XCTAssertEqual(MarineEggMorphology.morphotypeVictoryDisplayTitle(forCatalogSlug: "protostega"), "Testudine")
        XCTAssertEqual(MarineEggMorphology.morphotypeVictoryDisplayTitle(forCatalogSlug: "proganochelys"), "Testudine")
        XCTAssertEqual(MarineEggMorphology.morphotypeVictoryDisplayTitle(forCatalogSlug: "halisaurus"), "Halisaur")
        XCTAssertEqual(MarineEggMorphology.morphotypeVictoryDisplayTitle(forCatalogSlug: "gillicus"), "Spawn")
        XCTAssertEqual(MarineEggMorphology.morphotypeVictoryDisplayTitle(forCatalogSlug: "enchodus"), "Spawn")
    }

    func testMarineEggsVictoryRecapEggDisplayTitlesAreNonEmpty() {
        guard let config = MarineEggsGameConfigs.makeMarineEggs() else {
            XCTFail("Expected Marine Eggs config")
            return
        }
        let morphology = MarineEggMorphology.morphology
        for round in config.rounds {
            let title = morphology.eggDisplayTitle(for: round.eggType)
            XCTAssertFalse(title.isEmpty, "Victory recap needs a label for egg slug `\(round.eggType)`")
        }
    }

    func testMarineEggsConfigBuildsThreeDistinctCreatureRounds() {
        guard let config = MarineEggsGameConfigs.makeMarineEggs() else {
            XCTFail("Expected Marine Eggs config")
            return
        }
        XCTAssertEqual(config.id, "marine-eggs")
        XCTAssertEqual(config.rounds.count, 3)
        XCTAssertEqual(Set(config.rounds.map(\.correctCreature.id)).count, 3)
    }

    func testMarineEggsConfigBuildsThreeDistinctMorphotypeClades() {
        guard let config = MarineEggsGameConfigs.makeMarineEggs() else {
            XCTFail("Expected Marine Eggs config")
            return
        }
        let cladeKeys = config.rounds.map {
            MarineEggMorphology.morphotypeCladeKey(for: $0.correctCreature)
        }
        XCTAssertEqual(cladeKeys.count, 3)
        XCTAssertEqual(Set(cladeKeys).count, 3, "Each round should use a different morphotype clade")
    }

    func testMarineEggsDistractorsUseDistinctCladesFromCorrectAnswer() {
        guard let config = MarineEggsGameConfigs.makeMarineEggs() else {
            XCTFail("Expected Marine Eggs config")
            return
        }
        for round in config.rounds {
            let correctClade = MarineEggMorphology.morphotypeCladeKey(for: round.correctCreature)
            let distractorClades = round.distractors.map {
                MarineEggMorphology.morphotypeCladeKey(for: $0)
            }
            XCTAssertEqual(distractorClades.count, 2)
            XCTAssertEqual(Set(distractorClades).count, 2, "Distractors should be from two different clades")
            for clade in distractorClades {
                XCTAssertNotEqual(
                    clade,
                    correctClade,
                    "Round with \(round.correctCreature.name) should not include another \(clade) distractor"
                )
            }
        }
    }

    func testMarineEggsRepeatsGameplayDirectionsEachRound() {
        XCTAssertTrue(MarineEggMorphology.settings.repeatsGameplayDirectionsEachRound)
        XCTAssertNil(MarineEggMorphology.settings.roundIntroCreatureGridAudioKey)
    }

    func testMarineEggsRoundTriosUseThreeDistinctClades() {
        guard let config = MarineEggsGameConfigs.makeMarineEggs() else {
            XCTFail("Expected Marine Eggs config")
            return
        }
        for round in config.rounds {
            let trio = [round.correctCreature] + round.distractors
            XCTAssertEqual(trio.count, 3)
            let clades = trio.map { MarineEggMorphology.morphotypeCladeKey(for: $0) }
            XCTAssertEqual(Set(clades).count, 3, "Each round trio should span three clades")
        }
    }

    func testMarineEggsSpecimenRoundsDisableScanner() {
        guard let config = MarineEggsGameConfigs.makeMarineEggs() else {
            XCTFail("Expected Marine Eggs config")
            return
        }
        XCTAssertNil(MarineEggMorphology.settings.scannerNotAvailableAudioKey)
        let specimenRounds = config.rounds.filter { !$0.alternatesNestAndEgg }
        XCTAssertFalse(specimenRounds.isEmpty)
        for round in specimenRounds {
            XCTAssertFalse(round.alternatesNestAndEgg, "Live/spawn rounds should not alternate nest and egg")
            XCTAssertNotNil(round.fixedMainImageAssetName)
            let morphotypeKey = MarineEggMorphology.morphotypeAudioKey(forCatalogSlug: round.eggType)
            XCTAssertTrue(
                morphotypeKey.hasPrefix("marine-live-") || morphotypeKey.hasPrefix("marine-spawn-"),
                "Specimen rounds should use live or spawn morphotype narration when scanner is unavailable"
            )
        }
    }

    @MainActor
    func testMarineEggsSpecimenRoundScannerUnavailableUsesMorphotypeAudio() {
        let speech = SpeechManager()
        XCTAssertNotNil(speech.urlForAudio(key: "marine-live-halisaur"))
        XCTAssertNotNil(speech.urlForAudio(key: "marine-spawn-teleostei"))
        XCTAssertEqual(
            MarineEggMorphology.morphotypeAudioKey(forCatalogSlug: "halisaurus"),
            "marine-live-halisaur"
        )
        XCTAssertEqual(
            MarineEggMorphology.morphotypeAudioKey(forCatalogSlug: "gillicus"),
            "marine-spawn-teleostei"
        )
    }

    func testMarineEggsVictoryRecapDeduplicatesByCladeAudio() {
        XCTAssertTrue(MarineEggMorphology.settings.victoryRecapDeduplicatesByAudioKey)
    }

    func testPlayableSlugsMatchRoundAssetGate() {
        XCTAssertFalse(discoveredCatalogSlugs.isEmpty, "Expected marine-eggs egg/nest/live/spawn art in the catalog")
        for slug in discoveredCatalogSlugs.sorted() {
            XCTAssertEqual(
                MarineEggMorphology.allPlayableSlugs.contains(slug),
                MarineEggMorphology.roundAssetsExist(forSlug: slug),
                "Playable slug gate mismatch for `\(slug)`"
            )
        }
    }

    func testNestEggScanRevealUsesDedicatedScanArtWhenBundled() {
        for slug in MarineEggMorphology.playableNestEggSlugs {
            let dedicated = "marine-eggs-scan-\(slug)"
            let scan = MarineEggMorphology.scanAssetName(forCatalogSlug: slug)
            if ImageAssetNames.knownAssets.contains(dedicated) {
                XCTAssertEqual(scan, dedicated, "Scan for \(slug) should prefer bundled CT scan art")
            } else {
                XCTAssertTrue(
                    ImageAssetCache.imageExists(named: scan),
                    "Missing scan asset for \(slug): \(scan)"
                )
            }
            let egg = MarineEggMorphology.eggAssetName(forCatalogSlug: slug)
            XCTAssertNotEqual(
                scan,
                egg,
                "Scan should not fall back to the same egg image for \(slug) when dedicated scan art is expected"
            )
        }
    }

    func testMarineScanEmptyAssetIsBundledAndResolved() {
        XCTAssertTrue(
            ImageAssetNames.knownAssets.contains("marine-eggs-scan-empty"),
            "Expected marine-eggs-scan-empty imageset in the catalog"
        )
        XCTAssertEqual(
            MarineEggMorphology.morphology.scansEmptyName(),
            "marine-eggs-scan-empty"
        )
    }

    @MainActor
    func testMarineEggsReadySetGoAndScannerPromptsResolveToBundledClips() {
        let settings = MarineEggMorphology.settings
        XCTAssertTrue(settings.playsTapScannerPrompt)
        XCTAssertEqual(settings.roundIntroTapScannerAudioKey, "game-dino-eggs-tap-the-scanner")

        let speech = SpeechManager()
        for key in [
            "game-marine-eggs",
            "game-marine-eggs-gameplay-directions",
            "game-dino-eggs-tap-the-scanner",
            "marine-live-halisaur",
            "marine-spawn-teleostei",
            "game-dino-eggs-beep",
            "game-dino-eggs-scan-failed",
        ] {
            XCTAssertNotNil(speech.urlForAudio(key: key), "Missing bundled Marine Eggs clip: \(key)")
        }
    }

    func testSpecimenOnlyFishSlugsJoinPool() {
        XCTAssertTrue(MarineEggMorphology.playableSpecimenOnlySlugs.contains("enchodus"))
        XCTAssertTrue(MarineEggMorphology.playableSpecimenOnlySlugs.contains("gillicus"))
        XCTAssertTrue(MarineEggMorphology.playableSpecimenOnlySlugs.contains("xiphactinus"))
    }

    func testMakeMarineEggsCanIncludeSpecimenOnlyRound() {
        guard let config = MarineEggsGameConfigs.makeMarineEggs() else {
            XCTFail("Expected Marine Eggs config")
            return
        }
        let specimenRounds = config.rounds.filter { !$0.alternatesNestAndEgg }
        XCTAssertFalse(specimenRounds.isEmpty, "Expected at least one live/spawn-only round when fish spawn art is bundled")
        for round in specimenRounds {
            XCTAssertNotNil(round.fixedMainImageAssetName)
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(round.fixedMainImageAssetName!))
        }
    }

    func testMarineEggsDisplayMomentsIncludeSourceHintsAndCreatureTriads() {
        guard MarineEggsGameConfigs.makeMarineEggs() != nil else {
            XCTFail("Expected Marine Eggs to be playable for display-moment tests")
            return
        }
        let hintMoments = eggsMoments.filter { $0.context.hasPrefix("source-hint ") }
        XCTAssertEqual(hintMoments.count, MarineEggMorphology.sourceHints.count)
        let creatureMoments = eggsMoments.filter { $0.context.contains(" creature") }
        XCTAssertEqual(creatureMoments.count, 3, "Expected one creature triad per round")
        let eggMoments = eggsMoments.filter { $0.context.contains(" egg ") }
        XCTAssertEqual(
            eggMoments.count,
            0,
            "Egg triads ship when morphotype narration is bundled under Audio/Marine-Eggs/"
        )
        let nestMoments = eggsMoments.filter { $0.context.contains(" nest ") }
        XCTAssertEqual(
            nestMoments.count,
            0,
            "Nest triads ship when morphotype narration is bundled under Audio/Marine-Eggs/"
        )
    }

    func testMarineEggsDisplayMomentsHaveImagesInAssetCatalog() {
        guard MarineEggsGameConfigs.makeMarineEggs() != nil else {
            XCTFail("Expected Marine Eggs to be playable for display-moment tests")
            return
        }
        let known = ImageAssetNames.knownAssets
        let missing = eggsMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testMarineEggsDisplayMomentsHaveResolvableAudio() {
        guard MarineEggsGameConfigs.makeMarineEggs() != nil else {
            XCTFail("Expected Marine Eggs to be playable for display-moment tests")
            return
        }
        let speech = SpeechManager()
        let missing = eggsMoments.filter { moment in
            LandGameDisplayMomentCatalog.audioCandidateKeys(for: moment)
                .compactMap { speech.urlForAudio(key: $0) }
                .isEmpty
        }
        let labels = missing.map { moment in
            let keys = LandGameDisplayMomentCatalog.audioCandidateKeys(for: moment).joined(separator: "|")
            return "\(moment.context) → audio `\(keys)`"
        }
        XCTAssertTrue(labels.isEmpty, "Missing bundle audio: \(labels.joined(separator: "; "))")
    }

    func testMarineEggsSourceHintAssetsAndAudioExist() throws {
        XCTAssertTrue(MarineEggMorphology.settings.hasSourceHints)
        XCTAssertEqual(MarineEggMorphology.sourceHints.count, 1)
        let hint = MarineEggMorphology.sourceHints[0]
        XCTAssertEqual(hint.imageName, "source-marine-eggs-shape")
        XCTAssertEqual(hint.audioKey, "marine-eggs-shape")
        XCTAssertTrue(ImageAssetNames.knownAssets.contains(hint.imageName))

        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Marine-Eggs/hints")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        XCTAssertTrue(stems.contains("marine-eggs-shape"))
    }

    @MainActor
    func testMarineEggsSourceHintAudioResolvesInBundle() {
        XCTAssertNotNil(SpeechManager().urlForAudio(key: "marine-eggs-shape"))
    }

    func testMarineEggAndNestAudioKeysUseMarineEggsPrefix() {
        let morphology = MarineEggMorphology.morphology
        XCTAssertEqual(morphology.eggAudioKey(eggType: "archelon"), "marine-eggs-testudine")
        XCTAssertEqual(morphology.eggAudioKey(eggType: "mesoleptos"), "marine-eggs-basal")
        XCTAssertEqual(morphology.nestingAudioKey(style: "mesoleptos"), "marine-eggs-nest-mesoleptos")
    }

    func testMarineEggsMorphotypeAudioIsCheckedSeparatelyFromGameplayPrompts() {
        let morphotypeKeys = Set(MarineEggsAudioContracts.marineEggsMorphotypeAudioKeysOnDisk())
        let gameplayKeys = Set(MarineEggsAudioContracts.allRequiredKeys(forConfigId: "marine-eggs"))

        XCTAssertFalse(morphotypeKeys.isEmpty)
        XCTAssertTrue(
            gameplayKeys.isDisjoint(with: morphotypeKeys),
            "Morphotype narration stays on the dedicated on-disk contract, not gameplay `requiredAudioKeys`"
        )
        XCTAssertTrue(morphotypeKeys.contains("marine-eggs-testudine"))
        XCTAssertTrue(morphotypeKeys.contains("marine-live-halisaur"))
        XCTAssertTrue(morphotypeKeys.contains("marine-spawn-teleostei"))
        XCTAssertFalse(gameplayKeys.contains("marine-eggs-testudine"))
    }

    func testMarineEggsAudioContractIncludesAllRuntimeGameplayKeys() {
        guard let config = MarineEggsGameConfigs.makeMarineEggs() else {
            XCTFail("Expected Marine Eggs config")
            return
        }
        let settings = MarineEggMorphology.settings
        var runtimeKeys: [String] = [
            config.introAudio,
            config.gameplayDirectionsAudio,
            settings.beepKey,
            settings.scanFailedKey,
        ]
        if settings.playsHintsButtonIntro {
            runtimeKeys.append("game-hint")
        }
        if let tapScanner = settings.roundIntroTapScannerAudioKey {
            runtimeKeys.append(tapScanner)
        }
        if let gridIntro = settings.roundIntroCreatureGridAudioKey {
            runtimeKeys.append(gridIntro)
        }
        if let scannerUnavailable = settings.scannerNotAvailableAudioKey {
            runtimeKeys.append(scannerUnavailable)
        }
        if let gridIntro = settings.sourceHintsGridIntroAudioKey {
            runtimeKeys.append(gridIntro)
        }
        runtimeKeys.append(contentsOf: (settings.sourceHints ?? []).map(\.audioKey))

        let contracted = Set(MarineEggsAudioContracts.allRequiredKeys(forConfigId: "marine-eggs"))
        let missing = Set(runtimeKeys).subtracting(contracted).sorted()
        XCTAssertTrue(
            missing.isEmpty,
            "Marine Eggs audio contract missing runtime keys: \(missing)"
        )
    }

    func testMarineEggsMorphotypeAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Marine-Eggs")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        let keys = MarineEggsAudioContracts.marineEggsMorphotypeAudioKeysOnDisk()
        let missing = Set(keys).subtracting(stems).sorted()
        XCTAssertTrue(
            missing.isEmpty,
            "Missing Marine Eggs morphotype narration under Marine-Eggs/: \(missing)"
        )
    }

    @MainActor
    func testMarineEggsMorphotypeAudioResolvesInBundleWhenPresent() {
        let keys = MarineEggsAudioContracts.marineEggsMorphotypeAudioKeysOnDisk()
        let speech = SpeechManager()
        let missing = keys.filter { speech.urlForAudio(key: $0) == nil }.sorted()
        XCTAssertTrue(
            missing.isEmpty,
            """
            Missing Marine Eggs morphotype narration (expected under Assets/Audio/Marine-Eggs/ as \
            marine-eggs-{slug}.m4a and marine-eggs-nest-{slug}.m4a): \(missing)
            """
        )
    }
}
