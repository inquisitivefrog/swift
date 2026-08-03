//
//  WeighGameView.swift
//  DinoGames
//
//  Created by Timothy Stilwell on 1/24/26.
//

import SwiftUI
import UIKit

// MARK: - Data Models

struct WeighableItem: Identifiable {
    let id: Int
    let name: String
    let imageName: String? // Optional image name in Assets.xcassets
    let emoji: String // Emoji fallback
    let weight: Int // Weight value for comparison (1-8 scale, allows multiple items per side)
    let category: String // "dinosaur", "person", "vehicle", "building"
}

// MARK: - Game Configuration
// Weigh dino/marine seesaw art: WIDE_WEIGHT_CARD 17:7 (340×140) — trim empty sky/ground, keep the creature.
// TODO (future): Consider stacking items on the right with heaviest at bottom (tower like Measure the Dinosaur's height stack) to teach relative size/weight when balancing.

/// Trims low-detail top/bottom bands from square weigh assets (negative space), then caches the result.
private enum WeighSeesawImagePrep {
    private static let lock = NSLock()
    private static var cache: [String: (image: UIImage, aspect: CGFloat)] = [:]

    static func prepared(named name: String) -> (image: UIImage, aspect: CGFloat)? {
        lock.lock()
        if let hit = cache[name] {
            lock.unlock()
            return hit
        }
        lock.unlock()
        guard let source = UIImage(named: name) else { return nil }
        let trimmed = verticallyTrimNegativeSpace(source)
        let aspect = trimmed.size.width / max(trimmed.size.height, 1)
        let value = (trimmed, aspect)
        lock.lock()
        cache[name] = value
        lock.unlock()
        return value
    }

    /// Remove empty sky/ground/letterbox bands. Uses the largest contiguous content run so
    /// bottom sparkles / watermark lines do not keep huge empty blue/black fields.
    private static func verticallyTrimNegativeSpace(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 8, height > 8 else { return image }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let ctx = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return image }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var activities = [Double](repeating: 0, count: height)
        var meanLuma = [Double](repeating: 0, count: height)
        for y in 0..<height {
            let row = y * bytesPerRow
            var sumR = 0, sumG = 0, sumB = 0
            for x in 0..<width {
                let i = row + x * bytesPerPixel
                sumR += Int(data[i])
                sumG += Int(data[i + 1])
                sumB += Int(data[i + 2])
            }
            let n = Double(width)
            let meanR = Double(sumR) / n
            let meanG = Double(sumG) / n
            let meanB = Double(sumB) / n
            meanLuma[y] = (meanR + meanG + meanB) / 3
            var acc = 0.0
            for x in 0..<width {
                let i = row + x * bytesPerPixel
                acc += abs(Double(data[i]) - meanR)
                acc += abs(Double(data[i + 1]) - meanG)
                acc += abs(Double(data[i + 2]) - meanB)
            }
            activities[y] = acc / (n * 3)
        }

        let mid = Array(activities[height / 4 ..< (height * 3 / 4)])
        let sortedMid = mid.sorted()
        let thr = max(sortedMid[sortedMid.count / 5], 4.0) * 1.15
        let uniformThr = min(thr, 6.0)

        // Near-black letterbox bars (Troodon) count as empty even with slight noise.
        func isContent(_ y: Int) -> Bool {
            let a = activities[y]
            if meanLuma[y] < 18, a < 12 { return false }
            return a >= uniformThr
        }

        // Longest contiguous content run = the creature (ignore isolated sparkles / captions).
        var bestStart = 0
        var bestEnd = height - 1
        var bestLen = 0
        var runStart: Int?
        for y in 0...height {
            let on = y < height && isContent(y)
            if on {
                if runStart == nil { runStart = y }
            } else if let s = runStart {
                let len = y - s
                if len > bestLen {
                    bestLen = len
                    bestStart = s
                    bestEnd = y - 1
                }
                runStart = nil
            }
        }
        guard bestLen > 0 else { return image }

        // Textured dirt floors (e.g. Stegosaurus) stay above uniformThr but are much quieter
        // than the subject. Only climb when content runs to the image edge — letterboxed
        // cards (Ankylosaurus black bar) already stop before the edge.
        let runMax = activities[bestStart...bestEnd].max() ?? 0
        let band = max(8, bestLen / 5)
        if bestEnd >= height - 3 {
            let botSlice = activities[(bestEnd - band + 1)...bestEnd]
            let botMean = botSlice.reduce(0, +) / Double(botSlice.count)
            if botMean < 0.22 * runMax {
                let climb = 0.32 * runMax
                while bestEnd > bestStart && activities[bestEnd] < climb {
                    bestEnd -= 1
                }
            }
        }
        if bestStart <= 2 {
            let topSlice = activities[bestStart..<(bestStart + band)]
            let topMean = topSlice.reduce(0, +) / Double(topSlice.count)
            if topMean < 0.22 * runMax {
                let climb = 0.32 * runMax
                while bestStart < bestEnd && activities[bestStart] < climb {
                    bestStart += 1
                }
            }
        }
        bestLen = bestEnd - bestStart + 1

        // Already filling most of the frame — leave upright / filled portraits alone.
        if Double(bestLen) / Double(height) >= 0.88 {
            return image
        }

        let pad = max(2, height / 64)
        let top = max(0, bestStart - pad)
        let bottom = min(height - 1, bestEnd + pad)
        let cropH = bottom - top + 1
        guard cropH > 0, cropH < height else { return image }

        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: cropH),
            format: format
        )
        return renderer.image { _ in
            image.draw(in: CGRect(x: 0, y: -top, width: width, height: height))
        }
    }
}

struct WeighGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let items: [WeighableItem]
    
    // Threshold for "nearly the same" weight (within this difference)
    let similarWeightThreshold: Int = 1
}

// MARK: - Main View

struct WeighGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: WeighGameConfig
    
    @StateObject private var speechManager = SpeechManager()
    @State private var selectedLeftItem: WeighableItem?
    @State private var selectedRightItem: WeighableItem?
    @State private var isWeighing = false
    @State private var seesawAngle: Double = 0 // negative = left down, positive = right down
    @State private var leftItemOffset: CGFloat = 0
    @State private var leftItemOffsetX: CGFloat = 0 // for fly arc when light on left (parabola to the right)
    @State private var rightItemOffset: CGFloat = 0
    @State private var rightItemOffsetX: CGFloat = 0 // for slide-down-the-arm effect (heavy left, light right)
    @State private var leftItemOpacity: Double = 1.0
    @State private var rightItemOpacity: Double = 1.0
    @State private var roundsCompleted = 0
    private let maxRounds = 3
    /// When true, the user can tap a second dinosaur; stays false until the first dinosaur's name audio (and "choose second" prompt for dinosaur game) has finished.
    @State private var canSelectSecondDinosaur = false
    /// When true, "choose your first dinosaur" intro is playing; block all taps until it finishes.
    @State private var isChooseFirstAudioPlaying = false
    /// Intro walk for weigh-dinosaur: highlight each of the 9 and play name before "choose your first". -1 = not started, 0..<count = current index.
    @State private var introWalkStep: Int = -1
    /// True when intro walk is done (or not used); then "choose your first" can play and taps allowed after that.
    private var introWalkComplete: Bool {
        !usesIntroWalkAndFirstPickPrompt || displayItems.isEmpty || introWalkStep >= displayItems.count
    }

    /// Block taps and dismiss while intro, selection audio, or weighing feedback is playing.
    private var blocksUserInput: Bool {
        isChooseFirstAudioPlaying || !introWalkComplete || isWeighing || speechManager.isPlaying
    }

    /// Dinosaur + marine weigh: name each grid creature, then "choose your first dinosaur" (shared prompt audio).
    private var usesIntroWalkAndFirstPickPrompt: Bool {
        gameConfig.id == "weigh-dinosaur" || gameConfig.id == "weigh-marine-reptile" || gameConfig.id == "weigh-pterosaur"
    }
    private var isMarineWeighGame: Bool { gameConfig.id == "weigh-marine-reptile" }
    private var isPterosaurWeighGame: Bool { gameConfig.id == "weigh-pterosaur" }
    /// Running list of dinosaurs that played (left + right per round); we show unique dinos only (no repeats).
    @State private var dinosaursWeighed: [WeighableItem] = []
    /// Victory walk: -1 none, 1 = walking list (highlight + name), 2 = good-job + crowd then dismiss.
    @State private var endSequenceStep: Int = -1
    @State private var endHighlightIndex: Int = 0
    /// Items for the current round; reshuffled at start of each round when randomizeItems is set.
    @State private var currentRoundItems: [WeighableItem] = []
    /// Defensive fallback: if audio completion callbacks fail, unlock selection anyway.
    @State private var secondSelectionUnlockToken: UUID = UUID()
    /// Defensive fallback: if second name callback fails, proceed to weighing.
    @State private var weighingStartToken: UUID = UUID()
    
    private var isGameOver: Bool { roundsCompleted >= maxRounds }
    private var displayItems: [WeighableItem] { currentRoundItems.isEmpty ? gameConfig.items : currentRoundItems }
    private var currentWeightDiff: Int? {
        guard let left = selectedLeftItem, let right = selectedRightItem else { return nil }
        return left.weight - right.weight
    }

    /// Prefer weigh-dino-{slug} when it is a true wide card; square-hero / bad weigh art → `dino-*` portrait.
    private func weighImageName(for item: WeighableItem) -> String? {
        guard let base = item.imageName else { return nil }
        if gameConfig.id == "weigh-dinosaur" {
            let slug = base.replacingOccurrences(of: "dino-", with: "")
            // Karate-Kid / upright cards + weigh art with watermark text: keep square portrait on seesaw.
            if Self.squareSeesawDinosaurSlugs.contains(slug) {
                return item.imageName
            }
            let weighName = "weigh-\(base)"
            let found = ImageAssetCache.imageExists(named: weighName)
            #if DEBUG
            if !found {
                print("⚠️ Weigh image '\(weighName)' not found, using fallback '\(base)'")
            }
            #endif
            return found ? weighName : item.imageName
        }
        if gameConfig.id == "weigh-marine-reptile" {
            let parts = base.split(separator: "-", omittingEmptySubsequences: false)
            if parts.count >= 3, parts[0] == "marine" {
                let clade = String(parts[1])
                let baseName = parts.dropFirst(2).joined(separator: "-")
                let preferredMarineNames = [
                    "weight-marine-\(clade)-\(baseName)", // per-creature massive variant
                    "weigh-marine-\(clade)-\(baseName)",  // per-creature weigh variant
                    "weight-marine-\(clade)",             // clade-wide massive variant
                    "weigh-marine-\(clade)",              // clade-wide weigh variant
                ]
                for candidate in preferredMarineNames where ImageAssetCache.imageExists(named: candidate) {
                    return candidate
                }
            }
            let weighName = "weigh-\(base)"
            if ImageAssetCache.imageExists(named: weighName) { return weighName }
            return base
        }
        return item.imageName
    }

    /// Square on seesaw: SQUARE_HERO_CARD raptors/ornithomimids + weigh assets with watermark/bad framing.
    private static let squareSeesawDinosaurSlugs: Set<String> = [
        "albertosaurus", "carnotaurus", "deinocheirus", "deinonychus", "dromaeosaurus",
        "gallimimus", "gigantoraptor", "microraptor", "ornithomimus", "oviraptor",
        "struthiomimus", "therizinosaurus", "utahraptor", "velociraptor", "troodon",
        "argentinosaurus", // weigh-dino-* has AI prompt text burned into the bottom
    ]

    /// Pose box aspect from content-trimmed wide weigh art only. Portraits stay 1:1.
    private func seesawPoseAspect(for imageName: String?) -> CGFloat {
        guard let imageName, !isPterosaurWeighGame else { return 1 }
        guard imageName.hasPrefix("weigh-dino-")
                || imageName.hasPrefix("weigh-marine-")
                || imageName.hasPrefix("weight-marine-") else {
            return 1
        }
        if let prepared = WeighSeesawImagePrep.prepared(named: imageName) {
            return min(max(prepared.aspect, 1), WeighPlayAreaMetrics.weighPoseAspect)
        }
        return WeighPlayAreaMetrics.weighPoseAspect
    }

    /// Scale factor for seesaw image. Heavier gets full size (1.2). Lighter uses cube-root of
    /// weight ratio so extreme mismatches (chicken-sized raptor vs sauropod) read clearly;
    /// a low floor keeps tiny poses findable for kids. Tip-safe layout then shrinks both together
    /// so relative size is preserved.
    private func seesawImageScale(for item: WeighableItem, relativeTo other: WeighableItem?) -> CGFloat {
        let kg: Double? = {
            if gameConfig.id == "weigh-dinosaur" {
                return MatchingGameConfigs.dinosaurEstimatedWeightKgById[item.id]
            }
            if gameConfig.id == "weigh-marine-reptile" {
                return MarineReptileWeighCatalog.weightKgByStableId[item.id]
            }
            if gameConfig.id == "weigh-pterosaur" {
                return pterosaurEstimatedWeightKg(for: item)
            }
            return nil
        }()
        guard let kg else { return 1.0 }
        if gameConfig.id == "weigh-dinosaur" || gameConfig.id == "weigh-marine-reptile" || gameConfig.id == "weigh-pterosaur",
           let other = other {
            let otherKg: Double? = {
                if gameConfig.id == "weigh-dinosaur" {
                    return MatchingGameConfigs.dinosaurEstimatedWeightKgById[other.id]
                }
                if gameConfig.id == "weigh-marine-reptile" {
                    return MarineReptileWeighCatalog.weightKgByStableId[other.id]
                }
                if gameConfig.id == "weigh-pterosaur" {
                    return pterosaurEstimatedWeightKg(for: other)
                }
                return nil
            }()
            if let otherKg {
                if kg >= otherKg {
                    return 1.2
                } else {
                    let heavierKg = max(kg, otherKg)
                    let lighterKg = min(kg, otherKg)
                    let ratio = lighterKg / heavierKg
                    // Linear size ~ cube root of mass (volume-like); was sqrt + floor 0.55, which
                    // made chicken-sized dinos look nearly as big as sauropods.
                    let t = pow(max(ratio, 0.0001), 1.0 / 3.0)
                    return CGFloat(max(0.22, 1.15 * t))
                }
            }
        }
        let logMin = log10(0.5)
        let logMax = log10(70_000.0)
        let logKg = log10(max(kg, 0.5))
        let t = (logKg - logMin) / (logMax - logMin)
        return CGFloat(0.35 + 0.85 * min(max(t, 0), 1))
    }

    /// Pterosaur weigh items use stable ids; fall back to image-name matching for safety.
    private func pterosaurEstimatedWeightKg(for item: WeighableItem) -> Double? {
        if let byId = AirPterosaurData.pterosaurEstimatedWeightKgById[item.id] {
            return byId
        }
        guard let imageName = item.imageName?.lowercased() else { return nil }
        return allWeighablePterosaurs.first { $0.imageName.lowercased() == imageName }?.estimatedWeightKg
    }

    var body: some View {
        GeometryReader { geometry in
            let safeWidth = max(geometry.size.width, 1)
            let safeHeight = max(geometry.size.height, 1)
            // GeometryReader can lay out under the status bar / Dynamic Island — clear the title and
            // fold the inset into play chrome so the 3×3 shrinks instead of colliding with the seesaw.
            let topInset = geometry.safeAreaInsets.top
            let play = WeighPlayAreaMetrics.make(
                safeWidth: safeWidth,
                safeHeight: safeHeight,
                topSafeInset: topInset
            )
            if isGameOver {
                // Full-screen victory (same as MatchingGameView) so the game title stays pinned and visible.
                weighVictoryView
                    .frame(width: safeWidth, height: safeHeight)
            } else {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: play.topSpacer)
                    
                    // Grid: 3 columns; height scales up on iPad so cards remain readable
                    VStack(spacing: 6) {
                        VStack(spacing: 4) {
                            Text(gameConfig.title)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                                .allowsTightening(true)
                                .frame(maxWidth: .infinity)
                            Text("Round \(roundsCompleted + 1) of \(maxRounds)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 10)
                        .frame(height: play.titleBlockHeight)
                        .frame(maxWidth: play.gridContentWidth)
                        .frame(maxWidth: .infinity)
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 6),
                                GridItem(.flexible(), spacing: 6),
                                GridItem(.flexible(), spacing: 6),
                            ],
                            spacing: 6
                        ) {
                            ForEach(displayItems) { item in
                                ItemCard(
                                    item: item,
                                    displayImageName: nil, // Grid: dino-* / ptero-* (square); seesaw: weigh-dino-* (wide poses)
                                    imageSize: play.gridImageSize,
                                    labelFontSize: play.gridLabelFontSize,
                                    isSelected: selectedLeftItem?.id == item.id || selectedRightItem?.id == item.id,
                                    isDisabled: isWeighing || isGameOver || isChooseFirstAudioPlaying || (!introWalkComplete) || (selectedLeftItem != nil && selectedRightItem != nil) || (selectedLeftItem != nil && selectedRightItem == nil && !canSelectSecondDinosaur),
                                    isIntroHighlighted: usesIntroWalkAndFirstPickPrompt && introWalkStep >= 0 && introWalkStep < displayItems.count && displayItems[introWalkStep].id == item.id
                                ) {
                                    handleItemTap(item)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .frame(maxWidth: play.gridContentWidth)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: play.gridBlockHeight)
                    .frame(width: safeWidth)
                
                    // Expandable spacer: pushes seesaw toward bottom, ensures no collision with grid
                    Spacer()
                        .frame(minHeight: play.midSpacer)
                    
                    if isMarineWeighGame {
                        marineBuoyancyArea(safeWidth: safeWidth, play: play)
                    } else {
                    // Bottom — seesaw grows with leftover height so iPad landscape does not clip the beam
                    let beamW = play.beamHalfWidth
                    let sideMargin = play.sideMargin
                    let beamTopY: CGFloat = -9 * play.layoutScale
                    let seesawSeatHeight: CGFloat = 12 * play.layoutScale
                    let seatTopY = beamTopY - seesawSeatHeight
                    VStack {
                        Spacer()
                            .frame(minHeight: 10 * play.layoutScale)
                        
                        ZStack {
                            // A-frame support (playground seesaw style)
                            SeesawSupportView(scale: play.layoutScale)
                                .offset(y: 45 * play.layoutScale)
                            
                            // Beam + seats + dinosaurs rotate as one unit around fulcrum; fulcrum stays fixed
                            ZStack {
                                // Rotating assembly: beam, seats, and dinosaur images tilt together
                                ZStack {
                                    // Beam (arm)
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(LinearGradient(colors: [Color.brown, Color.brown.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                                            .frame(width: beamW, height: 18 * play.layoutScale)
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.brown.opacity(0.6), lineWidth: 1))
                                            .offset(x: -beamW / 2)
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(LinearGradient(colors: [Color.brown, Color.brown.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                                            .frame(width: beamW, height: 18 * play.layoutScale)
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.brown.opacity(0.6), lineWidth: 1))
                                            .offset(x: beamW / 2)
                                    }
                                    // Seats (above beam; center y=-15, height seesawSeatHeight → seat top at beamTopY - seesawSeatHeight; drawn on top so both dinosaur images remain visible)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.brown.opacity(0.9))
                                        .frame(width: 56 * play.layoutScale, height: seesawSeatHeight)
                                        .offset(x: -beamW, y: -15 * play.layoutScale)
                                        .zIndex(10)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.brown.opacity(0.9))
                                        .frame(width: 56 * play.layoutScale, height: seesawSeatHeight)
                                        .offset(x: beamW, y: -15 * play.layoutScale)
                                        .zIndex(10)
                                    
                                    // Left side item (on left seat) — inside rotating assembly so it tilts with seesaw
                                    if let leftItem = selectedLeftItem {
                                        let scale = seesawImageScale(for: leftItem, relativeTo: selectedRightItem)
                                        let peerScale = selectedRightItem.map { seesawImageScale(for: $0, relativeTo: leftItem) }
                                        let leftName = weighImageName(for: leftItem)
                                        let peerName = selectedRightItem.flatMap { weighImageName(for: $0) }
                                        let pose = play.poseSize(
                                            scale: scale,
                                            aspect: seesawPoseAspect(for: leftName),
                                            peerScale: peerScale,
                                            peerAspect: seesawPoseAspect(for: peerName)
                                        )
                                        let (width, height) = (pose.width, pose.height)
                                        let baseY = seatTopY - height / 2 // Group is centered in ZStack; offset so bottom lands on seat top
                                        Group {
                                            if let imageName = leftName {
                                                weighSeesawCreatureImage(imageName: imageName, width: width, height: height)
                                            } else {
                                                Text(leftItem.emoji)
                                                    .font(.system(size: 80 * play.layoutScale))
                                                    .frame(width: width, height: height)
                                            }
                                        }
                                        .frame(width: width, height: height, alignment: .bottom)
                                        .clipped()
                                        .offset(x: -beamW + leftItemOffsetX, y: leftItemOffset + baseY)
                                        .opacity(leftItemOpacity)
                                        .zIndex(5)
                                    }
                                    
                                    // Right side item (on right seat) — inside rotating assembly so it tilts with seesaw
                                    if let rightItem = selectedRightItem {
                                        let scale = seesawImageScale(for: rightItem, relativeTo: selectedLeftItem)
                                        let peerScale = selectedLeftItem.map { seesawImageScale(for: $0, relativeTo: rightItem) }
                                        let rightName = weighImageName(for: rightItem)
                                        let peerName = selectedLeftItem.flatMap { weighImageName(for: $0) }
                                        let pose = play.poseSize(
                                            scale: scale,
                                            aspect: seesawPoseAspect(for: rightName),
                                            peerScale: peerScale,
                                            peerAspect: seesawPoseAspect(for: peerName)
                                        )
                                        let (width, height) = (pose.width, pose.height)
                                        let baseY = seatTopY - height / 2 // Group is centered in ZStack; offset so bottom lands on seat top
                                        Group {
                                            if let imageName = rightName {
                                                weighSeesawCreatureImage(imageName: imageName, width: width, height: height)
                                            } else {
                                                Text(rightItem.emoji)
                                                    .font(.system(size: 80 * play.layoutScale))
                                                    .frame(width: width, height: height)
                                            }
                                        }
                                        .frame(width: width, height: height, alignment: .bottom)
                                        .clipped()
                                        .offset(x: beamW + rightItemOffsetX, y: rightItemOffset + baseY)
                                        .opacity(rightItemOpacity)
                                        .zIndex(5)
                                    }
                                }
                                .rotationEffect(.degrees(seesawAngle), anchor: .center)
                                .offset(y: 28 * play.layoutScale)
                                // Fulcrum (fixed, does not rotate)
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 32 * play.layoutScale, height: 32 * play.layoutScale)
                                    .overlay(Circle().stroke(Color.brown, lineWidth: 2))
                                    .offset(y: 28 * play.layoutScale)
                            }
                        }
                    .frame(width: max(1, safeWidth - 2 * sideMargin), height: play.seesawHeight)
                    .clipped() // Keep rotated beam from affecting layout
                        
                        Spacer()
                            .frame(minHeight: 8)
                    }
                    .frame(minHeight: play.seesawHeight + 10)
                    .frame(width: safeWidth)
                    }
                }
            }
            .frame(minHeight: safeHeight)
            .frame(maxHeight: safeHeight)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .allowsHitTesting(!blocksUserInput)
        .gameSheetDismissDisabledWhileAudioPlaying(blocksUserInput)
        .toolbar {
            #if DEBUG
            if DeveloperSessionFlags.showEarlyExitDone, !isGameOver {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .disabled(blocksUserInput)
                }
            }
            #endif
        }
        .onAppear {
            // First round: use shuffled pool (or config items if no per-round randomizer for this game)
            currentRoundItems = WeighGameConfigs.randomizedItems(forId: gameConfig.id)
            if currentRoundItems.isEmpty {
                currentRoundItems = gameConfig.items
            }
            // Weigh the Dinosaur / Marine Reptile: walk the 9 (highlight + name audio), then play "choose your first dinosaur"
            if usesIntroWalkAndFirstPickPrompt, !displayItems.isEmpty {
                introWalkStep = 0
                startWeighIntroWalk()
            }
            // Force landscape orientation (use requestGeometryUpdate; UIDevice.setValue is deprecated)
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                }
            }
        }
        .onDisappear {
            // Allow rotation back to portrait when leaving
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
    }

    @ViewBuilder
    private func marineBuoyancyArea(safeWidth: CGFloat, play: WeighPlayAreaMetrics) -> some View {
        let sideMargin = play.sideMargin
        let layoutScale = play.layoutScale
        let podOffset = play.marinePodOffset
        let maxCreatureWidth = play.marineMaxCreatureWidth
        // Start lower in the water so the lighter side can rise without clipping at the top.
        let plateBaseY: CGFloat = 64 * layoutScale
        let waterlineY: CGFloat = -8 * layoutScale
        let leftCreatureSize = selectedLeftItem.map { marineCreatureSize(item: $0, other: selectedRightItem, maxWidth: maxCreatureWidth, baseHeight: play.dinoBaseHeight) }
        let rightCreatureSize = selectedRightItem.map { marineCreatureSize(item: $0, other: selectedLeftItem, maxWidth: maxCreatureWidth, baseHeight: play.dinoBaseHeight) }
        let seatTopY = plateBaseY - 7 * layoutScale
        let defaultCreatureHeight = play.dinoBaseHeight
        // Keep creature bottoms pinned to seat tops even when scaled down.
        let leftCreatureCenterY = seatTopY + leftItemOffset - ((leftCreatureSize?.height ?? defaultCreatureHeight) / 2)
        let rightCreatureCenterY = seatTopY + rightItemOffset - ((rightCreatureSize?.height ?? defaultCreatureHeight) / 2)
        let leftCreatureTopY = leftCreatureCenterY - ((leftCreatureSize?.height ?? defaultCreatureHeight) / 2)
        let rightCreatureTopY = rightCreatureCenterY - ((rightCreatureSize?.height ?? defaultCreatureHeight) / 2)
        let leftRigX = -podOffset - 22 * layoutScale
        let rightRigX = podOffset + 22 * layoutScale
        let leftPodY = min(plateBaseY - 40 * layoutScale + leftItemOffset * 0.22, leftCreatureTopY - 34 * layoutScale)
        let rightPodY = min(plateBaseY - 40 * layoutScale + rightItemOffset * 0.22, rightCreatureTopY - 34 * layoutScale)
        let leftRopeBottomY = plateBaseY - 1 * layoutScale + leftItemOffset
        let rightRopeBottomY = plateBaseY - 1 * layoutScale + rightItemOffset
        let leftRopeLength = max(24 * layoutScale, leftRopeBottomY - leftPodY - 18 * layoutScale)
        let rightRopeLength = max(24 * layoutScale, rightRopeBottomY - rightPodY - 18 * layoutScale)
        let leftRopeY = leftPodY + 18 * layoutScale + leftRopeLength / 2
        let rightRopeY = rightPodY + 18 * layoutScale + rightRopeLength / 2
        VStack {
            Spacer()
                .frame(minHeight: 6)
            ZStack {
                LinearGradient(
                    colors: [Color.cyan.opacity(0.10), Color.blue.opacity(0.24), Color.teal.opacity(0.32)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .frame(height: play.seesawHeight - 12)

                Path { p in
                    p.move(to: CGPoint(x: -safeWidth * 0.45, y: waterlineY))
                    p.addCurve(
                        to: CGPoint(x: safeWidth * 0.45, y: waterlineY),
                        control1: CGPoint(x: -safeWidth * 0.20, y: waterlineY - 8 * layoutScale),
                        control2: CGPoint(x: safeWidth * 0.20, y: waterlineY + 8 * layoutScale)
                    )
                }
                .stroke(Color.white.opacity(0.7), lineWidth: 2)

                Capsule()
                    .fill(LinearGradient(colors: [Color.gray.opacity(0.85), Color.gray.opacity(0.65)], startPoint: .top, endPoint: .bottom))
                    .frame(width: podOffset * 2 + 120 * layoutScale, height: 12 * layoutScale)
                    .offset(y: plateBaseY - 22 * layoutScale)
                    .rotationEffect(.degrees(seesawAngle * 0.35))

                marineBuoyancyPod(scale: layoutScale)
                    .offset(x: leftRigX, y: leftPodY)
                marineBuoyancyPod(scale: layoutScale)
                    .offset(x: rightRigX, y: rightPodY)

                Capsule().fill(Color.white.opacity(0.35)).frame(width: 4 * layoutScale, height: leftRopeLength).offset(x: leftRigX, y: leftRopeY)
                Capsule().fill(Color.white.opacity(0.35)).frame(width: 4 * layoutScale, height: rightRopeLength).offset(x: rightRigX, y: rightRopeY)

                RoundedRectangle(cornerRadius: 8).fill(Color.brown.opacity(0.85)).frame(width: 72 * layoutScale, height: 14 * layoutScale).offset(x: -podOffset, y: plateBaseY + leftItemOffset)
                RoundedRectangle(cornerRadius: 8).fill(Color.brown.opacity(0.85)).frame(width: 72 * layoutScale, height: 14 * layoutScale).offset(x: podOffset, y: plateBaseY + rightItemOffset)

                if let leftItem = selectedLeftItem {
                    marineCreatureImage(item: leftItem, other: selectedRightItem, maxWidth: maxCreatureWidth, baseHeight: play.dinoBaseHeight)
                        .offset(x: -podOffset + leftItemOffsetX, y: leftCreatureCenterY)
                        .opacity(leftItemOpacity)
                }
                if let rightItem = selectedRightItem {
                    marineCreatureImage(item: rightItem, other: selectedLeftItem, maxWidth: maxCreatureWidth, baseHeight: play.dinoBaseHeight)
                        .offset(x: podOffset + rightItemOffsetX, y: rightCreatureCenterY)
                        .opacity(rightItemOpacity)
                }
            }
            .frame(width: max(1, safeWidth - 2 * sideMargin), height: play.seesawHeight)
            .clipped()
            Spacer().frame(minHeight: 8)
        }
        .frame(minHeight: play.seesawHeight + 10)
        .frame(width: safeWidth)
    }

    private func marineBuoyancyPod(scale: CGFloat) -> some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Color.white.opacity(0.95), Color.cyan.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(Color.white.opacity(0.75), lineWidth: 2)
            Circle().fill(Color.white.opacity(0.35)).frame(width: 16 * scale, height: 16 * scale).offset(x: -8 * scale, y: -7 * scale)
        }
        .frame(width: 38 * scale, height: 38 * scale)
    }

    private func marineCreatureSize(item: WeighableItem, other: WeighableItem?, maxWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let scale = seesawImageScale(for: item, relativeTo: other)
        // Slightly higher cap so heavy-vs-light differences read more clearly.
        let height = min(baseHeight * scale, baseHeight)
        let width = min(height * WeighPlayAreaMetrics.weighPoseAspect, maxWidth)
        return CGSize(width: width, height: height)
    }

    @ViewBuilder
    private func marineCreatureImage(item: WeighableItem, other: WeighableItem?, maxWidth: CGFloat, baseHeight: CGFloat) -> some View {
        let size = marineCreatureSize(item: item, other: other, maxWidth: maxWidth, baseHeight: baseHeight)
        if let imageName = weighImageName(for: item) {
            weighSeesawCreatureImage(imageName: imageName, width: size.width, height: size.height)
        } else {
            Text(item.emoji)
                .font(.system(size: 62 * (baseHeight / 130)))
                .frame(width: size.width, height: size.height)
        }
    }

    /// Seesaw art: trim empty bands on wide weigh cards only; portraits / ptero use plain fit.
    @ViewBuilder
    private func weighSeesawCreatureImage(imageName: String, width: CGFloat, height: CGFloat) -> some View {
        let useTrimmed = !isPterosaurWeighGame
            && (imageName.hasPrefix("weigh-dino-")
                || imageName.hasPrefix("weigh-marine-")
                || imageName.hasPrefix("weight-marine-"))
        if useTrimmed, let prepared = WeighSeesawImagePrep.prepared(named: imageName) {
            Image(uiImage: prepared.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: width, maxHeight: height, alignment: .bottom)
        } else {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: width, maxHeight: height, alignment: .bottom)
        }
    }

    private func handleItemTap(_ item: WeighableItem) {
        guard !isWeighing else { return }
        
        if selectedLeftItem == nil {
            // First selection: show on left, tilt seesaw left (left has weight), play name, then "choose your second dinosaur"
            selectedLeftItem = item
            canSelectSecondDinosaur = false
            secondSelectionUnlockToken = UUID()
            let unlockToken = secondSelectionUnlockToken
            withAnimation(.easeOut(duration: 0.5)) {
                if isMarineWeighGame {
                    leftItemOffset = item.weight <= 3 ? 4 : (item.weight <= 6 ? 8 : 12)
                    rightItemOffset = 0
                    seesawAngle = -2
                } else {
                    // Tilt seesaw left based on weight: light (1–3) → -6°, medium (4–6) → -10°, heavy (7–9) → -14°
                    let tilt: Double = item.weight <= 3 ? -6 : (item.weight <= 6 ? -10 : -14)
                    seesawAngle = tilt
                }
            }
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.speechManager.onAudioFinished = {
                    guard self.secondSelectionUnlockToken == unlockToken else { return }
                    self.canSelectSecondDinosaur = true
                    self.speechManager.onAudioFinished = nil
                }
                self.playSecondPickPrompt()
            }
            speechManager.speak(audioKey: item.imageName ?? item.name, fallbackText: item.name)
            // Safety fallback: audio callback chains can occasionally be dropped; never leave round stuck.
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                guard self.secondSelectionUnlockToken == unlockToken,
                      self.selectedLeftItem?.id == item.id,
                      self.selectedRightItem == nil,
                      !self.isWeighing else { return }
                self.speechManager.onAudioFinished = nil
                self.canSelectSecondDinosaur = true
            }
        } else if selectedRightItem == nil && selectedLeftItem?.id != item.id && canSelectSecondDinosaur {
            // Second selection: show name, play audio, then start weighing when name finishes
            selectedRightItem = item
            canSelectSecondDinosaur = false
            weighingStartToken = UUID()
            let startToken = weighingStartToken
            speechManager.onAudioFinished = {
                guard self.weighingStartToken == startToken else { return }
                self.speechManager.onAudioFinished = nil
                self.startWeighing()
            }
            speechManager.speak(audioKey: item.imageName ?? item.name, fallbackText: item.name)
            // Safety fallback: if name audio callback is missed, still begin weighing.
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                guard self.weighingStartToken == startToken,
                      self.selectedRightItem?.id == item.id,
                      !self.isWeighing else { return }
                self.speechManager.onAudioFinished = nil
                self.startWeighing()
            }
        }
    }
    
    private func estimatedWeightKg(for item: WeighableItem) -> Double? {
        if gameConfig.id == "weigh-dinosaur" {
            return MatchingGameConfigs.dinosaurEstimatedWeightKgById[item.id]
        }
        if gameConfig.id == "weigh-marine-reptile" {
            return MarineReptileWeighCatalog.weightKgByStableId[item.id]
        }
        if gameConfig.id == "weigh-pterosaur" {
            return pterosaurEstimatedWeightKg(for: item)
        }
        return nil
    }

    /// Uses estimated kg when available to drive both audio result and seesaw behavior.
    private func weighComparison(left: WeighableItem, right: WeighableItem) -> (weightDiff: Int, isNearlySame: Bool, isMassiveDifference: Bool) {
        if let leftKg = estimatedWeightKg(for: left), let rightKg = estimatedWeightKg(for: right) {
            let result = ComparisonGameLogic.weighComparison(leftKg: leftKg, rightKg: rightKg)
            let weightDiff = leftKg == rightKg ? 0 : (leftKg > rightKg ? 1 : -1)
            return (weightDiff, result.isNearlySame, result.isMassiveDifference)
        }

        let weightDiff = left.weight - right.weight
        let absDiff = abs(weightDiff)
        return (
            weightDiff,
            absDiff <= gameConfig.similarWeightThreshold,
            absDiff >= 4
        )
    }

    private func startWeighing() {
        guard let left = selectedLeftItem,
              let right = selectedRightItem else { return }
        
        // Add to victory list immediately so they display even if audio chain fails
        if !dinosaursWeighed.contains(where: { $0.id == left.id }) { dinosaursWeighed.append(left) }
        if !dinosaursWeighed.contains(where: { $0.id == right.id }) { dinosaursWeighed.append(right) }
        
        isWeighing = true
        let comparison = weighComparison(left: left, right: right)
        let weightDiff = comparison.weightDiff
        let isNearlySame = comparison.isNearlySame
        let isMassiveDifference = comparison.isMassiveDifference

        // Pause 0.2 seconds before adjusting seesaw (seesaw may already be tilted left from first selection)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 1.5)) {
                if self.isMarineWeighGame {
                    // Buoyancy rig: heavier side sinks, lighter side rises.
                    let sinkAmount: CGFloat = isMassiveDifference ? 42 : 28
                    seesawAngle = isNearlySame ? 0 : (weightDiff > 0 ? -8 : 8)
                    leftItemOpacity = 1
                    rightItemOpacity = 1
                    leftItemOffsetX = 0
                    rightItemOffsetX = 0
                    if isNearlySame {
                        leftItemOffset = 10
                        rightItemOffset = 10
                    } else if isMassiveDifference {
                        // Big mismatch: lighter reptile gets launched straight up off-screen; pod/rope stays.
                        if weightDiff > 0 {
                            leftItemOffset = sinkAmount
                            rightItemOffset = -320
                            rightItemOpacity = 0
                        } else {
                            leftItemOffset = -320
                            rightItemOffset = sinkAmount
                            leftItemOpacity = 0
                        }
                    } else if weightDiff > 0 {
                        leftItemOffset = sinkAmount
                        rightItemOffset = -sinkAmount * 0.55
                    } else {
                        leftItemOffset = -sinkAmount * 0.55
                        rightItemOffset = sinkAmount
                    }
                } else if isNearlySame {
                    // Nearly same weight: reposition to balanced (or slight tilt) while audio plays
                    if weightDiff > 0 {
                        seesawAngle = -2
                        rightItemOffset = 0
                    } else if weightDiff < 0 {
                        seesawAngle = 2
                        leftItemOffset = 0
                    } else {
                        seesawAngle = 0
                    }
                } else if weightDiff > 0 {
                    // Left heavy, right light: right dino slides along the beam toward the left seat (no fly)
                    seesawAngle = isMassiveDifference ? -20 : -14
                    leftItemOffset = 0 // No vertical fall; dinosaurs stay on seats
                    rightItemOffset = 0 // No vertical offset; slide follows the beam
                    rightItemOffsetX = -80 // Slides inward along the arm toward fulcrum (beam is horizontal in assembly coords; rotation makes it appear along the tilt)
                } else {
                    // Right heavy, left light: left dino flies in parabola up and to the right
                    seesawAngle = isMassiveDifference ? 22 : 15
                    rightItemOffset = 0 // No vertical fall; right dino stays on seat
                    leftItemOffset = isMassiveDifference ? -220 : -150
                    leftItemOffsetX = isMassiveDifference ? 140 : 100 // Parabola arc to the right
                    leftItemOpacity = 0
                }
            }
            
            // After tilt: announce result — either "they both weigh about the same" or "[name] is heavier".
            // Only after that audio finishes do we count the round and show game over or reset.
            if isNearlySame {
                self.speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.finishWeighingRound()
                }
                self.speechManager.speak("they-both-weigh-about-the-same")
            } else {
                let heavier = weightDiff >= 0 ? left : right
                self.speechManager.onAudioFinished = {
                    self.speechManager.speak("is-heavier", chainDelay: true)
                    self.speechManager.onAudioFinished = {
                        self.speechManager.onAudioFinished = nil
                        // Pregnant pause so the player can enjoy the moment (e.g. T-Rex launched into space)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.finishWeighingRound()
                        }
                    }
                }
                self.speechManager.speak(audioKey: heavier.imageName ?? heavier.name, fallbackText: heavier.name)
            }
        }
    }
    
    /// Called when the result audio for this round has finished (so the winner is declared before we advance).
    private func finishWeighingRound() {
        // Dinosaurs already added at startWeighing; ensure no duplicates if called twice
        if let left = selectedLeftItem, let right = selectedRightItem {
            if !dinosaursWeighed.contains(where: { $0.id == left.id }) { dinosaursWeighed.append(left) }
            if !dinosaursWeighed.contains(where: { $0.id == right.id }) { dinosaursWeighed.append(right) }
        }
        roundsCompleted += 1
        if roundsCompleted >= maxRounds {
            isWeighing = false
            selectedLeftItem = nil
            selectedRightItem = nil
            // Victory view will walk the list, then play good-job + crowd and dismiss
        } else {
            // New round: 9 new dinosaurs at random, excluding any already weighed this game (no repeat use)
            let usedIds = Set(dinosaursWeighed.map(\.id))
            let nextItems = WeighGameConfigs.randomizedItems(forId: gameConfig.id, excludingDinosaurIds: usedIds)
            if !nextItems.isEmpty {
                currentRoundItems = nextItems
            }
            resetWeighing()
        }
    }

    /// Recap rows: weighed creatures with weigh-grid art introduced during play.
    private var weighVictoryRecapItems: [VictoryRecapDisplayItem] {
        dinosaursWeighed.map { item in
            let imageName = item.imageName.flatMap { ImageAssetCache.imageExists(named: $0) ? $0 : nil }
            return VictoryRecapDisplayItem(
                id: "\(item.id)",
                title: item.name,
                imageAssetName: imageName,
                fallbackEmoji: item.emoji
            )
        }
    }

    /// Recap list height: up to `StandardVictoryLayout.maxVisibleRecapRows` rows visible; longer lists scroll.
    private var victoryListVisibleHeight: CGFloat {
        StandardVictoryLayout.recapListScrollHeight(itemCount: weighVictoryRecapItems.count)
    }

    private var weighVictorySuccessImageSide: CGFloat {
        GameCatalogImageMetrics.nameThatVictorySuccessImageSide
    }

    /// Victory screen: same as Dino Diets / Match the Dinosaur — top half list (highlight + name audio), bottom half success image (centered, no wrapper), then good-job + crowd and dismiss.
    private var weighVictoryView: some View {
        VictorySplitColumnView(
            listScrollHeight: victoryListVisibleHeight,
            showSuccessPhase: endSequenceStep == 2,
            endHighlightIndex: endHighlightIndex,
            gameTitle: gameConfig.title,
            recapItemCount: weighVictoryRecapItems.count,
            scrollRows: {
                ForEach(Array(weighVictoryRecapItems.enumerated()), id: \.element.id) { index, item in
                    StandardVictoryRecapRowView(
                        item: item,
                        isHighlighted: endSequenceStep >= 1 && index == endHighlightIndex
                    )
                    .id(index)
                }
            },
            successPhase: {
                LandGameVictorySuccessStingerThenContinue(
                    candidateSuccessImageNames: gameConfig.id == "weigh-marine-reptile"
                        ? ["game-weigh-the-marine-reptile-success", "game-weigh-the-marine-reptile"]
                        : ["game-\(gameConfig.id)-success", "game-\(gameConfig.id)"],
                    catalogGameIdForStinger: gameConfig.id,
                    imageSide: weighVictorySuccessImageSide,
                    speechManager: speechManager,
                    onContinue: playWeighGoodJobAndCrowdThenDismiss
                )
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            if dinosaursWeighed.isEmpty {
                endSequenceStep = 2
            } else {
                speechManager.speak(audioKey: dinosaursWeighed[0].imageName ?? dinosaursWeighed[0].name, fallbackText: dinosaursWeighed[0].name)
                speechManager.onAudioFinished = { advanceWeighEndHighlight() }
            }
        }
    }

    private func advanceWeighEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < dinosaursWeighed.count {
            speechManager.speak(audioKey: dinosaursWeighed[endHighlightIndex].imageName ?? dinosaursWeighed[endHighlightIndex].name, fallbackText: dinosaursWeighed[endHighlightIndex].name)
            speechManager.onAudioFinished = { advanceWeighEndHighlight() }
        } else {
            endSequenceStep = 2
        }
    }
    
    private func playWeighGoodJobAndCrowdThenDismiss() {
        StandardVictorySequence.dismissAfterVictory(
            configId: gameConfig.id,
            isPresented: $isPresented,
            speechManager: speechManager
        )
    }
    
    private func resetWeighing() {
        withAnimation {
            seesawAngle = 0
            leftItemOffset = 0
            leftItemOffsetX = 0
            rightItemOffset = 0
            rightItemOffsetX = 0
            leftItemOpacity = 1.0
            rightItemOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            selectedLeftItem = nil
            selectedRightItem = nil
            isWeighing = false
            canSelectSecondDinosaur = false
            secondSelectionUnlockToken = UUID()
            weighingStartToken = UUID()
            introWalkStep = -1
            // Weigh the Dinosaur / Marine: walk the 9, then play "choose your first dinosaur"
            if self.usesIntroWalkAndFirstPickPrompt, !self.displayItems.isEmpty {
                self.introWalkStep = 0
                self.startWeighIntroWalk()
            }
        }
    }

    /// Walk the current round's dinosaurs: speak name at introWalkStep, then advance; when done, play "choose your first dinosaur".
    private func startWeighIntroWalk() {
        guard introWalkStep >= 0, introWalkStep < displayItems.count else { return }
        let item = displayItems[introWalkStep]
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.advanceWeighIntroWalk()
        }
        speechManager.speak(audioKey: item.imageName ?? item.name, fallbackText: item.name)
    }

    private func advanceWeighIntroWalk() {
        speechManager.onAudioFinished = nil
        introWalkStep += 1
        if introWalkStep >= displayItems.count {
            isChooseFirstAudioPlaying = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.isChooseFirstAudioPlaying = false
            }
            playFirstPickPrompt()
            return
        }
        startWeighIntroWalk()
    }

    private func playFirstPickPrompt() {
        if isMarineWeighGame {
            speechManager.speak("game-choose-your-first-marine-reptile")
        } else if isPterosaurWeighGame {
            // Use dedicated pterosaur clip when available; otherwise speak a clean TTS fallback.
            speechManager.speak(audioKey: "game-choose-your-first-pterosaur", fallbackText: "Choose your first pterosaur")
        } else {
            speechManager.speak("game-choose-your-first-dinosaur")
        }
    }

    private func playSecondPickPrompt() {
        if isMarineWeighGame {
            speechManager.speak("game-choose-your-second-marine-reptile")
        } else if isPterosaurWeighGame {
            // Use dedicated pterosaur clip when available; otherwise speak a clean TTS fallback.
            speechManager.speak(audioKey: "game-choose-your-second-pterosaur", fallbackText: "Choose your second pterosaur")
        } else {
            speechManager.speak("game-choose-your-second-dinosaur")
        }
    }
}

// MARK: - Components

struct ItemCard: View {
    let item: WeighableItem
    /// When set (e.g. weigh-dino-* for Weigh the Dinosaur), use this instead of item.imageName.
    var displayImageName: String? = nil
    /// Grid cell image size; scales up on larger canvases (iPad).
    var imageSize: CGFloat = 96
    /// Base label size; long names still shrink via `minimumScaleFactor`.
    var labelFontSize: CGFloat = 15
    let isSelected: Bool
    let isDisabled: Bool
    /// When true, show accent border for intro walk (e.g. weigh-dinosaur introducing each dinosaur).
    var isIntroHighlighted: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                if let imageName = displayImageName ?? item.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: imageSize, height: imageSize)
                        .clipped()
                } else {
                    Text(item.emoji)
                        .font(.system(size: imageSize * 0.625))
                        .frame(width: imageSize, height: imageSize)
                }
                Text(item.name)
                    .font(.system(size: labelFontSize))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    // Keep all grid cards the same height: shrink long names instead of wrapping to two lines.
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .allowsTightening(true)
                    .frame(width: imageSize)
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.3) : (isIntroHighlighted ? Color.accentColor.opacity(0.08) : Color.clear))
        )
        .overlay(
            Group {
                if isSelected || isIntroHighlighted {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.accentColor, lineWidth: isIntroHighlighted ? 4 : 3)
                }
            }
        )
        .opacity(isDisabled && !isSelected && !isIntroHighlighted ? 0.5 : 1.0)
        .disabled(isDisabled && !isSelected)
    }
}

struct SpeedLinesView: View {
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { _ in
                Rectangle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 2, height: 40)
            }
        }
    }
}

// Phone-tuned seesaw was height 260 while beam grew with iPad width — clip truncation.
// Derive leftover height for the play stage and scale beam/dinos to fit.
struct WeighPlayAreaMetrics {
    static let phoneSeesawHeight: CGFloat = 260
    static let phoneGridBlockHeight: CGFloat = 422
    /// Match `CreatureThreeByThreeGridMetrics` — 2-line title + round line.
    static let phoneTitleBlockHeight: CGFloat = 80
    static let phoneDinoBaseHeight: CGFloat = 130
    static let phoneSideMargin: CGFloat = 12
    static let phoneGridImageSize: CGFloat = 96
    static let phoneGridLabelFontSize: CGFloat = 15
    /// WIDE_WEIGHT_CARD (17:7 / 340×140). Square weigh assets are center-cropped into this box.
    static let weighPoseAspect: CGFloat = 17.0 / 7.0
    /// Shrink poses so a tipped (~15–25°) wide image still fits inside `.clipped()`.
    static let tipSafety: CGFloat = 0.68

    let topSpacer: CGFloat
    let midSpacer: CGFloat
    let titleBlockHeight: CGFloat
    let gridBlockHeight: CGFloat
    let gridImageSize: CGFloat
    let gridLabelFontSize: CGFloat
    let gridContentWidth: CGFloat
    let seesawHeight: CGFloat
    let layoutScale: CGFloat
    let sideMargin: CGFloat
    let beamHalfWidth: CGFloat
    let maxDinoWidth: CGFloat
    let maxDinoHeight: CGFloat
    let dinoBaseHeight: CGFloat
    let marinePodOffset: CGFloat
    let marineMaxCreatureWidth: CGFloat

    static func make(safeWidth: CGFloat, safeHeight: CGFloat, topSafeInset: CGFloat = 0) -> WeighPlayAreaMetrics {
        let topSpacer: CGFloat = 16 + topSafeInset
        let midSpacer: CGFloat = 16
        let titleBlockHeight = phoneTitleBlockHeight
        let chrome = topSpacer + midSpacer + 16
        let reservedSeesaw = phoneSeesawHeight * 1.2
        let grid = CreatureThreeByThreeGridMetrics.make(
            safeWidth: safeWidth,
            safeHeight: safeHeight,
            reservedStageHeight: reservedSeesaw,
            chrome: chrome,
            minimumGridBudget: phoneGridBlockHeight * 0.85
        )
        let gridImageSize = grid.imageSize
        let gridLabelFontSize = grid.labelFontSize
        let gridContentWidth = grid.contentWidth
        let gridBlockHeight = grid.blockHeight
        let seesawHeight = max(
            phoneSeesawHeight,
            safeHeight - gridBlockHeight - chrome
        )
        let layoutScale = max(1, seesawHeight / phoneSeesawHeight)
        let sideMargin = phoneSideMargin
        // Keep seats inward on wide iPads so landscape weigh art has room to tip without clipping.
        let beamHalfWidth = min(
            max(safeWidth * 0.22, 100),
            seesawHeight * 0.70,
            safeWidth * 0.26
        )
        // Distance from a seat (±beam) to the canvas edge — that is the max half-width before tip.
        let seatToEdge = max(70, safeWidth / 2 - beamHalfWidth - sideMargin)
        let maxDinoWidth = max(90, seatToEdge * tipSafety * 2)
        let maxDinoHeight = max(70, seesawHeight * 0.48 * tipSafety)
        let dinoBaseHeight = min(
            phoneDinoBaseHeight * min(layoutScale, 1.35),
            maxDinoHeight
        )
        let marinePodOffset = min(max(safeWidth * 0.22, 88), seesawHeight * 0.75)
        let marineMaxCreatureWidth = max(110, min(safeWidth * 0.26, maxDinoWidth))
        return WeighPlayAreaMetrics(
            topSpacer: topSpacer,
            midSpacer: midSpacer,
            titleBlockHeight: titleBlockHeight,
            gridBlockHeight: gridBlockHeight,
            gridImageSize: gridImageSize,
            gridLabelFontSize: gridLabelFontSize,
            gridContentWidth: gridContentWidth,
            seesawHeight: seesawHeight,
            layoutScale: layoutScale,
            sideMargin: sideMargin,
            beamHalfWidth: beamHalfWidth,
            maxDinoWidth: maxDinoWidth,
            maxDinoHeight: maxDinoHeight,
            dinoBaseHeight: dinoBaseHeight,
            marinePodOffset: marinePodOffset,
            marineMaxCreatureWidth: marineMaxCreatureWidth
        )
    }

    /// Size a weigh pose so it remains inside the clip box while the beam tips.
    /// `aspect` is 17:7 for WIDE_WEIGHT_CARD, 1 for square Karate-Kid / upright cards.
    func poseSize(
        scale: CGFloat,
        aspect: CGFloat = weighPoseAspect,
        peerScale: CGFloat? = nil,
        peerAspect: CGFloat? = nil
    ) -> (width: CGFloat, height: CGFloat, fit: CGFloat) {
        let idealHeight = dinoBaseHeight * scale
        let idealWidth = idealHeight * aspect
        let peerHeight = peerScale.map { dinoBaseHeight * $0 } ?? idealHeight
        let peerWidth = peerHeight * (peerAspect ?? aspect)
        let maxIdealW = max(idealWidth, peerWidth)
        let maxIdealH = max(idealHeight, peerHeight)
        let fit = min(
            1,
            maxDinoWidth / max(maxIdealW, 1),
            maxDinoHeight / max(maxIdealH, 1)
        )
        return (idealWidth * fit, idealHeight * fit, fit)
    }

    /// Balance (landscape): allot a seesaw band from canvas height, then reuse tip-safe beam/pose metrics.
    static func makeSeesawStage(safeWidth: CGFloat, canvasHeight: CGFloat) -> WeighPlayAreaMetrics {
        let allotted = max(phoneSeesawHeight, min(canvasHeight * 0.42, 440))
        return make(
            safeWidth: safeWidth,
            safeHeight: allotted + phoneGridBlockHeight + 56
        )
    }
}

// A-frame support: legs meet at the pivot point (top) and diverge at the base, so the beam is clearly free to tip.
struct SeesawSupportView: View {
    var scale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .bottom) {
            // Left leg: pivots from top center, bottom sweeps left
            Rectangle()
                .fill(Color.brown.opacity(0.9))
                .frame(width: 12 * scale, height: 58 * scale)
                .rotationEffect(.degrees(-22), anchor: UnitPoint(x: 0.5, y: 0))
            // Right leg: pivots from top center, bottom sweeps right
            Rectangle()
                .fill(Color.brown.opacity(0.9))
                .frame(width: 12 * scale, height: 58 * scale)
                .rotationEffect(.degrees(22), anchor: UnitPoint(x: 0.5, y: 0))
            // Base bar (wider for stability)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.brown)
                .frame(width: 140 * scale, height: 12 * scale)
        }
    }
}

// MARK: - Pterosaur Weight Pool (for Weigh the Pterosaur)

private struct WeighablePterosaurPoolEntry {
    /// Same ids as `AirPterosaurData` (101+). Must be used as `WeighableItem.id` so SwiftUI and round logic don’t reuse rows 1…6 for different species.
    let creatureId: Int
    let name: String
    let imageName: String
    let emoji: String
    let estimatedWeightKg: Double
}

private let allWeighablePterosaurs: [WeighablePterosaurPoolEntry] = AirPterosaurData.allPterosaurs.compactMap { d in
    guard let img = d.imageName,
          let kg = AirPterosaurData.pterosaurEstimatedWeightKgById[d.id] else { return nil }
    return WeighablePterosaurPoolEntry(creatureId: d.id, name: d.name, imageName: img, emoji: d.icon, estimatedWeightKg: kg)
}

// MARK: - Game Configurations

struct WeighGameConfigs {
    /// Fixed config used as template (same id/title/intro); items are ignored when opening — use `weighDinosaurRandomized()` for play.
    static let weighDinosaur = WeighGameConfig(
        id: "weigh-dinosaur",
        title: "Weigh the Dinosaur!",
        introAudio: "game-intro-weigh",
        items: [] // Not used; caller uses weighDinosaurRandomized() for a random set of 9.
    )

    /// Returns randomized items for the given weigh game id (weigh-dinosaur or weigh-pterosaur), or [] for template configs. Used at game start and each new round.
    /// For weigh-dinosaur, pass excludingDinosaurIds (ids already weighed this game) so each round gets 9 new dinosaurs with no repeat use.
    static func randomizedItems(forId id: String, excludingDinosaurIds: Set<Int> = []) -> [WeighableItem] {
        switch id {
        case "weigh-dinosaur": return makeRandomDinosaurItems(excluding: excludingDinosaurIds)
        case "weigh-pterosaur": return makeRandomPterosaurItems(excluding: excludingDinosaurIds)
        case "weigh-marine-reptile": return makeRandomMarineReptileItems(excluding: excludingDinosaurIds)
        default: return []
        }
    }

    /// Returns 9 dinosaurs: one per clade (9 clades), shuffled for random grid order. Excludes ids already used this game.
    static func makeRandomDinosaurItems(excluding alreadyUsedIds: Set<Int> = []) -> [WeighableItem] {
        let pool = LandDinosaurWeighCatalog.allEntries.filter { !alreadyUsedIds.contains($0.stableId) }
        let byClade = Dictionary(grouping: pool) { $0.clade }
        var chosen: [LandDinosaurWeighCatalog.Entry] = []
        for clade in DinoClade.allCases {
            guard let candidates = byClade[clade], !candidates.isEmpty else { continue }
            chosen.append(candidates.randomElement()!)
        }
        while chosen.count < 9 {
            let taken = Set(chosen.map(\.stableId))
            let extras = pool.filter { !taken.contains($0.stableId) }
            guard let one = extras.randomElement() else { break }
            chosen.append(one)
        }
        // Assign ranks by weight order (lightest=1, heaviest=9), then shuffle for random grid display
        let sortedByWeight = chosen.sorted { $0.weightKg < $1.weightKg }
        let rankById = Dictionary(uniqueKeysWithValues: sortedByWeight.enumerated().map { ($0.element.stableId, $0.offset + 1) })
        return chosen.shuffled().map { entry in
            let dino = MatchingGameConfigs.allDinosaurs.first { $0.id == entry.stableId }
            return WeighableItem(
                id: entry.stableId,
                name: entry.displayName,
                imageName: entry.imageAssetName,
                emoji: dino?.icon ?? "🦖",
                weight: rankById[entry.stableId] ?? 1,
                category: "dinosaur"
            )
        }
    }

    /// Returns a config with 9 dinosaurs chosen at random from the pool, ordered by estimated weight.
    /// Pool is reshuffled at the start of each round (view uses randomizedItems(forId:)).
    static func weighDinosaurRandomized() -> WeighGameConfig {
        return WeighGameConfig(
            id: "weigh-dinosaur",
            title: "Weigh the Dinosaur!",
            introAudio: "game-intro-weigh",
            items: makeRandomDinosaurItems()
        )
    }

    /// Template for Weigh the Pterosaur (use weighPterosaurRandomized() for play).
    static let weighPterosaur = WeighGameConfig(
        id: "weigh-pterosaur",
        title: "Weigh the Pterosaur!",
        introAudio: "game-intro-weigh-pterosaur",
        items: []
    )

    /// Count of pterosaurs on the grid (3×3 to match Weigh the Dinosaur).
    private static let weighPterosaurGridCount = 9

    /// Returns 9 pterosaurs: one per `PterosaurGuessGroup` where the pool still has a candidate (same pattern as Weigh the Dinosaur’s `DinoClade` pass), then random extras from the remaining pool until `weighPterosaurGridCount`. Excludes ids already weighed this game when possible.
    static func makeRandomPterosaurItems(excluding alreadyUsedIds: Set<Int> = []) -> [WeighableItem] {
        let candidates = allWeighablePterosaurs.filter { !alreadyUsedIds.contains($0.creatureId) }
        let pool = candidates.isEmpty ? allWeighablePterosaurs : candidates
        let tagged = pool.compactMap { entry -> (WeighablePterosaurPoolEntry, PterosaurGuessGroup)? in
            guard let g = PterosaurGuessGroup.guessGroup(forImageName: entry.imageName) else { return nil }
            return (entry, g)
        }
        let byClade = Dictionary(grouping: tagged, by: { $0.1 }).mapValues { pairs in pairs.map(\.0) }
        var chosen: [WeighablePterosaurPoolEntry] = []
        for clade in PterosaurGuessGroup.allCases {
            guard let groupList = byClade[clade], !groupList.isEmpty else { continue }
            chosen.append(groupList.randomElement()!)
        }
        while chosen.count < weighPterosaurGridCount {
            let extras = pool.filter { e in !chosen.contains(where: { $0.creatureId == e.creatureId }) }
            guard let one = extras.randomElement() else { break }
            chosen.append(one)
        }
        let sortedByWeight = chosen.sorted { $0.estimatedWeightKg < $1.estimatedWeightKg }
        var rank = 0
        var prevKg: Double = -1
        var rankByCreatureId: [Int: Int] = [:]
        for entry in sortedByWeight {
            if entry.estimatedWeightKg > prevKg {
                rank += 1
                prevKg = entry.estimatedWeightKg
            }
            rankByCreatureId[entry.creatureId] = rank
        }
        return chosen.shuffled().map { entry in
            WeighableItem(
                id: entry.creatureId,
                name: entry.name,
                imageName: entry.imageName,
                emoji: entry.emoji,
                weight: rankByCreatureId[entry.creatureId] ?? 1,
                category: "pterosaur"
            )
        }
    }

    /// Returns a config with a random set of pterosaurs for the grid (same count as `weighPterosaurGridCount` when the pool allows).
    /// Pool is reshuffled at the start of each round (view uses randomizedItems(forId:)).
    static func weighPterosaurRandomized() -> WeighGameConfig {
        return WeighGameConfig(
            id: "weigh-pterosaur",
            title: "Weigh the Pterosaur!",
            introAudio: "game-intro-weigh-pterosaur",
            items: makeRandomPterosaurItems()
        )
    }

    /// Template for Weigh the Marine Reptile (use `weighMarineReptileRandomized()` for play).
    static let weighMarineReptile = WeighGameConfig(
        id: "weigh-marine-reptile",
        title: "Weigh the Marine Reptile!",
        introAudio: "game-intro-weigh-marine-reptile",
        items: []
    )

    /// Nine marine creatures: at most one per asset prefix clade (`marine-{clade}-*`). If more than nine clades
    /// have candidates, nine clades are chosen at random at the start of the round. Weights use `MarineReptileWeighCatalog` (kg ranks).
    static func makeRandomMarineReptileItems(excluding alreadyUsedIds: Set<Int> = []) -> [WeighableItem] {
        let pool = MarineReptileWeighCatalog.allEntries.filter { !alreadyUsedIds.contains($0.stableId) }
        guard !pool.isEmpty else { return [] }
        let byClade = Dictionary(grouping: pool, by: { $0.cladeRaw })
        var cladeKeys = Array(byClade.keys).shuffled()
        if cladeKeys.count > 9 {
            cladeKeys = Array(cladeKeys.prefix(9))
        }
        var chosen: [MarineReptileWeighCatalog.Entry] = []
        for clade in cladeKeys {
            if let pick = byClade[clade]?.filter({ !alreadyUsedIds.contains($0.stableId) }).randomElement() {
                chosen.append(pick)
            }
        }
        while chosen.count < 9 {
            let taken = Set(chosen.map(\.stableId))
            let remaining = pool.filter { !taken.contains($0.stableId) }
            guard let extra = remaining.randomElement() else { break }
            chosen.append(extra)
        }
        if chosen.count > 9 {
            chosen = Array(chosen.prefix(9))
        }
        let sortedByWeight = chosen.sorted { $0.weightKg < $1.weightKg }
        let rankById = Dictionary(uniqueKeysWithValues: sortedByWeight.enumerated().map { ($0.element.stableId, $0.offset + 1) })
        return chosen.shuffled().map { e in
            WeighableItem(
                id: e.stableId,
                name: e.displayName,
                imageName: e.imageAssetName,
                emoji: "🌊",
                weight: rankById[e.stableId] ?? 1,
                category: "marine"
            )
        }
    }

    static func weighMarineReptileRandomized() -> WeighGameConfig {
        WeighGameConfig(
            id: "weigh-marine-reptile",
            title: "Weigh the Marine Reptile!",
            introAudio: "game-intro-weigh-marine-reptile",
            items: makeRandomMarineReptileItems()
        )
    }
}

#Preview {
    WeighGameView(isPresented: .constant(true), gameConfig: WeighGameConfigs.weighDinosaurRandomized())
}
