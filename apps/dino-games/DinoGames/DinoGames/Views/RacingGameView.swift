//
//  RacingGameView.swift
//  DinoGames
//
//  Racing Dinosaurs!: Player picks two dinosaurs from four per period; they race on an oval track.
//  Uses emojis for now (racer-* and winner-race-* imagesets can be added later).
//

import SwiftUI
import AVFoundation

// MARK: - Data Models

struct RacingRacer: Identifiable {
    let id: Int
    let name: String
    let icon: String // Emoji fallback when imageset missing
    let speed: Double // Estimated top speed (mph) for deterministic winner

    /// Slug for asset names: lowercase, spaces → hyphens (e.g. "T-Rex" → "t-rex").
    var imageSlug: String {
        name.lowercased().replacingOccurrences(of: " ", with: "-")
    }
    /// racer-{slug} imageset (track & field jersey); use icon if missing.
    var racerImageName: String { "racer-\(imageSlug)" }
    /// winner-race-{slug} imageset (winner pose with trophy); use icon if missing.
    var winnerImageName: String { "winner-race-\(imageSlug)" }
}

struct RacingGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let racers: [RacingRacer] // 4 dinosaurs per period
}

// MARK: - Main View

private let tickInterval: TimeInterval = 1.0
private let stepPerTick: Double = 0.1 // Progress per tick; faster dino gains more (speed/maxSpeed) * stepPerTick

struct RacingGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: RacingGameConfig
    
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
    /// Pre-race: 0 = racer1 image 2s, 1 = racer2 image 2s, 2 = referee-start image 2s then starting-whistle
    @State private var preRaceStep: Int? = nil
    /// Post-race: "referee" = referee-finish image + crowd-cheering, "winner" = winner-race-{slug}
    @State private var postRaceStep: String? = nil
    @State private var hasPlayedStartingGun = false
    @State private var hasPlayedWeHaveAWinner = false
    /// When non-nil, show large image + name and play racer name audio; on finish apply selection and return to grid.
    @State private var showingExpandedRacer: RacingRacer? = nil
    @State private var hasPlayedFirstRacerPrompt = false

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
                    Text(gameConfig.title)
                        .font(.title2)
                        .padding(.top, 8)
                    
                    if showSelection {
                        if let racer = showingExpandedRacer {
                            expandedRacerView(geometry: geometry, racer: racer)
                        } else {
                            selectionGrid(geometry: geometry)
                                .onAppear {
                                    if selectedLane1 == nil && !hasPlayedFirstRacerPrompt {
                                        hasPlayedFirstRacerPrompt = true
                                        speechManager.speak("game-racer-choose-your-first-dinosaur-to-race")
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
                        ForEach(Array(gameConfig.racers.dropFirst(row * 2).prefix(2))) { racer in
                            RacingRacerCard(
                                racer: racer,
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
            speechManager.speak(racer.name)
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.showingExpandedRacer = nil
                self.selectedLane1 = racer
                self.canSelectSecond = true
                self.speechManager.speak("game-racer-choose-your-second-dinosaur-to-race")
            }
        } else if selectedLane2 == nil && pendingRacer2 == nil && selectedLane1?.id != racer.id && canSelectSecond {
            showingExpandedRacer = racer
            canSelectSecond = false
            speechManager.speak(racer.name)
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.showingExpandedRacer = nil
                self.selectedLane2 = racer
                self.beginPreRaceSequence()
            }
        }
    }

    /// Temporary large view: racer image + full name below; plays racer name audio, then on finish caller returns to grid.
    private func expandedRacerView(geometry: GeometryProxy, racer: RacingRacer) -> some View {
        let size = min(geometry.size.width, geometry.size.height) * 0.45
        return VStack(spacing: 20) {
            if UIImage(named: racer.racerImageName) != nil {
                Image(racer.racerImageName)
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

    // MARK: - Pre-race (racer1 2s → racer2 2s → referee-start 2s → starting-whistle → track)

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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            preRaceStep = 1
                        }
                    }
            } else if step == 1 {
                racerImageFullView(racer: racer2, size: min(geometry.size.width, geometry.size.height) * 0.5)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            preRaceStep = 2
                        }
                    }
            } else {
                refereeImageView("racer-referee-start")
                    .onAppear {
                        guard !hasPlayedStartingGun else { return }
                        hasPlayedStartingGun = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            speechManager.speak("starting-whistle")
                            // Show track shortly after whistle starts so the gap feels short (whistle continues in background)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                self.speechManager.onAudioFinished = nil
                                self.preRaceStep = nil
                                self.isRacing = true
                                self.fireRaceTimer(r1: racer1, r2: racer2)
                            }
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func racerImageFullView(racer: RacingRacer, size: CGFloat) -> some View {
        Group {
            if UIImage(named: racer.racerImageName) != nil {
                Image(racer.racerImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Text(racer.icon)
                    .font(.system(size: size * 0.8))
            }
        }
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
            if UIImage(named: "game-referee-finish") != nil {
                refereeImageView("game-referee-finish")
            } else {
                refereeImageView("racer-referee-finish")
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
    
    // MARK: - Race (oval track: center→right, up, right→left, down, left→center)

    private func raceTrack(geometry: GeometryProxy) -> some View {
        guard let r1 = selectedLane1, let r2 = selectedLane2 else { return AnyView(EmptyView()) }
        return AnyView(ovalTrackView(geometry: geometry, progress1: progress1, progress2: progress2, racer1: r1, racer2: r2))
    }

    /// Oval path: 1) left→right from middle, 2) up one row, 3) right→left, 4) down one row, 5) left→right to middle.
    private func pointOnOval(progress: Double, width: CGFloat, height: CGFloat) -> CGPoint {
        let p = max(0, min(1, progress))
        let w = width
        let h = height
        let cx = w / 2
        if p <= 0.2 {
            let t = p / 0.2
            return CGPoint(x: cx + t * (w - cx), y: h)
        } else if p <= 0.4 {
            let t = (p - 0.2) / 0.2
            return CGPoint(x: w, y: h - t * h)
        } else if p <= 0.6 {
            let t = (p - 0.4) / 0.2
            return CGPoint(x: w - t * w, y: 0)
        } else if p <= 0.8 {
            let t = (p - 0.6) / 0.2
            return CGPoint(x: 0, y: t * h)
        } else {
            let t = (p - 0.8) / 0.2
            return CGPoint(x: t * cx, y: h)
        }
    }

    private func ovalTrackView(geometry: GeometryProxy, progress1: Double, progress2: Double, racer1: RacingRacer, racer2: RacingRacer) -> some View {
        let padding: CGFloat = 24
        let ovalWidth = geometry.size.width - padding * 2
        let ovalHeight = max(120, geometry.size.height - 140)
        let racerSize: CGFloat = 48
        let trackInset: CGFloat = 44 // Inner track inset so both racers stay visible (no overlay when neck-and-neck)

        // Outer oval (racer 1) and inner oval (racer 2) in same coordinate space
        let outerPath = Path { path in
            path.addRect(CGRect(x: 0, y: 0, width: ovalWidth, height: ovalHeight))
        }
        let innerW = ovalWidth - trackInset * 2
        let innerH = ovalHeight - trackInset * 2
        let innerPath = Path { path in
            path.addRect(CGRect(x: trackInset, y: trackInset, width: innerW, height: innerH))
        }

        // Outer and inner positions for each racer's progress (inner track is shorter)
        let pt1Outer = pointOnOval(progress: progress1, width: ovalWidth, height: ovalHeight)
        let pt2Outer = pointOnOval(progress: progress2, width: ovalWidth, height: ovalHeight)
        let pt1InnerRaw = pointOnOval(progress: progress1, width: innerW, height: innerH)
        let pt2InnerRaw = pointOnOval(progress: progress2, width: innerW, height: innerH)
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
        return VStack(spacing: 8) {
            Text("Race!")
                .font(.headline)
            ZStack(alignment: .topLeading) {
                outerPath
                    .stroke(Color.gray.opacity(0.5), lineWidth: 6)
                    .frame(width: ovalWidth, height: ovalHeight)
                innerPath
                    .stroke(Color.gray.opacity(0.35), lineWidth: 6)
                    .frame(width: ovalWidth, height: ovalHeight)
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
            }
            .frame(width: ovalWidth, height: ovalHeight)
        }
        .padding(.horizontal, padding)
    }

    private func racerView(racer: RacingRacer, size: CGFloat) -> some View {
        Group {
            if UIImage(named: racer.racerImageName) != nil {
                Image(racer.racerImageName)
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
                if UIImage(named: racer.racerImageName) != nil {
                    Image(racer.racerImageName)
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
            self.speechManager.onAudioFinished = nil
            self.fireRaceTimer(r1: r1, r2: r2)
        }
    }

    private func fireRaceTimer(r1: RacingRacer, r2: RacingRacer) {
        let maxSpeed = max(r1.speed, r2.speed)
        raceTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { _ in
            let newP1 = min(1.0, progress1 + stepPerTick * (r1.speed / maxSpeed))
            let newP2 = min(1.0, progress2 + stepPerTick * (r2.speed / maxSpeed))
            DispatchQueue.main.async {
                progress1 = newP1
                progress2 = newP2
                if newP1 >= 1.0 || newP2 >= 1.0 {
                    stopRace()
                    winner = newP1 >= newP2 ? r1 : r2
                    postRaceStep = "referee"
                }
            }
        }
        raceTimer?.fire()
    }

    private func stopRace() {
        raceTimer?.invalidate()
        raceTimer = nil
    }
    
    // MARK: - Winner (announce by text + audio: optional "racing-the-winner-is", then crowd-cheering + dino name)
    private func winnerView(winner w: RacingRacer) -> some View {
        VStack(spacing: 20) {
            Text("🏆")
                .font(.system(size: 60))
            Text("The winner is")
                .font(.title3)
                .foregroundColor(.secondary)
            if UIImage(named: w.winnerImageName) != nil {
                Image(w.winnerImageName)
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
        let announceURL = speechManager.urlForAudio(key: "racing-the-winner-is")
        let crowdURL = speechManager.urlForAudio(key: "crowd-cheering")
        let winnerURL = speechManager.urlForAudio(key: w.name)

        func playCrowdAndWinnerThenDismiss() {
            if let u1 = crowdURL, let u2 = winnerURL {
                speechManager.playTogether(url1: u1, url2: u2) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.isPresented = false
                    }
                }
            } else if let u = crowdURL ?? winnerURL {
                speechManager.playAudioFile(url: u)
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.isPresented = false
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isPresented = false
                }
            }
        }

        if let url = announceURL {
            speechManager.playAudioFile(url: url)
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                playCrowdAndWinnerThenDismiss()
            }
        } else {
            playCrowdAndWinnerThenDismiss()
        }
    }
}

// MARK: - Racer Card (racer-{slug} image when present, else emoji)

struct RacingRacerCard: View {
    let racer: RacingRacer
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                if UIImage(named: racer.racerImageName) != nil {
                    Image(racer.racerImageName)
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

struct RacingGameConfigs {
    /// Config used for the game list card only (id "racing-dinosaurs" matches imageset game-racing-dinosaurs). Period choice then loads Jurassic or Cretaceous.
    static let racingDinosaurs: RacingGameConfig = {
        makeConfig(for: .cretaceous)
    }()

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
            RacingRacer(id: idBase + index + 1, name: entry.name, icon: entry.icon, speed: entry.speed)
        }
        return RacingGameConfig(
            id: "racing-dinosaurs-\(period.rawValue)",
            title: title,
            introAudio: "racing-dinosaurs",
            racers: Array(racers)
        )
    }
}

// MARK: - Period Selection (Jurassic / Cretaceous)

struct RacingPeriodSelectionView: View {
    @Binding var isPresented: Bool
    var onSelectPeriod: (RacingGameConfig) -> Void

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
            isPresented = false
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
            self.speechManager.onAudioFinished = nil
            self.periodIntroDone()
        }
        speechManager.speak("cover-choose-a-period")
    }

    private func periodIntroDone() {
        enabledJurassic = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.jurassicDone()
        }
        speechManager.speak("cover-jurassic", chainDelay: true)
    }

    private func jurassicDone() {
        enabledCretaceous = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            showText = true
        }
        speechManager.speak("cover-cretaceous", chainDelay: true)
    }
}

#Preview {
    RacingGameView(isPresented: .constant(true), gameConfig: RacingGameConfigs.racingDinosaurs)
}
