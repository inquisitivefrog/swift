//
//  MarineRacingXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class MarineRacingXCTests: XCTestCase {

    func testRacingMarineReptilesCardConfigRequiresPeriodSelection() {
        let config = RacingGameConfigs.racingMarineReptilesNeedsPeriod
        XCTAssertEqual(config.id, "racing-marine-reptiles")
        XCTAssertEqual(config.assetPrefix, "marine")
        XCTAssertEqual(config.trackLayout, .marineBuoySlalom(buoyCount: 8))
        XCTAssertTrue(config.racers.isEmpty, "Card config should route through period selection before race setup.")
    }

    func testRacingMarineBothPreviewConfigUsesSlalomAndMarinePrefix() throws {
        let config = RacingGameConfigs.racingMarineReptiles
        guard !config.racers.isEmpty else {
            throw XCTSkip("No marine reptiles with bundled racer art in the test catalog yet.")
        }
        XCTAssertEqual(config.id, "racing-marine-reptiles-both")
        XCTAssertEqual(config.assetPrefix, "marine")
        XCTAssertEqual(config.trackLayout, .marineBuoySlalom(buoyCount: 8))
    }

    func testMarineRacingAssetBasePrefersFlatSpeciesSlug() {
        XCTAssertEqual(
            SeaMarineReptileData.marineRacingAssetBase(fromCatalogImageName: "marine-mosa-mosasaurus"),
            "marine-racer-mosasaurus"
        )
        XCTAssertEqual(
            SeaMarineReptileData.marineRacingAssetBase(fromCatalogImageName: "marine-plesio-elasmosaurus"),
            "marine-racer-elasmosaurus"
        )
        XCTAssertNil(SeaMarineReptileData.marineRacingAssetBase(fromCatalogImageName: "invalid"))
    }

    func testMarineRacingExcludesPermianAndTriassicSpecies() {
        XCTAssertTrue(SeaMarineReptileData.marineRacingExcludedSlugs.contains("mesosaurus"))
        XCTAssertTrue(SeaMarineReptileData.marineRacingExcludedSlugs.contains("nothosaurus"))
        XCTAssertNil(SeaMarineReptileData.mesozoicSpanForRacing(slug: "mesosaurus"))
        XCTAssertNil(SeaMarineReptileData.mesozoicSpanForRacing(slug: "nothosaurus"))

        let bothSlugs = Set(
            SeaMarineReptileData.marineRacersForRacing(mesozoicSpan: .both)
                .compactMap { SeaMarineReptileData.matrixFossilSlug(for: $0.creature) }
        )
        XCTAssertFalse(bothSlugs.contains("mesosaurus"))
        XCTAssertFalse(bothSlugs.contains("nothosaurus"))
    }

    func testMarineRacersForRacingRespectsPeriodCatalog() throws {
        let jurassic = SeaMarineReptileData.marineRacersForRacing(mesozoicSpan: .jurassic)
        let cretaceous = SeaMarineReptileData.marineRacersForRacing(mesozoicSpan: .cretaceous)
        let both = SeaMarineReptileData.marineRacersForRacing(mesozoicSpan: .both)
        guard !both.isEmpty else {
            throw XCTSkip("No marine reptiles with bundled racer art in the test catalog yet.")
        }

        let jurassicSlugs = Set(jurassic.compactMap { SeaMarineReptileData.matrixFossilSlug(for: $0.creature) })
        let cretaceousSlugs = Set(cretaceous.compactMap { SeaMarineReptileData.matrixFossilSlug(for: $0.creature) })
        let bothSlugs = Set(both.compactMap { SeaMarineReptileData.matrixFossilSlug(for: $0.creature) })

        XCTAssertEqual(bothSlugs, jurassicSlugs.union(cretaceousSlugs))
        XCTAssertTrue(jurassicSlugs.isDisjoint(with: cretaceousSlugs))

        for slug in jurassicSlugs {
            XCTAssertEqual(SeaMarineReptileData.mesozoicSpanForRacing(slug: slug), .jurassic)
        }
        for slug in cretaceousSlugs {
            XCTAssertEqual(SeaMarineReptileData.mesozoicSpanForRacing(slug: slug), .cretaceous)
        }
    }

    func testRacingMarineReptilesPeriodConfigsBuildRacers() throws {
        let jurassic = RacingGameConfigs.makeMarineConfig(for: .jurassic)
        let cretaceous = RacingGameConfigs.makeMarineConfig(for: .cretaceous)
        let both = RacingGameConfigs.makeMarineConfig(for: .both)
        guard !both.racers.isEmpty else {
            throw XCTSkip("No marine reptiles with bundled racer art in the test catalog yet.")
        }
        XCTAssertEqual(jurassic.id, "racing-marine-reptiles-jurassic")
        XCTAssertEqual(cretaceous.id, "racing-marine-reptiles-cretaceous")
        XCTAssertEqual(both.id, "racing-marine-reptiles-both")
        XCTAssertFalse(jurassic.racers.isEmpty)
        XCTAssertFalse(cretaceous.racers.isEmpty)
        XCTAssertEqual(both.racers.count, jurassic.racers.count + cretaceous.racers.count)
        XCTAssertEqual(jurassic.racers.count, 6, "Expected six Jurassic marine racers with bundled art")
        XCTAssertEqual(cretaceous.racers.count, 6, "Expected six Cretaceous marine racers with bundled art")
        XCTAssertEqual(both.racers.count, 12, "Expected twelve marine racers when Both is selected")
    }

    func testMarineRacingSpeciesPackArtResolves() {
        for slug in ["mosasaurus", "ichthyosaurus", "archelon"] {
            let base = "marine-racer-\(slug)"
            guard SeaMarineReptileData.hasCompleteMarineRacingAssetPack(base: base) else { continue }
            XCTAssertTrue(ImageAssetNames.knownAssets.contains("\(base)-ready"))
            XCTAssertTrue(ImageAssetNames.knownAssets.contains("\(base)-finished-excited"))
            XCTAssertTrue(ImageAssetNames.knownAssets.contains("\(base)-finished-exhausted"))
        }
    }

    func testMarineReptileProgressCanonicalIdForRacing() {
        XCTAssertEqual(
            MarineReptileProgress.canonicalId(for: "racing-marine-reptiles"),
            "racing-marine-reptiles"
        )
        XCTAssertEqual(
            MarineReptileProgress.canonicalId(for: "racing-marine-reptiles-jurassic"),
            "racing-marine-reptiles"
        )
    }

    @MainActor
    func testMarineRacingSelectionPromptsResolveToBundledClips() {
        let speech = SpeechManager()
        XCTAssertNotNil(
            speech.urlForAudio(key: "game-choose-your-first-marine-reptile"),
            "Racing Marine Reptiles should use Games/game-choose-your-first-marine-reptile.m4a, not TTS"
        )
        XCTAssertNotNil(
            speech.urlForAudio(key: "game-choose-your-second-marine-reptile"),
            "Racing Marine Reptiles should use Games/game-choose-your-second-marine-reptile.m4a, not TTS"
        )
    }

    @MainActor
    func testMarineRacingReadySetGoResolveToBundledClips() {
        let speech = SpeechManager()
        for key in [
            "game-racing-marine-reptiles-ready",
            "game-racing-marine-reptiles-set",
            "game-racing-marine-reptiles-go",
        ] {
            XCTAssertNotNil(
                speech.urlForAudio(key: key),
                "Racing Marine Reptiles countdown should use bundled Games/\(key).m4a, not TTS"
            )
        }
    }

    func testMarineRacingBundledRefereeArtExists() {
        for name in [
            "marine-racer-referee-start",
            "marine-racer-referee-finished-winner",
            "marine-racer-referee-finished-tie",
        ] {
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(name), "Missing bundled referee art: \(name)")
        }
    }

    func testMarineRacingUsesPackSpecificRefereeArt() {
        XCTAssertEqual(startRefereeImageName(prefix: "marine"), "marine-racer-referee-start")
        XCTAssertEqual(finishRefereeImageName(prefix: "marine", isBroadDelta: true), "marine-racer-referee-finished-winner")
        XCTAssertEqual(tieRefereeImageName(prefix: "marine"), "marine-racer-referee-finished-tie")
    }
}
