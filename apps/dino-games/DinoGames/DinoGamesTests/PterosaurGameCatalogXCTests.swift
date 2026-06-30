//
//  PterosaurGameCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class PterosaurGameCatalogXCTests: XCTestCase {

    /// Canonical progress ids (runtime config ids may differ, e.g. `racing-pterosaurs-jurassic`).
    private let shippingCanonicalByLevel: [GameLevel: [String]] = [
        .level1: ["weigh-pterosaur", "which-ptero-is-taller", "ptero-puzzle"],
        .level2: ["name-that-pterosaur", "racing-pterosaurs", "ptero-ages"],
        .level3: ["ptero-footprints", "ptero-flora", "ptero-eggs"],
    ]

    private func expectedLevel4CanonicalIds() -> [String] {
        var ids: [String] = []
        if PteroMatrixGameConfigs.makePteroMatrix() != nil {
            ids.append("ptero-matrix")
        }
        ids.append("ptero-diets")
        if SmilingDinosGameConfigs.isPteroSmilePlayable {
            ids.append("ptero-smile")
        }
        return ids
    }

    func testVisibleAirLevelsAreOneThroughFour() {
        XCTAssertEqual(GameLevel.visibleInGamePicker, [.level1, .level2, .level3, .level4])
    }

    func testEachShippingAirLevelOneThroughThreeHasThreeGamesInCatalogOrder() {
        for level in [GameLevel.level1, .level2, .level3] {
            let expected = shippingCanonicalByLevel[level] ?? []
            let games = PterosaurGameCatalog.games(level: level)
            XCTAssertEqual(games.count, 3, "Air level \(level.number) should list three games")
            let actual = games.compactMap { $0.id.map { PterosaurProgress.canonicalId(for: $0) } }
            XCTAssertEqual(actual, expected, "Air level \(level.number) canonical catalog order")
        }
    }

    func testShippingAirLevelFourMatchesPlacedOptionalGames() {
        let expected = expectedLevel4CanonicalIds()
        XCTAssertFalse(expected.isEmpty, "Air level 4 should always include Ptero Diets")
        let games = PterosaurGameCatalog.games(level: .level4)
        XCTAssertEqual(games.count, expected.count, "Air level 4 game count should match placed optional games")
        let actual = games.compactMap { $0.id.map { PterosaurProgress.canonicalId(for: $0) } }
        XCTAssertEqual(actual, expected, "Air level 4 canonical catalog order")
    }

    func testShippingAirGamesMapToAirProgressCategory() {
        let ids = GameLevel.visibleInGamePicker.flatMap { PterosaurGameCatalog.games(level: $0).compactMap(\.id) }
        for id in ids {
            XCTAssertEqual(GameCategory.forCatalogConfigId(id), .air, "Config `\(id)` should map to air")
        }
    }

    func testAirCatalogBuildsWithoutFatalError() {
        XCTAssertNoThrow({
            _ = PterosaurGameCatalog.games
            _ = PterosaurProgress.allPterosaurGameCanonicalIds
        }())
    }

    func testPteroMatrixFossilSlugMatchesBundledComposites() {
        let dimorphodon = AirPterosaurData.allPterosaurs.first { $0.imageName == "ptero-basal-dimorphodon" }
        XCTAssertEqual(AirPterosaurData.matrixFossilSlug(for: dimorphodon!), "dimorphodon")
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("ptero-matrix-shale-dimorphodon"))

        let quetz = AirPterosaurData.allPterosaurs.first { $0.imageName == "ptero-azhd-quetzalcoatlus" }
        XCTAssertEqual(AirPterosaurData.matrixFossilSlug(for: quetz!), "quetzalcoatlus")
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("ptero-matrix-lignite-quetzalcoatlus"))
    }

    func testPteroMatrixConfigBuildsAndAppearsInLevel4() {
        XCTAssertNotNil(
            PteroMatrixGameConfigs.makePteroMatrix(),
            "Ptero Matrix needs at least three bundled fossil-in-matrix image sets."
        )
        let level4 = PterosaurGameCatalog.games(level: .level4)
        XCTAssertTrue(
            level4.contains { $0.id == "ptero-matrix" },
            "Expected Ptero Matrix in air level 4 when matrix config builds."
        )
        XCTAssertTrue(
            level4.contains { $0.id == "ptero-diets" },
            "Expected Ptero Diets in air level 4."
        )
    }

    func testPteroMatrixGameCardImageExists() {
        XCTAssertTrue(
            ImageAssetCache.imageExists(named: "game-ptero-matrix"),
            "Missing picker/transition art: game-ptero-matrix.imageset"
        )
        XCTAssertTrue(
            ImageAssetCache.imageExists(named: "game-ptero-matrix-success"),
            "Missing victory art: game-ptero-matrix-success.imageset"
        )
    }

    func testPteroSmileIsInCatalogWhenAssetsShip() {
        XCTAssertTrue(
            SmilingDinosGameConfigs.isPteroSmilePlayable,
            "Expected enough bundled pterosaur smile portraits and matching tooth art for 3×3 rounds."
        )
        let allIds = Set(PterosaurGameCatalog.games.compactMap(\.id))
        XCTAssertTrue(
            allIds.contains("ptero-smile"),
            "Ptero Smile should appear in the air catalog when smile/tooth assets are bundled."
        )
        XCTAssertTrue(
            ImageAssetCache.imageExists(named: "game-ptero-smile"),
            "Missing game card art: game-ptero-smile.imageset"
        )
        XCTAssertTrue(
            ImageAssetCache.imageExists(named: "game-ptero-smile-success"),
            "Missing victory art: game-ptero-smile-success.imageset"
        )
        let level4 = PterosaurGameCatalog.games(level: .level4)
        XCTAssertTrue(
            level4.contains { $0.id == "ptero-smile" },
            "Expected Ptero Smile in air level 4."
        )
    }

    func testPteroSmileConfigBuildsThreeRounds() {
        guard let config = SmilingDinosGameConfigs.makePteroSmile() else {
            XCTFail("makePteroSmile() returned nil — need 9+ morphology families with bundled portrait + tooth art.")
            return
        }
        XCTAssertEqual(config.rounds.count, 3)
        XCTAssertEqual(config.id, "ptero-smile")
        var morphologiesAcrossGame: Set<String> = []
        for round in config.rounds {
            XCTAssertEqual(round.pairs.count, SmilingDinosRound.creaturesPerRound)
            XCTAssertEqual(round.distractorToothTypes.count, SmilingDinosRound.distractorTeethPerRound)
            let roundMorphologies = round.pairs.compactMap { PteroSmileMorphology.morphologyCategory(for: $0.dinosaur) }
            XCTAssertEqual(Set(roundMorphologies).count, roundMorphologies.count, "Each round should use three distinct morphologies")
            morphologiesAcrossGame.formUnion(roundMorphologies)
            let answerTeeth = Set(round.pairs.map(\.toothType))
            XCTAssertTrue(answerTeeth.isDisjoint(with: round.distractorToothTypes), "Dummy teeth must not match round answers")
            let allTeethInRound = round.pairs.map(\.toothType) + round.distractorToothTypes
            let playerKindsInRound = allTeethInRound.compactMap { PteroSmileMorphology.playerKind(for: $0) }
            XCTAssertEqual(
                playerKindsInRound.count,
                Set(playerKindsInRound).count,
                "Each round should have at most one tooth per player alias; got \(playerKindsInRound.map(\.displayLabel))"
            )
            XCTAssertEqual(playerKindsInRound.count, allTeethInRound.count)
        }
        XCTAssertEqual(morphologiesAcrossGame.count, 9, "Three rounds × three morphologies with no repeats across the game")
    }

    func testPteroSmileRegistryMatchesREADME() {
        XCTAssertEqual(PteroSmileMorphology.allCategorySlugs.count, 14)
        XCTAssertEqual(PteroSmileMorphology.allToothSlugs.count, 43, "44 README pairings; nemicolopterus and wukongopterus share microscopic-needle-pin")
        XCTAssertEqual(PteroSmileMorphology.smileToothType(for: slug("quetzalcoatlus")), "elongated-cutting-wedge")
        XCTAssertEqual(PteroSmileMorphology.morphologyCategory(for: slug("quetzalcoatlus")), "hyper-elongated-spears")
        XCTAssertEqual(PteroSmileMorphology.smileToothType(for: slug("anhanguera")), "classic-pelican-javelin")
        XCTAssertEqual(PteroSmileMorphology.smileToothType(for: slug("dsungaripterus")), "pebble-crushers")
        XCTAssertEqual(PteroSmileMorphology.smileToothType(for: slug("caiuajara")), "pointed-fruit-cutter")
        XCTAssertEqual(PteroSmileMorphology.smileToothType(for: slug("eudimorphodon")), "dual-type-pincers")
        XCTAssertEqual(PteroSmileMorphology.smileToothType(for: slug("istiodactylus")), "straight-slicing-shears")
        XCTAssertEqual(PteroSmileMorphology.smileToothType(for: slug("zhejiangopterus")), "hyper-slender-razor-needles")
    }

    func testPteroSmileBundledPortraitAndToothArt() {
        let expected: [(portrait: String, tooth: String)] = [
            ("ptero-smile-quetzalcoatlus", "ptero-smile-tooth-elongated-cutting-wedge"),
            ("ptero-smile-hatzegopteryx", "ptero-smile-tooth-heavy-axe-beak"),
            ("ptero-smile-anuanguera", "ptero-smile-tooth-classic-pelican-javelin"),
            ("ptero-smile-ornithocheirus", "ptero-smile-tooth-crested-terminal-spikes"),
            ("ptero-smile-scaphognathus", "ptero-smile-tooth-curved-forward-grapplers"),
            ("ptero-smile-tupandactylus", "ptero-smile-tooth-deep-down-turned-scoop"),
            ("ptero-smile-jeholopterus", "ptero-smile-tooth-vampire-insect-needles"),
            ("ptero-smile-noripterus", "ptero-smile-tooth-shell-crushing-pegs"),
        ]
        for pair in expected {
            XCTAssertTrue(
                ImageAssetCache.imageExists(named: pair.portrait),
                "Missing portrait art: \(pair.portrait)"
            )
            XCTAssertTrue(
                ImageAssetCache.imageExists(named: pair.tooth),
                "Missing tooth art: \(pair.tooth)"
            )
        }
    }

    private func slug(_ matrixSlug: String) -> Dinosaur {
        let match = AirPterosaurData.allPterosaurs.first {
            AirPterosaurData.matrixFossilSlug(for: $0) == matrixSlug
        }
        XCTAssertNotNil(match, "Missing pterosaur registry entry for \(matrixSlug)")
        return match!
    }

    func testPteroEggsVictoryRecapUsesSpeciesNamesNotClades() {
        XCTAssertTrue(PteroEggMorphology.settings.victoryRecapUsesCreatureName)
        XCTAssertTrue(PteroEggMorphology.settings.victoryRecapLabelUsesCreatureName)
        let morphology = PteroEggMorphology.morphology
        for round in PteroEggsGameConfigs.pteroEggs.rounds {
            let speciesTitle = round.correctCreature.name
            let cladeTitle = morphology.eggDisplayTitle(for: round.eggType)
            XCTAssertFalse(speciesTitle.isEmpty)
            XCTAssertNotEqual(
                speciesTitle,
                cladeTitle,
                "Victory recap should name the matched pterosaur (`\(speciesTitle)`), not the egg clade (`\(cladeTitle)`)"
            )
        }
    }
}
