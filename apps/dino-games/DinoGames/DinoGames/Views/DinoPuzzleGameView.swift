//
//  DinoPuzzleGameView.swift
//  DinoGames
//
//  Dino Puzzle: three rounds. Each round picks a dinosaur from a distinct clade, splits its portrait
//  into one of ten grid “jigsaw” patterns, and the player drags pieces onto matching slots.
//

import SwiftUI

// MARK: - Pattern (10 distinct row×column splits)

enum DinoPuzzlePattern: Int, CaseIterable, Equatable {
    case grid2x2 = 0
    case grid2x3 = 1
    case grid3x2 = 2
    case grid3x3 = 3
    case grid2x4 = 4
    case grid4x2 = 5
    case grid3x4 = 6
    case grid4x3 = 7
    case grid2x5 = 8
    case grid5x2 = 9

    var rows: Int {
        switch self {
        case .grid2x2, .grid2x3, .grid2x4, .grid2x5: return 2
        case .grid3x2, .grid3x3, .grid3x4: return 3
        case .grid4x2, .grid4x3: return 4
        case .grid5x2: return 5
        }
    }

    var cols: Int {
        switch self {
        case .grid2x2, .grid3x2, .grid4x2, .grid5x2: return 2
        case .grid2x3, .grid3x3, .grid4x3: return 3
        case .grid2x4, .grid3x4: return 4
        case .grid2x5: return 5
        }
    }

    var pieceCount: Int { rows * cols }
}

// MARK: - Config

struct DinoPuzzleGameConfig: Equatable {
    let id: String
    let title: String
    let introAudio: String
}

enum DinoPuzzleGameConfigs {
    static let dinoPuzzle = DinoPuzzleGameConfig(
        id: "dino-puzzle",
        title: "Dino Puzzle",
        introAudio: "game-dino-puzzle"
    )
}

// MARK: - Round generation

private struct DinoPuzzleRoundBuilt: Identifiable {
    let id: Int
    let dinosaur: Dinosaur
    let clade: DinoClade
    let pattern: DinoPuzzlePattern
}

private enum DinoPuzzleRoundGenerator {
    static func makeRounds(pool: [Dinosaur] = LandDinosaurData.allDinosaurs) -> [DinoPuzzleRoundBuilt] {
        let shuffledClades = DinoClade.allCases.shuffled()
        let chosen = Array(shuffledClades.prefix(3))
        return chosen.enumerated().map { index, clade in
            let inClade = pool.filter { LandDinosaurCladeCatalog.clade(forCreatureId: $0.id) == clade }
            let dinosaur = inClade.randomElement() ?? pool.randomElement()!
            let pattern = DinoPuzzlePattern.allCases.randomElement() ?? .grid2x2
            return DinoPuzzleRoundBuilt(id: index + 1, dinosaur: dinosaur, clade: clade, pattern: pattern)
        }
    }
}

// MARK: - Piece model

private struct DinoPuzzlePieceModel: Identifiable {
    let id: Int
    let row: Int
    let col: Int
    var center: CGPoint
    var isLocked: Bool
}

// MARK: - Piece view (cropped cell of full image)

private struct DinoPuzzlePieceImage: View {
    let imageName: String?
    let emojiFallback: String
    let boardSide: CGFloat
    let rows: Int
    let cols: Int
    let row: Int
    let col: Int

    var body: some View {
        let cw = boardSide / CGFloat(cols)
        let ch = boardSide / CGFloat(rows)
        Group {
            if let name = imageName, ImageAssetCache.imageExists(named: name) {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: boardSide, height: boardSide, alignment: .topLeading)
                    .offset(x: -CGFloat(col) * cw, y: -CGFloat(row) * ch)
                    .frame(width: cw, height: ch)
                    .clipped()
            } else {
                Text(emojiFallback)
                    .font(.system(size: min(cw, ch) * 0.55))
                    .frame(width: cw, height: ch)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.2)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.primary.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Main view

struct DinoPuzzleGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: DinoPuzzleGameConfig

    @State private var speechManager = SpeechManager()
    @State private var rounds: [DinoPuzzleRoundBuilt] = []
    @State private var currentRoundIndex = 0
    @State private var pieces: [DinoPuzzlePieceModel] = []
    @State private var boardSide: CGFloat = 280
    @State private var isAudioPlaying = false
    @State private var isGameComplete = false
    @State private var dragStartById: [Int: CGPoint] = [:]
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var didScheduleFirstLayoutIntro = false

    private var currentRound: DinoPuzzleRoundBuilt? {
        guard currentRoundIndex < rounds.count else { return nil }
        return rounds[currentRoundIndex]
    }

    private func cladeTitle(_ clade: DinoClade) -> String {
        clade.rawValue
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    private func homeCenter(row: Int, col: Int, rows: Int, cols: Int, side: CGFloat) -> CGPoint {
        let cw = side / CGFloat(cols)
        let ch = side / CGFloat(rows)
        return CGPoint(x: (CGFloat(col) + 0.5) * cw, y: (CGFloat(row) + 0.5) * ch)
    }

    private func scatterCenter(
        row: Int,
        col: Int,
        rows: Int,
        cols: Int,
        side: CGFloat,
        existing: [CGPoint],
        home: CGPoint
    ) -> CGPoint {
        let cw = side / CGFloat(cols)
        let ch = side / CGFloat(rows)
        let minEdge = max(12, min(cw, ch) * 0.35)
        let snapThreshold = max(18, min(cw, ch) * 0.28)
        for _ in 0..<80 {
            let x = CGFloat.random(in: cw / 2 ... side - cw / 2)
            let y = CGFloat.random(in: ch / 2 ... side - ch / 2)
            let p = CGPoint(x: x, y: y)
            if hypot(p.x - home.x, p.y - home.y) < snapThreshold * 2.2 { continue }
            if existing.contains(where: { hypot($0.x - p.x, $0.y - p.y) < minEdge }) { continue }
            return p
        }
        return CGPoint(x: side * 0.85, y: side * 0.2 + CGFloat((row + col) % 3) * 40)
    }

    private func setupPieces(for round: DinoPuzzleRoundBuilt, side: CGFloat) {
        let rows = round.pattern.rows
        let cols = round.pattern.cols
        var built: [DinoPuzzlePieceModel] = []
        var centers: [CGPoint] = []
        var pid = 0
        for r in 0..<rows {
            for c in 0..<cols {
                let home = homeCenter(row: r, col: c, rows: rows, cols: cols, side: side)
                let start = scatterCenter(row: r, col: c, rows: rows, cols: cols, side: side, existing: centers, home: home)
                centers.append(start)
                built.append(DinoPuzzlePieceModel(id: pid, row: r, col: c, center: start, isLocked: false))
                pid += 1
            }
        }
        pieces = built
    }

    private func startRoundIntro() {
        guard let round = currentRound else { return }
        isAudioPlaying = true
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.isAudioPlaying = false
        }
        let key = round.dinosaur.imageName
            ?? round.dinosaur.name.lowercased().replacingOccurrences(of: " ", with: "-")
        speechManager.speak(audioKey: key, fallbackText: round.dinosaur.name)
    }

    private func snapThreshold(for round: DinoPuzzleRoundBuilt, side: CGFloat) -> CGFloat {
        let cw = side / CGFloat(round.pattern.cols)
        let ch = side / CGFloat(round.pattern.rows)
        return max(20, min(cw, ch) * 0.32)
    }

    private func attemptSnap(pieceId: Int) {
        guard let round = currentRound,
              let idx = pieces.firstIndex(where: { $0.id == pieceId }),
              !pieces[idx].isLocked
        else { return }
        let side = boardSide
        let rows = round.pattern.rows
        let cols = round.pattern.cols
        let home = homeCenter(row: pieces[idx].row, col: pieces[idx].col, rows: rows, cols: cols, side: side)
        let d = hypot(pieces[idx].center.x - home.x, pieces[idx].center.y - home.y)
        let thresh = snapThreshold(for: round, side: side)
        if d <= thresh {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                pieces[idx].center = home
                pieces[idx].isLocked = true
            }
            if pieces.allSatisfy({ $0.isLocked }) {
                finishPuzzleRound()
            }
        }
    }

    private func finishPuzzleRound() {
        isAudioPlaying = true
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            if self.currentRoundIndex < 2 {
                self.currentRoundIndex += 1
                if let r = self.currentRound {
                    self.setupPieces(for: r, side: self.boardSide)
                    self.startRoundIntro()
                }
            } else {
                self.isGameComplete = true
                self.isAudioPlaying = false
            }
        }
        speechManager.speak("thats-right-you-guessed-it")
    }

    private func playGoodJobAndCrowdThenDismiss() {
        let goodJobURL = speechManager.urlForAudio(key: "good-job-you-got-them-all")
        let crowdURL = speechManager.urlForAudio(key: "crowd-cheering")
        if let u1 = goodJobURL, let u2 = crowdURL {
            speechManager.playTogether(url1: u1, url2: u2) {
                self.speechManager.onAudioFinished = nil
                LandDinosaurProgress.notifyCompletionIfLandGame(configId: self.gameConfig.id)
                self.isPresented = false
            }
        } else if let u = goodJobURL ?? crowdURL {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                LandDinosaurProgress.notifyCompletionIfLandGame(configId: self.gameConfig.id)
                self.isPresented = false
            }
            speechManager.playAudioFile(url: u)
        } else {
            LandDinosaurProgress.notifyCompletionIfLandGame(configId: gameConfig.id)
            isPresented = false
        }
    }

    private func advanceEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        let dinos = rounds.map(\.dinosaur)
        if endHighlightIndex < dinos.count {
            let d = dinos[endHighlightIndex]
            let key = d.imageName ?? d.name.lowercased().replacingOccurrences(of: " ", with: "-")
            speechManager.speak(audioKey: key, fallbackText: d.name)
            speechManager.onAudioFinished = { advanceEndHighlight() }
        } else {
            playGoodJobAndCrowdThenDismiss()
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if isGameComplete {
                    dinoPuzzleEndSequenceView
                } else if let round = currentRound {
                    dinoPuzzleActiveView(round: round)
                } else {
                    Text("Loading…")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(gameConfig.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        speechManager.stopCurrentAudio()
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            rounds = DinoPuzzleRoundGenerator.makeRounds()
            currentRoundIndex = 0
            isGameComplete = false
            endSequenceStep = -1
            endHighlightIndex = 0
            pieces = []
            didScheduleFirstLayoutIntro = false
            dragStartById = [:]
        }
        .onDisappear {
            speechManager.onAudioFinished = nil
            speechManager.stopCurrentAudio()
            isAudioPlaying = false
        }
    }

    @ViewBuilder
    private func dinoPuzzleActiveView(round: DinoPuzzleRoundBuilt) -> some View {
        let rows = round.pattern.rows
        let cols = round.pattern.cols
        VStack(spacing: 16) {
            Text("Round \(currentRoundIndex + 1) of 3")
                .font(.headline)
                .foregroundColor(.secondary)
            Text(cladeTitle(round.clade))
                .font(.title3)
                .fontWeight(.semibold)
            Text("Drag each piece into the matching outline.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            GeometryReader { geo in
                let side = min(geo.size.width - 16, min(geo.size.height - 8, 380))
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor.opacity(0.45), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                        .frame(width: side, height: side)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.08))
                        )

                    ForEach(0..<rows, id: \.self) { r in
                        ForEach(0..<cols, id: \.self) { c in
                            let cw = side / CGFloat(cols)
                            let ch = side / CGFloat(rows)
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                .frame(width: cw - 2, height: ch - 2)
                                .position(
                                    x: (CGFloat(c) + 0.5) * cw,
                                    y: (CGFloat(r) + 0.5) * ch
                                )
                        }
                    }

                    ForEach(pieces) { piece in
                        let cw = side / CGFloat(cols)
                        let ch = side / CGFloat(rows)
                        DinoPuzzlePieceImage(
                            imageName: round.dinosaur.imageName,
                            emojiFallback: round.dinosaur.icon,
                            boardSide: side,
                            rows: rows,
                            cols: cols,
                            row: piece.row,
                            col: piece.col
                        )
                        .frame(width: cw, height: ch)
                        .position(piece.center)
                        .zIndex(piece.isLocked ? 0 : 2)
                        .shadow(color: .black.opacity(piece.isLocked ? 0 : 0.18), radius: 4, y: 2)
                        .gesture(
                            DragGesture()
                                .onChanged { g in
                                    guard !piece.isLocked, !isAudioPlaying else { return }
                                    if dragStartById[piece.id] == nil {
                                        dragStartById[piece.id] = piece.center
                                    }
                                    guard let start = dragStartById[piece.id],
                                          let idx = pieces.firstIndex(where: { $0.id == piece.id })
                                    else { return }
                                    pieces[idx].center = CGPoint(
                                        x: start.x + g.translation.width,
                                        y: start.y + g.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    dragStartById[piece.id] = nil
                                    attemptSnap(pieceId: piece.id)
                                }
                        )
                        .allowsHitTesting(!piece.isLocked && !isAudioPlaying)
                    }
                }
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    boardSide = side
                    guard let r = currentRound, side > 40 else { return }
                    setupPieces(for: r, side: side)
                    if !didScheduleFirstLayoutIntro {
                        didScheduleFirstLayoutIntro = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            startRoundIntro()
                        }
                    }
                }
                .onChange(of: side) { _, newSide in
                    guard let r = currentRound, newSide > 40 else { return }
                    boardSide = newSide
                    if pieces.contains(where: { $0.isLocked }) { return }
                    setupPieces(for: r, side: newSide)
                }
            }
            .frame(minHeight: 320)
        }
        .padding()
        .allowsHitTesting(!isAudioPlaying)
        .opacity(isAudioPlaying ? 0.75 : 1)
    }

    private var dinoPuzzleEndSequenceView: some View {
        let dinos = rounds.map(\.dinosaur)
        return VStack(spacing: 16) {
            Text("You solved all three!")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            VStack(spacing: 12) {
                ForEach(Array(dinos.enumerated()), id: \.offset) { index, dinosaur in
                    let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                    HStack(spacing: 16) {
                        Group {
                            if let name = dinosaur.imageName, ImageAssetCache.imageExists(named: name) {
                                Image(name)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                Text(dinosaur.icon)
                                    .font(.system(size: 40))
                                    .frame(width: 72, height: 72)
                            }
                        }
                        .opacity(isHighlighted ? 1 : 0.45)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                        )

                        Text(dinosaur.name)
                            .font(.title3)
                            .fontWeight(isHighlighted ? .semibold : .regular)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear)
                    )
                }
            }
            Spacer()
        }
        .padding()
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            isAudioPlaying = true
            if dinos.isEmpty {
                playGoodJobAndCrowdThenDismiss()
            } else {
                let d = dinos[0]
                let key = d.imageName ?? d.name.lowercased().replacingOccurrences(of: " ", with: "-")
                speechManager.speak(audioKey: key, fallbackText: d.name)
                speechManager.onAudioFinished = { advanceEndHighlight() }
            }
        }
    }
}
