//
//  MarineRacingTrackGeometry.swift
//  DinoGames
//
//  Racing Marine Reptiles course math. Two layouts:
//  • `classic` — preserved Feb 2026 design: buoys and wide legs on one outer ring, inner legs inset 36pt (switch back via `RacingTrackLayout.marineBuoyCircle`).
//  • `slalom` — buoys on outer ring; racers alternate wide legs (past the buoys) and tight inner legs.
//    Radii are fit-to-rect so wide legs + racer art stay inside the track frame (no L/R clip).
//

import CoreGraphics
import SwiftUI

enum MarineRacingTrackStyle: Equatable {
    case classic
    case slalom
}

/// Radii for the slalom layout (buoy ring separate from wide/tight racing lines).
struct MarineSlalomRadii: Equatable {
    let buoyRadius: CGFloat
    let wideRadius: CGFloat
    let tightRadius: CGFloat
}

/// Radii for the preserved classic layout (buoys on outer ring; race line alternates outer vs inner).
struct MarineClassicRadii: Equatable {
    let outerRadius: CGFloat
    let innerRadius: CGFloat
}

enum MarineRacingTrackGeometry {
    /// Classic inset between outer and inner racing arcs (preserved design).
    static let classicLaneInset: CGFloat = 36

    /// How far wide legs extend beyond the buoy ring on the slalom course (before fit-to-rect).
    static let slalomWideBulge: CGFloat = 38

    /// Lane offset used by `racerOffset` (must stay in sync).
    static let racerLaneGap: CGFloat = 11

    /// Phone racer art is 48pt; keep half + lane gap + 1pt stroke outside the wide racing line.
    static let slalomRacerHalfSize: CGFloat = 24

    /// Space outside `wideRadius` so an outer-lane racer stays on-canvas.
    static var slalomEdgeClearance: CGFloat { racerLaneGap + slalomRacerHalfSize + 1 }

    static func circleLaneRadius(width: CGFloat, height: CGFloat, laneInset: CGFloat) -> CGFloat {
        max(40, min(width, height) * 0.36 - laneInset)
    }

    static func classicRadii(width: CGFloat, height: CGFloat) -> MarineClassicRadii {
        MarineClassicRadii(
            outerRadius: circleLaneRadius(width: width, height: height, laneInset: 0),
            innerRadius: circleLaneRadius(width: width, height: height, laneInset: classicLaneInset)
        )
    }

    /// Slalom radii sized for the track rect. Prefer ideal buoy/wide/tight proportions; if
    /// `wideRadius + edgeClearance` would exceed half the shorter side, scale all three uniformly
    /// (buoy and racer *art* stay at their view sizes — only the course shrinks).
    static func slalomRadii(width: CGFloat, height: CGFloat) -> MarineSlalomRadii {
        let minDim = min(width, height)
        let half = minDim / 2
        var buoyRadius = max(48, minDim * 0.395)
        var wideRadius = buoyRadius + slalomWideBulge
        var tightRadius = max(34, minDim * 0.215)

        let maxWide = max(40, half - slalomEdgeClearance)
        if wideRadius > maxWide {
            let scale = maxWide / wideRadius
            buoyRadius *= scale
            wideRadius *= scale
            tightRadius *= scale
        }

        return MarineSlalomRadii(
            buoyRadius: buoyRadius,
            wideRadius: wideRadius,
            tightRadius: tightRadius
        )
    }

    /// Buoy positions (always on the exterior ring).
    static func pointOnBuoyCircle(
        progress: Double,
        width: CGFloat,
        height: CGFloat,
        buoyRadius: CGFloat
    ) -> CGPoint {
        let cx = width / 2
        let cy = height / 2
        let p = max(0, min(1, progress))
        let theta = CGFloat.pi / 2 + CGFloat(p) * 2 * CGFloat.pi
        return CGPoint(x: cx + buoyRadius * cos(theta), y: cy + buoyRadius * sin(theta))
    }

    // MARK: - Classic (preserved)

    private static func classicSegmentRadius(index: Int, radii: MarineClassicRadii) -> CGFloat {
        index % 2 == 0 ? radii.outerRadius : radii.innerRadius
    }

    static func pointOnClassicCourse(
        progress: Double,
        width: CGFloat,
        height: CGFloat,
        radii: MarineClassicRadii,
        buoyCount: Int
    ) -> CGPoint {
        pointOnAlternatingArcCourse(
            progress: progress,
            width: width,
            height: height,
            buoyCount: buoyCount,
            finishRadius: radii.outerRadius
        ) { index in
            classicSegmentRadius(index: index, radii: radii)
        }
    }

    // MARK: - Slalom

    private static func slalomSegmentRadius(index: Int, radii: MarineSlalomRadii) -> CGFloat {
        index % 2 == 0 ? radii.wideRadius : radii.tightRadius
    }

    static func pointOnSlalomCourse(
        progress: Double,
        width: CGFloat,
        height: CGFloat,
        radii: MarineSlalomRadii,
        buoyCount: Int
    ) -> CGPoint {
        pointOnAlternatingArcCourse(
            progress: progress,
            width: width,
            height: height,
            buoyCount: buoyCount,
            finishRadius: radii.wideRadius
        ) { index in
            slalomSegmentRadius(index: index, radii: radii)
        }
    }

    static func racerOffset(
        progress: Double,
        racerIndex: Int,
        width: CGFloat,
        height: CGFloat,
        style: MarineRacingTrackStyle,
        radiiClassic: MarineClassicRadii,
        radiiSlalom: MarineSlalomRadii,
        buoyCount: Int
    ) -> CGSize {
        switch style {
        case .classic:
            return alternatingArcCourseOffset(
                progress: progress,
                racerIndex: racerIndex,
                width: width,
                height: height,
                buoyCount: buoyCount,
                finishRadius: radiiClassic.outerRadius
            ) { index in
                classicSegmentRadius(index: index, radii: radiiClassic)
            }
        case .slalom:
            return alternatingArcCourseOffset(
                progress: progress,
                racerIndex: racerIndex,
                width: width,
                height: height,
                buoyCount: buoyCount,
                finishRadius: radiiSlalom.wideRadius
            ) { index in
                slalomSegmentRadius(index: index, radii: radiiSlalom)
            }
        }
    }

    static func coursePath(
        width: CGFloat,
        height: CGFloat,
        style: MarineRacingTrackStyle,
        radiiClassic: MarineClassicRadii,
        radiiSlalom: MarineSlalomRadii,
        buoyCount: Int
    ) -> Path {
        let count = max(3, buoyCount)
        let samples = count * 32
        var path = Path()
        for s in 0...samples {
            let progress = Double(s) / Double(samples)
            let pt: CGPoint
            switch style {
            case .classic:
                pt = pointOnClassicCourse(
                    progress: progress,
                    width: width,
                    height: height,
                    radii: radiiClassic,
                    buoyCount: count
                )
            case .slalom:
                pt = pointOnSlalomCourse(
                    progress: progress,
                    width: width,
                    height: height,
                    radii: radiiSlalom,
                    buoyCount: count
                )
            }
            if s == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        return path
    }

    static func pointOnCourse(
        progress: Double,
        width: CGFloat,
        height: CGFloat,
        style: MarineRacingTrackStyle,
        radiiClassic: MarineClassicRadii,
        radiiSlalom: MarineSlalomRadii,
        buoyCount: Int
    ) -> CGPoint {
        switch style {
        case .classic:
            return pointOnClassicCourse(
                progress: progress,
                width: width,
                height: height,
                radii: radiiClassic,
                buoyCount: buoyCount
            )
        case .slalom:
            return pointOnSlalomCourse(
                progress: progress,
                width: width,
                height: height,
                radii: radiiSlalom,
                buoyCount: buoyCount
            )
        }
    }

    /// Buoy ring radius for drawing markers (classic: outer race ring; slalom: dedicated buoy ring).
    static func buoyMarkerRadius(
        style: MarineRacingTrackStyle,
        radiiClassic: MarineClassicRadii,
        radiiSlalom: MarineSlalomRadii
    ) -> CGFloat {
        switch style {
        case .classic:
            return radiiClassic.outerRadius
        case .slalom:
            return radiiSlalom.buoyRadius
        }
    }

    // MARK: - Shared arc + radial sampler

    private enum AlternatingCourseLegKind {
        case arc(segmentIndex: Int)
        case radial(afterSegment: Int)
    }

    private struct AlternatingCourseLeg {
        let kind: AlternatingCourseLegKind
        let length: CGFloat
    }

    private struct AlternatingCourseSample {
        let point: CGPoint
        /// Unit tangent in the direction of increasing race progress.
        let tangent: CGVector
    }

    private static func alternatingCourseLegs(
        buoyCount: Int,
        radiusForSegment: (Int) -> CGFloat
    ) -> (legs: [AlternatingCourseLeg], segmentSweep: CGFloat, count: Int) {
        let count = max(3, buoyCount)
        let segmentSweep = 2 * CGFloat.pi / CGFloat(count)
        var legs: [AlternatingCourseLeg] = []
        legs.reserveCapacity(count * 2)
        for i in 0..<count {
            let r = radiusForSegment(i)
            legs.append(AlternatingCourseLeg(kind: .arc(segmentIndex: i), length: r * segmentSweep))
            let rNext = radiusForSegment((i + 1) % count)
            legs.append(AlternatingCourseLeg(kind: .radial(afterSegment: i), length: abs(r - rNext)))
        }
        return (legs, segmentSweep, count)
    }

    private static func unitTangent(
        for kind: AlternatingCourseLegKind,
        t: CGFloat,
        segmentSweep: CGFloat,
        segmentCount: Int,
        radiusForSegment: (Int) -> CGFloat
    ) -> CGVector {
        switch kind {
        case .arc(let i):
            let theta0 = CGFloat.pi / 2 + CGFloat(i) * segmentSweep
            let theta = theta0 + t * segmentSweep
            return CGVector(dx: -sin(theta), dy: cos(theta))
        case .radial(let i):
            let theta = CGFloat.pi / 2 + CGFloat(i + 1) * segmentSweep
            let rFrom = radiusForSegment(i)
            let rTo = radiusForSegment((i + 1) % segmentCount)
            let radialSign: CGFloat = rTo >= rFrom ? 1 : -1
            return CGVector(dx: cos(theta) * radialSign, dy: sin(theta) * radialSign)
        }
    }

    /// On radial legs, keep lane offset aligned with the departing arc tangent (stable through the junction).
    private static func laneOffsetTangent(
        for kind: AlternatingCourseLegKind,
        t: CGFloat,
        segmentSweep: CGFloat,
        segmentCount: Int,
        radiusForSegment: (Int) -> CGFloat
    ) -> CGVector {
        switch kind {
        case .arc:
            return unitTangent(
                for: kind,
                t: t,
                segmentSweep: segmentSweep,
                segmentCount: segmentCount,
                radiusForSegment: radiusForSegment
            )
        case .radial(let i):
            return unitTangent(
                for: .arc(segmentIndex: i),
                t: 1,
                segmentSweep: segmentSweep,
                segmentCount: segmentCount,
                radiusForSegment: radiusForSegment
            )
        }
    }

    /// One lap = alternating circular arcs and radial legs at each buoy (no radius teleport).
    private static func sampleAlternatingArcCourse(
        progress: Double,
        width: CGFloat,
        height: CGFloat,
        buoyCount: Int,
        finishRadius: CGFloat,
        radiusForSegment: (Int) -> CGFloat
    ) -> AlternatingCourseSample {
        let cx = width / 2
        let cy = height / 2
        let p = max(0, progress)
        if p >= 1 {
            return AlternatingCourseSample(
                point: CGPoint(x: cx + finishRadius * cos(CGFloat.pi / 2), y: cy + finishRadius * sin(CGFloat.pi / 2)),
                tangent: CGVector(dx: -1, dy: 0)
            )
        }

        let (legs, segmentSweep, count) = alternatingCourseLegs(
            buoyCount: buoyCount,
            radiusForSegment: radiusForSegment
        )
        let total = legs.reduce(CGFloat(0)) { $0 + $1.length }
        guard total > 0 else {
            return AlternatingCourseSample(
                point: CGPoint(x: cx, y: cy + finishRadius),
                tangent: CGVector(dx: 0, dy: -1)
            )
        }

        var dist = CGFloat(p) * total
        for (index, leg) in legs.enumerated() {
            if dist <= leg.length || index == legs.count - 1 {
                let t = leg.length > 0 ? min(1, dist / leg.length) : 0
                let point: CGPoint
                switch leg.kind {
                case .arc(let i):
                    let r = radiusForSegment(i)
                    let theta0 = CGFloat.pi / 2 + CGFloat(i) * segmentSweep
                    let theta = theta0 + t * segmentSweep
                    point = CGPoint(x: cx + r * cos(theta), y: cy + r * sin(theta))
                case .radial(let i):
                    let rFrom = radiusForSegment(i)
                    let rTo = radiusForSegment((i + 1) % count)
                    let theta = CGFloat.pi / 2 + CGFloat(i + 1) * segmentSweep
                    let r = rFrom + t * (rTo - rFrom)
                    point = CGPoint(x: cx + r * cos(theta), y: cy + r * sin(theta))
                }
                let tangent = laneOffsetTangent(
                    for: leg.kind,
                    t: t,
                    segmentSweep: segmentSweep,
                    segmentCount: count,
                    radiusForSegment: radiusForSegment
                )
                return AlternatingCourseSample(point: point, tangent: tangent)
            }
            dist -= leg.length
        }

        return AlternatingCourseSample(
            point: CGPoint(x: cx + finishRadius * cos(CGFloat.pi / 2), y: cy + finishRadius * sin(CGFloat.pi / 2)),
            tangent: CGVector(dx: -1, dy: 0)
        )
    }

    private static func pointOnAlternatingArcCourse(
        progress: Double,
        width: CGFloat,
        height: CGFloat,
        buoyCount: Int,
        finishRadius: CGFloat,
        radiusForSegment: (Int) -> CGFloat
    ) -> CGPoint {
        sampleAlternatingArcCourse(
            progress: progress,
            width: width,
            height: height,
            buoyCount: buoyCount,
            finishRadius: finishRadius,
            radiusForSegment: radiusForSegment
        ).point
    }

    private static func alternatingArcCourseOffset(
        progress: Double,
        racerIndex: Int,
        width: CGFloat,
        height: CGFloat,
        buoyCount: Int,
        finishRadius: CGFloat,
        radiusForSegment: (Int) -> CGFloat
    ) -> CGSize {
        let sample = sampleAlternatingArcCourse(
            progress: progress,
            width: width,
            height: height,
            buoyCount: buoyCount,
            finishRadius: finishRadius,
            radiusForSegment: radiusForSegment
        )
        let tangent = sample.tangent
        let len = hypot(tangent.dx, tangent.dy)
        guard len > 0.001 else { return .zero }
        let nx = -tangent.dy / len
        let ny = tangent.dx / len
        let side: CGFloat = racerIndex == 0 ? -1 : 1
        let gap = racerLaneGap
        return CGSize(width: nx * gap * side, height: ny * gap * side)
    }
}
