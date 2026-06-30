//
//  MarineAgesCatalogXCTests.swift
//  DinoGamesTests
//
//  Catalog, period pool, asset, and audio contracts for Marine Ages (sea level 2).
//

import XCTest
@testable import DinoGames

final class MarineAgesCatalogXCTests: XCTestCase {

    private var config: DinoAgesGameConfig { DinoAgesGameConfigs.marineAges }

    private var marineAgesJurassicImageNames: Set<String> {
        marineAgesPeriodImageNames(for: .jurassic)
    }

    private var marineAgesCretaceousImageNames: Set<String> {
        marineAgesPeriodImageNames(for: .cretaceous)
    }

    private enum MarineAgesPeriodKind {
        case jurassic
        case cretaceous
    }

    private func marineAgesPeriodImageNames(for period: MarineAgesPeriodKind) -> Set<String> {
        SeaMarineReptileData.allMarineReptiles.compactMap { marine -> String? in
            guard let name = marine.imageName, name.hasPrefix("marine-"),
                  let span = SeaMarineReptileData.mesozoicSpanForAges(creature: marine) else { return nil }
            switch (period, span) {
            case (.jurassic, .jurassic), (.jurassic, .both):
                return name
            case (.cretaceous, .cretaceous):
                return name
            default:
                return nil
            }
        }.reduce(into: Set()) { $0.insert($1) }
    }

    // MARK: - Config / catalog

    func testMarineAgesConfigIdAndIntro() {
        XCTAssertEqual(config.id, "marine-ages")
        XCTAssertEqual(config.title, "Marine Ages!")
        XCTAssertEqual(config.introAudio, "game-marine-ages")
    }

    func testMarineAgesAppearsOnLevel2() {
        let level2 = MarineReptileGameCatalog.games(level: .level2)
        XCTAssertTrue(
            level2.contains { $0.id == "marine-ages" },
            "Marine Ages should appear on marine level 2"
        )
    }

    func testMarineAgesProgressCategoryIsMarine() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("marine-ages"), .marineReptiles)
    }

    func testMarineAgesPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-marine-ages"), "Missing picker art: game-marine-ages")
        XCTAssertTrue(
            known.contains("game-marine-ages-success") || known.contains("game-marine-ages"),
            "Missing victory art for marine-ages"
        )
    }

    // MARK: - Period pool

    func testMarineAgesPeriodSetsAreDisjointAndLargeEnough() {
        let jurassic = marineAgesJurassicImageNames
        let cretaceous = marineAgesCretaceousImageNames
        XCTAssertTrue(jurassic.isDisjoint(with: cretaceous), "Jurassic and Cretaceous sets must not overlap")
        let minimum = DinoAgesMechanics.minimumUniqueDinosPerPeriod
        XCTAssertGreaterThanOrEqual(jurassic.count, minimum, "Need enough Jurassic marine reptiles for three rounds")
        XCTAssertGreaterThanOrEqual(cretaceous.count, minimum, "Need enough Cretaceous marine reptiles for three rounds")
    }

    func testMarineAgesPeriodSetsHaveBundledPortraits() {
        let known = ImageAssetNames.knownAssets
        var missing: [String] = []
        for name in marineAgesJurassicImageNames.union(marineAgesCretaceousImageNames) {
            if !known.contains(name) {
                missing.append(name)
            }
        }
        XCTAssertTrue(missing.isEmpty, "Missing bundled marine portraits for Marine Ages: \(missing)")
    }

    // MARK: - Period + source hint art

    func testMarineAgesPeriodAndSourceHintArtExists() {
        let known = ImageAssetNames.knownAssets
        for name in [
            "period-jurassic",
            "period-cretaceous",
            "marine-ages-jurassic",
            "marine-ages-cretaceous",
            "source-marine-ages-jurassic",
            "source-marine-ages-cretaceous",
        ] {
            XCTAssertTrue(known.contains(name), "Missing bundled asset: \(name)")
        }
    }

    func testMarineAgesSourceHintMomentsMatchCatalog() {
        XCTAssertEqual(LandGameDisplayMomentCatalog.marineAgesSourceHints.count, 2)
        for hint in LandGameDisplayMomentCatalog.marineAgesSourceHints {
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(hint.imageAssetName))
            XCTAssertFalse(hint.displayText.isEmpty)
            XCTAssertTrue(hint.audioKey.hasPrefix("game-marine-ages-"))
        }
        let agesHintMoments = LandGameDisplayMomentCatalog.shippingMarineMoments()
            .filter { $0.gameConfigId == "marine-ages" && $0.context.hasPrefix("source-hint") }
        XCTAssertEqual(agesHintMoments.count, 2)
    }

    // MARK: - Audio

    func testMarineAgesGameplayAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for key in [
            "game-marine-ages",
            "game-marine-ages-find-in-jurassic",
            "game-marine-ages-find-in-cretaceous",
            "game-marine-ages-jurassic-marine-reptiles",
            "game-marine-ages-cretaceous-marine-reptiles",
            "game-marine-ages-tap-the-period-to-hear-description",
        ] {
            XCTAssertTrue(stems.contains(key), "Missing Marine Ages gameplay audio: \(key).m4a")
        }
    }

    @MainActor
    func testMarineAgesGameplayAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            [
                "game-marine-ages",
                "game-hint",
                "game-marine-ages-find-in-jurassic",
                "game-marine-ages-find-in-cretaceous",
                "game-marine-ages-jurassic-marine-reptiles",
                "game-marine-ages-cretaceous-marine-reptiles",
                "game-marine-ages-tap-the-period-to-hear-description",
            ],
            messagePrefix: "Marine Ages"
        )
    }

    @MainActor
    func testMarineAgesCoverPeriodAudioResolvesInBundle() {
        let speech = SpeechManager()
        for key in ["cover-jurassic", "cover-cretaceous", "game-hint"] {
            XCTAssertNotNil(speech.urlForAudio(key: key), "Marine Ages round flow expects `\(key)` in bundle")
        }
    }

    @MainActor
    func testMarineAgesMarineReptileNameAudioResolvesForPeriodPoolSample() {
        let speech = SpeechManager()
        let sample = [
            marineAgesJurassicImageNames.first,
            marineAgesCretaceousImageNames.first,
        ].compactMap { $0 }
        var missing: [String] = []
        for key in sample {
            if speech.urlForAudio(key: key) == nil {
                missing.append(key)
            }
        }
        XCTAssertTrue(missing.isEmpty, "Missing creature narration for Marine Ages taps: \(missing)")
    }
}
