//
//  PterosaurRacingXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class PterosaurRacingXCTests: XCTestCase {

    func testRacingPterosaursCardConfigRequiresPeriodSelection() {
        let config = RacingGameConfigs.racingPterosaursCardConfig
        XCTAssertEqual(config.id, "racing-pterosaurs")
        XCTAssertEqual(config.assetPrefix, "ptero")
        XCTAssertTrue(config.racers.isEmpty, "Card config should route through period selection before race setup.")
    }

    func testPteroRacingAssetBaseDerivedFromCatalogImageName() {
        let firstBase = AirPterosaurData.pteroRacingAssetBase(fromCatalogImageName: "ptero-azhd-hatzegopteryx")
        XCTAssertTrue(
            firstBase == "ptero-racing-azhd-hatzegopteryx" || firstBase == "ptero-racer-azhd-hatzegopteryx"
        )

        let secondBase = AirPterosaurData.pteroRacingAssetBase(fromCatalogImageName: "ptero-basal-rhamphorhynchus")
        XCTAssertTrue(
            secondBase == "ptero-racing-basal-rhamphorhynchus" || secondBase == "ptero-racer-basal-rhamphorhynchus"
        )
        XCTAssertNil(AirPterosaurData.pteroRacingAssetBase(fromCatalogImageName: "invalid"))
    }

    func testRacingPterosaursJurassicPoolContainsOnlyJurassicOrBothSpeciesWhenNonEmpty() throws {
        let config = RacingGameConfigs.makePterosaurConfig(for: .jurassic)
        guard !config.racers.isEmpty else {
            throw XCTSkip("No pterosaurs with a full ptero-racing-* asset pack in the test bundle catalog yet.")
        }
        XCTAssertEqual(config.assetPrefix, "ptero")
        XCTAssertEqual(config.id, "racing-pterosaurs-jurassic")

        let ids = Set(config.racers.map(\.id))
        for id in ids {
            guard let span = AirPterosaurData.mesozoicSpanForRacing(pterosaurId: id) else {
                XCTFail("Missing Mesozoic span for pterosaur id \(id)")
                continue
            }
            XCTAssertTrue(span == .jurassic || span == .both, "Jurassic pool included non-Jurassic species id \(id)")
        }
    }

    func testRacingPterosaursCretaceousPoolContainsOnlyCretaceousOrBothSpeciesWhenNonEmpty() throws {
        let config = RacingGameConfigs.makePterosaurConfig(for: .cretaceous)
        guard !config.racers.isEmpty else {
            throw XCTSkip("No pterosaurs with a full ptero-racing-* asset pack in the test bundle catalog yet.")
        }
        XCTAssertEqual(config.assetPrefix, "ptero")
        XCTAssertEqual(config.id, "racing-pterosaurs-cretaceous")

        let ids = Set(config.racers.map(\.id))
        for id in ids {
            guard let span = AirPterosaurData.mesozoicSpanForRacing(pterosaurId: id) else {
                XCTFail("Missing Mesozoic span for pterosaur id \(id)")
                continue
            }
            XCTAssertTrue(span == .cretaceous || span == .both, "Cretaceous pool included non-Cretaceous species id \(id)")
        }
    }

    func testRacingPterosaursBothPoolIsSubsetOfCatalogWithRacingArt() throws {
        let config = RacingGameConfigs.makePterosaurConfig(for: .both)
        guard !config.racers.isEmpty else {
            throw XCTSkip("No pterosaurs with a full ptero-racing-* asset pack in the test bundle catalog yet.")
        }
        XCTAssertEqual(config.id, "racing-pterosaurs-both")

        let catalogIds = Set(AirPterosaurData.allPterosaurs.map(\.id))
        let racerIds = Set(config.racers.map(\.id))
        XCTAssertTrue(racerIds.isSubset(of: catalogIds))
        for racer in config.racers {
            XCTAssertNotNil(racer.pteroRacingAssetBase)
            XCTAssertTrue(racer.pteroRacingAssetBase!.hasPrefix("ptero-racing-"))
        }
    }

    func testRacingPterosaursIncludesKnownSpeciesAcrossSpansWhenThoseSpeciesHaveRacingArt() {
        let jurassic = RacingGameConfigs.makePterosaurConfig(for: .jurassic)
        let cretaceous = RacingGameConfigs.makePterosaurConfig(for: .cretaceous)
        let both = RacingGameConfigs.makePterosaurConfig(for: .both)

        func contains(_ speciesName: String, in config: RacingGameConfig) -> Bool {
            config.racers.contains(where: { $0.name.lowercased() == speciesName.lowercased() })
        }

        if contains("Rhamphorhynchus", in: jurassic) {
            XCTAssertFalse(contains("Rhamphorhynchus", in: cretaceous))
        }
        if contains("Ornithocheirus", in: cretaceous) {
            XCTAssertFalse(contains("Ornithocheirus", in: jurassic))
        }
        if contains("Dsungaripterus", in: jurassic), contains("Dsungaripterus", in: cretaceous) {
            XCTAssertTrue(contains("Dsungaripterus", in: both))
        }
    }
}
