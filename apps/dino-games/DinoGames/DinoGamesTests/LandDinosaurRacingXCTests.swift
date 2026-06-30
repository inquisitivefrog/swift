//
//  LandDinosaurRacingXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class LandDinosaurRacingXCTests: XCTestCase {

    private var racingMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingLandMoments().filter { $0.gameConfigId == "racing-dinosaurs" }
    }

    func testRacingDinosaursCardConfigRequiresPeriodSelection() {
        let config = RacingGameConfigs.racingDinosaursNeedsPeriod
        XCTAssertEqual(config.id, "racing-dinosaurs")
        XCTAssertEqual(config.assetPrefix, "dino")
        XCTAssertEqual(config.trackLayout, .ovalDualLane)
        XCTAssertTrue(config.racers.isEmpty, "Card config should route through period selection before race setup.")
        let level2 = DinosaurGameCatalog.games(level: .level2)
        XCTAssertTrue(level2.contains {
            guard case .racing(let cfg) = $0 else { return false }
            return LandDinosaurProgress.canonicalId(for: cfg.id) == "racing-dinosaurs"
        })
    }

    func testRacingDinosaursCretaceousPreviewConfigUsesOvalAndDinoPrefix() throws {
        let config = RacingGameConfigs.racingDinosaurs
        guard !config.racers.isEmpty else {
            throw XCTSkip("No dinosaurs with bundled racer art in the test catalog yet.")
        }
        XCTAssertEqual(config.id, "racing-dinosaurs-cretaceous")
        XCTAssertEqual(config.assetPrefix, "dino")
        XCTAssertEqual(config.trackLayout, .ovalDualLane)
    }

    func testDinoRacingAssetBaseMapsPortraitToFlatSlug() {
        XCTAssertEqual(
            LandDinosaurRacingCatalog.dinoRacingAssetBase(fromCatalogImageName: "dino-trex"),
            "dino-racer-trex"
        )
        XCTAssertEqual(
            LandDinosaurRacingCatalog.dinoRacingAssetBase(fromCatalogImageName: "dino-parasaurolophus"),
            "dino-racer-parasaurolophus"
        )
        XCTAssertEqual(
            LandDinosaurRacingCatalog.dinoRacingAssetBase(slug: "spinosaurus"),
            "dino-racer-spinosaurus"
        )
        XCTAssertNil(LandDinosaurRacingCatalog.dinoRacingAssetBase(fromCatalogImageName: "ptero-azhd-hatzegopteryx"))
    }

    func testDinoRacersForRacingRespectsPeriodCatalog() throws {
        let jurassic = LandDinosaurRacingCatalog.dinosaurRacersForRacing(mesozoicSpan: .jurassic)
        let cretaceous = LandDinosaurRacingCatalog.dinosaurRacersForRacing(mesozoicSpan: .cretaceous)
        let both = LandDinosaurRacingCatalog.dinosaurRacersForRacing(mesozoicSpan: .both)
        guard !both.isEmpty else {
            throw XCTSkip("No dinosaurs with bundled racer art in the test catalog yet.")
        }

        let jurassicSlugs = Set(jurassic.map(\.slug))
        let cretaceousSlugs = Set(cretaceous.map(\.slug))
        let bothSlugs = Set(both.map(\.slug))

        XCTAssertEqual(bothSlugs, jurassicSlugs.union(cretaceousSlugs))
        XCTAssertTrue(jurassicSlugs.isDisjoint(with: cretaceousSlugs))

        for slug in jurassicSlugs {
            XCTAssertEqual(LandDinosaurRacingCatalog.mesozoicSpanForRacing(slug: slug), .jurassic)
        }
        for slug in cretaceousSlugs {
            XCTAssertEqual(LandDinosaurRacingCatalog.mesozoicSpanForRacing(slug: slug), .cretaceous)
        }
    }

    func testRacingDinosaursPeriodConfigsBuildRacers() throws {
        let jurassic = RacingGameConfigs.makeConfig(for: .jurassic)
        let cretaceous = RacingGameConfigs.makeConfig(for: .cretaceous)
        let both = RacingGameConfigs.makeConfig(for: .both)
        guard !both.racers.isEmpty else {
            throw XCTSkip("No dinosaurs with bundled racer art in the test catalog yet.")
        }
        XCTAssertEqual(jurassic.id, "racing-dinosaurs-jurassic")
        XCTAssertEqual(cretaceous.id, "racing-dinosaurs-cretaceous")
        XCTAssertEqual(both.id, "racing-dinosaurs-both")
        XCTAssertFalse(jurassic.racers.isEmpty)
        XCTAssertFalse(cretaceous.racers.isEmpty)
        XCTAssertEqual(both.racers.count, jurassic.racers.count + cretaceous.racers.count)
        XCTAssertEqual(jurassic.racers.count, 6, "Expected six Jurassic dinosaur racers with bundled art")
        XCTAssertEqual(cretaceous.racers.count, 8, "Expected eight Cretaceous dinosaur racers with bundled art")
        XCTAssertEqual(both.racers.count, 14, "Expected fourteen dinosaur racers when Both is selected")
    }

    func testRacingDinosaursJurassicPoolContainsOnlyJurassicSpeciesWhenNonEmpty() throws {
        let config = RacingGameConfigs.makeConfig(for: .jurassic)
        guard !config.racers.isEmpty else {
            throw XCTSkip("No Jurassic dinosaur racers with bundled art in the test catalog yet.")
        }
        XCTAssertEqual(config.assetPrefix, "dino")
        XCTAssertEqual(config.id, "racing-dinosaurs-jurassic")

        let jurassicNames = Set(
            LandDinosaurRacingCatalog.dinosaurRacersForRacing(mesozoicSpan: .jurassic).map(\.displayName)
        )
        for racer in config.racers {
            XCTAssertTrue(jurassicNames.contains(racer.name), "Jurassic pool included non-Jurassic species \(racer.name)")
        }
    }

    func testRacingDinosaursCretaceousPoolContainsOnlyCretaceousSpeciesWhenNonEmpty() throws {
        let config = RacingGameConfigs.makeConfig(for: .cretaceous)
        guard !config.racers.isEmpty else {
            throw XCTSkip("No Cretaceous dinosaur racers with bundled art in the test catalog yet.")
        }
        XCTAssertEqual(config.assetPrefix, "dino")
        XCTAssertEqual(config.id, "racing-dinosaurs-cretaceous")

        let cretaceousNames = Set(
            LandDinosaurRacingCatalog.dinosaurRacersForRacing(mesozoicSpan: .cretaceous).map(\.displayName)
        )
        for racer in config.racers {
            XCTAssertTrue(cretaceousNames.contains(racer.name), "Cretaceous pool included non-Cretaceous species \(racer.name)")
        }
    }

    func testRacingDinosaursBothPoolIsSubsetOfCatalogWithRacingArt() throws {
        let config = RacingGameConfigs.makeConfig(for: .both)
        guard !config.racers.isEmpty else {
            throw XCTSkip("No dinosaurs with bundled racer art in the test catalog yet.")
        }
        XCTAssertEqual(config.id, "racing-dinosaurs-both")

        let catalogSlugs = Set(LandDinosaurRacingCatalog.allEntries.map(\.slug))
        let racerSlugs = Set(
            config.racers.map(\.dinoRacerSpeciesSegment).filter { catalogSlugs.contains($0) }
        )
        XCTAssertFalse(racerSlugs.isEmpty)
        for racer in config.racers {
            XCTAssertNotNil(racer.racerAssetClade)
            XCTAssertFalse(racer.dinoRacerAssetBases().isEmpty)
        }
    }

    func testRacingDinosaursIncludesKnownSpeciesAcrossSpansWhenThoseSpeciesHaveRacingArt() {
        let jurassic = RacingGameConfigs.makeConfig(for: .jurassic)
        let cretaceous = RacingGameConfigs.makeConfig(for: .cretaceous)

        func contains(_ speciesName: String, in config: RacingGameConfig) -> Bool {
            config.racers.contains(where: { $0.name.lowercased() == speciesName.lowercased() })
        }

        if contains("Allosaurus", in: jurassic) {
            XCTAssertFalse(contains("Allosaurus", in: cretaceous))
        }
        if contains("T-Rex", in: cretaceous) {
            XCTAssertFalse(contains("T-Rex", in: jurassic))
        }
    }

    func testDinoRacingSpeciesPackArtResolves() {
        for slug in ["trex", "parasaurolophus", "spinosaurus"] {
            let base = LandDinosaurRacingCatalog.dinoRacingAssetBase(slug: slug)
            guard LandDinosaurRacingCatalog.hasCompleteDinosaurRacingAssetPack(slug: slug) else { continue }
            XCTAssertTrue(ImageAssetNames.knownAssets.contains("\(base)-ready"))
            XCTAssertTrue(ImageAssetNames.knownAssets.contains("\(base)-finish-excited"))
            XCTAssertTrue(ImageAssetNames.knownAssets.contains("\(base)-finish-exhausted"))
        }
    }

    func testLandDinosaurProgressCanonicalIdForRacing() {
        XCTAssertEqual(LandDinosaurProgress.canonicalId(for: "racing-dinosaurs"), "racing-dinosaurs")
        XCTAssertEqual(LandDinosaurProgress.canonicalId(for: "racing-dinosaurs-jurassic"), "racing-dinosaurs")
    }

    @MainActor
    func testDinoRacingSelectionPromptsResolveToBundledClips() {
        let speech = SpeechManager()
        XCTAssertNotNil(
            speech.urlForAudio(key: "game-racer-choose-your-first-dinosaur-to-race"),
            "Racing Dinosaurs should use Games/game-racer-choose-your-first-dinosaur-to-race.m4a, not TTS"
        )
        XCTAssertNotNil(
            speech.urlForAudio(key: "game-racer-choose-your-second-dinosaur-to-race"),
            "Racing Dinosaurs should use Games/game-racer-choose-your-second-dinosaur-to-race.m4a, not TTS"
        )
    }

    @MainActor
    func testDinoRacingReadySetGoResolveToBundledClips() {
        let speech = SpeechManager()
        for key in [
            "game-racing-dinosaurs-ready",
            "game-racing-dinosaurs-set",
            "game-racing-dinosaurs-go",
        ] {
            XCTAssertNotNil(
                speech.urlForAudio(key: key),
                "Racing Dinosaurs countdown should use bundled Games/\(key).m4a, not TTS"
            )
        }
    }

    func testDinoRacingBundledRefereeArtExists() {
        for name in [
            "dino-racer-referee-start",
            "dino-racer-referee-finish-excited",
            "dino-racer-referee-finish-worried",
        ] {
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(name), "Missing bundled referee art: \(name)")
        }
    }

    func testDinoRacingUsesPackSpecificRefereeArt() {
        XCTAssertEqual(startRefereeImageName(prefix: "dino"), "dino-racer-referee-start")
        XCTAssertEqual(finishRefereeImageName(prefix: "dino", isBroadDelta: true), "dino-racer-referee-finish-excited")
        XCTAssertEqual(tieRefereeImageName(prefix: "dino"), "dino-racer-referee-finish")
    }

    // MARK: - Picker / victory art

    func testRacingDinosaursPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-racing-dinosaurs"), "Missing picker art: game-racing-dinosaurs")
        let successCandidates = ["game-racing-dinosaurs-success", "game-racing-dinosaurs"]
        XCTAssertTrue(
            successCandidates.contains { known.contains($0) },
            "Missing victory art. Tried: \(successCandidates)"
        )
    }

    // MARK: - Display moments

    func testRacingDinosaursDisplayMomentsCoverPeriodHintsAndRacers() throws {
        let periodHints = racingMoments.filter { $0.context.hasPrefix("period ") }
        XCTAssertEqual(periodHints.count, 2, "Expected Jurassic and Cretaceous period hints")
        let jurassicRacers = racingMoments.filter { $0.context.hasPrefix("jurassic racer ") }
        let cretaceousRacers = racingMoments.filter { $0.context.hasPrefix("cretaceous racer ") }
        let jurassicConfig = RacingGameConfigs.makeConfig(for: .jurassic)
        let cretaceousConfig = RacingGameConfigs.makeConfig(for: .cretaceous)
        guard !jurassicConfig.racers.isEmpty else {
            throw XCTSkip("No Jurassic dinosaur racers with bundled art in the test catalog yet.")
        }
        XCTAssertEqual(jurassicRacers.count, jurassicConfig.racers.count)
        XCTAssertEqual(cretaceousRacers.count, cretaceousConfig.racers.count)
        XCTAssertEqual(racingMoments.count, periodHints.count + jurassicRacers.count + cretaceousRacers.count)
    }

    func testRacingDinosaursDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = racingMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testRacingDinosaursDisplayMomentsHaveResolvableAudio() {
        let speech = SpeechManager()
        let missing = racingMoments.filter { moment in
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
}
