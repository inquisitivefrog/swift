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
// TODO (future): Consider stacking items on the right with heaviest at bottom (tower like Measure the Dinosaur's height stack) to teach relative size/weight when balancing.
// TODO (future): Make additional images 340×70 px for Weigh the Dinosaur to emphasize width as well as weight.

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
    
    @State private var speechManager = SpeechManager()
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
    @State private var showSpeedLines = false
    /// When the lighter dino is sent flying: true = left flew, false = right flew (used for speed lines).
    @State private var lighterFlewFromLeft: Bool? = nil
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

    /// Prefer weigh-dino-{slug} / weigh-marine-* when present; else base creature asset.
    private func weighImageName(for item: WeighableItem) -> String? {
        guard let base = item.imageName else { return nil }
        if gameConfig.id == "weigh-dinosaur" {
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

    /// Scale factor for seesaw image. When both selected: heavier gets full size (1.2), lighter scales down by weight ratio; min 0.55 keeps small dinos visible.
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
                    let t = sqrt(max(ratio, 0.001))
                    return CGFloat(max(0.55, 0.35 + 0.85 * t))
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
            if isGameOver {
                // Full-screen victory (same as MatchingGameView) so the game title stays pinned and visible.
                weighVictoryView
                    .frame(width: safeWidth, height: safeHeight)
            } else {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 32)
                    
                    // Grid: 3 columns, fixed height so all 3 rows are visible (no scroll around grid)
                    VStack(spacing: 6) {
                        VStack(spacing: 4) {
                            Text(gameConfig.title)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                            Text("Round \(roundsCompleted + 1) of \(maxRounds)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 56)
                        VStack(spacing: 6) {
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
                                        isSelected: selectedLeftItem?.id == item.id || selectedRightItem?.id == item.id,
                                        isDisabled: isWeighing || isGameOver || isChooseFirstAudioPlaying || (!introWalkComplete) || (selectedLeftItem != nil && selectedRightItem != nil) || (selectedLeftItem != nil && selectedRightItem == nil && !canSelectSecondDinosaur),
                                        isIntroHighlighted: usesIntroWalkAndFirstPickPrompt && introWalkStep >= 0 && introWalkStep < displayItems.count && displayItems[introWalkStep].id == item.id
                                    ) {
                                        handleItemTap(item)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    .frame(height: 422) // Room for game title + Round label + 3 full rows; compact so seesaw fits on screen
                    .frame(width: safeWidth)
                
                    // Expandable spacer: pushes seesaw toward bottom, ensures no collision with grid
                    Spacer()
                        .frame(minHeight: 36)
                    
                    if isMarineWeighGame {
                        marineBuoyancyArea(safeWidth: safeWidth)
                    } else {
                    // Bottom - Seesaw area (fixed min height so seesaw never slides off screen)
                    let beamW = max(safeWidth * 0.28, 100)
                    let sideMargin: CGFloat = 12
                    let beamTopY: CGFloat = -9       // Beam height 18, center 0 → top at -9
                    let seesawSeatHeight: CGFloat = 12
                    let seatTopY = beamTopY - seesawSeatHeight  // Dinosaur bottom aligns with top of seat (sitting surface)
                    let maxDinoWidth = max(100, safeWidth - 2 * beamW - 2 * sideMargin) // Cap so wide sauropod images fit with margin
                    VStack {
                        Spacer()
                            .frame(minHeight: 10) // Small spacer
                        
                        ZStack {
                            // A-frame support (playground seesaw style)
                            SeesawSupportView()
                                .offset(y: 45)
                            
                            // Beam + seats + dinosaurs rotate as one unit around fulcrum; fulcrum stays fixed
                            ZStack {
                                // Rotating assembly: beam, seats, and dinosaur images tilt together
                                ZStack {
                                    // Beam (arm)
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(LinearGradient(colors: [Color.brown, Color.brown.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                                            .frame(width: beamW, height: 18)
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.brown.opacity(0.6), lineWidth: 1))
                                            .offset(x: -beamW / 2)
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(LinearGradient(colors: [Color.brown, Color.brown.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                                            .frame(width: beamW, height: 18)
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.brown.opacity(0.6), lineWidth: 1))
                                            .offset(x: beamW / 2)
                                    }
                                    // Seats (above beam; center y=-15, height seesawSeatHeight → seat top at beamTopY - seesawSeatHeight; drawn on top so both dinosaur images remain visible)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.brown.opacity(0.9))
                                        .frame(width: 56, height: seesawSeatHeight)
                                        .offset(x: -beamW, y: -15)
                                        .zIndex(10)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.brown.opacity(0.9))
                                        .frame(width: 56, height: seesawSeatHeight)
                                        .offset(x: beamW, y: -15)
                                        .zIndex(10)
                                    
                                    // Left side item (on left seat) — inside rotating assembly so it tilts with seesaw
                                    if let leftItem = selectedLeftItem {
                                        let scale = seesawImageScale(for: leftItem, relativeTo: selectedRightItem)
                                        let idealHeight = 130 * scale
                                        let idealWidth = idealHeight * 2
                                        let rightIdealW = selectedRightItem.map { 130 * seesawImageScale(for: $0, relativeTo: leftItem) * 2 } ?? idealWidth
                                        let maxIdealW = max(idealWidth, rightIdealW)
                                        let scaleFactor = maxIdealW > maxDinoWidth ? maxDinoWidth / maxIdealW : 1.0
                                        let (width, height) = (idealWidth * scaleFactor, idealHeight * scaleFactor)
                                        let baseY = seatTopY - height / 2 // Group is centered in ZStack; offset so bottom lands on seat top
                                        Group {
                                            if let imageName = weighImageName(for: leftItem) {
                                                ZStack(alignment: .bottom) {
                                                    Color.clear.frame(width: width, height: height)
                                                    Image(imageName)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(maxWidth: width, maxHeight: height, alignment: .bottom)
                                                }
                                            } else {
                                                Text(leftItem.emoji)
                                                    .font(.system(size: 80))
                                                    .frame(width: width, height: height)
                                            }
                                        }
                                        .frame(width: width, height: height, alignment: .bottom)
                                        .clipped()
                                        .offset(x: -beamW + leftItemOffsetX, y: leftItemOffset + baseY)
                                        .opacity(leftItemOpacity)
                                        .zIndex(5)
                                        
                                        if showSpeedLines, lighterFlewFromLeft == false, let rightItem = selectedRightItem {
                                            let rightH = 130 * seesawImageScale(for: rightItem, relativeTo: selectedLeftItem) * scaleFactor
                                            SpeedLinesView()
                                                .offset(x: beamW, y: rightItemOffset + (seatTopY - rightH / 2))
                                        }
                                        if showSpeedLines, lighterFlewFromLeft == true, selectedLeftItem != nil {
                                            SpeedLinesView()
                                                .offset(x: -beamW + leftItemOffsetX, y: leftItemOffset + baseY)
                                        }
                                    }
                                    
                                    // Right side item (on right seat) — inside rotating assembly so it tilts with seesaw
                                    if let rightItem = selectedRightItem {
                                        let scale = seesawImageScale(for: rightItem, relativeTo: selectedLeftItem)
                                        let idealHeight = 130 * scale
                                        let idealWidth = idealHeight * 2
                                        let leftIdealW = selectedLeftItem.map { 130 * seesawImageScale(for: $0, relativeTo: rightItem) * 2 } ?? idealWidth
                                        let maxIdealW = max(idealWidth, leftIdealW)
                                        let scaleFactor = maxIdealW > maxDinoWidth ? maxDinoWidth / maxIdealW : 1.0
                                        let (width, height) = (idealWidth * scaleFactor, idealHeight * scaleFactor)
                                        let baseY = seatTopY - height / 2 // Group is centered in ZStack; offset so bottom lands on seat top
                                        Group {
                                            if let imageName = weighImageName(for: rightItem) {
                                                ZStack(alignment: .bottom) {
                                                    Color.clear.frame(width: width, height: height)
                                                    Image(imageName)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(maxWidth: width, maxHeight: height, alignment: .bottom)
                                                }
                                            } else {
                                                Text(rightItem.emoji)
                                                    .font(.system(size: 80))
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
                                .offset(y: 28)
                                // Fulcrum (fixed, does not rotate)
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 32, height: 32)
                                    .overlay(Circle().stroke(Color.brown, lineWidth: 2))
                                    .offset(y: 28)
                            }
                        }
                    .frame(width: max(1, safeWidth - 2 * sideMargin), height: 260) // Inset with margin so dinosaurs don't truncate at screen edge
                    .clipped() // Keep rotated beam from affecting layout
                        
                        Spacer()
                            .frame(minHeight: 8)
                    }
                    .frame(minHeight: 270)
                    .frame(width: safeWidth)
                    }
                }
            }
            .frame(minHeight: safeHeight)
            .frame(maxHeight: safeHeight)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    isPresented = false
                }
            }
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
    private func marineBuoyancyArea(safeWidth: CGFloat) -> some View {
        let sideMargin: CGFloat = 12
        let podOffset = max(safeWidth * 0.24, 88)
        let maxCreatureWidth = max(110, safeWidth * 0.28)
        // Start lower in the water so the lighter side can rise without clipping at the top.
        let plateBaseY: CGFloat = 64
        let waterlineY: CGFloat = -8
        let leftCreatureSize = selectedLeftItem.map { marineCreatureSize(item: $0, other: selectedRightItem, maxWidth: maxCreatureWidth) }
        let rightCreatureSize = selectedRightItem.map { marineCreatureSize(item: $0, other: selectedLeftItem, maxWidth: maxCreatureWidth) }
        let seatTopY = plateBaseY - 7
        let defaultCreatureHeight: CGFloat = 130
        // Keep creature bottoms pinned to seat tops even when scaled down.
        let leftCreatureCenterY = seatTopY + leftItemOffset - ((leftCreatureSize?.height ?? defaultCreatureHeight) / 2)
        let rightCreatureCenterY = seatTopY + rightItemOffset - ((rightCreatureSize?.height ?? defaultCreatureHeight) / 2)
        let leftCreatureTopY = leftCreatureCenterY - ((leftCreatureSize?.height ?? defaultCreatureHeight) / 2)
        let rightCreatureTopY = rightCreatureCenterY - ((rightCreatureSize?.height ?? defaultCreatureHeight) / 2)
        let leftRigX = -podOffset - 22
        let rightRigX = podOffset + 22
        let leftPodY = min(plateBaseY - 40 + leftItemOffset * 0.22, leftCreatureTopY - 34)
        let rightPodY = min(plateBaseY - 40 + rightItemOffset * 0.22, rightCreatureTopY - 34)
        let leftRopeBottomY = plateBaseY - 1 + leftItemOffset
        let rightRopeBottomY = plateBaseY - 1 + rightItemOffset
        let leftRopeLength = max(24, leftRopeBottomY - leftPodY - 18)
        let rightRopeLength = max(24, rightRopeBottomY - rightPodY - 18)
        let leftRopeY = leftPodY + 18 + leftRopeLength / 2
        let rightRopeY = rightPodY + 18 + rightRopeLength / 2
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
                .frame(height: 248)

                Path { p in
                    p.move(to: CGPoint(x: -safeWidth * 0.45, y: waterlineY))
                    p.addCurve(
                        to: CGPoint(x: safeWidth * 0.45, y: waterlineY),
                        control1: CGPoint(x: -safeWidth * 0.20, y: waterlineY - 8),
                        control2: CGPoint(x: safeWidth * 0.20, y: waterlineY + 8)
                    )
                }
                .stroke(Color.white.opacity(0.7), lineWidth: 2)

                Capsule()
                    .fill(LinearGradient(colors: [Color.gray.opacity(0.85), Color.gray.opacity(0.65)], startPoint: .top, endPoint: .bottom))
                    .frame(width: podOffset * 2 + 120, height: 12)
                    .offset(y: plateBaseY - 22)
                    .rotationEffect(.degrees(seesawAngle * 0.35))

                marineBuoyancyPod
                    .offset(x: leftRigX, y: leftPodY)
                marineBuoyancyPod
                    .offset(x: rightRigX, y: rightPodY)

                Capsule().fill(Color.white.opacity(0.35)).frame(width: 4, height: leftRopeLength).offset(x: leftRigX, y: leftRopeY)
                Capsule().fill(Color.white.opacity(0.35)).frame(width: 4, height: rightRopeLength).offset(x: rightRigX, y: rightRopeY)

                RoundedRectangle(cornerRadius: 8).fill(Color.brown.opacity(0.85)).frame(width: 72, height: 14).offset(x: -podOffset, y: plateBaseY + leftItemOffset)
                RoundedRectangle(cornerRadius: 8).fill(Color.brown.opacity(0.85)).frame(width: 72, height: 14).offset(x: podOffset, y: plateBaseY + rightItemOffset)

                if let leftItem = selectedLeftItem {
                    marineCreatureImage(item: leftItem, other: selectedRightItem, maxWidth: maxCreatureWidth)
                        .offset(x: -podOffset + leftItemOffsetX, y: leftCreatureCenterY)
                        .opacity(leftItemOpacity)
                }
                if let rightItem = selectedRightItem {
                    marineCreatureImage(item: rightItem, other: selectedLeftItem, maxWidth: maxCreatureWidth)
                        .offset(x: podOffset + rightItemOffsetX, y: rightCreatureCenterY)
                        .opacity(rightItemOpacity)
                }
            }
            .frame(width: max(1, safeWidth - 2 * sideMargin), height: 260)
            .clipped()
            Spacer().frame(minHeight: 8)
        }
        .frame(minHeight: 270)
        .frame(width: safeWidth)
    }

    private var marineBuoyancyPod: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Color.white.opacity(0.95), Color.cyan.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(Color.white.opacity(0.75), lineWidth: 2)
            Circle().fill(Color.white.opacity(0.35)).frame(width: 16, height: 16).offset(x: -8, y: -7)
        }
        .frame(width: 38, height: 38)
    }

    private func marineCreatureSize(item: WeighableItem, other: WeighableItem?, maxWidth: CGFloat) -> CGSize {
        let scale = seesawImageScale(for: item, relativeTo: other)
        // Slightly higher cap so heavy-vs-light differences read more clearly.
        let height = min(130 * scale, 130)
        let width = min(height * 1.8, maxWidth)
        return CGSize(width: width, height: height)
    }

    @ViewBuilder
    private func marineCreatureImage(item: WeighableItem, other: WeighableItem?, maxWidth: CGFloat) -> some View {
        let size = marineCreatureSize(item: item, other: other, maxWidth: maxWidth)
        if let imageName = weighImageName(for: item) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size.width, height: size.height, alignment: .bottom)
        } else {
            Text(item.emoji)
                .font(.system(size: 62))
                .frame(width: size.width, height: size.height)
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
            let heavier = max(leftKg, rightKg)
            let lighter = min(leftKg, rightKg)
            let ratio = heavier > 0 ? lighter / heavier : 1
            let isNearlySame = ratio >= 0.85
            // "Massive" mismatch: lighter is under 40% of heavier.
            let isMassiveDifference = ratio < 0.40
            let weightDiff = leftKg == rightKg ? 0 : (leftKg > rightKg ? 1 : -1)
            return (weightDiff, isNearlySame, isMassiveDifference)
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
                    showSpeedLines = false
                    lighterFlewFromLeft = nil
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
                    lighterFlewFromLeft = nil
                    seesawAngle = isMassiveDifference ? -20 : -14
                    leftItemOffset = 0 // No vertical fall; dinosaurs stay on seats
                    rightItemOffset = 0 // No vertical offset; slide follows the beam
                    rightItemOffsetX = -80 // Slides inward along the arm toward fulcrum (beam is horizontal in assembly coords; rotation makes it appear along the tilt)
                    showSpeedLines = false
                } else {
                    // Right heavy, left light: left dino flies in parabola up and to the right
                    lighterFlewFromLeft = true
                    seesawAngle = isMassiveDifference ? 22 : 15
                    rightItemOffset = 0 // No vertical fall; right dino stays on seat
                    leftItemOffset = isMassiveDifference ? -220 : -150
                    leftItemOffsetX = isMassiveDifference ? 140 : 100 // Parabola arc to the right
                    leftItemOpacity = 0
                    showSpeedLines = true
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

    /// Marine weigh keeps title + recap visible above the success card (Name That style).
    private var weighVictoryKeepsRecapDuringSuccess: Bool {
        gameConfig.id == "weigh-marine-reptile"
    }

    private var weighVictorySuccessImageSide: CGFloat {
        weighVictoryKeepsRecapDuringSuccess
            ? 180
            : GameCatalogImageMetrics.nameThatVictorySuccessImageSide
    }

    /// Victory screen: same as Dino Diets / Match the Dinosaur — top half list (highlight + name audio), bottom half success image (centered, no wrapper), then good-job + crowd and dismiss.
    private var weighVictoryView: some View {
        VictorySplitColumnView(
            listScrollHeight: victoryListVisibleHeight,
            showSuccessPhase: endSequenceStep == 2,
            endHighlightIndex: endHighlightIndex,
            gameTitle: gameConfig.title,
            hideGameTitleDuringSuccessPhase: !weighVictoryKeepsRecapDuringSuccess,
            collapseRecapListDuringSuccessPhase: !weighVictoryKeepsRecapDuringSuccess,
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
            showSpeedLines = false
            lighterFlewFromLeft = nil
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
    let isSelected: Bool
    let isDisabled: Bool
    /// When true, show accent border for intro walk (e.g. weigh-dinosaur introducing each dinosaur).
    var isIntroHighlighted: Bool = false
    let onTap: () -> Void
    
    /// Grid cell image size; compact so seesaw fits on screen.
    private let imageSize: CGFloat = 96
    
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
                        .font(.system(size: 60))
                        .frame(width: imageSize, height: imageSize)
                }
                Text(item.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    // Keep all grid cards the same height: shrink long names instead of wrapping to two lines.
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .allowsTightening(true)
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

// A-frame support: legs meet at the pivot point (top) and diverge at the base, so the beam is clearly free to tip.
struct SeesawSupportView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            // Left leg: pivots from top center, bottom sweeps left
            Rectangle()
                .fill(Color.brown.opacity(0.9))
                .frame(width: 12, height: 58)
                .rotationEffect(.degrees(-22), anchor: UnitPoint(x: 0.5, y: 0))
            // Right leg: pivots from top center, bottom sweeps right
            Rectangle()
                .fill(Color.brown.opacity(0.9))
                .frame(width: 12, height: 58)
                .rotationEffect(.degrees(22), anchor: UnitPoint(x: 0.5, y: 0))
            // Base bar (wider for stability)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.brown)
                .frame(width: 140, height: 12)
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
        let cladeById = LandDinosaurCladeCatalog.cladeByCreatureId
        let pool = MatchingGameConfigs.allDinosaurs.filter { d in
            d.imageName != nil && d.imageName!.hasPrefix("dino-") && MatchingGameConfigs.dinosaurEstimatedWeightKgById[d.id] != nil && !alreadyUsedIds.contains(d.id)
        }
        let byClade = Dictionary(grouping: pool) { cladeById[$0.id] ?? .theropod }
        var chosen: [Dinosaur] = []
        for clade in DinoClade.allCases {
            guard let candidates = byClade[clade], !candidates.isEmpty else { continue }
            chosen.append(candidates.randomElement()!)
        }
        while chosen.count < 9 {
            let extras = pool.filter { d in !chosen.contains(where: { $0.id == d.id }) }
            guard let one = extras.randomElement() else { break }
            chosen.append(one)
        }
        // Assign ranks by weight order (lightest=1, heaviest=9), then shuffle for random grid display
        let sortedByWeight = chosen.sorted { (MatchingGameConfigs.dinosaurEstimatedWeightKgById[$0.id] ?? 0) < (MatchingGameConfigs.dinosaurEstimatedWeightKgById[$1.id] ?? 0) }
        let rankById = Dictionary(uniqueKeysWithValues: sortedByWeight.enumerated().map { ($0.element.id, $0.offset + 1) })
        return chosen.shuffled().map { d in
            WeighableItem(
                id: d.id,
                name: d.name,
                imageName: d.imageName,
                emoji: d.icon,
                weight: rankById[d.id] ?? 1,
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
