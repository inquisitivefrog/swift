//
//  MarineReptileImageAssetsXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class MarineReptileImageAssetsXCTests: XCTestCase {

    func testMarineBaseAndSilhouetteAssetsArePaired() {
        let marineAssets = ImageAssetNames.knownAssets.filter { $0.hasPrefix("marine-") }
        let baseAssets = Set(marineAssets.filter { !$0.contains("-silhouette-") })
        let silhouetteAssets = Set(marineAssets.filter { $0.contains("-silhouette-") })

        XCTAssertFalse(baseAssets.isEmpty, "Expected marine base assets to be present.")
        XCTAssertFalse(silhouetteAssets.isEmpty, "Expected marine silhouette assets to be present.")

        // Level picker cards (`marine-level-*`) are not creature bodies; they do not use `-silhouette-` pairs.
        let baseAssetsRequiringSilhouettes = baseAssets.filter { !$0.hasPrefix("marine-level-") }
        for base in baseAssetsRequiringSilhouettes {
            let silhouette = silhouetteName(fromBase: base)
            XCTAssertTrue(
                silhouetteAssets.contains(silhouette),
                "Missing silhouette asset for \(base): expected \(silhouette)"
            )
        }

        for silhouette in silhouetteAssets {
            let base = baseName(fromSilhouette: silhouette)
            XCTAssertTrue(
                baseAssets.contains(base),
                "Missing base asset for \(silhouette): expected \(base)"
            )
        }
    }

    func testMarineGameCardAssetsExist() {
        let requiredGameCards: Set<String> = [
            "game-name-that-marine-reptile",
            "game-name-that-marine-reptile-success",
            "game-marine-reptile-puzzle",
            "game-marine-reptile-puzzle-success",
        ]

        for gameCard in requiredGameCards {
            XCTAssertTrue(
                ImageAssetNames.knownAssets.contains(gameCard),
                "Missing game card asset: \(gameCard)"
            )
        }
    }

    private func silhouetteName(fromBase base: String) -> String {
        let parts = base.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count >= 3 else { return base + "-silhouette" }
        let slug = parts.dropFirst(2).joined(separator: "-")
        return "marine-\(parts[1])-silhouette-\(slug)"
    }

    private func baseName(fromSilhouette silhouette: String) -> String {
        silhouette.replacingOccurrences(of: "-silhouette-", with: "-")
    }
}
