//
//  PterosaurImageAssetsXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class PterosaurImageAssetsXCTests: XCTestCase {

    func testPickTwoPterosaurDecoysPreferDistinctNonQuestionGroups() {
        let pool = AirPterosaurData.allPterosaurs
        guard let question = pool.first(where: { PterosaurGuessGroup.guessGroup(forImageName: $0.imageName ?? "") == .azhdarchid }) else {
            XCTFail("Expected an azhdarchid in pterosaur pool")
            return
        }
        let decoys = AirPterosaurData.pickTwoDecoysDistinctGuessGroups(question: question, pool: pool)
        XCTAssertEqual(decoys.count, 2)
        XCTAssertFalse(decoys.contains { $0.id == question.id })
        let qg = PterosaurGuessGroup.guessGroup(forImageName: question.imageName ?? "")
        for d in decoys {
            XCTAssertNotEqual(PterosaurGuessGroup.guessGroup(forImageName: d.imageName ?? ""), qg)
        }
        let distinctGroups = Set(pool.compactMap { PterosaurGuessGroup.guessGroup(forImageName: $0.imageName ?? "") })
        if distinctGroups.count >= 3 {
            let g0 = PterosaurGuessGroup.guessGroup(forImageName: decoys[0].imageName ?? "")
            let g1 = PterosaurGuessGroup.guessGroup(forImageName: decoys[1].imageName ?? "")
            XCTAssertNotEqual(g0, g1, "With 3+ groups in pool, decoys should use two different groups when possible")
        }
    }

    func testPterosaurBodyImagesBundled() {
        let baseAssets = Set(MatchingGameConfigs.allPterosaurs.compactMap { $0.imageName?.lowercased() })
        let known = ImageAssetNames.knownAssets
        XCTAssertFalse(baseAssets.isEmpty, "Expected pterosaur base assets to be present.")
        for base in baseAssets {
            XCTAssertTrue(
                known.contains(base),
                "Missing pterosaur body imageset for catalog key: \(base)"
            )
        }
    }

    /// Species that have a dedicated silhouette imageset still used first when present; others use tinted body in the guess UI.
    func testBundledPterosaurSilhouettesMatchAirPterosaurNaming() {
        let known = ImageAssetNames.knownAssets
        for d in AirPterosaurData.nameThatPterosaurPool {
            guard let base = d.imageName?.lowercased() else {
                XCTFail("Pterosaur missing imageName")
                continue
            }
            let sil = AirPterosaurData.silhouetteAssetName(forBodyImage: base)
            XCTAssertTrue(
                known.contains(sil),
                "Missing silhouette imageset \(sil) for body \(base)"
            )
        }
    }

    func testPterosaurGameCardAssetsExist() {
        let requiredGameCards: Set<String> = [
            "game-name-that-pterosaur",
            "game-ptero-diets",
            "game-ptero-diets-success",
            "game-ptero-footprints",
            "game-ptero-footprints-success",
            "game-ptero-matrix",
            "game-ptero-matrix-success",
            "game-weigh-pterosaur",
            "game-which-ptero-is-taller",
            "game-which-ptero-is-taller-success",
        ]

        for gameCard in requiredGameCards {
            XCTAssertTrue(
                ImageAssetNames.knownAssets.contains(gameCard),
                "Missing game card asset: \(gameCard)"
            )
        }
    }

    func testPteroFootprintsGuessConfigAndTierImages() {
        let config = GuessGameConfigs.pteroFootprints
        XCTAssertEqual(config.id, "ptero-footprints")
        XCTAssertEqual(config.rounds.count, 3)
        let known = ImageAssetNames.knownAssets
        for round in config.rounds {
            XCTAssertTrue(
                known.contains(round.questionImageName),
                "Round \(round.id) question image missing: \(round.questionImageName)"
            )
            if let fallback = round.questionImageFallback {
                XCTAssertTrue(known.contains(fallback), "Round \(round.id) fallback missing: \(fallback)")
            }
        }
        for group in PterosaurGuessGroup.allCases {
            let stem = group == .transitional ? "transition" : group.rawValue
            XCTAssertTrue(
                known.contains("source-ptero-footprints-\(stem)"),
                "Missing pterosaur source-ptero-footprints hint imageset for \(group.rawValue)"
            )
            for size in ["small", "medium", "large"] {
                let tier = "ptero-footprint-\(stem)-\(size)"
                XCTAssertTrue(known.contains(tier), "Missing pterosaur footprint tier: \(tier)")
            }
        }
    }

}
