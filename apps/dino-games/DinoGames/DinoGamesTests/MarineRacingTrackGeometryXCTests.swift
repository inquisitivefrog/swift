//
//  MarineRacingTrackGeometryXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class MarineRacingTrackGeometryXCTests: XCTestCase {

    func testSlalomWideRadiusExceedsBuoyRing() {
        let radii = MarineRacingTrackGeometry.slalomRadii(width: 320, height: 280)
        XCTAssertGreaterThan(radii.wideRadius, radii.buoyRadius)
        XCTAssertLessThan(radii.tightRadius, radii.buoyRadius)
    }

    func testClassicPreservedRadiiMatchPriorInset() {
        let radii = MarineRacingTrackGeometry.classicRadii(width: 320, height: 280)
        let expectedOuter = MarineRacingTrackGeometry.circleLaneRadius(width: 320, height: 280, laneInset: 0)
        let expectedInner = MarineRacingTrackGeometry.circleLaneRadius(width: 320, height: 280, laneInset: MarineRacingTrackGeometry.classicLaneInset)
        XCTAssertEqual(radii.outerRadius, expectedOuter, accuracy: 0.01)
        XCTAssertEqual(radii.innerRadius, expectedInner, accuracy: 0.01)
    }

    func testSlalomAndClassicCoursesDiffer() {
        let w: CGFloat = 300
        let h: CGFloat = 260
        let classic = MarineRacingTrackGeometry.classicRadii(width: w, height: h)
        let slalom = MarineRacingTrackGeometry.slalomRadii(width: w, height: h)
        let pClassic = MarineRacingTrackGeometry.pointOnClassicCourse(
            progress: 0.125, width: w, height: h, radii: classic, buoyCount: 8
        )
        let pSlalom = MarineRacingTrackGeometry.pointOnSlalomCourse(
            progress: 0.125, width: w, height: h, radii: slalom, buoyCount: 8
        )
        XCTAssertGreaterThan(hypot(pSlalom.x - pClassic.x, pSlalom.y - pClassic.y), 8)
    }

    func testMarineGameDefaultsToSlalomLayout() {
        XCTAssertEqual(
            RacingGameConfigs.racingMarineReptiles.trackLayout,
            .marineBuoySlalom(buoyCount: 8)
        )
    }

    func testClassicLayoutStillAvailableForRevert() {
        let classic = RacingTrackLayout.marineBuoyCircle(buoyCount: 8)
        guard case .marineBuoyCircle(let count) = classic else {
            return XCTFail("Expected preserved classic layout case")
        }
        XCTAssertEqual(count, 8)
    }
}
