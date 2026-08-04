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

    /// Phone-width tracks used to clip: wide = buoy + 38 exceeded half the shorter side.
    func testSlalomWideRadiusFitsInTrackBounds() {
        let sizes: [(CGFloat, CGFloat)] = [
            (320, 280),
            (342, 400),
            (280, 500),
            (390, 300),
            (700, 500),
        ]
        for (w, h) in sizes {
            let radii = MarineRacingTrackGeometry.slalomRadii(width: w, height: h)
            let half = min(w, h) / 2
            let outerExtent = radii.wideRadius + MarineRacingTrackGeometry.slalomEdgeClearance
            XCTAssertLessThanOrEqual(
                outerExtent,
                half + 0.01,
                "wide+clearance \(outerExtent) must fit in half \(half) for \(Int(w))×\(Int(h))"
            )
            XCTAssertGreaterThan(radii.wideRadius, radii.buoyRadius)
            XCTAssertLessThan(radii.tightRadius, radii.buoyRadius)
        }
    }

    func testSlalomCoursePointsStayInsideTrackWithRacerClearance() {
        let w: CGFloat = 320
        let h: CGFloat = 280
        let radii = MarineRacingTrackGeometry.slalomRadii(width: w, height: h)
        let margin = MarineRacingTrackGeometry.slalomEdgeClearance
        for step in 0...64 {
            let progress = Double(step) / 64.0
            let point = MarineRacingTrackGeometry.pointOnSlalomCourse(
                progress: progress, width: w, height: h, radii: radii, buoyCount: 8
            )
            XCTAssertGreaterThanOrEqual(point.x, margin - 0.5)
            XCTAssertLessThanOrEqual(point.x, w - margin + 0.5)
            XCTAssertGreaterThanOrEqual(point.y, margin - 0.5)
            XCTAssertLessThanOrEqual(point.y, h - margin + 0.5)
        }
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

    func testSlalomProgressStepsHaveSimilarScreenDistance() {
        let w: CGFloat = 320
        let h: CGFloat = 280
        let radii = MarineRacingTrackGeometry.slalomRadii(width: w, height: h)
        let steps = 64
        var distances: [CGFloat] = []
        var previous = MarineRacingTrackGeometry.pointOnSlalomCourse(
            progress: 0, width: w, height: h, radii: radii, buoyCount: 8
        )
        for step in 1...steps {
            let progress = Double(step) / Double(steps)
            let point = MarineRacingTrackGeometry.pointOnSlalomCourse(
                progress: progress, width: w, height: h, radii: radii, buoyCount: 8
            )
            distances.append(hypot(point.x - previous.x, point.y - previous.y))
            previous = point
        }
        guard let maxDist = distances.max(), let minDist = distances.min(), minDist > 0 else {
            return XCTFail("Expected non-zero slalom step distances")
        }
        XCTAssertLessThan(
            maxDist / minDist,
            2.2,
            "Slalom path should not teleport at buoys; max/min step ratio was \(maxDist / minDist)"
        )
    }

    func testSlalomLaneOffsetDoesNotSpinOnInnerRadialLeg() {
        let w: CGFloat = 320
        let h: CGFloat = 280
        let style = MarineRacingTrackStyle.slalom
        let classic = MarineRacingTrackGeometry.classicRadii(width: w, height: h)
        let slalom = MarineRacingTrackGeometry.slalomRadii(width: w, height: h)
        // First radial leg (wide → tight), progress ~0.086–0.151 for 320×280 track.
        let radialStart = 0.095
        let radialEnd = 0.145
        let samples = 12
        var offsets: [CGSize] = []
        for i in 0...samples {
            let progress = radialStart + (radialEnd - radialStart) * Double(i) / Double(samples)
            offsets.append(
                MarineRacingTrackGeometry.racerOffset(
                    progress: progress,
                    racerIndex: 0,
                    width: w,
                    height: h,
                    style: style,
                    radiiClassic: classic,
                    radiiSlalom: slalom,
                    buoyCount: 8
                )
            )
        }
        guard let first = offsets.first else { return XCTFail("Missing offset samples") }
        for offset in offsets.dropFirst() {
            let delta = hypot(offset.width - first.width, offset.height - first.height)
            XCTAssertLessThan(
                delta,
                3,
                "Lane offset should stay stable along inner radial leg; saw spin delta \(delta)"
            )
        }
    }
}
