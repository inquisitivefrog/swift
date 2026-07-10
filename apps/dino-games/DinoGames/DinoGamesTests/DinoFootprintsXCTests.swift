//
//  DinoFootprintsXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, audio, and round-mechanic contracts for Dino Footprints (land L3).
//

import XCTest
@testable import DinoGames

final class DinoFootprintsXCTests: XCTestCase {

    private var config: GuessGameConfig { GuessGameConfigs.dinoFootprints }

    private var footprintMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingLandMoments().filter { $0.gameConfigId == "dino-footprints" }
    }

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "dinoFootprintsUsedSlotKeys")
    }

    // MARK: - Config / catalog

    func testDinoFootprintsConfigIdTitleAndIntro() {
        XCTAssertEqual(config.id, "dino-footprints")
        XCTAssertEqual(config.title, "Dino Footprints!")
        XCTAssertEqual(config.introAudio, "game-dino-footprints")
    }

    func testDinoFootprintsAppearsOnLevel3() {
        let level3 = DinosaurGameCatalog.games(level: .level3)
        XCTAssertTrue(
            level3.contains { $0.id == "dino-footprints" },
            "Dino Footprints should appear on land level 3"
        )
    }

    func testDinoFootprintsProgressCategoryIsLand() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("dino-footprints"), .land)
    }

    func testDinoFootprintsPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-dino-footprints"), "Missing picker art: game-dino-footprints")
        XCTAssertTrue(
            known.contains("game-dino-footprints-success") || known.contains("game-dino-footprints"),
            "Missing victory art for dino-footprints"
        )
    }

    func testDinoFootprintsPlayablePoolIsLargeEnough() {
        XCTAssertGreaterThanOrEqual(config.availableDinosaurs.count, 5)
        for dino in config.availableDinosaurs {
            XCTAssertTrue(dino.imageName?.hasPrefix("dino-") == true)
            XCTAssertNotNil(
                Self.footprintMorphotypeClade(for: dino),
                "Playable pool dinosaur \(dino.name) should appear in footprint morphotype map"
            )
        }
    }

    // MARK: - Round structure

    func testDinoFootprintsProductionConfigThreeRounds() {
        XCTAssertEqual(config.rounds.count, 3)
        let correctIds = config.rounds.map(\.correctAnswerId)
        XCTAssertEqual(Set(correctIds).count, 3, "Each round should feature a distinct correct dinosaur")
    }

    func testDinoFootprintsRoundOptionsAndQuestionImages() {
        let known = ImageAssetNames.knownAssets
        for round in config.rounds {
            XCTAssertEqual(round.options.count, 3)
            XCTAssertEqual(Set(round.options.map(\.id)).count, 3)
            XCTAssertTrue(round.options.contains { $0.id == round.correctAnswerId })
            XCTAssertTrue(
                round.questionImageName.hasPrefix("footprint-"),
                "Round \(round.id) question should use footprint art: \(round.questionImageName)"
            )
            XCTAssertTrue(
                known.contains(round.questionImageName),
                "Round \(round.id) missing footprint imageset: \(round.questionImageName)"
            )
            if let fallback = round.questionImageFallback {
                XCTAssertTrue(known.contains(fallback), "Round \(round.id) missing portrait: \(fallback)")
            }
            for option in round.options {
                guard let imageName = option.imageName else {
                    XCTFail("Option \(option.name) missing imageName")
                    continue
                }
                XCTAssertTrue(known.contains(imageName), "Round \(round.id) option missing portrait: \(imageName)")
            }
        }
    }

    func testDinoFootprintsDecoysUseDifferentFootprintMorphotypes() {
        for round in config.rounds {
            guard let correct = round.options.first(where: { $0.id == round.correctAnswerId }) else {
                XCTFail("Round \(round.id) missing correct option")
                continue
            }
            guard let correctClade = Self.footprintMorphotypeClade(for: correct) else {
                XCTFail("Correct answer \(correct.name) missing footprint morphotype")
                continue
            }
            let decoys = round.options.filter { $0.id != round.correctAnswerId }
            XCTAssertEqual(decoys.count, 2)
            for decoy in decoys {
                guard let decoyClade = Self.footprintMorphotypeClade(for: decoy) else {
                    XCTFail("Decoy \(decoy.name) missing footprint morphotype")
                    continue
                }
                XCTAssertNotEqual(
                    decoyClade,
                    correctClade,
                    "Decoy \(decoy.name) must not share footprint morphotype with question \(correct.name)"
                )
            }
        }
    }

    func testDinoFootprintsQuestionImageMatchesCorrectMorphotype() {
        for round in config.rounds {
            guard let correct = round.options.first(where: { $0.id == round.correctAnswerId }),
                  let clade = Self.footprintMorphotypeClade(for: correct) else {
                XCTFail("Round \(round.id) missing correct morphotype")
                continue
            }
            XCTAssertTrue(
                round.questionImageName.contains(clade),
                "Round \(round.id) footprint \(round.questionImageName) should include morphotype stem `\(clade)` for \(correct.name)"
            )
        }
    }

    // MARK: - Source hints

    func testDinoFootprintsSourceHintMomentsCoverNineMorphotypes() {
        let hintMoments = footprintMoments.filter { $0.context.hasPrefix("source-hint ") }
        XCTAssertEqual(hintMoments.count, 9)
    }

    // MARK: - Display moments

    func testDinoFootprintsDisplayMomentsIncludeRoundFootprintsAndOptions() {
        let roundFootprints = footprintMoments.filter { $0.context.contains("footprint") && $0.context.hasPrefix("round ") }
        XCTAssertEqual(roundFootprints.count, 3)
        let optionMoments = footprintMoments.filter { $0.context.contains("option") }
        XCTAssertEqual(optionMoments.count, 9, "Expected three rounds × three options")
    }

    func testDinoFootprintsDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = footprintMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testDinoFootprintsDisplayMomentsHaveResolvableAudio() {
        let speech = SpeechManager()
        let missing = footprintMoments.filter { moment in
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

    // MARK: - Audio

    @MainActor
    func testDinoFootprintsGameplayAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            LandDinosaurGameAudioContracts.allRequiredKeys(forConfigId: "dino-footprints"),
            messagePrefix: "Dino Footprints"
        )
    }

    @MainActor
    func testDinoFootprintsGuessFeedbackAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            ["thats-right-you-guessed-it", "try-again"],
            messagePrefix: "Dino Footprints feedback"
        )
    }

    // MARK: - Footprint morphotype lookup (keep in sync with `footprintDinosaurMap` in GuessGameView.swift)

    private static func footprintMorphotypeClade(for dinosaur: Dinosaur) -> String? {
        guard let slug = dinosaur.imageName?
            .replacingOccurrences(of: "dino-", with: "")
            .lowercased() else { return nil }
        return footprintMorphotypeCladeBySlug[slug]
    }

    /// Slug → morphotype clade for Dino Footprints gameplay (`FootprintClade.rawValue`).
    private static let footprintMorphotypeCladeBySlug: [String: String] = [
        "trex": "theropod", "velociraptor": "theropod", "troodon": "theropod",
        "therizinosaurus": "theropod", "masiakasaurus": "theropod", "torvosaurus": "theropod",
        "majungasaurus": "theropod", "allosaurus": "theropod", "oviraptor": "theropod",
        "compsognathus": "theropod", "microraptor": "theropod", "giganotosaurus": "theropod",
        "deinonychus": "theropod", "dromaeosaurus": "theropod", "albertosaurus": "theropod",
        "anchiornis": "theropod", "archaeopteryx": "theropod", "ceratosaurus": "theropod",
        "eosinopteryx": "theropod", "pedopenna": "theropod", "utahraptor": "theropod",
        "xiaotingia": "theropod", "acrocanthosaurus": "theropod", "carcharodontosaurus": "theropod",
        "carnotaurus": "theropod", "fukuiraptor": "theropod", "gigantoraptor": "theropod",
        "spinosaurus": "spinosaurid", "baryonyx": "spinosaurid", "suchomimus": "spinosaurid",
        "riparovenator": "spinosaurid", "gallimimus": "ornithomimid", "ornithomimus": "ornithomimid",
        "struthiomimus": "ornithomimid", "deinocheirus": "ornithomimid", "apatosaurus": "sauropod",
        "diplodocus": "sauropod", "camarasaurus": "sauropod", "rapetosaurus": "sauropod",
        "argentinosaurus": "sauropod", "brachiosaurus": "sauropod", "brontosaurus": "sauropod",
        "amargasaurus": "sauropod", "mamenchisaurus": "sauropod", "triceratops": "ceratopsian",
        "chasmosaurus": "ceratopsian", "torosaurus": "ceratopsian", "kosmoceratops": "ceratopsian",
        "styracosaurus": "ceratopsian", "corythosaurus": "hadrosaur", "parasaurolophus": "hadrosaur",
        "iguanodon": "hadrosaur", "edmontosaurus": "hadrosaur", "lambeosaurus": "hadrosaur",
        "maiasaura": "hadrosaur", "ouranosaurus": "hadrosaur", "dryosaurus": "ornithischian",
        "gasparinisaura": "ornithischian", "pachycephalosaurus": "hadrosaur", "stegoceras": "hadrosaur",
        "stygimoloch": "hadrosaur", "stegosaurus": "stegosaur", "kentrosaurus": "stegosaur",
        "huayangosaurus": "stegosaur", "ankylosaurus": "ankylosaur", "euoplocephalus": "ankylosaur",
        "edmontonia": "ankylosaur", "nodosaurus": "ankylosaur", "polacanthus": "ankylosaur",
    ]
}
