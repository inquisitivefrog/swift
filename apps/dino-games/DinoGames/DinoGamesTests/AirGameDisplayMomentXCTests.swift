//
//  AirGameDisplayMomentXCTests.swift
//  DinoGamesTests
//
//  CI contract: every air gameplay display moment has bundled image, non-empty text,
//  and resolvable audio, with consistent spelling between id / image / audio keys.
//

import XCTest
@testable import DinoGames

final class AirGameDisplayMomentXCTests: XCTestCase {

    private var shippingGameIds: Set<String> {
        PterosaurProgress.allPterosaurGameCanonicalIds
    }

    private var moments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingAirMoments()
    }

    // MARK: - Coverage

    func testShippingAirMomentsAreNonEmpty() {
        XCTAssertFalse(moments.isEmpty, "Expected at least one display moment for shipping air games.")
    }

    func testEachShippingAirGameHasDisplayMoments() {
        let covered = Set(moments.map(\.gameConfigId))
        let missing = shippingGameIds.subtracting(covered).sorted()
        XCTAssertTrue(
            missing.isEmpty,
            "Missing display-moment coverage for: \(missing). Add moments in `LandGameDisplayMomentCatalog.shippingAirMoments()`."
        )
    }

    // MARK: - Text

    func testAllMomentsHaveNonEmptyDisplayText() {
        let empty = moments.filter { $0.displayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let labels = empty.map { "\($0.gameConfigId) / \($0.context)" }
        XCTAssertTrue(labels.isEmpty, "Moments with empty display text: \(labels.joined(separator: ", "))")
    }

    // MARK: - Images

    func testAllMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = moments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.gameConfigId) / \($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    // MARK: - Audio

    @MainActor
    func testAllMomentsHaveResolvableAudio() {
        let speech = SpeechManager()
        let missing = moments.filter { moment in
            LandGameDisplayMomentCatalog.audioCandidateKeys(for: moment)
                .compactMap { speech.urlForAudio(key: $0) }
                .isEmpty
        }
        let labels = missing.map { moment in
            let keys = LandGameDisplayMomentCatalog.audioCandidateKeys(for: moment).joined(separator: "|")
            return "\(moment.gameConfigId) / \(moment.context) → audio `\(keys)`"
        }
        XCTAssertTrue(labels.isEmpty, "Missing bundle audio: \(labels.joined(separator: "; "))")
    }

    // MARK: - Spelling / alignment

    func testCreatureMomentsUseImageNameAsAudioKey() {
        let creatureMoments = moments.filter {
            $0.triad.id.hasPrefix("creature-") && !$0.triad.id.contains("-smile")
        }
        XCTAssertFalse(creatureMoments.isEmpty)
        let mismatched = creatureMoments.filter { $0.audioKey != $0.imageAssetName }
        let labels = mismatched.map { "\($0.gameConfigId) / \($0.context): image `\($0.imageAssetName)` audio `\($0.audioKey)`" }
        XCTAssertTrue(
            labels.isEmpty,
            "Creature moments should use imageName as audio key (gameplay speak path): \(labels.joined(separator: "; "))"
        )
    }

    func testPteroSourceHintImageNamesContainHintIdSlug() {
        var hints = LandGameDisplayMomentCatalog.pteroFootprintSourceHints
            + LandGameDisplayMomentCatalog.pteroAgesSourceHints
            + LandGameDisplayMomentCatalog.pteroFloraCategoryHints
            + PteroEggMorphology.sourceHints.map {
                LandGameDisplayTriad(id: $0.id, displayText: $0.displayName, imageAssetName: $0.imageName, audioKey: $0.audioKey)
            }
        if let matrix = PteroMatrixGameConfigs.makePteroMatrix() {
            hints += matrix.sourceHints.map {
                LandGameDisplayTriad(id: $0.id, displayText: $0.displayName, imageAssetName: $0.imageName, audioKey: $0.audioKey)
            }
        }

        let misaligned = hints.filter { hint in
            let slug = hint.id.replacingOccurrences(of: "-", with: "")
            return !hint.imageAssetName.lowercased().contains(hint.id)
                && !hint.imageAssetName.lowercased().contains(slug)
        }
        let labels = misaligned.map { "\($0.id): image `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Hint images should include hint id slug: \(labels.joined(separator: "; "))")
    }

    func testPteroFootprintSourceHintAudioKeysContainIdSlug() {
        for hint in LandGameDisplayMomentCatalog.pteroFootprintSourceHints {
            let slug = hint.id == "transition" ? "transition" : hint.id
            XCTAssertTrue(
                hint.audioKey.lowercased().contains(slug),
                "Hint `\(hint.id)` audio key `\(hint.audioKey)` should contain id slug"
            )
        }
    }

    func testPteroSmilePortraitMomentsUseCreatureAudioWithSmileImage() throws {
        guard SmilingDinosGameConfigs.isPteroSmilePlayable else {
            throw XCTSkip("Ptero Smile assets not bundled in this catalog snapshot.")
        }
        let smileMoments = moments.filter { $0.gameConfigId == "ptero-smile" && $0.context.contains("smile") }
        XCTAssertFalse(smileMoments.isEmpty)
        let mismatched = smileMoments.filter {
            !$0.imageAssetName.hasPrefix("ptero-smile-") || !$0.audioKey.hasPrefix("ptero-")
        }
        let labels = mismatched.map { "\($0.context): image `\($0.imageAssetName)` audio `\($0.audioKey)`" }
        XCTAssertTrue(labels.isEmpty, "Smile portraits use smile art + creature name audio: \(labels.joined(separator: "; "))")
    }

    func testPteroFloraPlantIdsAlignWithAudioAndImageSlugs() {
        for plant in pteroFloraPlants {
            XCTAssertTrue(plant.displayName.count >= 2, "Plant `\(plant.id)` needs display text")
            XCTAssertTrue(
                plant.treeImageName.hasPrefix("ptero-flora-"),
                "Plant `\(plant.id)` habitat image should use ptero-flora prefix: `\(plant.treeImageName)`"
            )
            XCTAssertEqual(
                plant.audioKey,
                plant.assetStem,
                "Plant `\(plant.id)` audio key should match asset stem"
            )
            XCTAssertTrue(
                plant.treeImageName.contains(plant.formation),
                "Plant `\(plant.id)` image should include formation slug `\(plant.formation)`"
            )
            XCTAssertTrue(
                plant.treeImageName.contains(plant.taxon),
                "Plant `\(plant.id)` image should include taxon slug `\(plant.taxon)`"
            )
            XCTAssertTrue(
                ImageAssetNames.knownAssets.contains(plant.treeImageName),
                "Plant `\(plant.id)` missing habitat imageset `\(plant.treeImageName)`"
            )
            XCTAssertTrue(
                ImageAssetNames.knownAssets.contains(plant.seedsImageName),
                "Plant `\(plant.id)` missing seeds imageset `\(plant.seedsImageName)`"
            )
        }
    }
}
