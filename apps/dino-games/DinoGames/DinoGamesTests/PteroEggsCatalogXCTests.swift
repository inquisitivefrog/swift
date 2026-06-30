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

    func testPteroEggsPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-ptero-eggs"), "Missing picker art: game-ptero-eggs")
        let successCandidates = ["game-ptero-eggs-success", "game-ptero-eggs"]
        XCTAssertTrue(
            successCandidates.contains { known.contains($0) },
            "Missing victory art. Tried: \(successCandidates)"
        )
    }

    func testPteroEggsDisplayMomentsIncludeSourceHintsAndCreatureTriads() {
        let hintMoments = eggsMoments.filter { $0.context.hasPrefix("source-hint ") }
        XCTAssertEqual(hintMoments.count, PteroEggMorphology.sourceHints.count)
        let creatureMoments = eggsMoments.filter { $0.context.contains(" creature") }
        XCTAssertEqual(creatureMoments.count, 3, "Expected one creature triad per round")
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

    func testPteroEggsSourceHintAssetsAndAudioExist() throws {
        XCTAssertEqual(PteroEggMorphology.sourceHints.count, 1)
        for hint in PteroEggMorphology.sourceHints {
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(hint.imageName))
        }
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        XCTAssertTrue(stems.contains("game-ptero-eggs-tap-the-image"))
    }

    @MainActor
    func testPteroEggsSourceHintAudioResolvesInBundle() {
        let speech = SpeechManager()
        XCTAssertNotNil(speech.urlForAudio(key: "ptero-hint-shape"))
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
