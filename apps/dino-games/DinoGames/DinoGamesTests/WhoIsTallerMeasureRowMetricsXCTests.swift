//
//  WhoIsTallerMeasureRowMetricsXCTests.swift
//  DinoGamesTests
//
//  Which Ptero Is Taller comparison row: hug 140×340 poses so phone stages don't
//  leave empty slot padding (gaps) or a leading-shifted stack.
//

import XCTest
@testable import DinoGames

final class WhoIsTallerMeasureRowMetricsXCTests: XCTestCase {

    private let iPhoneWidth: CGFloat = 393
    private let phoneStageHeight: CGFloat = 228
    private let desiredAreaHeight: CGFloat = 340

    func testScaleOnePoseUses140By340Aspect() {
        let row = WhoIsTallerMeasureRowMetrics.make(
            availableWidth: iPhoneWidth,
            maxHeight: phoneStageHeight,
            desiredAreaHeight: desiredAreaHeight,
            leftScale: 1,
            rightScale: 0,
            centerScale: 1.7 / 5.5,
            showsLeft: true,
            showsRight: false
        )
        let expectedHeight = min(desiredAreaHeight, max(160, phoneStageHeight - 20))
        XCTAssertEqual(row.areaHeight, expectedHeight)
        XCTAssertEqual(row.layoutFit, 1, accuracy: 0.001)
        XCTAssertEqual(row.leftWidth / row.areaHeight, 140.0 / 340.0, accuracy: 0.001)
        XCTAssertLessThan(row.packedWidth, iPhoneWidth - 16)
    }

    func testPackedClusterIsNarrowerThanPhoneSoItCanCenter() {
        // Quetzalcoatlus 5.5 m vs Caiuajara 1.0 m vs 1.7 m human.
        let row = WhoIsTallerMeasureRowMetrics.make(
            availableWidth: iPhoneWidth,
            maxHeight: phoneStageHeight,
            desiredAreaHeight: desiredAreaHeight,
            leftScale: 1,
            rightScale: 1.0 / 5.5,
            centerScale: 1.7 / 5.5,
            showsLeft: true,
            showsRight: true
        )
        XCTAssertEqual(row.layoutFit, 1, accuracy: 0.001)
        XCTAssertGreaterThan(row.leftWidth, row.rightWidth * 4)
        let sideInset = (iPhoneWidth - row.packedWidth) / 2
        XCTAssertGreaterThan(sideInset, 80, "Giant-vs-tiny row should have equal leftover on both sides when centered")
        XCTAssertEqual(row.packedWidth + sideInset * 2, iPhoneWidth, accuracy: 0.5)
        let legacyPacked = 140 + 110 * (1.7 / 5.5) + 140 * (1.0 / 5.5)
        XCTAssertLessThan(row.packedWidth, legacyPacked)
    }

    func testSimilarHeightsStayPackedAndCenteredOnPhone() {
        // Tupandactylus 1.4 m vs Bakonydraco 1.2 m vs 1.7 m human.
        let row = WhoIsTallerMeasureRowMetrics.make(
            availableWidth: iPhoneWidth,
            maxHeight: phoneStageHeight,
            desiredAreaHeight: desiredAreaHeight,
            leftScale: 1.4 / 1.7,
            rightScale: 1.2 / 1.7,
            centerScale: 1,
            showsLeft: true,
            showsRight: true
        )
        XCTAssertEqual(row.layoutFit, 1, accuracy: 0.001)
        XCTAssertLessThan(row.packedWidth, iPhoneWidth * 0.65)
        XCTAssertGreaterThan(row.centerWidth, 50)
    }

    func testNarrowCanvasShrinksTheRowInsteadOfOverflowing() {
        let row = WhoIsTallerMeasureRowMetrics.make(
            availableWidth: 200,
            maxHeight: phoneStageHeight,
            desiredAreaHeight: desiredAreaHeight,
            leftScale: 1,
            rightScale: 1,
            centerScale: 1,
            showsLeft: true,
            showsRight: true
        )
        XCTAssertLessThan(row.layoutFit, 1)
        XCTAssertEqual(row.packedWidth, 200 - 16, accuracy: 0.5)
    }
}
