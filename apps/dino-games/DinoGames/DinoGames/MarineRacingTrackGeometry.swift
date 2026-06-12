//
//  MarineRacingTrackGeometry.swift
//  DinoGames
//
//  Racing Marine Reptiles course math. Two layouts:
//  • `classic` — preserved Feb 2026 design: buoys and wide legs on one outer ring, inner legs inset 36pt (switch back via `RacingTrackLayout.marineBuoyCircle`).
//  • `slalom` — buoys on outer ring; racers alternate wide legs (past the buoys, may clip the frame) and tight inner legs.
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

    /// How far wide legs extend beyond the buoy ring on the slalom course.
    static let slalomWideBulge: CGFloat = 38

    static func circleLaneRadius(width: CGFloat, height: CGFloat, laneInset: CGFloat) -> CGFloat {
        max(40, min(width, height) * 0.36 - laneInset)
    }

    static func classicRadii(width: CGFloat, height: CGFloat) -> MarineClassicRadii {
        MarineClassicRadii(
            outerRadius: circleLaneRadius(width: width, height: height, laneInset: 0),
            innerRadius: circleLaneRadius(width: width, height: height, laneInset: classicLaneInset)
        )
    }

    static func slalomRadii(width: CGFloat, height: CGFloat) -> MarineSlalomRadii {
        let minDim = min(width, height)
        let buoyRadius = max(48, minDim * 0.395)
        let wideRadius = buoyRadius + slalomWideBulge
        let tightRadius = max(34, minDim * 0.215)
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
        let delta = 0.005
        let pointOnCourse: (Double) -> CGPoint = { p in
            switch style {
            case .classic:
                return pointOnClassicCourse(
                    progress: p,
                    width: width,
                    height: height,
                    radii: radiiClassic,
                    buoyCount: buoyCount
                )
            case .slalom:
                return pointOnSlalomCourse(
                    progress: p,
                    width: width,
                    height: height,
                    radii: radiiSlalom,
                    buoyCount: buoyCount
                )
            }
        }
        let p0 = pointOnCourse(max(0, progress - delta))
        let p1 = pointOnCourse(min(1, progress + delta))
        let dx = p1.x - p0.x
        let dy = p1.y - p0.y
        let len = hypot(dx, dy)
        guard len > 0.5 else { return .zero }
        let nx = -dy / len
        let ny = dx / len
        let side: CGFloat = racerIndex == 0 ? -1 : 1
        let gap: CGFloat = 11
        return CGSize(width: nx * gap * side, height: ny * gap * side)
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

    // MARK: - Shared arc sampler

    private static func pointOnAlternatingArcCourse(
        progress: Double,
        width: CGFloat,
        height: CGFloat,
        buoyCount: Int,
        finishRadius: CGFloat,
        radiusForSegment: (Int) -> CGFloat
    ) -> CGPoint {
        let count = max(3, buoyCount)
        let cx = width / 2
        let cy = height / 2
        let p = max(0, progress)
        if p >= 1 {
            return CGPoint(x: cx + finishRadius * cos(CGFloat.pi / 2), y: cy + finishRadius * sin(CGFloat.pi / 2))
        }
        let segmentSweep = 2 * CGFloat.pi / CGFloat(count)
        let lengths = (0..<count).map { radiusForSegment($0) * segmentSweep }
        let total = lengths.reduce(0, +)
        guard total > 0 else {
            return CGPoint(x: cx, y: cy + finishRadius)
        }
        var dist = CGFloat(p) * total
        for i in 0..<count {
            let segLen = lengths[i]
            if dist <= segLen || i == count - 1 {
                let t = segLen > 0 ? min(1, dist / segLen) : 0
                let r = radiusForSegment(i)
                let theta = CGFloat.pi / 2 + CGFloat(i) * segmentSweep + t * segmentSweep
                return CGPoint(x: cx + r * cos(theta), y: cy + r * sin(theta))
            }
            dist -= segLen
        }
        return CGPoint(x: cx + finishRadius * cos(CGFloat.pi / 2), y: cy + finishRadius * sin(CGFloat.pi / 2))
    }
}
