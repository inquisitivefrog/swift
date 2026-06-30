//
//  DinoSmileXCTests.swift
//  DinoGamesTests
//
//  Catalog + asset/audio/mechanic contracts for Dino Smile. Parallels `PteroSmileXCTests`.
//

import XCTest
@testable import DinoGames

final class DinoSmileXCTests: XCTestCase {

    private var smileMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingLandMoments().filter { $0.gameConfigId == "smiling-dinos" }
    }

    // MARK: - Config / catalog

    func testDinoSmileConfigId() {
        XCTAssertEqual(SmilingDinosGameConfigs.smilingDinos.id, "smiling-dinos")
        XCTAssertEqual(SmilingDinosGameConfigs.smilingDinos.title, "Dino Smile!")
    }

    func testDinoSmileAppearsOnLevel4() {
        let level4 = DinosaurGameCatalog.games(level: .level4)
        XCTAssertTrue(level4.contains { $0.id == "smiling-dinos" })
    }

    func testDinoSmilePickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-dino-smile"), "Missing picker art: game-dino-smile")
        let successCandidates = SmilingDinosGameConfigs.smilingDinos.successImageCandidates
        XCTAssertTrue(
            successCandidates.contains { known.contains($0) },
            "Missing victory art. Tried: \(successCandidates)"
        )
    }

    // MARK: - Morphology overrides

    func testDinoSmileSmileToothTypeOverrides() {
        XCTAssertEqual(DentalMorphology.smileToothType(for: landDino("stegosaurus")), "fluted-leaf")
        XCTAssertEqual(DentalMorphology.smileToothType(for: landDino("kentrosaurus")), "fluted-leaf")
        XCTAssertEqual(DentalMorphology.smileToothType(for: landDino("triceratops")), "forked-battery")
        XCTAssertEqual(DentalMorphology.smileToothType(for: landDino("gallimimus")), "nipping-beak")
        XCTAssertEqual(DentalMorphology.smileToothType(for: landDino("iguanodon")), "diamond-battery")
        XCTAssertEqual(DentalMorphology.smileToothType(for: landDino("oviraptor")), "nutcracker")
    }

    func testDinoSmileFlutedLeafImagesetUsesFlutedSlug() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("dino-smile-tooth-fluted-leaf"))
        XCTAssertFalse(known.contains("dino-smile-tooth-flute-leaf"), "Retired flute-leaf imageset should not remain in catalog")
    }

    // MARK: - Round mechanics

    func testDinoSmileConfigBuildsThreeRounds() {
        let config = SmilingDinosGameConfigs.smilingDinos
        XCTAssertEqual(config.rounds.count, 3)

        var toothTypesAcrossGame: Set<String> = []
        for round in config.rounds {
            XCTAssertEqual(round.pairs.count, SmilingDinosRound.creaturesPerRound)
            XCTAssertEqual(round.distractorToothTypes.count, SmilingDinosRound.distractorTeethPerRound)

            let answerTeeth = Set(round.pairs.map(\.toothType))
            XCTAssertEqual(answerTeeth.count, SmilingDinosRound.creaturesPerRound)
            XCTAssertTrue(answerTeeth.isDisjoint(with: round.distractorToothTypes))

            toothTypesAcrossGame.formUnion(answerTeeth)
            toothTypesAcrossGame.formUnion(round.distractorToothTypes)
        }
        XCTAssertGreaterThanOrEqual(toothTypesAcrossGame.count, 9, "Three rounds should surface many distinct tooth types")
    }

    func testDinoSmileLiveConfigRoundArtExists() {
        let known = ImageAssetNames.knownAssets
        let config = SmilingDinosGameConfigs.smilingDinos
        var missing: [String] = []

        for round in config.rounds {
            for pair in round.pairs {
                let slug = pair.dinosaur.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(pair.dinosaur.id)"
                let smileImage = DentalMorphology.smilePortraitImageAssetName(for: slug)
                let toothImage = config.toothImageName(for: pair.toothType)
                if !known.contains(smileImage) { missing.append(smileImage) }
                if !known.contains(toothImage) { missing.append(toothImage) }
            }
            for distractor in round.distractorToothTypes {
                let toothImage = config.toothImageName(for: distractor)
                if !known.contains(toothImage) { missing.append(toothImage) }
            }
        }

        XCTAssertTrue(missing.isEmpty, "Live config references missing art: \(Set(missing).sorted().joined(separator: ", "))")
    }

    // MARK: - Playable pool

    func testDinoSmilePlayablePoolHasEnoughSpecies() {
        let pool = landSmilePlayableDinosaurs()
        XCTAssertGreaterThanOrEqual(pool.count, 9, "Need at least 9 species for 3×3 rounds")
    }

    func testDinoSmilePlayablePoolSpeciesAndToothImagesetsExist() {
        let known = ImageAssetNames.knownAssets
        var missingSmiles: [String] = []
        var missingTeeth: [String] = []

        for dino in landSmilePlayableDinosaurs() {
            let slug = dino.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(dino.id)"
            let smileImage = DentalMorphology.smilePortraitImageAssetName(for: slug)
            if !known.contains(smileImage) { missingSmiles.append(smileImage) }

            guard let toothType = DentalMorphology.smileToothType(for: dino) else { continue }
            let toothImage = DentalMorphology.smileToothImageAssetName(for: toothType)
            if !known.contains(toothImage) { missingTeeth.append(toothImage) }
        }

        XCTAssertTrue(missingSmiles.isEmpty, "Playable pool missing smile art: \(missingSmiles.sorted().joined(separator: ", "))")
        XCTAssertTrue(missingTeeth.isEmpty, "Playable pool missing tooth art: \(Set(missingTeeth).sorted().joined(separator: ", "))")
    }

    func testDinoSmilePlayablePoolToothTypesHaveJsonPrompts() throws {
        let jsonRoot = TestBundleHelpers.urlUnderProjectRoot("json/dino-smile/teeth")
        let jsonStems = Set(try TestBundleHelpers.recursiveFiles(in: jsonRoot, allowedExtensions: ["json"])
            .map { $0.deletingPathExtension().lastPathComponent })

        let missingJson = landSmilePlayableToothTypes()
            .map { DentalMorphology.smileToothImageAssetName(for: $0) }
            .filter { !jsonStems.contains($0) }
            .sorted()

        XCTAssertTrue(
            missingJson.isEmpty,
            "Playable tooth types missing json prompts under json/dino-smile/teeth/: \(missingJson.joined(separator: ", "))"
        )
    }

    // MARK: - Audio

    @MainActor
    func testDinoSmilePlayablePoolToothAudioResolvableInBundle() {
        let speech = SpeechManager()
        let toothTypes = landSmilePlayableToothTypes()
        XCTAssertFalse(toothTypes.isEmpty)

        let unresolved = toothTypes.filter { toothType in
            DentalMorphology.smileToothAudioCandidateKeys(for: toothType)
                .compactMap { speech.urlForAudio(key: $0) }
                .isEmpty
        }

        let labels = unresolved.map { toothType in
            let keys = DentalMorphology.smileToothAudioCandidateKeys(for: toothType)
            return "\(toothType) → tried `\(keys.joined(separator: "|"))`"
        }
        XCTAssertTrue(
            labels.isEmpty,
            "Playable Dino Smile tooth types need bundle audio: \(labels.joined(separator: "; "))"
        )
    }

    func testDinoSmileFlutedLeafAudioOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Dino-Smile")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        let candidates = DentalMorphology.smileToothAudioCandidateKeys(for: "fluted-leaf")
        let resolved = candidates.first { stems.contains($0) }
        XCTAssertNotNil(
            resolved,
            "Expected fluted-leaf narration under Assets/Audio/Dino-Smile/. Tried: \(candidates.joined(separator: ", "))"
        )
    }

    @MainActor
    func testDinoSmileIntroAudioKeysResolveInBundle() {
        let config = SmilingDinosGameConfigs.smilingDinos
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            [config.introAudio, config.gameplayDirectionsAudio],
            messagePrefix: "Dino Smile"
        )
    }

    // MARK: - Display moments

    func testDinoSmileDisplayMomentsCoverLiveConfigRounds() {
        let config = SmilingDinosGameConfigs.smilingDinos
        XCTAssertFalse(smileMoments.isEmpty)
        for round in config.rounds {
            let smileMomentsForRound = smileMoments.filter { $0.context.hasPrefix("round \(round.id) smile ") }
            XCTAssertEqual(smileMomentsForRound.count, round.pairs.count)
            let toothMoments = smileMoments.filter { $0.context.hasPrefix("round \(round.id) tooth ") }
            XCTAssertEqual(toothMoments.count, round.pairs.count)
            let distractorMoments = smileMoments.filter { $0.context.hasPrefix("round \(round.id) distractor tooth ") }
            XCTAssertEqual(distractorMoments.count, round.distractorToothTypes.count)
        }
        let expectedTotal = config.rounds.reduce(0) { partial, round in
            partial + round.pairs.count * 2 + round.distractorToothTypes.count
        }
        XCTAssertEqual(smileMoments.count, expectedTotal)
    }

    func testDinoSmileDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = smileMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testDinoSmileDisplayMomentsHaveResolvableAudio() {
        let speech = SpeechManager()
        let missing = smileMoments.filter { moment in
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

    // MARK: - Helpers

    private func landDino(_ slug: String) -> Dinosaur {
        let match = MatchingGameConfigs.allDinosaurs.first {
            ($0.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\($0.id)") == slug
        }
        XCTAssertNotNil(match, "Missing dinosaur registry entry for `\(slug)`")
        return match!
    }

    private func landSmilePlayableDinosaurs() -> [Dinosaur] {
        let known = ImageAssetNames.knownAssets
        return MatchingGameConfigs.allDinosaurs.filter { dino in
            let slug = dino.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(dino.id)"
            guard known.contains(DentalMorphology.smilePortraitImageAssetName(for: slug)),
                  let toothType = DentalMorphology.smileToothType(for: dino) else { return false }
            return known.contains(DentalMorphology.smileToothImageAssetName(for: toothType))
        }
    }

    private func landSmilePlayableToothTypes() -> Set<String> {
        Set(landSmilePlayableDinosaurs().compactMap { DentalMorphology.smileToothType(for: $0) })
    }
}
