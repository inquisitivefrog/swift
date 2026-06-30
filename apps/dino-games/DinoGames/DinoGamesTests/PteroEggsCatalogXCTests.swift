//
//  PteroEggsCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class PteroEggsCatalogXCTests: XCTestCase {

    private var eggsMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingAirMoments().filter { $0.gameConfigId == "ptero-eggs" }
    }

    func testAirCatalogBuildsWithoutFatalErrorWhenPteroEggsUnavailable() {
        XCTAssertNoThrow({
            _ = PterosaurGameCatalog.games
            _ = PterosaurProgress.allPterosaurGameCanonicalIds
        }())
    }

    func testPteroEggAssetsEnablePlayableGame() {
        XCTAssertFalse(PteroEggMorphology.shippedClades.isEmpty, "Expected ptero-eggs + nest art in the catalog")
        XCTAssertTrue(
            PterosaurGameCatalog.games(level: .level3).contains {
                guard case .pteroEggs = $0 else { return false }
                return true
            },
            "Ptero Eggs should appear in the air level-3 picker"
        )
    }

    func testBasalHasMatchingEggNestAndScan() {
        XCTAssertTrue(PteroEggMorphology.shippedClades.contains("basal"))
        let morphology = PteroEggMorphology.morphology
        XCTAssertTrue(ImageAssetNames.knownAssets.contains(morphology.eggImageName(eggType: "basal")))
        XCTAssertTrue(ImageAssetNames.knownAssets.contains(morphology.nestingImageName(style: "basal")))
        XCTAssertTrue(ImageAssetNames.knownAssets.contains(PteroEggMorphology.scanAssetName(forClade: "basal")))
    }

    func testUndiscoveredEggCladesAreExcludedFromShippedCatalog() {
        let undiscovered: Set<String> = ["tapejarid", "thalassodromid"]
        XCTAssertFalse(
            undiscovered.isSubset(of: PteroEggMorphology.shippedClades),
            "Tapejarid and thalassodromid eggs are not discovered yet; keep them out of shipped clades"
        )
        for clade in undiscovered {
            XCTAssertFalse(PteroEggMorphology.shippedClades.contains(clade))
        }
    }

    func testUndiscoveredCladePterosaursHaveNoEggType() {
        let undiscoveredGroups: Set<PterosaurGuessGroup> = [.tapejarid, .thalassodromid]
        let undiscoveredPterosaurs = MatchingGameConfigs.allPterosaurs.filter { ptero in
            guard let imageName = ptero.imageName,
                  let group = PterosaurGuessGroup.guessGroup(forImageName: imageName) else { return false }
            return undiscoveredGroups.contains(group)
        }
        XCTAssertFalse(
            undiscoveredPterosaurs.isEmpty,
            "Expected tapejarid/thalassodromid pterosaurs in the registry for this gate test"
        )
        for ptero in undiscoveredPterosaurs {
            XCTAssertNil(
                PteroEggMorphology.eggType(for: ptero),
                "\(ptero.name) (`\(ptero.imageName ?? "")`) should not map to an egg clade until eggs are discovered"
            )
        }
    }

    func testUndiscoveredEggCladesRemainOutsideEggGameAssetsAndAudio() throws {
        let undiscovered = ["tapejarid", "thalassodromid"]
        let known = ImageAssetNames.knownAssets
        let morphology = PteroEggMorphology.morphology

        for clade in undiscovered {
            XCTAssertFalse(known.contains(morphology.eggImageName(eggType: clade)))
            XCTAssertFalse(known.contains(morphology.nestingImageName(style: clade)))
            XCTAssertFalse(known.contains(PteroEggMorphology.scanAssetName(forClade: clade)))
        }

        let morphotypeKeys = PterosaurGameAudioContracts.pteroEggsMorphotypeAudioKeysOnDisk()
        for clade in undiscovered {
            XCTAssertFalse(morphotypeKeys.contains("ptero-eggs-\(clade)"))
            XCTAssertFalse(morphotypeKeys.contains("ptero-eggs-nests-\(clade)"))
        }

        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Ptero-Eggs")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for clade in undiscovered {
            XCTAssertFalse(stems.contains("ptero-eggs-\(clade)"))
            XCTAssertFalse(stems.contains("ptero-eggs-nests-\(clade)"))
        }

        for round in PteroEggsGameConfigs.pteroEggs.rounds {
            XCTAssertFalse(undiscovered.contains(round.eggType))
            XCTAssertFalse(undiscovered.contains(round.nestingStyle))
        }
    }

    func testPteroEggsMorphotypeAudioIsCheckedSeparatelyFromMainContract() {
        let morphotypeKeys = Set(PterosaurGameAudioContracts.pteroEggsMorphotypeAudioKeysOnDisk())
        let mainContractKeys = Set(PterosaurGameAudioContracts.allRequiredKeys(forConfigId: "ptero-eggs"))

        XCTAssertFalse(morphotypeKeys.isEmpty)
        XCTAssertTrue(
            mainContractKeys.isDisjoint(with: morphotypeKeys),
            "Morphotype narration stays on the dedicated on-disk contract, not `requiredAudioKeys`"
        )
        XCTAssertTrue(morphotypeKeys.contains("ptero-eggs-basal"))
        XCTAssertFalse(mainContractKeys.contains("ptero-eggs-basal"))
    }

    func testTransitionalEggAndNestAudioUseBundledTransitionSuffix() {
        let morphology = PteroEggMorphology.morphology
        XCTAssertEqual(morphology.eggAudioKey(eggType: "transitional"), "ptero-eggs-transition")
        XCTAssertEqual(morphology.nestingAudioKey(style: "transitional"), "ptero-eggs-nests-transition")
    }

    func testTransitionalEggNestAndScanImagesUseBundledTransitionSuffix() {
        XCTAssertEqual(PteroEggMorphology.bundledImageKey(forClade: "transitional"), "transition")
        XCTAssertEqual(PteroEggMorphology.bundledImageKey(forClade: "basal"), "basal")

        let morphology = PteroEggMorphology.morphology
        XCTAssertEqual(morphology.eggImageName(eggType: "transitional"), "ptero-eggs-transition")
        XCTAssertEqual(morphology.nestingImageName(style: "transitional"), "ptero-nests-transition")
        XCTAssertEqual(PteroEggMorphology.scanAssetName(forClade: "transitional"), "ptero-eggs-scan-transition")
        XCTAssertEqual(morphology.randomColorsAsset("transitional"), "ptero-eggs-transition")

        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("ptero-eggs-transition"))
        XCTAssertTrue(known.contains("ptero-nests-transition"))
        XCTAssertTrue(known.contains("ptero-eggs-scan-transition"))

        let transitionalPterosaur = MatchingGameConfigs.allPterosaurs.first {
            $0.imageName == "ptero-trans-darwinopterus"
        }
        XCTAssertNotNil(transitionalPterosaur)
        XCTAssertEqual(PteroEggMorphology.eggType(for: transitionalPterosaur!), "transitional")
    }

    func testPteroEggsVictoryUsesCreatureNameRecap() {
        XCTAssertTrue(PteroEggMorphology.settings.victoryRecapUsesCreatureName)
        XCTAssertTrue(PteroEggMorphology.settings.victoryRecapLabelUsesCreatureName)
        XCTAssertEqual(
            PteroEggMorphology.morphology.eggAudioKey(eggType: "basal"),
            "ptero-eggs-basal"
        )
    }

    func testPteroEggsVictoryRecapEggDisplayTitlesAreNonEmpty() {
        let config = PteroEggsGameConfigs.pteroEggs
        let morphology = PteroEggMorphology.morphology
        for round in config.rounds {
            let title = morphology.eggDisplayTitle(for: round.eggType)
            XCTAssertFalse(title.isEmpty, "Victory recap needs a label for egg clade `\(round.eggType)`")
        }
    }

    func testPteroEggsConfigBuildsThreeDistinctCreatureRounds() {
        let config = PteroEggsGameConfigs.pteroEggs
        XCTAssertEqual(config.id, "ptero-eggs")
        XCTAssertEqual(config.rounds.count, 3)
        XCTAssertEqual(Set(config.rounds.map(\.correctCreature.id)).count, 3)
    }

    func testPteroEggsConfigBuildsThreeDistinctEggClades() {
        let config = PteroEggsGameConfigs.pteroEggs
        XCTAssertEqual(Set(config.rounds.map(\.eggType)).count, 3)
    }

    func testPteroEggsPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-ptero-eggs"), "Missing picker art: game-ptero-eggs")
        let successCandidates = ["game-ptero-eggs-success", "game-ptero-eggs"]
        XCTAssertTrue(
            successCandidates.contains { known.contains($0) },
            "Missing victory art. Tried: \(successCandidates)"
        )
    }

    func testPteroEggsDisplayMomentsIncludeSourceHintsCreatureEggAndNestTriads() {
        let hintMoments = eggsMoments.filter { $0.context.hasPrefix("source-hint ") }
        XCTAssertEqual(hintMoments.count, PteroEggMorphology.sourceHints.count)
        let creatureMoments = eggsMoments.filter { $0.context.contains(" creature") }
        XCTAssertEqual(creatureMoments.count, 3, "Expected one creature triad per round")
        let eggMoments = eggsMoments.filter { $0.context.contains(" egg ") }
        XCTAssertEqual(eggMoments.count, 3, "Expected one egg triad per round")
        let nestMoments = eggsMoments.filter { $0.context.contains(" nest ") }
        XCTAssertEqual(nestMoments.count, 3, "Expected one nest triad per round")
    }

    func testPteroEggsDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = eggsMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testPteroEggsDisplayMomentsHaveResolvableAudio() {
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
        for clade in PteroEggMorphology.shippedClades {
            let scan = PteroEggMorphology.scanAssetName(forClade: clade)
            XCTAssertTrue(ImageAssetCache.imageExists(named: scan), "Missing scan asset for \(clade): \(scan)")
            let egg = PteroEggMorphology.morphology.eggImageName(eggType: clade)
            XCTAssertNotEqual(
                scan,
                egg,
                "Scan should not fall back to the same egg image for \(clade)"
            )
        }
    }

    func testPteroScanEmptyAssetIsBundledAndResolved() {
        XCTAssertTrue(
            ImageAssetNames.knownAssets.contains("ptero-eggs-scan-empty"),
            "Expected ptero-eggs-scan-empty imageset in the catalog"
        )
        XCTAssertEqual(
            PteroEggMorphology.morphology.scansEmptyName(),
            "ptero-eggs-scan-empty"
        )
    }

    func testShippedEggCladesHaveRoundAssetGateArt() {
        let morphology = PteroEggMorphology.morphology
        for clade in PteroEggMorphology.shippedClades {
            let bundled = PteroEggMorphology.bundledImageKey(forClade: clade)
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(morphology.eggImageName(eggType: clade)))
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(morphology.nestingImageName(style: clade)))
            XCTAssertTrue(ImageAssetNames.knownAssets.contains("ptero-eggs-\(bundled)"))
            XCTAssertTrue(ImageAssetNames.knownAssets.contains("ptero-nests-\(bundled)"))
        }
    }

    func testPteroEggsMorphotypeAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Ptero-Eggs")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        let keys = PterosaurGameAudioContracts.pteroEggsMorphotypeAudioKeysOnDisk()
        let missing = Set(keys).subtracting(stems).sorted()
        XCTAssertTrue(
            missing.isEmpty,
            "Missing Ptero Eggs morphotype narration under Ptero-Eggs/: \(missing)"
        )
    }

    func testPteroEggsSourceHintAssetsAndAudioExist() throws {
        XCTAssertEqual(PteroEggMorphology.sourceHints.count, 1)
        let hint = PteroEggMorphology.sourceHints[0]
        XCTAssertEqual(hint.imageName, "source-ptero-eggs-shape")
        XCTAssertEqual(hint.audioKey, "ptero-hint-shape")
        XCTAssertTrue(ImageAssetNames.knownAssets.contains(hint.imageName))

        let hintDirectory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Ptero-Eggs/hints")
        let hintStems = try TestBundleHelpers.audioStems(in: hintDirectory)
        XCTAssertTrue(hintStems.contains("ptero-hint-shape"))

        let gamesDirectory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let gamesStems = try TestBundleHelpers.audioStems(in: gamesDirectory)
        XCTAssertTrue(gamesStems.contains("game-ptero-eggs-tap-the-image"))
    }

    @MainActor
    func testPteroEggsSourceHintAudioResolvesInBundle() {
        let speech = SpeechManager()
        XCTAssertNotNil(speech.urlForAudio(key: "ptero-hint-shape"))
    }

    func testPteroEggsAudioContractIncludesAllRuntimeGameplayKeys() {
        let settings = PteroEggMorphology.settings
        var runtimeKeys: [String] = [
            PteroEggsGameConfigs.pteroEggs.introAudio,
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

        let contracted = Set(PterosaurGameAudioContracts.allRequiredKeys(forConfigId: "ptero-eggs"))
        let missing = Set(runtimeKeys).subtracting(contracted).sorted()
        XCTAssertTrue(
            missing.isEmpty,
            "Ptero Eggs audio contract missing runtime keys: \(missing)"
        )
    }

    @MainActor
    func testPteroEggsReadySetGoAndScannerPromptsResolveToBundledClips() {
        let speech = SpeechManager()
        for key in [
            "game-ptero-eggs",
            "game-ptero-eggs-gameplay-directions",
            "game-dino-eggs-tap-the-scanner",
            "game-dino-eggs-beep",
            "game-dino-eggs-scan-failed",
        ] {
            XCTAssertNotNil(speech.urlForAudio(key: key), "Missing bundled Ptero Eggs clip: \(key)")
        }
    }
}
