//
//  ComparisonGameNegativeXCTests.swift
//  DinoGamesTests
//
//  Negative / edge-case contracts for land comparison games (Who Is Taller, Weigh the Dinosaur).
//

import XCTest
@testable import DinoGames

final class ComparisonGameNegativeXCTests: XCTestCase {

    // MARK: - Feedback audio (negative paths must resolve)

    @MainActor
    func testComparisonNegativeFeedbackAudioResolves() {
        let keys = [
            "thats-too-small-to-see",
            "they-are-about-the-same-height",
            "they-both-weigh-about-the-same",
            "is-taller",
            "is-heavier",
        ]
        TestBundleHelpers.assertBundleResolvesAudioKeys(keys, messagePrefix: "comparison negative feedback")
    }

    @MainActor
    func testTooSmallToSeeAudioFileExistsOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Feedback")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        XCTAssertTrue(stems.contains("thats-too-small-to-see"), "Missing Feedback/thats-too-small-to-see.m4a")
    }

    // MARK: - Who Is Taller — height pairs (catalog-backed meters)

    /// Standing heights (m) for a few catalog ids — mirrors `whoIsTallerHeightMetersById` in WhoIsTallerGameView.
    private let catalogHeightsM: [Int: Double] = [
        1: 12,    // large theropod reference (e.g. T-Rex class)
        2: 9,
        3: 9,
        26: 0.35, // small theropod
        33: 0.32,
        34: 0.22,
    ]

    // 1. Nearly equivalent choices → "about the same" path, never too-small-to-see.
    func testHeightComparison_nearlyEquivalentChoices_useAboutTheSameOutcome() {
        let hA = catalogHeightsM[2]!
        let hB = catalogHeightsM[3]!
        XCTAssertTrue(ComparisonGameLogic.heightsAreAboutTheSame(hA, hB))
        XCTAssertEqual(ComparisonGameLogic.heightComparisonOutcome(firstMeters: hA, secondMeters: hB), .aboutTheSame)
        XCTAssertEqual(ComparisonGameLogic.heightSecondPickResult(firstMeters: hA, secondMeters: hB), .allowed)
        XCTAssertEqual(
            ComparisonGameLogic.heightComparisonResultAudioKey(outcome: .aboutTheSame),
            "they-are-about-the-same-height"
        )
    }

    // 2. First vastly taller than second → second pick blocked with thats-too-small-to-see.
    func testHeightComparison_firstVastlyTallerThanSecond_blocksSecondPick() {
        let huge = catalogHeightsM[1]!   // 12 m first
        let tiny = catalogHeightsM[26]!  // 0.35 m second attempt
        XCTAssertLessThan(tiny / huge, ComparisonGameLogic.minVisibleHeightRatio)
        XCTAssertEqual(ComparisonGameLogic.heightSecondPickResult(firstMeters: huge, secondMeters: tiny), .tooSmallToSee)
        XCTAssertEqual(ComparisonGameLogic.heightComparisonOutcome(firstMeters: huge, secondMeters: tiny), .firstTaller)
    }

    // 3. Second vastly taller than first (reverse order) → allowed; comparison declares second taller.
    func testHeightComparison_secondVastlyTallerThanFirst_allowsSecondPick() {
        let tiny = catalogHeightsM[33]!
        let huge = catalogHeightsM[1]!
        XCTAssertEqual(ComparisonGameLogic.heightSecondPickResult(firstMeters: tiny, secondMeters: huge), .allowed)
        XCTAssertEqual(ComparisonGameLogic.heightComparisonOutcome(firstMeters: tiny, secondMeters: huge), .secondTaller)
        XCTAssertEqual(
            ComparisonGameLogic.heightComparisonResultAudioKey(outcome: .secondTaller),
            "is-taller"
        )
    }

    // 4. Opposite order asymmetry: tiny-first + huge-second shows delta; huge-first + tiny-second triggers complaint.
    func testHeightComparison_oppositeOrderAsymmetry_onlyTinyFirstBlocksHugeSecond() {
        let tiny = catalogHeightsM[34]!
        let huge = catalogHeightsM[2]!

        XCTAssertEqual(
            ComparisonGameLogic.heightSecondPickResult(firstMeters: tiny, secondMeters: huge),
            .allowed,
            "Tiny first, huge second: player should see scale delta without complaint"
        )
        XCTAssertEqual(
            ComparisonGameLogic.heightSecondPickResult(firstMeters: huge, secondMeters: tiny),
            .tooSmallToSee,
            "Huge first, tiny second: referee blocks with thats-too-small-to-see"
        )
    }

    func testHeightComparison_eligiblePoolContainsNearEqualAndMismatchPairs() {
        let items = WhoIsTallerGameConfigs.allEligibleDinosaurItems()
        XCTAssertGreaterThanOrEqual(items.count, 2)
        let byId = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.heightMeters) })

        let nearEqual = items.filter { partner in
            items.contains { other in
                other.id != partner.id && ComparisonGameLogic.heightsAreAboutTheSame(partner.heightMeters, other.heightMeters)
            }
        }
        XCTAssertFalse(nearEqual.isEmpty, "Eligible pool should include at least one near-equal height pair for CI")

        let hasTinyHugeMismatch = items.contains { first in
            items.contains { second in
                second.id != first.id
                    && first.heightMeters > second.heightMeters
                    && ComparisonGameLogic.rejectsSecondHeightPick(firstMeters: first.heightMeters, secondMeters: second.heightMeters)
            }
        }
        XCTAssertTrue(hasTinyHugeMismatch, "Eligible pool should include a tiny-second-blocked pair when huge is picked first")

        if let h1 = byId[1], let h26 = byId[26] {
            XCTAssertEqual(ComparisonGameLogic.heightSecondPickResult(firstMeters: h1, secondMeters: h26), .tooSmallToSee)
        }
    }

    /// Grid UX contract: after a tall first pick, shorter grid cells below the visibility ratio are grayed out;
    /// tapping them plays `thats-too-small-to-see` (Who Is Taller / marine length use `heightSecondPickResult`).
    func testHeightComparison_gridEliminatedSecondChoicesUseTooSmallFeedback() {
        let huge = catalogHeightsM[1]!
        let tiny = catalogHeightsM[26]!
        let medium = catalogHeightsM[2]!

        XCTAssertEqual(ComparisonGameLogic.heightSecondPickResult(firstMeters: huge, secondMeters: tiny), .tooSmallToSee)
        XCTAssertEqual(ComparisonGameLogic.heightSecondPickResult(firstMeters: huge, secondMeters: medium), .allowed)
        XCTAssertEqual(ComparisonGameLogic.thatsTooSmallToSee, "thats-too-small-to-see")
    }

    // MARK: - Weigh the Dinosaur — weight pairs (catalog-backed kg)

    private func kg(_ id: Int) -> Double {
        MatchingGameConfigs.dinosaurEstimatedWeightKgById[id]!
    }

    // 1. Nearly equivalent weights → balanced seesaw + shared-weight audio.
    func testWeightComparison_nearlyEquivalentChoices_useBalancedBehavior() {
        let left = kg(47)  // 3500
        let right = kg(48) // 3000 — ratio 0.857
        let result = ComparisonGameLogic.weighComparison(leftKg: left, rightKg: right)
        XCTAssertTrue(result.isNearlySame)
        XCTAssertFalse(result.isMassiveDifference)
        XCTAssertEqual(ComparisonGameLogic.weighSeesawBehavior(leftKg: left, rightKg: right), .nearlyBalanced)
        XCTAssertEqual(ComparisonGameLogic.weighResultAudioKeys(leftKg: left, rightKg: right), ["they-both-weigh-about-the-same"])
    }

    // 2. Left vastly heavier → left-heavy massive behavior (lighter launched / hidden on right).
    func testWeightComparison_leftVastlyHeavierThanRight_usesLeftHeavyMassiveBehavior() {
        let left = kg(6)   // 7000 kg
        let right = kg(12) // 50 kg
        let result = ComparisonGameLogic.weighComparison(leftKg: left, rightKg: right)
        XCTAssertTrue(result.isMassiveDifference)
        XCTAssertTrue(result.heavierIsLeft)
        XCTAssertEqual(ComparisonGameLogic.weighSeesawBehavior(leftKg: left, rightKg: right), .leftHeavierMassive)
    }

    // 3. Right vastly heavier → right-heavy massive behavior (lighter launched from left).
    func testWeightComparison_rightVastlyHeavierThanLeft_usesRightHeavyMassiveBehavior() {
        let left = kg(12)  // 50 kg
        let right = kg(6)  // 7000 kg
        let result = ComparisonGameLogic.weighComparison(leftKg: left, rightKg: right)
        XCTAssertTrue(result.isMassiveDifference)
        XCTAssertFalse(result.heavierIsLeft)
        XCTAssertEqual(ComparisonGameLogic.weighSeesawBehavior(leftKg: left, rightKg: right), .rightHeavierMassive)
    }

    // 4. Moderate mismatch (not near-equal, not massive) — asymmetric moderate behaviors by side.
    func testWeightComparison_moderateMismatch_usesSideSpecificModerateBehavior() {
        let left = kg(8)  // 6000
        let right = kg(9) // 3500 — ratio 0.583 → moderate, left heavier
        XCTAssertFalse(ComparisonGameLogic.weighComparison(leftKg: left, rightKg: right).isNearlySame)
        XCTAssertFalse(ComparisonGameLogic.weighComparison(leftKg: left, rightKg: right).isMassiveDifference)
        XCTAssertEqual(ComparisonGameLogic.weighSeesawBehavior(leftKg: left, rightKg: right), .leftHeavierModerate)

        let leftLight = kg(9)
        let rightHeavy = kg(8)
        XCTAssertEqual(ComparisonGameLogic.weighSeesawBehavior(leftKg: leftLight, rightKg: rightHeavy), .rightHeavierModerate)
    }

    func testWeightComparison_oppositeOrderProducesDifferentMassiveBehaviors() {
        let heavy = kg(23) // 35000
        let light = kg(33) // 1
        XCTAssertEqual(ComparisonGameLogic.weighSeesawBehavior(leftKg: heavy, rightKg: light), .leftHeavierMassive)
        XCTAssertEqual(ComparisonGameLogic.weighSeesawBehavior(leftKg: light, rightKg: heavy), .rightHeavierMassive)
        XCTAssertNotEqual(
            ComparisonGameLogic.weighSeesawBehavior(leftKg: heavy, rightKg: light),
            ComparisonGameLogic.weighSeesawBehavior(leftKg: light, rightKg: heavy)
        )
    }
}
