//
//  DinoEggsCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class DinoEggsCatalogXCTests: XCTestCase {

    private var eggsMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingLandMoments().filter { $0.gameConfigId == "dino-eggs" }
    }

    func testDinoCatalogBuildsWithoutFatalErrorWhenEggsUnavailable() {
        XCTAssertNoThrow({
            _ = DinosaurGameCatalog.games
            _ = LandDinosaurProgress.allLandGameCanonicalIds
        }())
    }

    func testDinoEggAssetsEnablePlayableGame() {
        XCTAssertFalse(DinoEggMorphology.playableEggClades.isEmpty, "Expected dino-egg-colors + nest + scan art in the catalog")
        XCTAssertTrue(
            DinosaurGameCatalog.games(level: .level3).contains {
                guard case .dinoEggs = $0 else { return false }
                return true
            },
            "Dino Eggs should appear in the land level-3 picker"
        )
    }

    func testDinoEggsProgressCategoryIsLand() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("dino-eggs"), .land)
    }

    func testHadrosaurHasMatchingEggNestAndScan() {
        XCTAssertTrue(DinoEggMorphology.playableEggClades.contains("hadrosaur"))
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("dino-egg-colors-hadrosaur"))
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("dino-nest-hadrosaur"))
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("dino-eggs-scans-hadrosaur"))
    }

    func testDinoEggsVictoryUsesCladeRecapNotSpeciesNames() {
        XCTAssertFalse(DinoEggMorphology.settings.victoryRecapUsesCreatureName)
        XCTAssertFalse(DinoEggMorphology.settings.victoryRecapLabelUsesCreatureName)
        XCTAssertEqual(
            DinoEggMorphology.morphology.eggAudioKey(eggType: "hadrosaur"),
            "dino-eggs-hadrosaur"
        )
    }

    func testDinoEggsVictoryRecapEggDisplayTitlesAreNonEmpty() {
        let config = DinoEggsGameConfigs.dinoEggs
        let morphology = DinoEggMorphology.morphology
        for round in config.rounds {
            let title = morphology.eggDisplayTitle(for: round.eggType)
            XCTAssertFalse(title.isEmpty, "Victory recap needs a label for egg clade `\(round.eggType)`")
        }
    }

    func testDinoEggsConfigBuildsThreeDistinctEggClades() {
        let config = DinoEggsGameConfigs.dinoEggs
        XCTAssertEqual(config.id, "dino-eggs")
        XCTAssertEqual(config.rounds.count, 3)
        XCTAssertEqual(Set(config.rounds.map(\.eggType)).count, 3)
    }

    func testDinoEggsConfigBuildsThreeDistinctCreatureRounds() {
        let config = DinoEggsGameConfigs.dinoEggs
        XCTAssertEqual(config.id, "dino-eggs")
        XCTAssertEqual(config.rounds.count, 3)
        XCTAssertEqual(Set(config.rounds.map(\.correctCreature.id)).count, 3)
    }

    func testDinoEggsPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-dino-eggs"), "Missing picker art: game-dino-eggs")
        let successCandidates = ["game-dino-eggs-success", "game-dino-eggs"]
        XCTAssertTrue(
            successCandidates.contains { known.contains($0) },
            "Missing victory art. Tried: \(successCandidates)"
        )
    }

    func testDinoEggsDisplayMomentsIncludeSourceHintsAndRoundTriads() {
        let hintMoments = eggsMoments.filter { $0.context.hasPrefix("source-hint ") }
        XCTAssertEqual(hintMoments.count, DinoEggMorphology.sourceHints.count)
        let eggMoments = eggsMoments.filter { $0.context.contains(" egg ") }
        let nestMoments = eggsMoments.filter { $0.context.contains(" nest ") }
        let creatureMoments = eggsMoments.filter { $0.context.contains(" creature") }
        XCTAssertEqual(eggMoments.count, 3, "Expected one egg triad per round")
        XCTAssertEqual(nestMoments.count, 3, "Expected one nest triad per round")
        XCTAssertEqual(creatureMoments.count, 3, "Expected one creature triad per round")
    }

    func testDinoEggsDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = eggsMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testDinoEggsDisplayMomentsHaveResolvableAudio() {
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

    func testNestEggScanRevealUsesDedicatedScanArtWhenBundled() {
        for clade in DinoEggMorphology.playableEggClades {
            let scan = DinoEggMorphology.scanAssetName(for: clade)
            XCTAssertTrue(ImageAssetCache.imageExists(named: scan), "Missing scan asset for \(clade): \(scan)")
            let egg = DinoEggMorphology.coloredEggAssetName(for: clade)
                ?? DinoEggMorphology.morphology.eggImageName(eggType: clade)
            XCTAssertNotEqual(
                scan,
                egg,
                "Scan should not fall back to the same egg image for \(clade)"
            )
        }
    }

    func testDinoScanEmptyAssetIsBundledAndResolved() {
        XCTAssertTrue(
            ImageAssetNames.knownAssets.contains("dino-eggs-scans-empty"),
            "Expected dino-eggs-scans-empty imageset in the catalog"
        )
        XCTAssertEqual(
            DinoEggMorphology.morphology.scansEmptyName(),
            "dino-eggs-scans-empty"
        )
    }

    func testPlayableEggCladesMatchRoundAssetGate() {
        for clade in DinoEggMorphology.eggMorphotypeClades {
            XCTAssertEqual(
                DinoEggMorphology.playableEggClades.contains(clade),
                DinoEggMorphology.roundAssetsExist(for: clade),
                "Playable clade gate mismatch for `\(clade)`"
            )
        }
    }

    func testDinoEggsSourceHintAssetsAndAudioExist() throws {
        XCTAssertEqual(DinoEggMorphology.sourceHints.count, 2)
        for hint in DinoEggMorphology.sourceHints {
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(hint.imageName))
        }
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        XCTAssertTrue(stems.contains("game-dino-eggs-shape"))
        XCTAssertTrue(stems.contains("game-dino-eggs-color"))
    }

    @MainActor
    func testDinoEggsSourceHintAudioResolvesInBundle() {
        let speech = SpeechManager()
        XCTAssertNotNil(speech.urlForAudio(key: "game-dino-eggs-shape"))
        XCTAssertNotNil(speech.urlForAudio(key: "game-dino-eggs-color"))
    }

    @MainActor
    func testDinoEggsReadySetGoAndScannerPromptsResolveToBundledClips() {
        XCTAssertTrue(DinoEggMorphology.settings.playsHintsButtonIntro)
        let speech = SpeechManager()
        for key in [
            "game-dino-eggs",
            "game-dino-eggs-gameplay-directions",
            "game-dino-eggs-tap-the-scanner",
            "game-hint",
            "game-dino-eggs-beep",
            "game-dino-eggs-scan-failed",
        ] {
            XCTAssertNotNil(speech.urlForAudio(key: key), "Missing bundled Dino Eggs clip: \(key)")
        }
    }

    func testDinoEggsMorphotypeAudioIsCheckedSeparatelyFromMainContract() {
        let morphotypeKeys = Set(LandDinosaurGameAudioContracts.dinoEggsMorphotypeAudioKeysOnDisk())
        let mainContractKeys = Set(LandDinosaurGameAudioContracts.allRequiredKeys(forConfigId: "dino-eggs"))

        XCTAssertFalse(morphotypeKeys.isEmpty)
        XCTAssertTrue(
            mainContractKeys.isDisjoint(with: morphotypeKeys),
            "Morphotype narration stays on the dedicated on-disk contract, not `requiredAudioKeys`"
        )
        XCTAssertTrue(morphotypeKeys.contains("dino-eggs-hadrosaur"))
        XCTAssertFalse(mainContractKeys.contains("dino-eggs-hadrosaur"))
    }

    func testDinoEggsAudioContractIncludesAllRuntimeGameplayKeys() {
        let settings = DinoEggMorphology.settings
        var runtimeKeys: [String] = [
            DinoEggsGameConfigs.dinoEggs.introAudio,
            settings.gameplayDirectionsAudioKey,
            settings.beepKey,
            settings.scanFailedKey,
        ]
        if settings.playsHintsButtonIntro {
            runtimeKeys.append("game-hint")
        }
        if let tapScanner = settings.roundIntroTapScannerAudioKey {
            runtimeKeys.append(tapScanner)
        }
        if let gridIntro = settings.sourceHintsGridIntroAudioKey {
            runtimeKeys.append(gridIntro)
        }
        runtimeKeys.append(contentsOf: (settings.sourceHints ?? []).map(\.audioKey))

        let contracted = Set(LandDinosaurGameAudioContracts.allRequiredKeys(forConfigId: "dino-eggs"))
        let missing = Set(runtimeKeys).subtracting(contracted).sorted()
        XCTAssertTrue(
            missing.isEmpty,
            "Dino Eggs audio contract missing runtime keys: \(missing)"
        )
    }
}
