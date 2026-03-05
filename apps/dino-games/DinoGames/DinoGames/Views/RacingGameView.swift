//
//  RacingGameView.swift
//  DinoGames
//
//  Racing Dinosaurs!: Player picks two dinosaurs from four per period; they race on an oval track.
//  Dinosaur racing uses dino-racer-* and dino-winner-race-* imagesets (ptero-racer-*, etc. for future games).
//

import SwiftUI
import AVFoundation

// MARK: - Data Models

struct RacingRacer: Identifiable {
    let id: Int
    let name: String
    let icon: String // Emoji fallback when imageset missing
    let speed: Double // Estimated top speed (mph) for deterministic winner
    /// When set (e.g. for pterosaurs), used for fallback image and name audio; nil = use prefix-based fallback (dino).
    let fallbackImageName: String?

    /// Slug for asset names: lowercase, spaces → hyphens (e.g. "T-Rex" → "t-rex").
    var imageSlug: String {
        name.lowercased().replacingOccurrences(of: " ", with: "-")
    }
    /// Racer image name for a given asset prefix (e.g. "dino" → dino-racer-*, "ptero" → ptero-racer-*). T-Rex special case for dino only.
    func racerImageName(prefix: String) -> String {
        if prefix == "dino" && imageSlug == "t-rex" { return "dino-racer-trex" }
        return "\(prefix)-racer-\(imageSlug)"
    }
    /// Winner image name for a given asset prefix.
    func winnerImageName(prefix: String) -> String {
        if prefix == "dino" && imageSlug == "t-rex" { return "dino-winner-race-trex" }
        return "\(prefix)-winner-race-\(imageSlug)"
    }
    /// Fallback image/audio name when racer/winner assets are missing. Uses fallbackImageName if set, else prefix-based (dino: dino-{slug}).
    func effectiveFallbackImageName(prefix: String) -> String {
        if let f = fallbackImageName { return f }
        let dinoSlug = imageSlug.replacingOccurrences(of: "-", with: "")
        return "dino-\(dinoSlug)"
    }
}

/// Returns image name to use for a racer: {prefix}-racer-{slug} if present, else fallback (e.g. dino-trex, ptero-pteranodon).
private func racerDisplayImageName(for racer: RacingRacer, config: RacingGameConfig) -> String? {
    let prefix = config.assetPrefix
    if UIImage(named: racer.racerImageName(prefix: prefix)) != nil { return racer.racerImageName(prefix: prefix) }
    let fallback = racer.effectiveFallbackImageName(prefix: prefix)
    if UIImage(named: fallback) != nil { return fallback }
    return nil
}

/// Returns image name for winner view: {prefix}-winner-race-{slug} if present, else same fallback as racer.
private func winnerDisplayImageName(for racer: RacingRacer, config: RacingGameConfig) -> String? {
    let prefix = config.assetPrefix
    if UIImage(named: racer.winnerImageName(prefix: prefix)) != nil { return racer.winnerImageName(prefix: prefix) }
    return racerDisplayImageName(for: racer, config: config)
}

struct RacingGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let assetPrefix: String // "dino" or "ptero" for racer/winner/referee image names
    let racers: [RacingRacer] // 4 racers per game
}

// MARK: - Main View

private let tickInterval: TimeInterval = 1.0
private let stepPerTick: Double = 0.1 // Progress per tick; faster dino gains more (speed/maxSpeed) * stepPerTick

struct RacingGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: RacingGameConfig

    /// When gameConfig has empty racers (racing-dinosaurs needs period), we show period selection first; effectiveConfig updates when period is chosen.
    @State private var effectiveConfig: RacingGameConfig?

    @State private var speechManager = SpeechManager()
    @State private var selectedLane1: RacingRacer?
    @State private var selectedLane2: RacingRacer?
    /// Second racer chosen but name audio still playing; we don't transition to pre-race until audio finishes.
    @State private var pendingRacer2: RacingRacer?
    @State private var canSelectSecond = false
    @State private var isRacing = false
    @State private var progress1: Double = 0
    @State private var progress2: Double = 0
    @State private var raceTimer: Timer?
    @State private var winner: RacingRacer?
    @State private var isAudioPlaying = false
    /// Pre-race: 0 = outside track dino (name + outside-track audio), 1 = inside track dino (name + inside-track audio), 2 = referee + ready-set + whistle
    @State private var preRaceStep: Int? = nil
    /// Post-race: "referee" = dino-racer-referee-finish image, "winner" = dino-winner-race-{slug}
    @State private var postRaceStep: String? = nil
    @State private var hasPlayedStartingGun = false
    @State private var hasPlayedWeHaveAWinner = false
    /// When non-nil, show large image + name and play racer name audio; on finish apply selection and return to grid.
    @State private var showingExpandedRacer: RacingRacer? = nil
    @State private var hasPlayedFirstRacerPrompt = false

    /// Config used for play: either period-specific (when chosen) or initial (when racers already set).
    private var config: RacingGameConfig {
        effectiveConfig ?? gameConfig
    }

    /// True when we need to show period selection first (racing-dinosaurs with empty racers).
    private var needsPeriodSelection: Bool {
        gameConfig.racers.isEmpty && gameConfig.id == "racing-dinosaurs"
    }

    private var showSelection: Bool {
        selectedLane1 == nil || ((selectedLane2 == nil && pendingRacer2 == nil) && !isRacing && preRaceStep == nil)
    }
    private var showPreRace: Bool { preRaceStep != nil }
    private var showRace: Bool {
        selectedLane1 != nil && selectedLane2 != nil && isRacing && winner == nil && preRaceStep == nil
    }
    private var showRefereeFinish: Bool { postRaceStep == "referee" }
    private var showWinner: Bool { winner != nil && postRaceStep == "winner" }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 16) {
                    Text(config.title)
                        .font(.title2)
                        .padding(.top, 8)
                    
                    if needsPeriodSelection && effectiveConfig == nil {
                        embeddedPeriodSelectionView(geometry: geometry)
                    } else if showSelection {
                        if let racer = showingExpandedRacer {
                            expandedRacerView(geometry: geometry, racer: racer)
                        } else {
                            selectionGrid(geometry: geometry)
                                .onAppear {
                                    if selectedLane1 == nil && !hasPlayedFirstRacerPrompt {
                                        hasPlayedFirstRacerPrompt = true
                                        let firstPrompt = config.assetPrefix == "ptero" ? "game-racer-choose-your-first-pterosaur-to-race" : "game-racer-choose-your-first-dinosaur-to-race"
                                        speechManager.speak(firstPrompt)
                                    }
                                }
                        }
                    } else if showPreRace, let r1 = selectedLane1, let r2 = selectedLane2 {
                        preRaceView(geometry: geometry, racer1: r1, racer2: r2)
                    } else if showRace {
                        raceTrack(geometry: geometry)
                    } else if showRefereeFinish {
                        refereeFinishView(geometry: geometry)
                    } else if showWinner, let w = winner {
                        winnerView(winner: w)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                stopRace()
                speechManager.stopCurrentAudio()
            }
        }
    }

    /// Period selection shown when gameConfig has empty racers (racing-dinosaurs from catalog). No sheet dismiss/present.
    private func embeddedPeriodSelectionView(geometry: GeometryProxy) -> some View {
        RacingPeriodSelectionView(isPresented: $isPresented, onSelectPeriod: { config in
            effectiveConfig = config
        }, embedMode: true)
    }
    
    // MARK: - Selection (2×4 grid, emoji only)
    
    private func selectionGrid(geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            if selectedLane1 == nil {
                Text("Choose your first dinosaur to race")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if selectedLane2 == nil && pendingRacer2 == nil {
                Text("Choose your second dinosaur to race")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            VStack(spacing: 10) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(Array(config.racers.dropFirst(row * 2).prefix(2))) { racer in
                            RacingRacerCard(
                                racer: racer,
                                gameConfig: config,
                                isSelected: selectedLane1?.id == racer.id || selectedLane2?.id == racer.id || pendingRacer2?.id == racer.id,
                                isDisabled: (selectedLane1 != nil && selectedLane2 == nil && pendingRacer2 == nil && !canSelectSecond) || (selectedLane1 != nil && (selectedLane2 != nil || pendingRacer2 != nil))
                            ) {
                                handleRacerTap(racer)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 15)
        }
        .padding()
    }
    
    private func handleRacerTap(_ racer: RacingRacer) {
        if selectedLane1 == nil {
            showingExpandedRacer = racer
            canSelectSecond = false
            speechManager.onAudioFinished = {
                Task { @MainActor in
                    self.speechManager.onAudioFinished = nil
                    self.showingExpandedRacer = nil
                    self.selectedLane1 = racer
                    self.canSelectSecond = true
                    let secondPrompt = self.config.assetPrefix == "ptero" ? "game-racer-choose-your-second-pterosaur-to-race" : "game-racer-choose-your-second-dinosaur-to-race"
                    self.speechManager.speak(secondPrompt)
                }
            }
            speechManager.speak(racer.name)
        } else if selectedLane2 == nil && pendingRacer2 == nil && selectedLane1?.id != racer.id && canSelectSecond {
            showingExpandedRacer = racer
            canSelectSecond = false
            speechManager.onAudioFinished = {
                Task { @MainActor in
                    self.speechManager.onAudioFinished = nil
                    self.showingExpandedRacer = nil
                    self.selectedLane2 = racer
                    self.beginPreRaceSequence()
                }
            }
            speechManager.speak(racer.name)
        }
    }

    /// Temporary large view: racer image + full name below; plays racer name audio, then on finish caller returns to grid.
    private func expandedRacerView(geometry: GeometryProxy, racer: RacingRacer) -> some View {
        let size = min(geometry.size.width, geometry.size.height) * 0.45
        return VStack(spacing: 20) {
            if let imageName = racerDisplayImageName(for: racer, config: config) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Text(racer.icon)
                    .font(.system(size: size * 0.8))
            }
            Text(racer.name)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Pre-race (racer1 + outside-track audio → racer2 + inside-track audio → referee + ready-set → starting-whistle → track)

    private func beginPreRaceSequence() {
        progress1 = 0
        progress2 = 0
        preRaceStep = 0
    }

    private func preRaceView(geometry: GeometryProxy, racer1: RacingRacer, racer2: RacingRacer) -> some View {
        let step = preRaceStep ?? 0
        return Group {
            if step == 0 {
                racerImageFullView(racer: racer1, size: min(geometry.size.width, geometry.size.height) * 0.5)
                    .onAppear {
                        // Display and announce outside track dinosaur: name then "on the outside track"
                        speechManager.onAudioFinished = {
                            Task { @MainActor in
                                self.speechManager.onAudioFinished = nil
                                self.speechManager.onAudioFinished = {
                                    Task { @MainActor in
                                        self.speechManager.onAudioFinished = nil
                                        self.preRaceStep = 1
                                    }
                                }
                                if let url = self.speechManager.urlForAudio(key: "game-racing-outside-track") {
                                    self.speechManager.playAudioFile(url: url)
                                } else {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        self.preRaceStep = 1
                                    }
                                }
                            }
                        }
                        speechManager.speak(audioKey: racer1.effectiveFallbackImageName(prefix: config.assetPrefix), fallbackText: racer1.name, chainDelay: true)
                    }
            } else if step == 1 {
                racerImageFullView(racer: racer2, size: min(geometry.size.width, geometry.size.height) * 0.5)
                    .onAppear {
                        // Display and announce inside track dinosaur: name then "on the inside track"
                        speechManager.onAudioFinished = {
                            Task { @MainActor in
                                self.speechManager.onAudioFinished = nil
                                self.speechManager.onAudioFinished = {
                                    Task { @MainActor in
                                        self.speechManager.onAudioFinished = nil
                                        self.preRaceStep = 2
                                    }
                                }
                                if let url = self.speechManager.urlForAudio(key: "game-racing-inside-track") {
                                    self.speechManager.playAudioFile(url: url)
                                } else {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        self.preRaceStep = 2
                                    }
                                }
                            }
                        }
                        speechManager.speak(audioKey: racer2.effectiveFallbackImageName(prefix: config.assetPrefix), fallbackText: racer2.name, chainDelay: true)
                    }
            } else {
                Group {
                    if config.assetPrefix == "ptero" {
                        refereeImageView(ImageAssetCache.imageExists(named: "game-referee-start") ? "game-referee-start" : "\(config.assetPrefix)-racer-referee-start")
                    } else {
                        preRaceRefereeTrackView(geometry: geometry, racer1: racer1, racer2: racer2)
                    }
                }
                    .onAppear {
                        guard !hasPlayedStartingGun else { return }
                        hasPlayedStartingGun = true
                        func playWhistleThenRace() {
                            Task { @MainActor in
                                self.speechManager.speak("starting-whistle")
                            }
                            // Start race 0.35s after whistle begins (whistle continues in background)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                self.speechManager.onAudioFinished = nil
                                self.preRaceStep = nil
                                self.isRacing = true
                                self.fireRaceTimer(r1: racer1, r2: racer2)
                            }
                        }
                        if let url = speechManager.urlForAudio(key: "game-racing-ready-set") {
                            speechManager.onAudioFinished = {
                                Task { @MainActor in
                                    self.speechManager.onAudioFinished = nil
                                    playWhistleThenRace()
                                }
                            }
                            speechManager.playAudioFile(url: url)
                        } else {
                            playWhistleThenRace()
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func racerImageFullView(racer: RacingRacer, size: CGFloat) -> some View {
        Group {
            if let imageName = racerDisplayImageName(for: racer, config: config) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Text(racer.icon)
                    .font(.system(size: size * 0.8))
            }
        }
    }

    /// Track with dinosaurs at start and referee just outside the outer lane. Referee stays until race starts.
    private func preRaceRefereeTrackView(geometry: GeometryProxy, racer1: RacingRacer, racer2: RacingRacer) -> some View {
        let padding: CGFloat = 24
        let trackInset: CGFloat = 44
        let ovalWidth = max(trackInset * 2 + 4, geometry.size.width - padding * 2)
        let ovalHeight = max(120, geometry.size.height - 140)
        let racerSize: CGFloat = 48
        let cornerRadius = min(min(ovalWidth, ovalHeight) * 0.18, min(ovalWidth, ovalHeight) / 4)
        let innerW = ovalWidth - trackInset * 2
        let innerH = ovalHeight - trackInset * 2
        let innerCornerRadius = max(0, cornerRadius - trackInset / 2)
        let refereeSize: CGFloat = 64
        // Referee-start on inner field (infield) ahead of the two racers so they can see him when he blows the whistle
        let refereeStartX = ovalWidth / 2 + 24
        let refereeStartY = ovalHeight - refereeSize - 16
        let outerPath = RoundedRectangle(cornerRadius: cornerRadius).path(in: CGRect(x: 0, y: 0, width: ovalWidth, height: ovalHeight))
        let innerPath = RoundedRectangle(cornerRadius: innerCornerRadius).path(in: CGRect(x: 0, y: 0, width: innerW, height: innerH))
        let outerStart = ovalPathStartOffset(width: ovalWidth, height: ovalHeight)
        let innerStart = ovalPathStartOffset(width: innerW, height: innerH)
        let pt1Outer = pointOnRoundedRect(progress: outerStart, width: ovalWidth, height: ovalHeight)
        let pt2Outer = pointOnRoundedRect(progress: outerStart, width: ovalWidth, height: ovalHeight)
        let pt1InnerRaw = pointOnRoundedRect(progress: innerStart, width: innerW, height: innerH)
        let pt2InnerRaw = pointOnRoundedRect(progress: innerStart, width: innerW, height: innerH)
        let pt1Inner = CGPoint(x: pt1InnerRaw.x + trackInset, y: pt1InnerRaw.y + trackInset)
        let pt2Inner = CGPoint(x: pt2InnerRaw.x + trackInset, y: pt2InnerRaw.y + trackInset)
        let racer1OnInner = racer1.speed <= racer2.speed
        let pos1 = racer1OnInner ? pt1Inner : pt1Outer
        let pos2 = racer1OnInner ? pt2Outer : pt2Inner
        let half = racerSize / 2
        let finishLineWidth: CGFloat = 4
        let finishLineRowHeight: CGFloat = 10
        let finishLineX = ovalWidth / 2 - finishLineWidth / 2
        return VStack(spacing: 8) {
            Text("Get set!")
                .font(.headline)
            ZStack(alignment: .topLeading) {
                outerPath
                    .stroke(Color.gray.opacity(0.5), lineWidth: 6)
                    .frame(width: ovalWidth, height: ovalHeight)
                innerPath
                    .stroke(Color.gray.opacity(0.35), lineWidth: 6)
                    .frame(width: innerW, height: innerH)
                    .offset(x: trackInset, y: trackInset)
                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: finishLineWidth, height: finishLineRowHeight)
                    .offset(x: finishLineX, y: ovalHeight - finishLineRowHeight)
                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: finishLineWidth, height: finishLineRowHeight)
                    .offset(x: finishLineX, y: trackInset + innerH - finishLineRowHeight)
                racerView(racer: racer1, size: racerSize)
                    .offset(x: pos1.x - half, y: pos1.y - half)
                racerView(racer: racer2, size: racerSize)
                    .offset(x: pos2.x - half, y: pos2.y - half)
                refereeImageViewSmall(ImageAssetCache.imageExists(named: "game-referee-start") ? "game-referee-start" : "\(config.assetPrefix)-racer-referee-start", size: refereeSize)
                    .offset(x: refereeStartX, y: refereeStartY)
            }
            .frame(width: ovalWidth, height: ovalHeight)
        }
        .padding(.horizontal, padding)
    }

    private func refereeImageViewSmall(_ imageName: String, size: CGFloat) -> some View {
        Group {
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Text("🏁")
                    .font(.system(size: size * 0.6))
            }
        }
        .frame(width: size, height: size)
    }

    private func refereeImageView(_ imageName: String) -> some View {
        Group {
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 280, maxHeight: 280)
            } else {
                Text("🏁")
                    .font(.system(size: 120))
            }
        }
    }

    private func refereeFinishView(geometry: GeometryProxy) -> some View {
        Group {
            // Use large referee-finish image when available (both dino and ptero) so both paleontologist images are prominently displayed
            if UIImage(named: "game-referee-finish") != nil {
                refereeImageView("game-referee-finish")
            } else if UIImage(named: "\(config.assetPrefix)-racer-referee-finish") != nil {
                refereeImageView("\(config.assetPrefix)-racer-referee-finish")
            } else {
                refereeFinishTrackView(geometry: geometry)
            }
        }
            .onAppear {
                guard !hasPlayedWeHaveAWinner else { return }
                hasPlayedWeHaveAWinner = true
                // Show referee image for 2 seconds, then show winner view (with crowd-cheering + winner name audio)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.postRaceStep = "winner"
                }
            }
    }

    /// Track with dinosaurs at finish and referee-finish on grass ahead of the finish line.
    private func refereeFinishTrackView(geometry: GeometryProxy) -> some View {
        guard let r1 = selectedLane1, let r2 = selectedLane2 else { return AnyView(EmptyView()) }
        let cfg = config
        let padding: CGFloat = 24
        let trackInset: CGFloat = 44
        let ovalWidth = max(trackInset * 2 + 4, geometry.size.width - padding * 2)
        let ovalHeight = max(120, geometry.size.height - 140)
        let racerSize: CGFloat = 48
        let cornerRadius = min(min(ovalWidth, ovalHeight) * 0.18, min(ovalWidth, ovalHeight) / 4)
        let innerW = ovalWidth - trackInset * 2
        let innerH = ovalHeight - trackInset * 2
        let innerCornerRadius = max(0, cornerRadius - trackInset / 2)
        let refereeSize: CGFloat = 64
        let outerPath = RoundedRectangle(cornerRadius: cornerRadius).path(in: CGRect(x: 0, y: 0, width: ovalWidth, height: ovalHeight))
        let innerPath = RoundedRectangle(cornerRadius: innerCornerRadius).path(in: CGRect(x: 0, y: 0, width: innerW, height: innerH))
        let pt1Outer = pointOnRoundedRect(progress: 1.0, width: ovalWidth, height: ovalHeight)
        let pt2Outer = pointOnRoundedRect(progress: 1.0, width: ovalWidth, height: ovalHeight)
        let pt1InnerRaw = pointOnRoundedRect(progress: 1.0, width: innerW, height: innerH)
        let pt2InnerRaw = pointOnRoundedRect(progress: 1.0, width: innerW, height: innerH)
        let pt1Inner = CGPoint(x: pt1InnerRaw.x + trackInset, y: pt1InnerRaw.y + trackInset)
        let pt2Inner = CGPoint(x: pt2InnerRaw.x + trackInset, y: pt2InnerRaw.y + trackInset)
        let racer1OnInner = r1.speed <= r2.speed
        let pos1 = racer1OnInner ? pt1Inner : pt1Outer
        let pos2 = racer1OnInner ? pt2Outer : pt2Inner
        let half = racerSize / 2
        let finishLineWidth: CGFloat = 4
        let finishLineRowHeight: CGFloat = 10
        let finishLineX = ovalWidth / 2 - finishLineWidth / 2
        // Referee-finish on inner field just past the finish line
        let refereeFinishX = ovalWidth / 2 + 24
        let refereeFinishY = ovalHeight - refereeSize - 16
        return AnyView(VStack(spacing: 8) {
            Text("We have a winner!")
                .font(.headline)
            ZStack(alignment: .topLeading) {
                outerPath
                    .stroke(Color.gray.opacity(0.5), lineWidth: 6)
                    .frame(width: ovalWidth, height: ovalHeight)
                innerPath
                    .stroke(Color.gray.opacity(0.35), lineWidth: 6)
                    .frame(width: innerW, height: innerH)
                    .offset(x: trackInset, y: trackInset)
                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: finishLineWidth, height: finishLineRowHeight)
                    .offset(x: finishLineX, y: ovalHeight - finishLineRowHeight)
                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: finishLineWidth, height: finishLineRowHeight)
                    .offset(x: finishLineX, y: trackInset + innerH - finishLineRowHeight)
                racerView(racer: r1, size: racerSize)
                    .offset(x: pos1.x - half, y: pos1.y - half)
                racerView(racer: r2, size: racerSize)
                    .offset(x: pos2.x - half, y: pos2.y - half)
                refereeImageViewSmall(UIImage(named: "game-referee-finish") != nil ? "game-referee-finish" : "\(cfg.assetPrefix)-racer-referee-finish", size: refereeSize)
                    .offset(x: refereeFinishX, y: refereeFinishY)
            }
            .frame(width: ovalWidth, height: ovalHeight)
        }
        .padding(.horizontal, padding))
    }
    
    // MARK: - Race (oval for dinosaurs; airport A→B→C→D for pterosaurs)

    private func raceTrack(geometry: GeometryProxy) -> some View {
        guard let r1 = selectedLane1, let r2 = selectedLane2 else { return AnyView(EmptyView()) }
        if config.assetPrefix == "ptero" {
            return AnyView(airportTrackView(geometry: geometry, progress1: progress1, progress2: progress2, racer1: r1, racer2: r2))
        }
        return AnyView(ovalTrackView(geometry: geometry, progress1: progress1, progress2: progress2, racer1: r1, racer2: r2))
    }

    /// Airport course for pterosaurs: A (left) → B (diagonal up, top-right) → C (straight down, bottom-right) → D (diagonal up, top-left) → A.
    /// Returns point on path for progress in [0, 1]. inset > 0 gives inner (shorter) path.
    private func pointOnAirportCourse(progress: Double, width: CGFloat, height: CGFloat, inset: CGFloat = 0) -> CGPoint {
        let p = max(0, min(1, progress))
        let m = 24 + inset
        let w = width
        let h = height
        let A = CGPoint(x: m, y: h - m)
        let B = CGPoint(x: w - m, y: m)
        let C = CGPoint(x: w - m, y: h - m)
        let D = CGPoint(x: m, y: m)
        func len(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            hypot(b.x - a.x, b.y - a.y)
        }
        let L_AB = len(A, B)
        let L_BC = len(B, C)
        let L_CD = len(C, D)
        let L_DA = len(D, A)
        let total = L_AB + L_BC + L_CD + L_DA
        let d = CGFloat(p) * total
        func lerp(_ a: CGPoint, _ b: CGPoint, t: CGFloat) -> CGPoint {
            CGPoint(x: a.x + t * (b.x - a.x), y: a.y + t * (b.y - a.y))
        }
        if d < L_AB { return lerp(A, B, t: d / L_AB) }
        let d2 = d - L_AB
        if d2 < L_BC { return lerp(B, C, t: d2 / L_BC) }
        let d3 = d2 - L_BC
        if d3 < L_CD { return lerp(C, D, t: d3 / L_CD) }
        let d4 = d3 - L_CD
        return lerp(D, A, t: d4 / L_DA)
    }

    /// Path for airport course (same corners as pointOnAirportCourse with inset 0).
    private func airportPath(width: CGFloat, height: CGFloat, inset: CGFloat = 0) -> Path {
        let m = 24 + inset
        let w = width
        let h = height
        let A = CGPoint(x: m, y: h - m)
        let B = CGPoint(x: w - m, y: m)
        let C = CGPoint(x: w - m, y: h - m)
        let D = CGPoint(x: m, y: m)
        var path = Path()
        path.move(to: A)
        path.addLine(to: B)
        path.addLine(to: C)
        path.addLine(to: D)
        path.closeSubpath()
        return path
    }

    private func airportTrackView(geometry: GeometryProxy, progress1: Double, progress2: Double, racer1: RacingRacer, racer2: RacingRacer) -> some View {
        let padding: CGFloat = 24
        let trackWidth = max(1, geometry.size.width - padding * 2)
        let trackHeight = max(120, geometry.size.height - 140)
        let racerSize: CGFloat = 48
        let trackInset: CGFloat = 36

        let outerPath = airportPath(width: trackWidth, height: trackHeight, inset: 0)
        let innerPath = airportPath(width: trackWidth, height: trackHeight, inset: trackInset)

        let pt1Outer = pointOnAirportCourse(progress: progress1, width: trackWidth, height: trackHeight, inset: 0)
        let pt2Outer = pointOnAirportCourse(progress: progress2, width: trackWidth, height: trackHeight, inset: 0)
        let pt1Inner = pointOnAirportCourse(progress: progress1, width: trackWidth, height: trackHeight, inset: trackInset)
        let pt2Inner = pointOnAirportCourse(progress: progress2, width: trackWidth, height: trackHeight, inset: trackInset)

        let racer1OnInner = racer1.speed <= racer2.speed
        let pos1 = racer1OnInner ? pt1Inner : pt1Outer
        let pos2 = racer1OnInner ? pt2Outer : pt2Inner

        let half = racerSize / 2
        let margin: CGFloat = 24
        let finishLineHeight: CGFloat = 12
        let finishLineX = margin - 2
        return VStack(spacing: 8) {
            Text("Race!")
                .font(.headline)
            ZStack(alignment: .topLeading) {
                outerPath
                    .stroke(Color.gray.opacity(0.5), lineWidth: 6)
                    .frame(width: trackWidth, height: trackHeight)
                innerPath
                    .stroke(Color.gray.opacity(0.35), lineWidth: 6)
                    .frame(width: trackWidth, height: trackHeight)
                // Start/finish at airport A (left)
                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 4, height: finishLineHeight)
                    .offset(x: finishLineX, y: trackHeight - margin - finishLineHeight / 2)
                // Airport labels
                Text("A").font(.caption.weight(.bold)).foregroundColor(.secondary).offset(x: margin - 8, y: trackHeight - margin - 6)
                Text("B").font(.caption.weight(.bold)).foregroundColor(.secondary).offset(x: trackWidth - margin - 8, y: margin - 4)
                Text("C").font(.caption.weight(.bold)).foregroundColor(.secondary).offset(x: trackWidth - margin - 8, y: trackHeight - margin - 6)
                Text("D").font(.caption.weight(.bold)).foregroundColor(.secondary).offset(x: margin - 8, y: margin - 4)
                racerView(racer: racer1, size: racerSize)
                    .offset(x: pos1.x - half, y: pos1.y - half)
                racerView(racer: racer2, size: racerSize)
                    .offset(x: pos2.x - half, y: pos2.y - half)
            }
            .frame(width: trackWidth, height: trackHeight)
        }
        .padding(.horizontal, padding)
    }

    /// Total path length for oval (rounded rect). Same formula as pointOnRoundedRect.
    private func ovalPathLength(width: CGFloat, height: CGFloat) -> CGFloat {
        let w = width
        let h = height
        let cx = w / 2
        let r = min(min(w, h) * 0.18, min(w, h) / 4)
        let arcLen = .pi * r / 2
        let L1 = (w - r) - cx
        let L2 = h - 2 * r
        let L3 = w - 2 * r
        let L4 = cx - r
        return L1 + arcLen + L2 + arcLen + L3 + arcLen + L2 + arcLen + L4
    }

    /// Progress offset so race progress 0 = finish line (center bottom). Path starts at center; both lanes start on the same line.
    private func ovalPathStartOffset(width: CGFloat, height: CGFloat) -> Double {
        return 0  // Start at path origin = center bottom = finish line; no head start for inner lane
    }

    /// Rounded-rectangle path: start/finish at center bottom; clockwise lap (right → up → left → down → right to center).
    /// Returns point on path for progress in [0, 1]. Uses same corner radius proportion as drawn track.
    private func pointOnRoundedRect(progress: Double, width: CGFloat, height: CGFloat) -> CGPoint {
        let p = max(0, min(1, progress))
        let w = width
        let h = height
        let cx = w / 2
        let r = min(min(w, h) * 0.18, min(w, h) / 4)
        let arcLen = .pi * r / 2
        let L1 = (w - r) - cx
        let L2 = h - 2 * r
        let L3 = w - 2 * r
        let L4 = cx - r
        let total = L1 + arcLen + L2 + arcLen + L3 + arcLen + L2 + arcLen + L4
        let d = p * total
        let t1 = d / L1
        if d < L1 { return CGPoint(x: cx + t1 * (w - r - cx), y: h) }
        let d2 = d - L1
        if d2 < arcLen {
            let t = CGFloat(d2 / arcLen)
            let angle = CGFloat.pi / 2 * (1 - t)
            return CGPoint(x: (w - r) + r * cos(angle), y: (h - r) + r * sin(angle))
        }
        let d3 = d2 - arcLen
        if d3 < L2 { return CGPoint(x: w, y: (h - r) - d3 / L2 * (h - 2 * r)) }
        let d4 = d3 - L2
        if d4 < arcLen {
            let t = CGFloat(d4 / arcLen)
            let angle = -CGFloat.pi / 2 * t
            return CGPoint(x: (w - r) + r * cos(angle), y: r + r * sin(angle))
        }
        let d5 = d4 - arcLen
        if d5 < L3 { return CGPoint(x: (w - r) - d5 / L3 * (w - 2 * r), y: 0) }
        let d6 = d5 - L3
        if d6 < arcLen {
            let t = CGFloat(d6 / arcLen)
            let angle = -CGFloat.pi / 2 + (3 * CGFloat.pi / 2) * t
            return CGPoint(x: r + r * cos(angle), y: r + r * sin(angle))
        }
        let d7 = d6 - arcLen
        if d7 < L2 { return CGPoint(x: 0, y: r + d7 / L2 * (h - 2 * r)) }
        let d8 = d7 - L2
        if d8 < arcLen {
            let t = CGFloat(d8 / arcLen)
            let angle = CGFloat.pi - CGFloat.pi / 2 * t
            return CGPoint(x: r + r * cos(angle), y: (h - r) + r * sin(angle))
        }
        let d9 = d8 - arcLen
        let t9 = d9 / L4
        return CGPoint(x: r + t9 * (cx - r), y: h)
    }

    private func ovalTrackView(geometry: GeometryProxy, progress1: Double, progress2: Double, racer1: RacingRacer, racer2: RacingRacer) -> some View {
        let padding: CGFloat = 24
        let trackInset: CGFloat = 44
        let ovalWidth = max(trackInset * 2 + 4, geometry.size.width - padding * 2)
        let ovalHeight = max(120, geometry.size.height - 140)
        let racerSize: CGFloat = 48
        let cornerRadius = min(min(ovalWidth, ovalHeight) * 0.18, min(ovalWidth, ovalHeight) / 4)

        // Rounded-rectangle tracks (outer and inner)
        let outerPath = RoundedRectangle(cornerRadius: cornerRadius).path(in: CGRect(x: 0, y: 0, width: ovalWidth, height: ovalHeight))
        let innerW = ovalWidth - trackInset * 2
        let innerH = ovalHeight - trackInset * 2
        let innerCornerRadius = max(0, cornerRadius - trackInset / 2)
        let innerPath = RoundedRectangle(cornerRadius: innerCornerRadius).path(in: CGRect(x: 0, y: 0, width: innerW, height: innerH))

        // Outer and inner positions: progress 0 = finish line (center bottom), progress 1 = finish line after one lap.
        // Both use same progress so they start on the same line; inner lane has shorter path so no head start.
        let outerStart = ovalPathStartOffset(width: ovalWidth, height: ovalHeight)
        let innerStart = ovalPathStartOffset(width: innerW, height: innerH)
        let outerSpan = 1.0 - outerStart
        let innerSpan = 1.0 - innerStart
        let p1Outer = outerStart + progress1 * outerSpan
        let p2Outer = outerStart + progress2 * outerSpan
        let p1Inner = innerStart + progress1 * innerSpan
        let p2Inner = innerStart + progress2 * innerSpan
        let pt1Outer = pointOnRoundedRect(progress: p1Outer, width: ovalWidth, height: ovalHeight)
        let pt2Outer = pointOnRoundedRect(progress: p2Outer, width: ovalWidth, height: ovalHeight)
        let pt1InnerRaw = pointOnRoundedRect(progress: p1Inner, width: innerW, height: innerH)
        let pt2InnerRaw = pointOnRoundedRect(progress: p2Inner, width: innerW, height: innerH)
        let pt1Inner = CGPoint(x: pt1InnerRaw.x + trackInset, y: pt1InnerRaw.y + trackInset)
        let pt2Inner = CGPoint(x: pt2InnerRaw.x + trackInset, y: pt2InnerRaw.y + trackInset)

        // Slower racer on inner (shorter) track, faster on outer (longer) track
        let racer1OnInner = racer1.speed <= racer2.speed
        let pos1 = racer1OnInner ? pt1Inner : pt1Outer
        let pos2 = racer1OnInner ? pt2Outer : pt2Inner

        let half = racerSize / 2
        let finishLineWidth: CGFloat = 4
        let finishLineRowHeight: CGFloat = 10 // One row at center bottom
        let finishLineX = ovalWidth / 2 - finishLineWidth / 2
        let refereeSize: CGFloat = 64
        return VStack(spacing: 8) {
            Text("Race!")
                .font(.headline)
            ZStack(alignment: .topLeading) {
                outerPath
                    .stroke(Color.gray.opacity(0.5), lineWidth: 6)
                    .frame(width: ovalWidth, height: ovalHeight)
                innerPath
                    .stroke(Color.gray.opacity(0.35), lineWidth: 6)
                    .frame(width: innerW, height: innerH)
                    .offset(x: trackInset, y: trackInset)
                // Start/finish line on outer track (one row at center bottom)
                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: finishLineWidth, height: finishLineRowHeight)
                    .offset(x: finishLineX, y: ovalHeight - finishLineRowHeight)
                // Start/finish line on inner track (one row at center bottom)
                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: finishLineWidth, height: finishLineRowHeight)
                    .offset(x: finishLineX, y: trackInset + innerH - finishLineRowHeight)
                racerView(racer: racer1, size: racerSize)
                    .offset(x: pos1.x - half, y: pos1.y - half)
                racerView(racer: racer2, size: racerSize)
                    .offset(x: pos2.x - half, y: pos2.y - half)
                // Referee-start on inner field ahead of racers so they can see him when he blows the whistle
                refereeImageViewSmall(ImageAssetCache.imageExists(named: "game-referee-start") ? "game-referee-start" : "\(config.assetPrefix)-racer-referee-start", size: refereeSize)
                    .offset(x: ovalWidth / 2 + 24, y: ovalHeight - refereeSize - 16)
            }
            .frame(width: ovalWidth, height: ovalHeight)
        }
        .padding(.horizontal, padding)
    }

    private func racerView(racer: RacingRacer, size: CGFloat) -> some View {
        Group {
            if let imageName = racerDisplayImageName(for: racer, config: config) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Text(racer.icon)
                    .font(.system(size: size))
            }
        }
        .frame(width: size, height: size)
    }

    private func laneView(racer: RacingRacer, progress: Double, trackWidth: CGFloat, laneHeight: CGFloat, emojiSize: CGFloat) -> some View {
        let racerX = max(0, progress * (trackWidth - emojiSize - CGFloat(4)))
        return ZStack(alignment: .leading) {
            // Track background (full width so both lanes align)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: trackWidth, height: laneHeight)
            // Finish line (right)
            Rectangle()
                .fill(Color.red)
                .frame(width: 4, height: laneHeight)
                .frame(maxWidth: .infinity, alignment: .trailing)
            // Racer: left-justified at start (progress 0 = x 0), same formula for both lanes
            Group {
                if let imageName = racerDisplayImageName(for: racer, config: config) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: emojiSize, height: emojiSize)
                } else {
                    Text(racer.icon)
                        .font(.system(size: emojiSize))
                }
            }
            .frame(width: emojiSize, height: emojiSize, alignment: .leading)
            .offset(x: racerX)
        }
        .frame(width: trackWidth, height: laneHeight)
    }
    
    private func startRace() {
        guard let r1 = selectedLane1, let r2 = selectedLane2 else { return }
        isRacing = true
        progress1 = 0
        progress2 = 0
        speechManager.speak("starting-whistle")
        speechManager.onAudioFinished = {
            Task { @MainActor in
                self.speechManager.onAudioFinished = nil
                self.fireRaceTimer(r1: r1, r2: r2)
            }
        }
    }

    private func fireRaceTimer(r1: RacingRacer, r2: RacingRacer) {
        let maxSpeed = max(r1.speed, r2.speed)
        raceTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { _ in
            let rawP1 = progress1 + stepPerTick * (r1.speed / maxSpeed)
            let rawP2 = progress2 + stepPerTick * (r2.speed / maxSpeed)
            let newP1 = min(1.0, rawP1)
            let newP2 = min(1.0, rawP2)
            DispatchQueue.main.async {
                progress1 = newP1
                progress2 = newP2
                if newP1 >= 1.0 || newP2 >= 1.0 {
                    stopRace()
                    // Use raw progress to break ties: when both hit 1.0 in same tick, higher raw value crossed first
                    winner = rawP1 >= rawP2 ? r1 : r2
                    postRaceStep = "referee"
                    // Cheering when first dinosaur crosses the finish line
                    if let url = speechManager.urlForAudio(key: "crowd-cheering") {
                        speechManager.playAudioFile(url: url)
                    } else {
                        speechManager.speak("crowd-cheering")
                    }
                }
            }
        }
        raceTimer?.fire()
    }

    private func stopRace() {
        raceTimer?.invalidate()
        raceTimer = nil
    }
    
    // MARK: - Winner (announce by text + audio: game-racing-the-winner-is, then dino name, then crowd-cheering)
    private func winnerView(winner w: RacingRacer) -> some View {
        VStack(spacing: 20) {
            Text("🏆")
                .font(.system(size: 60))
            Text("The winner is")
                .font(.title3)
                .foregroundColor(.secondary)
            if let imageName = winnerDisplayImageName(for: w, config: config) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text(w.icon)
                    .font(.system(size: 80))
            }
            Text(w.name)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
        .onAppear {
            playWinnerAnnouncement(winner: w)
        }
    }

    private func playWinnerAnnouncement(winner w: RacingRacer) {
        let announceURL = speechManager.urlForAudio(key: "game-racing-the-winner-is")
        let crowdURL = speechManager.urlForAudio(key: "crowd-cheering")

        func playCrowdThenDismiss() {
            if let url = crowdURL {
                speechManager.playAudioFile(url: url)
                speechManager.onAudioFinished = {
                    Task { @MainActor in
                        self.speechManager.onAudioFinished = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.isPresented = false
                        }
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isPresented = false
                }
            }
        }

        func playWinnerNameThenCrowd() {
            speechManager.onAudioFinished = {
                Task { @MainActor in
                    self.speechManager.onAudioFinished = nil
                    playCrowdThenDismiss()
                }
            }
            speechManager.speak(audioKey: w.effectiveFallbackImageName(prefix: config.assetPrefix), fallbackText: w.name)
        }

        if let url = announceURL {
            speechManager.playAudioFile(url: url)
            speechManager.onAudioFinished = {
                Task { @MainActor in
                    self.speechManager.onAudioFinished = nil
                    playWinnerNameThenCrowd()
                }
            }
        } else {
            playWinnerNameThenCrowd()
        }
    }
}

// MARK: - Racer Card (dino-racer-{slug} image when present, else emoji)

struct RacingRacerCard: View {
    let racer: RacingRacer
    let gameConfig: RacingGameConfig
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                if let imageName = racerDisplayImageName(for: racer, config: gameConfig) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 84, height: 84)
                } else {
                    Text(racer.icon)
                        .font(.system(size: 84))
                }
                if isSelected {
                    Text(racer.name)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
            }
            .frame(width: 150, height: isSelected ? 150 : 125)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .opacity(isDisabled && !isSelected ? 0.5 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled && !isSelected)
    }
}

// MARK: - Game Configuration (pools per period; 4 racers chosen randomly per game)

enum RacingPeriod: String, CaseIterable {
    case jurassic
    case cretaceous
}

/// Pool entry: add more over time; each game picks 4 at random from the pool.
private struct RacingRacerPoolEntry {
    let name: String
    let icon: String
    let speed: Double
}

private let jurassicRacerPool: [RacingRacerPoolEntry] = [
    RacingRacerPoolEntry(name: "Allosaurus", icon: "🦖", speed: 25),
    RacingRacerPoolEntry(name: "Stegosaurus", icon: "🦎", speed: 12.5),
    RacingRacerPoolEntry(name: "Apatosaurus", icon: "🦕", speed: 13.5),
    RacingRacerPoolEntry(name: "Diplodocus", icon: "🦕", speed: 12),
    RacingRacerPoolEntry(name: "Compsognathus", icon: "🦖", speed: 40),
    RacingRacerPoolEntry(name: "Brontosaurus", icon: "🦕", speed: 13.5),
]

private let cretaceousRacerPool: [RacingRacerPoolEntry] = [
    RacingRacerPoolEntry(name: "T-Rex", icon: "🦖", speed: 17),
    RacingRacerPoolEntry(name: "Triceratops", icon: "🦏", speed: 27),
    RacingRacerPoolEntry(name: "Ankylosaurus", icon: "🛡️", speed: 4.5),
    RacingRacerPoolEntry(name: "Velociraptor", icon: "🦖", speed: 22.5),
    RacingRacerPoolEntry(name: "Gallimimus", icon: "🦃", speed: 45),
    RacingRacerPoolEntry(name: "Albertosaurus", icon: "🦖", speed: 25),
]

/// Pterosaur pool for Racing Pterosaurs: name, icon, speed (estimated flight mph), imageName for fallback/audio.
private let pterosaurRacerPool: [(name: String, icon: String, speed: Double, imageName: String)] = {
    MatchingGameConfigs.allPterosaurs.compactMap { p in
        guard let img = p.imageName else { return nil }
        return (p.name, p.icon, pterosaurSpeedEstimate(name: p.name), img)
    }
}()

private func pterosaurSpeedEstimate(name: String) -> Double {
    switch name {
    case "Pteranodon", "Nyctosaurus": return 25
    case "Rhamphorhynchus", "Dsungaripterus", "Tapejara": return 22
    case "Pterodactylus", "Quetzalcoatlus", "Anurognathus", "Tupandactylus": return 20
    case "Dimorphodon": return 18
    default: return 20
    }
}

struct RacingGameConfigs {
    /// Config used for the game list card only (id "racing-dinosaurs" matches imageset game-racing-dinosaurs). Period choice then loads Jurassic or Cretaceous.
    static let racingDinosaurs: RacingGameConfig = {
        makeConfig(for: .cretaceous)
    }()

    /// Config with empty racers: RacingGameView shows period selection first, then dinosaur selection. Avoids sheet dismiss/present flash.
    static let racingDinosaursNeedsPeriod: RacingGameConfig = RacingGameConfig(
        id: "racing-dinosaurs",
        title: "Racing Dinosaurs!",
        introAudio: "racing-dinosaurs",
        assetPrefix: "dino",
        racers: []
    )

    /// Card config for Racing Pterosaurs! (id used for image/audio; actual play uses racingPterosaursRandomized()).
    static var racingPterosaursCardConfig: RacingGameConfig {
        racingPterosaursRandomized()
    }

    /// Returns a new config with 4 pterosaurs chosen at random. Use when starting Racing Pterosaurs! so each game has a fresh set.
    static func racingPterosaursRandomized() -> RacingGameConfig {
        let pool = pterosaurRacerPool
        guard pool.count >= 4 else {
            return RacingGameConfig(id: "racing-pterosaurs", title: "Racing Pterosaurs!", introAudio: "racing-pterosaurs", assetPrefix: "ptero", racers: [])
        }
        let picked = pool.shuffled().prefix(4)
        let racers = picked.enumerated().map { index, entry in
            RacingRacer(id: 300 + index + 1, name: entry.name, icon: entry.icon, speed: entry.speed, fallbackImageName: entry.imageName)
        }
        return RacingGameConfig(
            id: "racing-pterosaurs",
            title: "Racing Pterosaurs!",
            introAudio: "racing-pterosaurs",
            assetPrefix: "ptero",
            racers: Array(racers)
        )
    }

    /// Returns a new config with 4 racers chosen at random from the period's pool. Call when user picks a period so each game has a fresh set.
    static func makeConfig(for period: RacingPeriod) -> RacingGameConfig {
        let pool: [RacingRacerPoolEntry]
        let idBase: Int
        let title: String
        switch period {
        case .jurassic:
            pool = jurassicRacerPool
            idBase = 100
            title = "Racing Dinosaurs! (Jurassic)"
        case .cretaceous:
            pool = cretaceousRacerPool
            idBase = 200
            title = "Racing Dinosaurs! (Cretaceous)"
        }
        let picked = pool.shuffled().prefix(4)
        let racers = picked.enumerated().map { index, entry in
            RacingRacer(id: idBase + index + 1, name: entry.name, icon: entry.icon, speed: entry.speed, fallbackImageName: nil)
        }
        return RacingGameConfig(
            id: "racing-dinosaurs-\(period.rawValue)",
            title: title,
            introAudio: "racing-dinosaurs",
            assetPrefix: "dino",
            racers: Array(racers)
        )
    }
}

// MARK: - Period Selection (Jurassic / Cretaceous)

struct RacingPeriodSelectionView: View {
    @Binding var isPresented: Bool
    var onSelectPeriod: (RacingGameConfig) -> Void
    /// When true, period selection is embedded in RacingGameView; selecting a period does not dismiss.
    var embedMode: Bool = false

    @State private var speechManager = SpeechManager()
    @State private var enabledJurassic = false
    @State private var enabledCretaceous = false
    @State private var hasStartedSequence = false
    @State private var showText = false

    private let periods: [(name: String, imageAssetName: String, emoji: String, period: RacingPeriod)] = [
        ("Jurassic", "period-jurassic", "🦕", .jurassic),
        ("Cretaceous", "period-cretaceous", "🦖", .cretaceous),
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose a period")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 24)
                    .opacity(showText ? 1 : 0)
                Text("Only dinosaurs from that period can race.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(showText ? 1 : 0)
                Text("Mesozoic Age")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.top, 8)
                    .opacity(showText ? 1 : 0)
                VStack(spacing: 16) {
                    periodCard(name: periods[0].name, imageAssetName: periods[0].imageAssetName, emoji: periods[0].emoji, period: periods[0].period, isEnabled: enabledJurassic)
                    periodCard(name: periods[1].name, imageAssetName: periods[1].imageAssetName, emoji: periods[1].emoji, period: periods[1].period, isEnabled: enabledCretaceous)
                }
                .padding(.horizontal, 24)
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                showText = true
                if !hasStartedSequence {
                    hasStartedSequence = true
                    startPeriodSequence()
                }
            }
            .onDisappear {
                speechManager.stopCurrentAudio()
            }
            .allowsHitTesting(enabledJurassic || enabledCretaceous)
        }
    }

    private func periodCard(name: String, imageAssetName: String, emoji: String, period: RacingPeriod, isEnabled: Bool) -> some View {
        Button {
            onSelectPeriod(RacingGameConfigs.makeConfig(for: period))
            if !embedMode { isPresented = false }
        } label: {
            VStack(spacing: 8) {
                if UIImage(named: imageAssetName) != nil {
                    Image(imageAssetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                } else {
                    Text(emoji)
                        .font(.system(size: 64))
                        .frame(height: 100)
                }
                Text(name)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.12)))
            .opacity(isEnabled ? 1 : 0.7)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    /// Three-step sequence: cover-choose-a-period → enable Jurassic + cover-jurassic → enable Cretaceous + cover-cretaceous. Then show text.
    private func startPeriodSequence() {
        speechManager.onAudioFinished = {
            Task { @MainActor in
                self.speechManager.onAudioFinished = nil
                self.periodIntroDone()
            }
        }
        speechManager.speak("cover-choose-a-period")
    }

    private func periodIntroDone() {
        enabledJurassic = true
        speechManager.onAudioFinished = {
            Task { @MainActor in
                self.speechManager.onAudioFinished = nil
                self.jurassicDone()
            }
        }
        speechManager.speak("cover-jurassic", chainDelay: true)
    }

    private func jurassicDone() {
        enabledCretaceous = true
        speechManager.onAudioFinished = {
            Task { @MainActor in
                self.speechManager.onAudioFinished = nil
            }
        }
        speechManager.speak("cover-cretaceous", chainDelay: true)
    }
}

#Preview {
    RacingGameView(isPresented: .constant(true), gameConfig: RacingGameConfigs.racingDinosaurs)
}
