//
//  CreatureThreeByThreeGridMetricsXCTests.swift
//  DinoGamesTests
//
//  Phone 3×3 portraits for Weigh / Which taller-longer must fill the canvas width
//  instead of shrinking to a thumbnail strip under a tall reserved stage.
//

import XCTest
@testable import DinoGames

final class CreatureThreeByThreeGridMetricsXCTests: XCTestCase {

    /// iPhone 16-class portrait, GeometryReader under the status bar.
    private let iPhoneWidth: CGFloat = 393
    private let iPhoneHeight: CGFloat = 852
    private let iPhoneTopInset: CGFloat = 59

    func testPhoneGridFillsWidthForWeighStyleReservation() {
        let chrome: CGFloat = 16 + iPhoneTopInset + 16 + 16
        let reservedSeesaw = min(260, max(200, (iPhoneHeight - chrome) * 0.28))
        let grid = CreatureThreeByThreeGridMetrics.make(
            safeWidth: iPhoneWidth,
            safeHeight: iPhoneHeight,
            reservedStageHeight: reservedSeesaw,
            chrome: chrome,
            minimumGridBudget: 422 * 0.85
        )
        let expected = CreatureThreeByThreeGridMetrics.widthFillingImageSize(safeWidth: iPhoneWidth)
        XCTAssertEqual(grid.imageSize, expected, "Weigh 3×3 should keep width-filling portraits on iPhone")
        XCTAssertGreaterThanOrEqual(grid.imageSize, 100)
        XCTAssertGreaterThan(grid.contentWidth, iPhoneWidth * 0.85)
    }

    func testPhoneGridFillsWidthForTallerStyleReservation() {
        let chrome = 32 + iPhoneTopInset
        let stageBudget = max(200, (iPhoneHeight - chrome) * 0.30)
        let grid = CreatureThreeByThreeGridMetrics.make(
            safeWidth: iPhoneWidth,
            safeHeight: iPhoneHeight,
            reservedStageHeight: stageBudget,
            chrome: chrome
        )
        let expected = CreatureThreeByThreeGridMetrics.widthFillingImageSize(safeWidth: iPhoneWidth)
        XCTAssertEqual(grid.imageSize, expected, "Which-taller 3×3 should keep width-filling portraits on iPhone")
        XCTAssertGreaterThanOrEqual(grid.imageSize, 100)
    }

    func testPhoneGridDoesNotShrinkBelowReadableFloor() {
        let grid = CreatureThreeByThreeGridMetrics.make(
            safeWidth: 375,
            safeHeight: 667,
            reservedStageHeight: 312,
            chrome: 100
        )
        XCTAssertGreaterThanOrEqual(grid.imageSize, CreatureThreeByThreeGridMetrics.phoneMinImageSize)
    }

    func testIPadGridStaysCappedAtMaxScale() {
        let iPadWidth: CGFloat = 834
        let grid = CreatureThreeByThreeGridMetrics.make(
            safeWidth: iPadWidth,
            safeHeight: 1194,
            reservedStageHeight: 400,
            chrome: 48
        )
        let cap = (CreatureThreeByThreeGridMetrics.phoneImageSize * CreatureThreeByThreeGridMetrics.maxScale).rounded()
        XCTAssertLessThanOrEqual(grid.imageSize, cap)
        XCTAssertGreaterThan(grid.imageSize, CreatureThreeByThreeGridMetrics.phoneImageSize)
    }

    func testWeighPlayAreaKeepsPhoneWidthPortraits() {
        let play = WeighPlayAreaMetrics.make(
            safeWidth: iPhoneWidth,
            safeHeight: iPhoneHeight,
            topSafeInset: iPhoneTopInset
        )
        let expected = CreatureThreeByThreeGridMetrics.widthFillingImageSize(safeWidth: iPhoneWidth)
        XCTAssertEqual(play.gridImageSize, expected)
        XCTAssertGreaterThanOrEqual(play.seesawHeight, WeighPlayAreaMetrics.phoneMinSeesawHeight)
    }
}
