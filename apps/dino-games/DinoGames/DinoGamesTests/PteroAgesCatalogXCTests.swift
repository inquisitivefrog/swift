//
//  PteroAgesCatalogXCTests.swift
//  DinoGamesTests
//
//  Catalog, period pool, asset, and audio contracts for Ptero Ages (air level 2).
//

import XCTest
@testable import DinoGames

final class PteroAgesCatalogXCTests: XCTestCase {

    private var config: DinoAgesGameConfig { DinoAgesGameConfigs.pteroAges }

    private var pteroAgesJurassicImageNames: Set<String> {
        pteroAgesPeriodImageNames(for: .jurassic)
    }

    private var pteroAgesCretaceousImageNames: Set<String> {
        pteroAgesPeriodImageNames(for: .cretaceous)
    }

    private func pteroAgesPeriodImageNames(for period: DinoAgesPeriodKind) -> Set<String> {
        AirPterosaurData.allPterosaurs.compactMap { ptero -> String? in
            guard let name = ptero.imageName, name.hasPrefix("ptero-"),
                  let span = AirPterosaurData.mesozoicSpanForRacing(pterosaurId: ptero.id) else { return nil }
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

    private enum DinoAgesPeriodKind {
        case jurassic
        case cretaceous
    }

    // MARK: - Config / catalog

    func testPteroAgesConfigIdAndIntro() {
        XCTAssertEqual(config.id, "ptero-ages")
        XCTAssertEqual(config.title, "Ptero Ages!")
        XCTAssertEqual(config.introAudio, "game-ptero-ages")
    }

    func testPteroAgesAppearsOnLevel2() {
        let level2 = PterosaurGameCatalog.games(level: .level2)
        XCTAssertTrue(
            level2.contains { $0.id == "ptero-ages" },
            "Ptero Ages should appear on air level 2"
        )
    }

    func testPteroAgesProgressCategoryIsAir() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("ptero-ages"), .air)
    }

    func testPteroAgesPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-ptero-ages"), "Missing picker art: game-ptero-ages")
        XCTAssertTrue(
            known.contains("game-ptero-ages-success") || known.contains("game-ptero-ages"),
            "Missing victory art for ptero-ages"
        )
    }

    // MARK: - Period pool

    func testPteroAgesPeriodSetsAreDisjointAndLargeEnough() {
        let jurassic = pteroAgesJurassicImageNames
        let cretaceous = pteroAgesCretaceousImageNames
        XCTAssertTrue(jurassic.isDisjoint(with: cretaceous), "Jurassic and Cretaceous sets must not overlap")
        let minimum = DinoAgesMechanics.minimumUniqueDinosPerPeriod
        XCTAssertGreaterThanOrEqual(jurassic.count, minimum, "Need enough Jurassic pterosaurs for three rounds")
        XCTAssertGreaterThanOrEqual(cretaceous.count, minimum, "Need enough Cretaceous pterosaurs for three rounds")
    }

    func testPteroAgesPeriodSetsHaveBundledPortraits() {
        let known = ImageAssetNames.knownAssets
        var missing: [String] = []
        for name in pteroAgesJurassicImageNames.union(pteroAgesCretaceousImageNames) {
            if !known.contains(name) {
                missing.append(name)
            }
        }
        XCTAssertTrue(missing.isEmpty, "Missing bundled pterosaur portraits for Ptero Ages: \(missing)")
    }

    // MARK: - Period + source hint art

    func testPteroAgesPeriodAndSourceHintArtExists() {
        let known = ImageAssetNames.knownAssets
        for name in [
            "period-jurassic",
            "period-cretaceous",
            "ptero-ages-jurassic",
            "ptero-ages-cretaceous",
            "source-ptero-ages-jurassic",
            "source-ptero-ages-cretaceous",
        ] {
            XCTAssertTrue(known.contains(name), "Missing bundled asset: \(name)")
        }
    }

    func testPteroAgesSourceHintMomentsMatchCatalog() {
        XCTAssertEqual(LandGameDisplayMomentCatalog.pteroAgesSourceHints.count, 2)
        for hint in LandGameDisplayMomentCatalog.pteroAgesSourceHints {
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(hint.imageAssetName))
            XCTAssertFalse(hint.displayText.isEmpty)
            XCTAssertTrue(hint.audioKey.hasPrefix("game-ptero-ages-"))
        }
        let agesHintMoments = LandGameDisplayMomentCatalog.shippingAirMoments()
            .filter { $0.gameConfigId == "ptero-ages" && $0.context.hasPrefix("source-hint") }
        XCTAssertEqual(agesHintMoments.count, 2)
    }

    // MARK: - Audio

    func testPteroAgesGameplayAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for key in [
            "game-ptero-ages",
            "game-ptero-ages-find-in-jurassic",
            "game-ptero-ages-find-in-cretaceous",
            "game-ptero-ages-jurassic-pterosaurs",
            "game-ptero-ages-cretaceous-pterosaurs",
            "game-ptero-ages-tap-the-period-to-hear-description",
        ] {
            XCTAssertTrue(stems.contains(key), "Missing Ptero Ages gameplay audio: \(key).m4a")
        }
    }

    @MainActor
    func testPteroAgesGameplayAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            PterosaurGameAudioContracts.allRequiredKeys(forConfigId: "ptero-ages"),
            messagePrefix: "Ptero Ages"
        )
    }

    @MainActor
    func testPteroAgesCoverPeriodAudioResolvesInBundle() {
        let speech = SpeechManager()
        for key in ["cover-jurassic", "cover-cretaceous", "game-hint"] {
            XCTAssertNotNil(speech.urlForAudio(key: key), "Ptero Ages round flow expects `\(key)` in bundle")
        }
    }

    @MainActor
    func testPteroAgesPterosaurNameAudioResolvesForPeriodPoolSample() {
        let speech = SpeechManager()
        let sample = [
            pteroAgesJurassicImageNames.first,
            pteroAgesCretaceousImageNames.first,
        ].compactMap { $0 }
        var missing: [String] = []
        for key in sample {
            if speech.urlForAudio(key: key) == nil {
                missing.append(key)
            }
        }
        XCTAssertTrue(missing.isEmpty, "Missing creature narration for Ptero Ages taps: \(missing)")
    }
}
