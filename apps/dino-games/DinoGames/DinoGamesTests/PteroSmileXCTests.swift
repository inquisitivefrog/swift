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

    func testPteroSmileAppearsOnLevel4WhenPlayable() {
        guard SmilingDinosGameConfigs.isPteroSmilePlayable else {
            XCTFail("Ptero Smile needs 9+ morphology families with bundled portrait + tooth art.")
            return
        }
        let level4 = PterosaurGameCatalog.games(level: .level4)
        XCTAssertTrue(level4.contains { $0.id == "ptero-smile" })
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

    func testPteroSmileVictoryRecapDedupesPlayerLabels() {
        let matchedSlugs = [
            "crested-terminal-spikes", // Fang
            "spoon-tipped-fangs", // Fang
            "tangled-interlocking-spikes", // Fang
            "barbed-spear-tip", // Spike
            "pebble-crushers", // Peg
        ]
        let unique = smileVictoryRecapToothSlugs(matchedSlugs, line: .air)
        XCTAssertEqual(unique.count, 3)
        XCTAssertEqual(PteroSmileMorphology.playerLabel(for: unique[0]), "Fang")
        XCTAssertEqual(PteroSmileMorphology.playerLabel(for: unique[1]), "Spike")
        XCTAssertEqual(PteroSmileMorphology.playerLabel(for: unique[2]), "Peg")
    }

    func testPteroSmilePlayerAudioKeysListedInContract() {
        let keys = PterosaurGameAudioContracts.supplementalAudioKeys(forConfigId: "ptero-smile")
        let expected = PteroSmilePlayerToothKind.allCases.map(\.audioKey)
        XCTAssertEqual(Set(keys), Set(expected))
    }

    // MARK: - Registry / round mechanics

    func testPteroSmileExpectedPlayerLabelsForCommonSpecies() {
        XCTAssertEqual(PteroSmileMorphology.playerKind(for: pteroSlug("pteranodon")), .spear)
        XCTAssertEqual(PteroSmileMorphology.playerLabel(for: PteroSmileMorphology.smileToothType(for: pteroSlug("pteranodon"))!), "Spear")
        XCTAssertEqual(PteroSmileMorphology.smileToothType(for: pteroSlug("pteranodon")), "classic-pelican-javelin")
        XCTAssertFalse(PteroSmileMorphology.smilePortraitShowsTeeth(for: pteroSlug("pteranodon")))
        XCTAssertFalse(PteroSmileMorphology.toothArtShowsTeeth(for: "classic-pelican-javelin"))
        XCTAssertEqual(PteroSmileMorphology.playerKind(for: pteroSlug("nemicolopterus")), .pin)
        XCTAssertEqual(PteroSmileMorphology.playerLabel(for: PteroSmileMorphology.smileToothType(for: pteroSlug("nemicolopterus"))!), "Pin")
        XCTAssertEqual(PteroSmileMorphology.playerKind(for: pteroSlug("sordes")), .spike)
        XCTAssertEqual(PteroSmileMorphology.playerLabel(for: PteroSmileMorphology.smileToothType(for: pteroSlug("sordes"))!), "Spike")
        XCTAssertEqual(PteroSmileMorphology.playerKind(for: pteroSlug("darwinopterus")), .peg)
        XCTAssertEqual(PteroSmileMorphology.smileToothType(for: pteroSlug("darwinopterus")), "spaced-vertical-pegs")
        XCTAssertEqual(PteroSmileMorphology.playerKind(for: pteroSlug("ludodactylus")), .spike)
        XCTAssertEqual(PteroSmileMorphology.smileToothType(for: pteroSlug("ludodactylus")), "barbed-spear-tip")
        XCTAssertTrue(PteroSmileMorphology.toothArtShowsTeeth(for: "barbed-spear-tip"))
        XCTAssertEqual(PteroSmileMorphology.playerKind(for: pteroSlug("guidraco")), .fang)
        XCTAssertEqual(PteroSmileMorphology.playerKind(for: pteroSlug("pterodactylus")), .peg)
        XCTAssertEqual(PteroSmileMorphology.playerKind(for: pteroSlug("nyctosaurus")), .needle)
        XCTAssertEqual(PteroSmileMorphology.smileToothType(for: pteroSlug("nyctosaurus")), "needle-cage-braces")
        XCTAssertTrue(PteroSmileMorphology.toothArtShowsTeeth(for: "needle-cage-braces"))
    }

    func testPteroSmileRegistryMatchesREADME() {
        XCTAssertEqual(PteroSmileMorphology.allCategorySlugs.count, 14)
        XCTAssertEqual(Set(PteroSmileMorphology.allToothSlugs).count, PteroSmileMorphology.allToothSlugs.count)
        XCTAssertGreaterThanOrEqual(PteroSmileMorphology.allToothSlugs.count, 38)
        XCTAssertEqual(PteroSmileMorphology.allPlayerToothKinds.count, 14)
    }

    /// Bundled tooth-card art names its species in JSON prompts; portrait pairings must follow the art, not stale README rows.
    func testPteroSmilePortraitToothPairingsMatchBundledArt() {
        let artAligned: [(String, String)] = [
            ("scaphognathus", "spaced-vertical-pegs"),
            ("tupandactylus", "deep-rounded-clip"),
            ("anurognathus", "miniature-insect-trap-pins"),
            ("gnathosaurus", "filter-tooth-field"),
            ("ctenochasma", "comb-needles"),
            ("dimorphodon", "dual-type-pincers"),
            ("sinopterus", "pointed-fruit-cutter"),
            ("caiuajara", "deep-down-turned-scoop"),
            ("kariridraco", "up-turned-tweezers"),
        ]
        for (species, toothSlug) in artAligned {
            XCTAssertEqual(
                PteroSmileMorphology.smileToothType(for: pteroSlug(species)),
                toothSlug,
                "\(species) smile should pair with bundled tooth art `\(toothSlug)`"
            )
        }
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
            let allTeethInRound = round.pairs.map(\.toothType) + round.distractorToothTypes
            let playerKindsInRound = allTeethInRound.compactMap { PteroSmileMorphology.playerKind(for: $0) }
            XCTAssertEqual(playerKindsInRound.count, allTeethInRound.count)
            let uniquenessKeys = playerKindsInRound.map(\.roundUniquenessKey)
            XCTAssertEqual(
                uniquenessKeys.count,
                Set(uniquenessKeys).count,
                "Each round needs unique tooth shapes (Spike/Needle share a key); got \(playerKindsInRound.map(\.displayLabel))"
            )
            let labels = Set(playerKindsInRound.map(\.displayLabel))
            XCTAssertFalse(
                labels.isSuperset(of: ["Spike", "Needle"]),
                "Spike and Needle must not co-appear in one round (shared audio + similar dentition)"
            )
        }
        XCTAssertEqual(morphologiesAcrossGame.count, 9)
    }

    /// Stress: many shuffles still never pack Spike + Needle into one round.
    func testPteroSmileNeverPacksSpikeAndNeedleTogether() {
        for _ in 0..<40 {
            guard let config = SmilingDinosGameConfigs.makePteroSmile() else {
                XCTFail("makePteroSmile() returned nil")
                return
            }
            for round in config.rounds {
                let kinds = (round.pairs.map(\.toothType) + round.distractorToothTypes)
                    .compactMap { PteroSmileMorphology.playerKind(for: $0) }
                let labels = Set(kinds.map(\.displayLabel))
                XCTAssertFalse(labels.isSuperset(of: ["Spike", "Needle"]))
            }
        }
    }

    func testPteroSmileToothImagesetsUseREADMESlugs() {
        let known = ImageAssetNames.knownAssets
        let missing = PteroSmileMorphology.allToothSlugs.filter { toothSlug in
            !known.contains(PteroSmileMorphology.toothImageAssetName(for: toothSlug))
        }
        XCTAssertTrue(
            missing.isEmpty,
            "Missing tooth imagesets for README slugs: \(missing.joined(separator: ", "))"
        )
    }

    // MARK: - Audio

    func testPteroSmilePlayerAudioMissingFromBundle() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Ptero-Smile")
        let stems = try TestBundleHelpers.audioStems(in: directory)

        var missingPrimary: [String] = []

        for kind in PteroSmilePlayerToothKind.allCases {
            let primary = kind.audioKey
            if stems.contains(primary) { continue }
            missingPrimary.append("\(primary).m4a")
        }

        XCTAssertTrue(
            missingPrimary.isEmpty,
            """
            Missing primary player-kind clips under Assets/Audio/Ptero-Smile/:
            \(missingPrimary.sorted().joined(separator: ", "))
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

    private func pteroSlug(_ matrixSlug: String) -> Dinosaur {
        let match = AirPterosaurData.allPterosaurs.first {
            AirPterosaurData.matrixFossilSlug(for: $0) == matrixSlug
        }
        XCTAssertNotNil(match, "Missing pterosaur registry entry for \(matrixSlug)")
        return match!
    }
}
