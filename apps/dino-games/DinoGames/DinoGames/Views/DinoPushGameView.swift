//
//  DinoPushGameView.swift
//  DinoGames
//
//  Dino Push!: Sumo-style face-off. Two dinosaurs in a circular arena; stronger pushes weaker out.
//  Images: dino-push-{slug}-ready (face-off), dino-push-{slug}-finish-excited/exhausted.
//
//  Asset naming: Uses game-dino-push-* prefix for all audio/images (period selection, tie, etc).
//  Intentional duplication with Racing (cover-*, period-*) for clarity during development;
//  can refactor to shared assets later if desired.
//

import SwiftUI
import AVFoundation

// MARK: - Data Models

struct DinoPushRacer: Identifiable {
    let id: Int
    let name: String
    let icon: String
    let strength: Double
    let fallbackImageName: String?

    var imageSlug: String {
        name.lowercased().replacingOccurrences(of: " ", with: "-")
    }
    /// Selection grid/expanded: dino-{slug} (e.g. dino-trex, dino-triceratops).
    func selectionImageName() -> String {
        if imageSlug == "t-rex" { return "dino-trex" }
        return "dino-\(imageSlug)"
    }
    /// Arena (during push): dino-push-{slug}-ready.
    func arenaReadyImageName() -> String {
        if imageSlug == "t-rex" { return "dino-push-trex-ready" }
        return "dino-push-\(imageSlug)-ready"
    }
    /// Victory: dino-push-{slug}-finish-excited or -exhausted.
    func arenaFinishExcitedImageName() -> String {
        if imageSlug == "t-rex" { return "dino-push-trex-finish-excited" }
        return "dino-push-\(imageSlug)-finish-excited"
    }
    func arenaFinishExhaustedImageName() -> String {
        if imageSlug == "t-rex" { return "dino-push-trex-finish-exhausted" }
        return "dino-push-\(imageSlug)-finish-exhausted"
    }
    func effectiveFallbackImageName(prefix: String) -> String {
        if let f = fallbackImageName { return f }
        return "dino-\(imageSlug.replacingOccurrences(of: "-", with: ""))"
    }
}

struct DinoPushGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let assetPrefix: String
    let racers: [DinoPushRacer]
}

// MARK: - Constants

private let phaseInterval: TimeInterval = 0.38  // Tick rate (slower = longer matches, ~15–20s typical)
private let matchDurationSeconds = 90
private let strengthDeltaThreshold = 0.15 // Below this ratio, coin flip
private let approachStep: Double = 0.035  // Radius decrease when approaching (slightly slower for longer buildup)
private let backupStep: Double = 0.06    // Radius increase when backing up after partial collision
private let pushStep: Double = 0.10      // Loser pushed outward per resolve tick (decisive but not instant)
private let fullCollisionDist: Double = 0.18   // Distance for full collision → resolve (wider so we reach push phase sooner)
private let partialCollisionDist: Double = 0.28  // Distance for partial collision → backup and retry
private let centerRadius: Double = 0.08  // Near-center threshold for referee to back away

// MARK: - Main View

struct DinoPushGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: DinoPushGameConfig

    @State private var effectiveConfig: DinoPushGameConfig?
    @State private var speechManager = SpeechManager()
    @State private var selected1: DinoPushRacer?
    @State private var selected2: DinoPushRacer?
    @State private var pendingRacer2: DinoPushRacer?
    @State private var canSelectSecond = false
    @State private var showingExpandedRacer: DinoPushRacer?
    @State private var hasPlayedFirstPrompt = false
    @State private var selectionTapsBlocked = true  // Block taps until "choose first/second" prompt finishes

    @State private var isPushing = false
    @State private var showRefereeAtStart = false  // Referee between dinos before they approach; whistle then go
    @State private var r1: Double = 0.5   // Polar: radius 0=center, 1=edge
    @State private var theta1: Double = 0
    @State private var r2: Double = 0.5
    @State private var theta2: Double = .pi
    @State private var refereeR: Double = 0.15  // Referee distance from center; backs up when dinos approach
    @State private var refereeTheta: Double = .pi / 2  // Referee angle
    @State private var pushTimer: Timer?
    @State private var pushRoundPhase: Int = 0  // 0=backup, 1=slam, 2=resolve
    @State private var timeRemaining: Int = 90
    @State private var winner: DinoPushRacer?
    @State private var isTie = false
    @State private var showResult = false
    @State private var roundsCompleted = 0
    private let maxRounds = 5
    @State private var winners: [DinoPushRacer] = []
    @State private var showVictory = false
    @State private var endSequenceStep: Int = -1
    @State private var endHighlightIndex: Int = 0

    private var config: DinoPushGameConfig { effectiveConfig ?? gameConfig }

    private var showSelection: Bool {
        selected1 == nil || ((selected2 == nil && pendingRacer2 == nil) && !isPushing && !showResult)
    }

    /// True when we need to show period selection first (dino-push with empty racers).
    private var needsPeriodSelection: Bool {
        gameConfig.racers.isEmpty && gameConfig.id == "dino-push"
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    if needsPeriodSelection && effectiveConfig == nil {
                        embeddedPeriodSelectionView(geometry: geometry)
                    } else if showVictory {
                        victoryView
                    } else if showSelection {
                        if let racer = showingExpandedRacer {
                            expandedRacerView(geometry: geometry, racer: racer)
                        } else {
                            selectionGrid(geometry: geometry)
                                .onAppear {
                                    if selected1 == nil && !hasPlayedFirstPrompt {
                                        hasPlayedFirstPrompt = true
                                        selectionTapsBlocked = true
                                        speechManager.onAudioFinished = {
                                            Task { @MainActor in
                                                self.speechManager.onAudioFinished = nil
                                                self.speechManager.speak("game-push-choose-your-first-strong-dinosaur")
                                                self.speechManager.onAudioFinished = {
                                                    Task { @MainActor in
                                                        self.selectionTapsBlocked = false
                                                        self.speechManager.onAudioFinished = nil
                                                    }
                                                }
                                            }
                                        }
                                        speechManager.speak("game-dino-push-choose-two-dinosaurs")
                                    }
                                }
                        }
                    } else if isPushing, let r1 = selected1, let r2 = selected2 {
                        pushArenaView(geometry: geometry, racer1: r1, racer2: r2)
                    } else if showResult {
                        resultView(geometry: geometry)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(config.title)
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                stopPush()
                speechManager.stopCurrentAudio()
            }
        }
    }

    /// Period selection shown when gameConfig has empty racers. Uses Dino Push–specific assets.
    private func embeddedPeriodSelectionView(geometry: GeometryProxy) -> some View {
        DinoPushPeriodSelectionView(isPresented: $isPresented, onSelectPeriod: { config in
            effectiveConfig = config
        }, embedMode: true)
    }

    // MARK: - Selection

    private func selectionGrid(geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            Text("Round \(roundsCompleted + 1) of \(maxRounds)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            if selected1 == nil {
                Text("Choose your first dinosaur to race")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if selected2 == nil && pendingRacer2 == nil {
                Text("Choose your second dinosaur to race")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            VStack(spacing: 10) {
                ForEach(0..<((config.racers.count + 1) / 2), id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(Array(config.racers.dropFirst(row * 2).prefix(2))) { racer in
                            DinoPushRacerCard(
                                racer: racer,
                                selectionImageName: racerSelectionImageName(racer),
                                isSelected: selected1?.id == racer.id || selected2?.id == racer.id || pendingRacer2?.id == racer.id,
                                isDisabled: selectionTapsBlocked || (selected1 != nil && selected2 == nil && pendingRacer2 == nil && !canSelectSecond) || (selected1 != nil && (selected2 != nil || pendingRacer2 != nil))
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

    private func handleRacerTap(_ racer: DinoPushRacer) {
        guard !selectionTapsBlocked else { return }
        if selected1 == nil {
            showingExpandedRacer = racer
            canSelectSecond = false
            speechManager.onAudioFinished = {
                Task { @MainActor in
                    self.dismissExpandedAndSetFirst(racer)
                }
            }
            speechManager.speak(audioKey: racer.effectiveFallbackImageName(prefix: config.assetPrefix), fallbackText: racer.name)
        } else if selected2 == nil && pendingRacer2 == nil && selected1?.id != racer.id && canSelectSecond {
            showingExpandedRacer = racer
            canSelectSecond = false
            speechManager.onAudioFinished = {
                Task { @MainActor in
                    self.dismissExpandedAndSetSecond(racer)
                }
            }
            speechManager.speak(audioKey: racer.effectiveFallbackImageName(prefix: config.assetPrefix), fallbackText: racer.name)
        }
    }

    private func dismissExpandedAndSetFirst(_ racer: DinoPushRacer) {
        speechManager.onAudioFinished = nil
        speechManager.stopCurrentAudio()
        showingExpandedRacer = nil
        selected1 = racer
        canSelectSecond = true
        selectionTapsBlocked = true
        speechManager.onAudioFinished = {
            Task { @MainActor in
                self.selectionTapsBlocked = false
                self.speechManager.onAudioFinished = nil
            }
        }
        speechManager.speak("game-push-choose-your-second-strong-dinosaur")
    }

    private func dismissExpandedAndSetSecond(_ racer: DinoPushRacer) {
        speechManager.onAudioFinished = nil
        speechManager.stopCurrentAudio()
        showingExpandedRacer = nil
        selected2 = racer
        beginPushMatch()
    }

    private func expandedRacerView(geometry: GeometryProxy, racer: DinoPushRacer) -> some View {
        let size = min(geometry.size.width, geometry.size.height) * 0.45
        let imageName = racerSelectionImageName(racer) ?? racer.effectiveFallbackImageName(prefix: config.assetPrefix)
        return VStack(spacing: 20) {
            if UIImage(named: imageName) != nil {
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
            Text("Strength: \(Int(racer.strength))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if selected1 == nil { dismissExpandedAndSetFirst(racer) }
            else { dismissExpandedAndSetSecond(racer) }
        }
    }

    /// Selection: dino-{slug}. For grid and expanded selection view.
    private func racerSelectionImageName(_ racer: DinoPushRacer) -> String? {
        let name = racer.selectionImageName()
        return UIImage(named: name) != nil ? name : nil
    }
    /// Arena: dino-push-{slug}-ready. For during the push match.
    private func racerArenaImageName(_ racer: DinoPushRacer) -> String? {
        let ready = racer.arenaReadyImageName()
        if UIImage(named: ready) != nil { return ready }
        let base = racer.imageSlug == "t-rex" ? "dino-push-trex" : "dino-push-\(racer.imageSlug)"
        return UIImage(named: base) != nil ? base : nil
    }
    /// Victory: dino-push-{slug}-finish-excited or -exhausted.
    private func racerVictoryImageName(_ racer: DinoPushRacer) -> String? {
        if UIImage(named: racer.arenaFinishExcitedImageName()) != nil { return racer.arenaFinishExcitedImageName() }
        if UIImage(named: racer.arenaFinishExhaustedImageName()) != nil { return racer.arenaFinishExhaustedImageName() }
        return racerArenaImageName(racer)
    }

    // MARK: - Push Arena

    private func pushArenaView(geometry: GeometryProxy, racer1 r1: DinoPushRacer, racer2 r2: DinoPushRacer) -> some View {
        let size = min(geometry.size.width, geometry.size.height) - 80
        let arenaSize = min(size, 320)
        let innerRadius: CGFloat = 24
        let outerRadius = arenaSize / 2 - 20
        return VStack(spacing: 16) {
            Text("\(timeRemaining)s")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(timeRemaining <= 10 ? .red : .primary)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.5), lineWidth: 6)
                    .frame(width: arenaSize, height: arenaSize)
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: innerRadius * 2, height: innerRadius * 2)
                dinoAtPosition(racer: r1, radius: self.r1, theta: theta1, arenaSize: arenaSize, outerRadius: outerRadius)
                dinoAtPosition(racer: r2, radius: self.r2, theta: theta2, arenaSize: arenaSize, outerRadius: outerRadius)
                if showRefereeAtStart, ImageAssetCache.imageExists(named: "dino-push-referee-start") {
                    Image("dino-push-referee-start")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                } else if !showRefereeAtStart, ImageAssetCache.imageExists(named: "dino-push-referee-start") {
                    Image("dino-push-referee-start")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .offset(
                            x: cos(refereeTheta) * CGFloat(refereeR) * outerRadius,
                            y: -sin(refereeTheta) * CGFloat(refereeR) * outerRadius
                        )
                }
            }
            .frame(width: arenaSize, height: arenaSize)
            .onAppear {
                guard showRefereeAtStart else { return }
                speechManager.speak("starting-whistle")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showRefereeAtStart = false
                    refereeR = 0.15
                    refereeTheta = .pi / 2
                    startApproachPhase(r1: r1, r2: r2)
                    pushTimer = Timer.scheduledTimer(withTimeInterval: phaseInterval, repeats: true) { _ in
                        DispatchQueue.main.async {
                            tickPush(r1: r1, r2: r2)
                        }
                    }
                    pushTimer?.fire()
                }
            }

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    if let img = racerArenaImageName(r1) {
                        Image(img)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                    } else {
                        Text(r1.icon)
                            .font(.system(size: 36))
                    }
                    Text(r1.name)
                        .font(.caption)
                    Text("\(Int(r1.strength))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                VStack(spacing: 4) {
                    if let img = racerArenaImageName(r2) {
                        Image(img)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                    } else {
                        Text(r2.icon)
                            .font(.system(size: 36))
                    }
                    Text(r2.name)
                        .font(.caption)
                    Text("\(Int(r2.strength))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func dinoAtPosition(racer: DinoPushRacer, radius: Double, theta: Double, arenaSize: CGFloat, outerRadius: CGFloat) -> some View {
        let r = outerRadius * (0.05 + min(1, radius) * 0.95)
        let x = cos(theta) * r
        let y = -sin(theta) * r  // Y flipped for screen coords
        let imgName = racerArenaImageName(racer) ?? racer.effectiveFallbackImageName(prefix: config.assetPrefix)
        return Group {
            if UIImage(named: imgName) != nil {
                Image(imgName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
            } else {
                Text(racer.icon)
                    .font(.system(size: 44))
            }
        }
        .offset(x: x, y: y)
    }

    private func beginPushMatch() {
        guard selected1 != nil, selected2 != nil else { return }
        // Referee phase: dinos at edges, referee in center; whistle then approach
        self.r1 = 0.85
        theta1 = 0
        self.r2 = 0.85
        theta2 = .pi
        refereeR = 0.15
        refereeTheta = .pi / 2
        showRefereeAtStart = true
        pushRoundPhase = 0
        timeRemaining = matchDurationSeconds
        winner = nil
        isTie = false
        isPushing = true
        // Timer starts in pushArenaView.onAppear after whistle (0.35s)
    }

    /// Start approach with random angles so they approach from different directions.
    /// Rotate the whole setup randomly so face-offs occur around the entire circle (not just 1–3 o'clock).
    private func startApproachPhase(r1 racer1: DinoPushRacer, r2 racer2: DinoPushRacer) {
        let spread = Double.pi * 0.4
        let baseAngle = Double.random(in: 0..<(2 * .pi))
        theta1 = baseAngle + Double.random(in: -spread...spread)
        theta2 = baseAngle + .pi + Double.random(in: -spread...spread)
        r1 = 0.85
        r2 = 0.85
        pushRoundPhase = 0
    }

    /// Polar distance between two dinos (normalized 0–1).
    private func polarDistance(_ r1: Double, _ t1: Double, _ r2: Double, _ t2: Double) -> Double {
        let x1 = r1 * cos(t1)
        let y1 = r1 * sin(t1)
        let x2 = r2 * cos(t2)
        let y2 = r2 * sin(t2)
        return sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
    }

    /// Angle from (r1,t1) toward (r2,t2).
    private func angleToward(r1: Double, t1: Double, r2: Double, t2: Double) -> Double {
        let x1 = r1 * cos(t1)
        let y1 = r1 * sin(t1)
        let x2 = r2 * cos(t2)
        let y2 = r2 * sin(t2)
        return atan2(y2 - y1, x2 - x1)
    }

    /// Each round: approach (stronger pursues weaker) → collision check → partial backup or resolve.
    private func tickPush(r1 racer1: DinoPushRacer, r2 racer2: DinoPushRacer) {
        let dist = polarDistance(self.r1, theta1, self.r2, theta2)

        // Referee backs away when dinos approach center; returns when they move to edges
        if self.r1 < centerRadius || self.r2 < centerRadius || dist < 0.3 {
            refereeR = min(0.95, refereeR + 0.08)
            let awayFromDinos = (theta1 + theta2) / 2 + .pi
            refereeTheta = awayFromDinos
        } else if self.r1 > 0.35 && self.r2 > 0.35 && dist > 0.4 {
            refereeR = max(0.15, refereeR - 0.05)
        }

        timeRemaining -= 1
        if timeRemaining <= 0 {
            stopPush()
            isTie = true
            showResult = true
            return
        }

        switch pushRoundPhase {
        case 0:
            // Approach: both move toward center and toward each other (converge directly to reduce bouncing).
            let target1to2 = angleToward(r1: self.r1, t1: theta1, r2: self.r2, t2: theta2)
            let target2to1 = angleToward(r1: self.r2, t1: theta2, r2: self.r1, t2: theta1)
            theta1 = theta1 + (target1to2 - theta1) * 0.2
            theta2 = theta2 + (target2to1 - theta2) * 0.2
            let stronger = racer1.strength >= racer2.strength ? racer1 : racer2
            let strongerIs1 = stronger.id == racer1.id
            if strongerIs1 {
                self.r1 = max(0.02, self.r1 - approachStep)
                self.r2 = max(0.02, self.r2 - approachStep * 0.85)
            } else {
                self.r2 = max(0.02, self.r2 - approachStep)
                self.r1 = max(0.02, self.r1 - approachStep * 0.85)
            }

            let newDist = polarDistance(self.r1, theta1, self.r2, theta2)
            if newDist < fullCollisionDist {
                pushRoundPhase = 2
            } else if newDist < partialCollisionDist {
                pushRoundPhase = 1
            }
        case 1:
            // Partial collision: back up slightly, small angle nudge, try again
            self.r1 = min(0.9, self.r1 + backupStep * 0.5)
            self.r2 = min(0.9, self.r2 + backupStep * 0.5)
            theta1 += Double.random(in: -0.15...0.15)
            theta2 += Double.random(in: -0.15...0.15)
            pushRoundPhase = 0
        default:
            // Resolve: winner pushes loser outward
            let maxStr = max(racer1.strength, racer2.strength)
            let delta = abs(racer1.strength - racer2.strength)
            let deltaRatio = maxStr > 0 ? delta / maxStr : 0

            let r1Wins: Bool
            if deltaRatio >= strengthDeltaThreshold {
                r1Wins = racer1.strength > racer2.strength
            } else {
                r1Wins = Bool.random()
            }

            if r1Wins {
                self.r2 = min(1.0, self.r2 + pushStep)
                self.r1 = min(1.0, self.r1 + pushStep * 0.3)
                theta1 = theta1 + (theta2 - theta1) * 0.2
            } else {
                self.r1 = min(1.0, self.r1 + pushStep)
                self.r2 = min(1.0, self.r2 + pushStep * 0.3)
                theta2 = theta2 + (theta1 - theta2) * 0.2
            }

            // Stay in resolve until someone reaches edge; do not return to approach (which would undo the push)
            if self.r1 >= 0.98 || self.r2 >= 0.98 {
                stopPush()
                winner = self.r1 >= 0.98 ? racer2 : racer1
                showResult = true
            }
        }
    }

    private func stopPush() {
        pushTimer?.invalidate()
        pushTimer = nil
        isPushing = false
    }

    // MARK: - Result

    private func resultView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 24) {
            if isTie {
                Text("It's a tie!")
                    .font(.title)
                    .fontWeight(.bold)
                if let r1 = selected1, let r2 = selected2 {
                    HStack(spacing: 24) {
                        racerResultImage(r1)
                        racerResultImage(r2)
                    }
                    Text("\(r1.name) & \(r2.name)")
                        .font(.headline)
                }
            } else if let w = winner {
                Text("\(w.name) wins!")
                    .font(.title)
                    .fontWeight(.bold)
                racerResultImage(w)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if isTie {
                speechManager.speak("game-dino-push-its-a-tie")
                speechManager.onAudioFinished = {
                    Task { @MainActor in
                        self.speechManager.onAudioFinished = nil
                        finishRoundAndAdvance()
                    }
                }
            } else if let w = winner {
                speechManager.speak(audioKey: w.effectiveFallbackImageName(prefix: config.assetPrefix), fallbackText: "\(w.name) wins!")
                speechManager.onAudioFinished = {
                    Task { @MainActor in
                        self.speechManager.onAudioFinished = nil
                        finishRoundAndAdvance()
                    }
                }
            }
        }
    }

    private func finishRoundAndAdvance() {
        if isTie, let r1 = selected1, let r2 = selected2 {
            winners.append(r1)
            winners.append(r2)
        } else if let w = winner {
            winners.append(w)
        }
        roundsCompleted += 1
        showResult = false
        winner = nil
        isTie = false
        if roundsCompleted < maxRounds {
            advanceToNextRound()
        } else {
            showVictory = true
        }
    }

    private func advanceToNextRound() {
        selected1 = nil
        selected2 = nil
        pendingRacer2 = nil
        showingExpandedRacer = nil
        canSelectSecond = false
        hasPlayedFirstPrompt = false
        showRefereeAtStart = false
        r1 = 0.5
        theta1 = 0
        r2 = 0.5
        theta2 = .pi
        refereeR = 0.15
        refereeTheta = .pi / 2
    }

    // MARK: - Victory

    private var uniqueWinners: [DinoPushRacer] {
        var seen: Set<Int> = []
        return winners.filter { seen.insert($0.id).inserted }
    }

    private var victoryView: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(uniqueWinners.enumerated()), id: \.offset) { index, racer in
                                let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                                HStack(spacing: 16) {
                                    Group {
                                        if let name = racerVictoryImageName(racer), UIImage(named: name) != nil {
                                            Image(name)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 72, height: 72)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        } else {
                                            Text(racer.icon)
                                                .font(.system(size: 40))
                                                .frame(width: 72, height: 72)
                                        }
                                    }
                                    .opacity(isHighlighted ? 1.0 : 0.4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                                    )

                                    Text("\(racer.name) – \(Int(racer.strength))")
                                        .font(.system(size: racer.name.count > 10 ? 18 : 22, weight: isHighlighted ? .semibold : .regular))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .opacity(isHighlighted ? 1.0 : 0.5)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .frame(height: 92)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                                .id(index)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    }
                    .frame(height: 16 + 4 * 92 + 3 * 12 + 16)
                    .onChange(of: endHighlightIndex) { _, newIndex in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Group {
                    if endSequenceStep == 2 {
                        dinoPushSuccessImageView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    playGoodJobAndCrowdThenDismiss()
                                }
                            }
                    } else {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            let unique = uniqueWinners
            if unique.isEmpty {
                endSequenceStep = 2
            } else {
                let racer = unique[0]
                speechManager.speak(audioKey: racer.effectiveFallbackImageName(prefix: config.assetPrefix), fallbackText: racer.name)
                speechManager.onAudioFinished = { advanceVictoryHighlight() }
            }
        }
    }

    private func advanceVictoryHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        let unique = uniqueWinners
        if endHighlightIndex < unique.count {
            let racer = unique[endHighlightIndex]
            speechManager.speak(audioKey: racer.effectiveFallbackImageName(prefix: config.assetPrefix), fallbackText: racer.name)
            speechManager.onAudioFinished = { advanceVictoryHighlight() }
        } else {
            endSequenceStep = 2
        }
    }

    private var dinoPushSuccessImageView: some View {
        Group {
            if ImageAssetCache.imageExists(named: "game-dino-push-success") {
                Image("game-dino-push-success")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else if ImageAssetCache.imageExists(named: "game-dino-push") {
                Image("game-dino-push")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else {
                Text("🦖")
                    .font(.system(size: 120))
            }
        }
    }

    private func playGoodJobAndCrowdThenDismiss() {
        let goodJobURL = speechManager.urlForAudio(key: "good-job-you-got-them-all")
        let crowdURL = speechManager.urlForAudio(key: "crowd-cheering")
        if let u1 = goodJobURL, let u2 = crowdURL {
            speechManager.playTogether(url1: u1, url2: u2) {
                self.speechManager.onAudioFinished = nil
                self.isPresented = false
            }
        } else if let u = goodJobURL ?? crowdURL {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.isPresented = false
            }
            speechManager.playAudioFile(url: u)
        } else {
            isPresented = false
        }
    }

    private func racerResultImage(_ racer: DinoPushRacer) -> some View {
        let imgName = racerVictoryImageName(racer)
        return Group {
            if let name = imgName, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
            } else {
                Text(racer.icon)
                    .font(.system(size: 80))
            }
        }
    }
}

// MARK: - Racer Card

private struct DinoPushRacerCard: View {
    let racer: DinoPushRacer
    let selectionImageName: String?
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if let img = selectionImageName {
                    Image(img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                } else {
                    Text(racer.icon)
                        .font(.system(size: 48))
                }
                Text(racer.name)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("\(Int(racer.strength))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.12)))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            )
            .opacity(isDisabled && !isSelected ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled && !isSelected)
    }
}

// MARK: - Config (pools per period)

enum DinoPushPeriod: String, CaseIterable {
    case jurassic
    case cretaceous
    case both
}

private struct DinoPushPoolEntry {
    let name: String
    let icon: String
    let strength: Double
}

private let jurassicPushPool: [DinoPushPoolEntry] = [
    DinoPushPoolEntry(name: "Allosaurus", icon: "🦖", strength: 80),
    DinoPushPoolEntry(name: "Stegosaurus", icon: "🦎", strength: 75),
    DinoPushPoolEntry(name: "Apatosaurus", icon: "🦕", strength: 88),
    DinoPushPoolEntry(name: "Diplodocus", icon: "🦕", strength: 85),
    DinoPushPoolEntry(name: "Compsognathus", icon: "🦖", strength: 25),
    DinoPushPoolEntry(name: "Brontosaurus", icon: "🦕", strength: 85),
]

private let cretaceousPushPool: [DinoPushPoolEntry] = [
    DinoPushPoolEntry(name: "T-Rex", icon: "🦖", strength: 95),
    DinoPushPoolEntry(name: "Triceratops", icon: "🦏", strength: 90),
    DinoPushPoolEntry(name: "Ankylosaurus", icon: "🛡️", strength: 98),
    DinoPushPoolEntry(name: "Velociraptor", icon: "🦖", strength: 35),
    DinoPushPoolEntry(name: "Gallimimus", icon: "🦃", strength: 30),
    DinoPushPoolEntry(name: "Albertosaurus", icon: "🦖", strength: 85),
]

struct DinoPushGameConfigs {
    /// Config with empty racers: DinoPushGameView shows period selection first, then dinosaur selection.
    static let dinoPushNeedsPeriod: DinoPushGameConfig = DinoPushGameConfig(
        id: "dino-push",
        title: "Dino Push!",
        introAudio: "game-dino-push",
        assetPrefix: "dino",
        racers: []
    )

    /// Returns a new config from the period's pool. Call when user picks a period.
    static func makeConfig(for period: DinoPushPeriod) -> DinoPushGameConfig {
        let pool: [DinoPushPoolEntry]
        let idBase: Int
        let title: String
        switch period {
        case .jurassic:
            pool = jurassicPushPool
            idBase = 100
            title = "Dino Push! (Jurassic)"
        case .cretaceous:
            pool = cretaceousPushPool
            idBase = 200
            title = "Dino Push! (Cretaceous)"
        case .both:
            pool = jurassicPushPool + cretaceousPushPool
            idBase = 0
            title = "Dino Push! (Both)"
        }
        let racers = pool.enumerated().map { index, entry in
            DinoPushRacer(id: idBase + index + 1, name: entry.name, icon: entry.icon, strength: entry.strength, fallbackImageName: nil)
        }
        let periodId = period == .both ? "both" : period.rawValue
        return DinoPushGameConfig(
            id: "dino-push-\(periodId)",
            title: title,
            introAudio: "game-dino-push",
            assetPrefix: "dino",
            racers: Array(racers)
        )
    }
}

// MARK: - Period Selection (Jurassic / Cretaceous / Both)

struct DinoPushPeriodSelectionView: View {
    @Binding var isPresented: Bool
    var onSelectPeriod: (DinoPushGameConfig) -> Void
    var embedMode: Bool = false

    @State private var speechManager = SpeechManager()
    @State private var enabledJurassic = false
    @State private var enabledCretaceous = false
    @State private var enabledBoth = false
    @State private var hasStartedSequence = false
    @State private var showText = false

    private let periods: [(name: String, imageAssetName: String, emoji: String, period: DinoPushPeriod)] = [
        ("Jurassic", "game-dino-push-period-jurassic", "🦕", .jurassic),
        ("Cretaceous", "game-dino-push-period-cretaceous", "🦖", .cretaceous),
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose a period")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 24)
                    .opacity(showText ? 1 : 0)
                Text("Only dinosaurs from that period can push.")
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
                    bothPeriodCard(isEnabled: enabledBoth)
                }
                .padding(.horizontal, 24)
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
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
            .allowsHitTesting(enabledJurassic || enabledCretaceous || enabledBoth)
        }
    }

    private func bothPeriodCard(isEnabled: Bool) -> some View {
        Button {
            onSelectPeriod(DinoPushGameConfigs.makeConfig(for: .both))
            if !embedMode { isPresented = false }
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    if UIImage(named: "game-dino-push-period-jurassic") != nil {
                        Image("game-dino-push-period-jurassic")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 60)
                    } else {
                        Text("🦕")
                            .font(.system(size: 40))
                            .frame(height: 60)
                    }
                    if UIImage(named: "game-dino-push-period-cretaceous") != nil {
                        Image("game-dino-push-period-cretaceous")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 60)
                    } else {
                        Text("🦖")
                            .font(.system(size: 40))
                            .frame(height: 60)
                    }
                }
                Text("Both")
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

    private func periodCard(name: String, imageAssetName: String, emoji: String, period: DinoPushPeriod, isEnabled: Bool) -> some View {
        Button {
            onSelectPeriod(DinoPushGameConfigs.makeConfig(for: period))
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

    private func startPeriodSequence() {
        speechManager.onAudioFinished = {
            Task { @MainActor in
                self.speechManager.onAudioFinished = nil
                self.periodIntroDone()
            }
        }
        speechManager.speak("game-dino-push-choose-period")
    }

    private func periodIntroDone() {
        enabledJurassic = true
        speechManager.onAudioFinished = {
            Task { @MainActor in
                self.speechManager.onAudioFinished = nil
                self.jurassicDone()
            }
        }
        speechManager.speak("game-dino-push-jurassic", chainDelay: true)
    }

    private func jurassicDone() {
        enabledCretaceous = true
        speechManager.onAudioFinished = {
            Task { @MainActor in
                self.speechManager.onAudioFinished = nil
                self.cretaceousDone()
            }
        }
        speechManager.speak("game-dino-push-cretaceous", chainDelay: true)
    }

    private func cretaceousDone() {
        enabledBoth = true
        speechManager.onAudioFinished = nil
        if speechManager.urlForAudio(key: "game-dino-push-both") != nil {
            speechManager.speak("game-dino-push-both", chainDelay: true)
        }
    }
}
