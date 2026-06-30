//
//  PterosaurRacingXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class PterosaurRacingXCTests: XCTestCase {

    private var racingMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingAirMoments().filter { $0.gameConfigId == "racing-pterosaurs" }
    }

    func testRacingPterosaursCardConfigRequiresPeriodSelection() {
        let config = RacingGameConfigs.racingPterosaursCardConfig
        XCTAssertEqual(config.id, "racing-pterosaurs")
        XCTAssertEqual(config.assetPrefix, "ptero")
        XCTAssertTrue(config.racers.isEmpty, "Card config should route through period selection before race setup.")
        let level2 = PterosaurGameCatalog.games(level: .level2)
        XCTAssertTrue(level2.contains {
            guard case .racing(let cfg) = $0 else { return false }
            return PterosaurProgress.canonicalId(for: cfg.id) == "racing-pterosaurs"
        })
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

        // Portrait key uses alternate spellings bundled under racer filenames.
        XCTAssertEqual(
            AirPterosaurData.pteroRacingAssetBase(fromCatalogImageName: "ptero-azhd-quetzalcoatlus"),
            "ptero-racer-azhd-quetzalcoatlus"
        )
        // Legacy portrait misspelling still resolves to bundled racer pack.
        XCTAssertEqual(
            AirPterosaurData.pteroRacingAssetBase(fromCatalogImageName: "ptero-azhd-quetzacoatlus"),
            "ptero-racer-azhd-quetzalcoatlus"
        )
        XCTAssertEqual(
            AirPterosaurData.pteroRacingAssetBase(fromCatalogImageName: "ptero-spec-pterodactylus"),
            "ptero-racer-spec-pterodactylus"
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
            let b = racer.pteroRacingAssetBase!
            XCTAssertTrue(b.hasPrefix("ptero-racer-") || b.hasPrefix("ptero-racing-"))
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

    func testPterosaurProgressCanonicalIdForRacing() {
        XCTAssertEqual(PterosaurProgress.canonicalId(for: "racing-pterosaurs"), "racing-pterosaurs")
        XCTAssertEqual(PterosaurProgress.canonicalId(for: "racing-pterosaurs-jurassic"), "racing-pterosaurs")
    }

    @MainActor
    func testPteroRacingSelectionPromptsResolveToBundledClips() {
        let speech = SpeechManager()
        XCTAssertNotNil(
            speech.urlForAudio(key: "game-racer-choose-your-first-pterosaur-to-race"),
            "Racing Pterosaurs should use Games/game-racer-choose-your-first-pterosaur-to-race.m4a, not TTS"
        )
        XCTAssertNotNil(
            speech.urlForAudio(key: "game-racer-choose-your-second-pterosaur-to-race"),
            "Racing Pterosaurs should use Games/game-racer-choose-your-second-pterosaur-to-race.m4a, not TTS"
        )
    }

    @MainActor
    func testPteroRacingReadySetGoResolveToBundledClips() {
        let speech = SpeechManager()
        for key in [
            "game-racing-pterosaurs-ready",
            "game-racing-pterosaurs-set",
            "game-racing-pterosaurs-go",
        ] {
            XCTAssertNotNil(
                speech.urlForAudio(key: key),
                "Racing Pterosaurs countdown should use bundled Games/\(key).m4a, not TTS"
            )
        }
    }

    func testPteroRacingBundledRefereeArtExists() {
        for name in [
            "ptero-racer-referee-start",
            "ptero-racer-referee-finished-winner",
            "ptero-racer-referee-finished-tie",
        ] {
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(name), "Missing bundled referee art: \(name)")
        }
    }

    func testPteroRacingUsesPackSpecificRefereeArt() {
        XCTAssertEqual(startRefereeImageName(prefix: "ptero"), "ptero-racer-referee-start")
        XCTAssertEqual(finishRefereeImageName(prefix: "ptero", isBroadDelta: true), "ptero-racer-referee-finished-winner")
        XCTAssertEqual(tieRefereeImageName(prefix: "ptero"), "ptero-racer-referee-finished-tie")
    }

    // MARK: - Picker / victory art

    func testRacingPterosaursPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-racing-pterosaurs"), "Missing picker art: game-racing-pterosaurs")
        let successCandidates = ["game-racing-pterosaurs-success", "game-racing-pterosaurs"]
        XCTAssertTrue(
            successCandidates.contains { known.contains($0) },
            "Missing victory art. Tried: \(successCandidates)"
        )
    }

    // MARK: - Display moments

    func testRacingPterosaursDisplayMomentsCoverPeriodHintsAndRacers() throws {
        let periodHints = racingMoments.filter { $0.context.hasPrefix("period ") }
        XCTAssertEqual(periodHints.count, 2, "Expected Jurassic and Cretaceous period hints")
        let jurassicRacers = racingMoments.filter { $0.context.hasPrefix("jurassic racer ") }
        let cretaceousRacers = racingMoments.filter { $0.context.hasPrefix("cretaceous racer ") }
        let jurassicConfig = RacingGameConfigs.makePterosaurConfig(for: .jurassic)
        let cretaceousConfig = RacingGameConfigs.makePterosaurConfig(for: .cretaceous)
        guard !jurassicConfig.racers.isEmpty else {
            throw XCTSkip("No Jurassic pterosaur racers with bundled art in the test catalog yet.")
        }
        XCTAssertEqual(jurassicRacers.count, jurassicConfig.racers.count)
        XCTAssertEqual(cretaceousRacers.count, cretaceousConfig.racers.count)
        XCTAssertEqual(racingMoments.count, periodHints.count + jurassicRacers.count + cretaceousRacers.count)
    }

    func testRacingPterosaursDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = racingMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testRacingPterosaursDisplayMomentsHaveResolvableAudio() {
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
