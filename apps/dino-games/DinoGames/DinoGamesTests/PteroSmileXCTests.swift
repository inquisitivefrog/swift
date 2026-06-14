//
//  PteroSmileXCTests.swift
//  DinoGamesTests
//
//  Catalog + asset/audio/mechanic contracts for Ptero Smile. Parallels `PteroFloraXCTests`.
//

import XCTest
@testable import DinoGames

final class PteroSmileXCTests: XCTestCase {

    // MARK: - Config / catalog

    func testPteroSmileConfigId() {
        XCTAssertEqual(SmilingDinosGameConfigs.pteroSmile.id, "ptero-smile")
    }

    func testPteroSmileAppearsOnLevel3WhenPlayable() {
        guard SmilingDinosGameConfigs.isPteroSmilePlayable else {
            XCTFail("Ptero Smile needs 9+ morphology families with bundled portrait + tooth art.")
            return
        }
        let level3 = PterosaurGameCatalog.games(level: .level3)
        XCTAssertTrue(level3.contains { $0.id == "ptero-smile" })
    }

    func testPteroSmilePickerArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-ptero-smile"), "Missing picker art: game-ptero-smile")
    }

    // MARK: - Pre-reader labels

    func testPteroSmilePlayerLabelsAreShortWords() {
        for toothSlug in PteroSmileMorphology.allToothSlugs {
            let label = PteroSmileMorphology.playerLabel(for: toothSlug)
            XCTAssertFalse(label.contains("-"), "Player label should be a short word, not slug text: \(toothSlug) → \(label)")
            XCTAssertLessThanOrEqual(label.count, 10, "Player label too long for pre-readers: \(toothSlug) → \(label)")
        }
    }

    func testPteroSmilePlayerKindExamples() {
        XCTAssertEqual(PteroSmileMorphology.playerLabel(for: "crested-terminal-spikes"), "Fang")
        XCTAssertEqual(PteroSmileMorphology.playerLabel(for: "pebble-crushers"), "Peg")
        XCTAssertEqual(PteroSmileMorphology.playerLabel(for: "heavy-axe-beak"), "Beak")
        XCTAssertEqual(PteroSmileMorphology.playerLabel(for: "stout-spear-beak"), "Stub")
        XCTAssertEqual(PteroSmileMorphology.toothAudioKey(for: "pebble-crushers"), "ptero-smile-peg")
    }

    func testPteroSmilePlayerAudioKeysListedInContract() {
        let keys = PterosaurGameAudioContracts.supplementalAudioKeys(forConfigId: "ptero-smile")
        let expected = PteroSmilePlayerToothKind.allCases.map(\.audioKey)
        XCTAssertEqual(Set(keys), Set(expected))
    }

    // MARK: - Registry / round mechanics

    func testPteroSmileRegistryMatchesREADME() {
        XCTAssertEqual(PteroSmileMorphology.allCategorySlugs.count, 14)
        XCTAssertEqual(PteroSmileMorphology.allToothSlugs.count, 43)
        XCTAssertEqual(PteroSmileMorphology.allPlayerToothKinds.count, 12)
    }

    func testPteroSmileConfigBuildsThreeRounds() {
        guard let config = SmilingDinosGameConfigs.makePteroSmile() else {
            XCTFail("makePteroSmile() returned nil — need 9+ morphology families with bundled portrait + tooth art.")
            return
        }
        XCTAssertEqual(config.rounds.count, 3)
        var morphologiesAcrossGame: Set<String> = []
        for round in config.rounds {
            XCTAssertEqual(round.pairs.count, SmilingDinosRound.creaturesPerRound)
            XCTAssertEqual(round.distractorToothTypes.count, SmilingDinosRound.distractorTeethPerRound)
            let roundMorphologies = round.pairs.compactMap { PteroSmileMorphology.morphologyCategory(for: $0.dinosaur) }
            XCTAssertEqual(Set(roundMorphologies).count, roundMorphologies.count)
            morphologiesAcrossGame.formUnion(roundMorphologies)
            let answerTeeth = Set(round.pairs.map(\.toothType))
            XCTAssertTrue(answerTeeth.isDisjoint(with: round.distractorToothTypes))
        }
        XCTAssertEqual(morphologiesAcrossGame.count, 9)
    }

    func testPteroSmileToothImageSlugAliasesResolveInCatalog() {
        let aliases: [(readmeSlug: String, imagesetSuffix: String)] = [
            ("microscopic-needle-pin", "microscopic-needle-pins"),
            ("miniature-insect-trap-pins", "minature-insect-trap-pins"),
        ]
        for alias in aliases {
            let asset = PteroSmileMorphology.toothImageAssetName(for: alias.readmeSlug)
            XCTAssertTrue(
                ImageAssetNames.knownAssets.contains(asset),
                "Missing tooth imageset for README slug `\(alias.readmeSlug)` → `\(asset)`"
            )
        }
    }

    // MARK: - Audio

    func testPteroSmilePlayerAudioMissingFromBundle() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Ptero-Smile")
        let stems = try TestBundleHelpers.audioStems(in: directory)

        var missingPrimary: [String] = []
        var coveredByLegacy: [(kind: String, legacy: String)] = []

        for kind in PteroSmilePlayerToothKind.allCases {
            let primary = kind.audioKey
            if stems.contains(primary) { continue }
            missingPrimary.append("\(primary).m4a")
            if let legacy = kind.legacyAudioKey, stems.contains(legacy) {
                coveredByLegacy.append((kind: kind.rawValue, legacy: "\(legacy).m4a"))
            }
        }

        let legacyOnly = Set(PteroSmilePlayerToothKind.allCases.compactMap(\.legacyAudioKey))
        let orphanLegacy = legacyOnly.filter { legacy in
            guard stems.contains(legacy) else { return false }
            return !PteroSmilePlayerToothKind.allCases.contains { $0.audioKey == legacy }
        }.map { "\($0).m4a" }

        XCTAssertFalse(
            missingPrimary.isEmpty,
            """
            Record primary player-kind clips under Assets/Audio/Ptero-Smile/:
            \(missingPrimary.sorted().joined(separator: ", "))
            Legacy fallbacks on disk for now: \(coveredByLegacy.map { "\($0.kind) → \($0.legacy)" }.sorted().joined(separator: "; "))
            Orphan legacy clips (rename target): \(orphanLegacy.sorted().joined(separator: ", "))
            """
        )
    }

    @MainActor
    func testPteroSmilePlayablePoolPlayerKindsHaveResolvableAudio() {
        let speech = SpeechManager()
        let kinds = PteroSmileMorphology.playerKindsUsedByPlayablePool()
        XCTAssertFalse(kinds.isEmpty, "Playable pool should expose at least one player tooth kind.")

        let missing = kinds.filter { kind in
            let sampleSlug = PteroSmileMorphology.allToothSlugs.first { PteroSmileMorphology.playerKind(for: $0) == kind }
            guard let sampleSlug else { return true }
            return PteroSmileMorphology.playerAudioCandidateKeys(for: sampleSlug)
                .compactMap { speech.urlForAudio(key: $0) }
                .isEmpty
        }

        let labels = missing.map { kind in
            let keys = PteroSmileMorphology.playerAudioCandidateKeys(
                for: PteroSmileMorphology.allToothSlugs.first { PteroSmileMorphology.playerKind(for: $0) == kind } ?? kind.rawValue
            )
            return "\(kind.displayLabel) → tried `\(keys.joined(separator: "|"))`"
        }
        XCTAssertTrue(
            labels.isEmpty,
            "Playable Ptero Smile kinds need primary or legacy audio: \(labels.joined(separator: "; "))"
        )
    }

    @MainActor
    func testPteroSmilePlayerKindsResolveViaCandidateKeysInBundle() {
        let speech = SpeechManager()
        let unresolved = PteroSmilePlayerToothKind.allCases.filter { kind in
            let sampleSlug = PteroSmileMorphology.allToothSlugs.first { PteroSmileMorphology.playerKind(for: $0) == kind }
            guard let sampleSlug else { return true }
            return PteroSmileMorphology.playerAudioCandidateKeys(for: sampleSlug)
                .compactMap { speech.urlForAudio(key: $0) }
                .isEmpty
        }
        let labels = unresolved.map(\.displayLabel)
        XCTAssertTrue(
            labels.isEmpty,
            "Each player tooth kind needs primary or legacy bundle audio: \(labels.joined(separator: ", "))"
        )
    }
}
