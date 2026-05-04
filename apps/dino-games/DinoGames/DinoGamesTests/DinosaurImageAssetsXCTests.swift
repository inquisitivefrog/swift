//
//  DinosaurImageAssetsXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class DinosaurImageAssetsXCTests: XCTestCase {

    func testDinosaurBaseAndSilhouetteAssetsArePaired() {
        let baseAssets = Set(MatchingGameConfigs.allDinosaurs.compactMap { $0.imageName?.lowercased() })
        let silhouetteAssets = Set(
            ImageAssetNames.knownAssets
                .filter { $0.hasPrefix("dino-silhouette-") }
                .map { $0.lowercased() }
        )

        XCTAssertFalse(baseAssets.isEmpty, "Expected dinosaur base assets to be present.")
        XCTAssertFalse(silhouetteAssets.isEmpty, "Expected dinosaur silhouette assets to be present.")

        for base in baseAssets {
            let silhouette = silhouetteName(fromBase: base)
            XCTAssertTrue(
                silhouetteAssets.contains(silhouette),
                "Missing silhouette asset for \(base): expected \(silhouette)"
            )
        }
    }

    func testDinosaurGameCardAssetsExist() {
        let requiredGameCards: Set<String> = [
            "game-name-that-dinosaur",
            "game-name-that-dinosaur-success",
            "game-weigh-dinosaur",
            "game-weigh-dinosaur-success",
        ]

        for gameCard in requiredGameCards {
            XCTAssertTrue(
                ImageAssetNames.knownAssets.contains(gameCard),
                "Missing game card asset: \(gameCard)"
            )
        }
    }

    private func silhouetteName(fromBase base: String) -> String {
        let slug = base.replacingOccurrences(of: "dino-", with: "")
        return "dino-silhouette-\(slug)"
    }
}
