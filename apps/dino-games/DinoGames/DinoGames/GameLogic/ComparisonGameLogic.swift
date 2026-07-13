//
//  ComparisonGameLogic.swift
//  DinoGames
//
//  Pure decision rules for height/weight comparison games (Who Is Taller, Weigh the Dinosaur).
//  Views call these helpers; XCTests lock negative edge cases (near-equal, asymmetric mismatch, too-small-to-see).
//

import Foundation

enum ComparisonGameLogic {

    // MARK: - Who Is Taller (land dinosaurs)

    /// Feedback clip when a grayed-out second grid choice is tapped (`Assets/Audio/Feedback/thats-too-small-to-see.m4a`).
    static let thatsTooSmallToSee = "thats-too-small-to-see"
    /// Marine: second pick much longer than first (`Assets/Audio/Feedback/thats-too-big-to-see.m4a`).
    static let thatsTooBigToSee = "thats-too-big-to-see"

    /// Minimum height ratio for the smaller creature in a pair (below → "too small to see" when picked second).
    static let minVisibleHeightRatio: Double = 0.1
    /// Marine 0–22 m tape: shorter ÷ longer must stay within this band or the strip is unreadable.
    static let minVisibleMarineLengthRatio: Double = 0.22
    static let maxVisibleMarineLengthRatio: Double = 4.5
    /// Relative difference below which two heights count as "about the same".
    static let sameHeightRelativeThreshold: Double = 0.08

    enum HeightComparisonOutcome: Equatable {
        case aboutTheSame
        case firstTaller
        case secondTaller
    }

    enum HeightSecondPickResult: Equatable {
        case allowed
        case tooSmallToSee
    }

    enum MarineLengthSecondPickResult: Equatable {
        case allowed
        case tooSmallToSee
        case tooBigToSee
    }

    /// Second pick only: reject when the candidate is much shorter than the locked-in first choice.
    static func heightSecondPickResult(firstMeters: Double, secondMeters: Double) -> HeightSecondPickResult {
        rejectsSecondHeightPick(firstMeters: firstMeters, secondMeters: secondMeters) ? .tooSmallToSee : .allowed
    }

    /// Marine length game: block when the pair ratio falls outside the readable tape band.
    static func marineLengthSecondPickResult(firstMeters: Double, secondMeters: Double) -> MarineLengthSecondPickResult {
        guard firstMeters > 0, secondMeters > 0 else { return .allowed }
        if secondMeters < firstMeters {
            if (secondMeters / firstMeters) < minVisibleMarineLengthRatio { return .tooSmallToSee }
        } else if secondMeters > firstMeters {
            if (secondMeters / firstMeters) > maxVisibleMarineLengthRatio { return .tooBigToSee }
        }
        return .allowed
    }

    static func rejectsSecondHeightPick(firstMeters: Double, secondMeters: Double, isMarine: Bool = false) -> Bool {
        guard isMarine else {
            guard secondMeters < firstMeters else { return false }
            guard firstMeters > 0 else { return false }
            return (secondMeters / firstMeters) < minVisibleHeightRatio
        }
        return marineLengthSecondPickResult(firstMeters: firstMeters, secondMeters: secondMeters) != .allowed
    }

    static func heightComparisonOutcome(firstMeters: Double, secondMeters: Double) -> HeightComparisonOutcome {
        if heightsAreAboutTheSame(firstMeters, secondMeters) {
            return .aboutTheSame
        }
        return firstMeters >= secondMeters ? .firstTaller : .secondTaller
    }

    static func heightsAreAboutTheSame(_ a: Double, _ b: Double) -> Bool {
        let diff = abs(a - b)
        return diff < sameHeightRelativeThreshold * max(a, b)
    }

    static func heightComparisonResultAudioKey(outcome: HeightComparisonOutcome, isMarine: Bool = false) -> String {
        switch outcome {
        case .aboutTheSame:
            return isMarine ? "about-the-same-length" : "they-are-about-the-same-height"
        case .firstTaller, .secondTaller:
            return isMarine ? "is-longer" : "is-taller"
        }
    }

    // MARK: - Weigh the Dinosaur

    static let nearlySameWeightRatio: Double = 0.85
    static let massiveWeightRatio: Double = 0.40

    struct WeightComparisonResult: Equatable {
        let heavierIsLeft: Bool
        let isNearlySame: Bool
        let isMassiveDifference: Bool
    }

    enum WeighSeesawBehavior: Equatable {
        case nearlyBalanced
        case leftHeavierModerate
        case rightHeavierModerate
        case leftHeavierMassive
        case rightHeavierMassive
    }

    static func weighComparison(leftKg: Double, rightKg: Double) -> WeightComparisonResult {
        let heavier = max(leftKg, rightKg)
        let lighter = min(leftKg, rightKg)
        let ratio = heavier > 0 ? lighter / heavier : 1
        return WeightComparisonResult(
            heavierIsLeft: leftKg >= rightKg,
            isNearlySame: ratio >= nearlySameWeightRatio,
            isMassiveDifference: ratio < massiveWeightRatio
        )
    }

    static func weighSeesawBehavior(leftKg: Double, rightKg: Double) -> WeighSeesawBehavior {
        let result = weighComparison(leftKg: leftKg, rightKg: rightKg)
        if result.isNearlySame { return .nearlyBalanced }
        if result.heavierIsLeft {
            return result.isMassiveDifference ? .leftHeavierMassive : .leftHeavierModerate
        }
        return result.isMassiveDifference ? .rightHeavierMassive : .rightHeavierModerate
    }

    static func weighResultAudioKeys(leftKg: Double, rightKg: Double) -> [String] {
        let result = weighComparison(leftKg: leftKg, rightKg: rightKg)
        if result.isNearlySame {
            return ["they-both-weigh-about-the-same"]
        }
        return ["is-heavier"]
    }
}
