//
//  PortraitJigsawPuzzleGameView.swift
//  DinoGames
//
//  Shared portrait jigsaw for Dino Puzzle (land clades), Ptero Puzzle (pterosaur groups), and Marine Reptile Puzzle (marine image groups).
//

import SwiftUI

// MARK: - Pattern (10 distinct row×column splits)

enum PortraitJigsawPuzzlePattern: Int, CaseIterable, Equatable {
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

// MARK: - Line (dino vs ptero)

enum PortraitJigsawPuzzleLine: Equatable {
    case dinosaur(DinoPuzzleGameConfig)
    case pterosaur(PteroPuzzleGameConfig)
    case marineReptile(MarineReptilePuzzleGameConfig)

    var navigationTitle: String {
        switch self {
        case .dinosaur(let c): return c.title
        case .pterosaur(let c): return c.title
        case .marineReptile(let c): return c.title
        }
    }

    var guessPromptAudioKey: String {
        switch self {
        case .dinosaur: return "game-dino-puzzle-guess-the-dinosaur-in-clade"
        case .pterosaur: return "game-ptero-puzzle-guess-the-pterosaur-in-clade"
        case .marineReptile: return "game-marine-reptile-puzzle-guess-the-marine-reptile-in-clade"
        }
    }

    var directionsAudioKey: String {
        switch self {
        case .dinosaur: return "game-dino-puzzle-gameplay-directions"
        case .pterosaur: return "game-ptero-puzzle-gameplay-directions"
        case .marineReptile: return "game-marine-reptile-puzzle-gameplay-directions"
        }
    }

    var successImagePrimary: String {
        switch self {
        case .dinosaur: return "game-dino-puzzle-success"
        case .pterosaur: return "game-ptero-puzzle-success"
        case .marineReptile: return "game-marine-reptile-puzzle-success"
        }
    }

    var successImageFallback: String {
        switch self {
        case .dinosaur: return "game-dino-puzzle"
        case .pterosaur: return "game-ptero-puzzle"
        case .marineReptile: return "game-marine-reptile-puzzle"
        }
    }

    /// Config id for `LandGameVictorySuccessStingerThenContinue` (`game-{id}-success`, `game-{id}-victory` stinger).
    var catalogGameId: String {
        switch self {
        case .dinosaur(let c): return c.id
        case .pterosaur(let c): return c.id
        case .marineReptile(let c): return c.id
        }
    }

    var successImageCandidateNames: [String] {
        [successImagePrimary, successImageFallback]
    }

    func notifyGameCompleted() {
        switch self {
        case .dinosaur(let c):
            LandDinosaurProgress.notifyCompletionIfLandGame(configId: c.id)
        case .pterosaur(let c):
            PterosaurProgress.notifyCompletionIfPterosaurGame(configId: c.id)
        case .marineReptile(let c):
            MarineReptileProgress.notifyCompletionIfMarineGame(configId: c.id)
        }
    }
}

private enum PortraitJigsawRoundBucket: Equatable {
    case dinosaur(DinoClade)
    case pterosaur(PterosaurGuessGroup)
    /// Middle segment of `marine-<group>-*` image names (e.g. `mosa`, `plesio`).
    case marineClade(String)
}

private struct PortraitJigsawRoundBuilt: Identifiable {
    let id: Int
    let creature: Dinosaur
    let bucket: PortraitJigsawRoundBucket
    let pattern: PortraitJigsawPuzzlePattern
}

private enum PortraitJigsawRoundGenerator {
    static func makeRounds(for line: PortraitJigsawPuzzleLine) -> [PortraitJigsawRoundBuilt] {
        switch line {
        case .dinosaur:
            let pool = LandDinosaurData.allDinosaurs
            let shuffledClades = DinoClade.allCases.shuffled()
            let chosen = Array(shuffledClades.prefix(3))
            return chosen.enumerated().map { index, clade in
                let inClade = pool.filter { LandDinosaurCladeCatalog.clade(forCreatureId: $0.id) == clade }
                let dinosaur = inClade.randomElement() ?? pool.randomElement()!
                let pattern = PortraitJigsawPuzzlePattern.allCases.randomElement() ?? .grid2x2
                return PortraitJigsawRoundBuilt(
                    id: index + 1,
                    creature: dinosaur,
                    bucket: .dinosaur(clade),
                    pattern: pattern
                )
            }
        case .pterosaur:
            let pool = AirPterosaurData.allPterosaurs
            let shuffled = PterosaurGuessGroup.allCases.shuffled()
            let chosen = Array(shuffled.prefix(3))
            return chosen.enumerated().map { index, group in
                let inGroup = pool.filter { PterosaurGuessGroup.guessGroup(forImageName: $0.imageName ?? "") == group }
                let creature = inGroup.randomElement() ?? pool.randomElement()!
                let pattern = PortraitJigsawPuzzlePattern.allCases.randomElement() ?? .grid2x2
                return PortraitJigsawRoundBuilt(
                    id: index + 1,
                    creature: creature,
                    bucket: .pterosaur(group),
                    pattern: pattern
                )
            }
        case .marineReptile:
            let pool = SeaMarineReptileData.allMarineReptiles
            let distinctGroups = Array(Set(pool.map { SeaMarineReptileData.marineCladeRawValue(for: $0) })).shuffled()
            var chosenGroups: [String] = Array(distinctGroups.prefix(3))
            while chosenGroups.count < 3 {
                chosenGroups.append(distinctGroups.randomElement() ?? SeaMarineReptileData.marineCladeRawValue(for: pool[0]))
            }
            chosenGroups = Array(chosenGroups.prefix(3))
            return chosenGroups.enumerated().map { index, group in
                let inGroup = pool.filter { SeaMarineReptileData.marineCladeRawValue(for: $0) == group }
                let creature = inGroup.randomElement() ?? pool.randomElement()!
                let pattern = PortraitJigsawPuzzlePattern.allCases.randomElement() ?? .grid2x2
                return PortraitJigsawRoundBuilt(
                    id: index + 1,
                    creature: creature,
                    bucket: .marineClade(group),
                    pattern: pattern
                )
            }
        }
    }
}

private struct PortraitJigsawPieceModel: Identifiable {
    let id: Int
    let row: Int
    let col: Int
    var center: CGPoint
    var isLocked: Bool
}

private struct PortraitJigsawPieceImage: View {
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
                ZStack(alignment: .topLeading) {
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .frame(width: boardSide, height: boardSide)
                        .offset(x: -CGFloat(col) * cw, y: -CGFloat(row) * ch)
                }
                .frame(width: cw, height: ch, alignment: .topLeading)
                .clipped()
            } else {
                Text(emojiFallback.isEmpty ? "🦕" : emojiFallback)
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

struct PortraitJigsawPuzzleGameView: View {
    @Binding var isPresented: Bool
    let line: PortraitJigsawPuzzleLine

    @State private var speechManager = SpeechManager()
    @State private var rounds: [PortraitJigsawRoundBuilt] = []
    @State private var currentRoundIndex = 0
    @State private var pieces: [PortraitJigsawPieceModel] = []
    @State private var boardSide: CGFloat = 280
    @State private var isAudioPlaying = false
    @State private var isGameComplete = false
    @State private var dragStartById: [Int: CGPoint] = [:]
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var draggingPieceId: Int?
    @State private var lastAnnouncedRoundId: Int?
    /// Last interaction order per piece; larger means visually on top.
    @State private var pieceInteractionOrderById: [Int: Int] = [:]
    @State private var nextPieceInteractionOrder: Int = 1

    private var currentRound: PortraitJigsawRoundBuilt? {
        guard currentRoundIndex < rounds.count else { return nil }
        return rounds[currentRoundIndex]
    }

    private func bucketTitle(_ bucket: PortraitJigsawRoundBucket) -> String {
        switch bucket {
        case .dinosaur(let clade):
            switch clade {
            case .stegosaur:
                return "Stegosaurid"
            default:
                return clade.rawValue
                    .replacingOccurrences(of: "-", with: " ")
                    .capitalized
            }
        case .pterosaur(let group):
            return group.displayName
        case .marineClade(let raw):
            return SeaMarineReptileData.displayTitleForMarineGroup(raw)
        }
    }

    private func cladeAudioKeys(_ bucket: PortraitJigsawRoundBucket) -> [String] {
        switch bucket {
        case .dinosaur(let clade):
            switch clade {
            case .stegosaur:
                return ["dino-clade-stegosaurid", "dino-clade-stegosaur"]
            default:
                return ["dino-clade-\(clade.rawValue)"]
            }
        case .pterosaur(let group):
            return ["ptero-clade-\(group.cladeAudioSlug)"]
        case .marineClade(let raw):
            let slug = SeaMarineReptileData.audioSlugForMarineGroupRaw(raw)
            return ["marine-clade-\(slug)"]
        }
    }

    private func footprintFallbackCladeAudioKey(_ clade: DinoClade) -> String? {
        switch clade {
        case .theropod: return "footprint-therapod"
        case .sauropod: return "footprint-sauropod"
        case .hadrosaur: return "footprint-hadrosaur"
        case .ceratopsian: return "footprint-ceratopsian"
        case .ankylosaurid: return "footprint-ankylosaur"
        case .spinosaurid, .stegosaur, .ornithopod, .pachycephalosaur:
            return nil
        }
    }

    private func playCladeAudio(_ bucket: PortraitJigsawRoundBucket) {
        for key in cladeAudioKeys(bucket) {
            if let url = speechManager.urlForAudio(key: key) {
                speechManager.playAudioFile(url: url)
                return
            }
        }
        if case .dinosaur(let clade) = bucket,
           let fallbackKey = footprintFallbackCladeAudioKey(clade),
           let url = speechManager.urlForAudio(key: fallbackKey) {
            speechManager.playAudioFile(url: url)
            return
        }
        speechManager.speak(bucketTitle(bucket))
    }

    private func announceRoundCladeIfNeeded(_ round: PortraitJigsawRoundBuilt) {
        guard lastAnnouncedRoundId != round.id else { return }
        lastAnnouncedRoundId = round.id
        isAudioPlaying = true
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playCladeAudio(round.bucket)
            self.speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.speechManager.speak(self.line.directionsAudioKey, chainDelay: true)
                self.speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.isAudioPlaying = false
                }
            }
        }
        speechManager.speak(line.guessPromptAudioKey)
    }

    private func homeCenter(row: Int, col: Int, rows: Int, cols: Int, side: CGFloat) -> CGPoint {
        let cw = side / CGFloat(cols)
        let ch = side / CGFloat(rows)
        return CGPoint(x: (CGFloat(col) + 0.5) * cw, y: (CGFloat(row) + 0.5) * ch)
    }

    private func scatterCenter(
        pieceIndex: Int,
        pieceCount: Int,
        rows: Int,
        cols: Int,
        side: CGFloat,
        existing: [CGPoint],
        home: CGPoint
    ) -> CGPoint {
        let cw = side / CGFloat(cols)
        let ch = side / CGFloat(rows)
        let minCenterDist = max(max(cw, ch) * 1.02, 34)
        let avoidHome = max(cw, ch) * 1.05
        for _ in 0..<220 {
            let x = CGFloat.random(in: cw * 0.55 ... side - cw * 0.55)
            let y = CGFloat.random(in: ch * 0.55 ... side - ch * 0.55)
            let p = CGPoint(x: x, y: y)
            if hypot(p.x - home.x, p.y - home.y) < avoidHome { continue }
            if existing.contains(where: { hypot($0.x - p.x, $0.y - p.y) < minCenterDist }) { continue }
            return p
        }
        let step = 2 * Double.pi / Double(max(pieceCount, 1))
        let angle = step * Double(pieceIndex) + 0.35
        let radius = min(side * 0.43, max(cw, ch) * 2.85)
        var p = CGPoint(
            x: side * 0.5 + CGFloat(cos(angle)) * radius,
            y: side * 0.5 + CGFloat(sin(angle)) * radius
        )
        p.x = min(max(p.x, cw * 0.55), side - cw * 0.55)
        p.y = min(max(p.y, ch * 0.55), side - ch * 0.55)
        if existing.contains(where: { hypot($0.x - p.x, $0.y - p.y) < minCenterDist * 0.55 }) {
            p.x += CGFloat((pieceIndex % 3) - 1) * cw * 0.22
            p.y += CGFloat((pieceIndex % 2)) * ch * 0.18
            p.x = min(max(p.x, cw * 0.55), side - cw * 0.55)
            p.y = min(max(p.y, ch * 0.55), side - ch * 0.55)
        }
        return p
    }

    private func separateCenters(_ centers: inout [CGPoint], minDistance: CGFloat, side: CGFloat, rows: Int, cols: Int) {
        guard centers.count > 1 else { return }
        let cw = side / CGFloat(cols)
        let ch = side / CGFloat(rows)
        let minX = cw * 0.55
        let maxX = side - cw * 0.55
        let minY = ch * 0.55
        let maxY = side - ch * 0.55

        for _ in 0..<40 {
            var moved = false
            for i in 0..<centers.count {
                for j in (i + 1)..<centers.count {
                    let dx = centers[j].x - centers[i].x
                    let dy = centers[j].y - centers[i].y
                    let dist = hypot(dx, dy)
                    guard dist < minDistance else { continue }
                    let safeDist = max(dist, 0.001)
                    let push = (minDistance - safeDist) / 2
                    let nx = dx / safeDist
                    let ny = dy / safeDist
                    centers[i].x -= nx * push
                    centers[i].y -= ny * push
                    centers[j].x += nx * push
                    centers[j].y += ny * push
                    centers[i].x = min(max(centers[i].x, minX), maxX)
                    centers[i].y = min(max(centers[i].y, minY), maxY)
                    centers[j].x = min(max(centers[j].x, minX), maxX)
                    centers[j].y = min(max(centers[j].y, minY), maxY)
                    moved = true
                }
            }
            if !moved { break }
        }
    }

    private func setupPieces(for round: PortraitJigsawRoundBuilt, side: CGFloat) {
        let rows = round.pattern.rows
        let cols = round.pattern.cols
        let pieceCount = rows * cols
        var built: [PortraitJigsawPieceModel] = []
        var centers: [CGPoint] = []
        var pid = 0
        for r in 0..<rows {
            for c in 0..<cols {
                let home = homeCenter(row: r, col: c, rows: rows, cols: cols, side: side)
                let start = scatterCenter(
                    pieceIndex: pid,
                    pieceCount: pieceCount,
                    rows: rows,
                    cols: cols,
                    side: side,
                    existing: centers,
                    home: home
                )
                centers.append(start)
                built.append(PortraitJigsawPieceModel(id: pid, row: r, col: c, center: start, isLocked: false))
                pid += 1
            }
        }
        let desiredSpacing = max(max(side / CGFloat(cols), side / CGFloat(rows)) * 1.02, 40)
        separateCenters(&centers, minDistance: desiredSpacing, side: side, rows: rows, cols: cols)
        for index in built.indices {
            built[index].center = centers[index]
        }
        pieces = built
        pieceInteractionOrderById = Dictionary(
            uniqueKeysWithValues: built.enumerated().map { ($0.element.id, $0.offset) }
        )
        nextPieceInteractionOrder = built.count + 1
    }

    private func pieceZIndex(_ piece: PortraitJigsawPieceModel) -> Double {
        if piece.isLocked { return 0 }
        if draggingPieceId == piece.id { return 120 }
        let order = pieceInteractionOrderById[piece.id] ?? piece.id
        return 2 + Double(order) * 0.001
    }

    private func bringPieceToFront(_ pieceId: Int) {
        pieceInteractionOrderById[pieceId] = nextPieceInteractionOrder
        nextPieceInteractionOrder += 1
    }

    private func snapThreshold(for round: PortraitJigsawRoundBuilt, side: CGFloat) -> CGFloat {
        let cw = side / CGFloat(round.pattern.cols)
        let ch = side / CGFloat(round.pattern.rows)
        return max(20, min(cw, ch) * 0.32)
    }

    private func clampPieceCenter(_ center: CGPoint, side: CGFloat, rows: Int, cols: Int) -> CGPoint {
        let cw = side / CGFloat(cols)
        let ch = side / CGFloat(rows)
        let minX = cw / 2
        let maxX = side - cw / 2
        let minY = ch / 2
        let maxY = side - ch / 2
        return CGPoint(
            x: min(max(center.x, minX), maxX),
            y: min(max(center.y, minY), maxY)
        )
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
        guard let round = currentRound else { return }
        let solved = round.creature

        isAudioPlaying = true
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.speechManager.speak("thats-right-you-guessed-it")
            self.speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.advanceAfterRoundCompletionAudio()
            }
        }
        let key = solved.imageName
            ?? solved.name.lowercased().replacingOccurrences(of: " ", with: "-")
        speechManager.speak(audioKey: key, fallbackText: solved.name)
    }

    private func advanceAfterRoundCompletionAudio() {
        if currentRoundIndex < 2 {
            currentRoundIndex += 1
            if let r = currentRound {
                setupPieces(for: r, side: boardSide)
                announceRoundCladeIfNeeded(r)
            } else {
                isAudioPlaying = false
            }
        } else {
            isGameComplete = true
            isAudioPlaying = false
        }
    }

    private func playGoodJobAndCrowdThenDismiss() {
        StandardVictorySequence.dismissAfterVictory(
            configId: line.catalogGameId,
            isPresented: $isPresented,
            speechManager: speechManager,
            beforeDismiss: { line.notifyGameCompleted() }
        )
    }

    private func advanceEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        let creatures = rounds.map(\.creature)
        if endHighlightIndex < creatures.count {
            let d = creatures[endHighlightIndex]
            let key = d.imageName ?? d.name.lowercased().replacingOccurrences(of: " ", with: "-")
            speechManager.speak(audioKey: key, fallbackText: d.name)
            speechManager.onAudioFinished = { advanceEndHighlight() }
        } else {
            endSequenceStep = 2
        }
    }

    private var puzzleVictoryListHeight: CGFloat {
        StandardVictoryLayout.recapListScrollHeight(itemCount: rounds.count)
    }

    var body: some View {
        NavigationView {
            Group {
                if isGameComplete {
                    puzzleEndSequenceView
                } else if let round = currentRound {
                    puzzleActiveView(round: round)
                } else {
                    Text("Loading…")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(line.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            rounds = PortraitJigsawRoundGenerator.makeRounds(for: line)
            currentRoundIndex = 0
            isGameComplete = false
            endSequenceStep = -1
            endHighlightIndex = 0
            pieces = []
            dragStartById = [:]
            draggingPieceId = nil
            lastAnnouncedRoundId = nil
            pieceInteractionOrderById = [:]
            nextPieceInteractionOrder = 1
        }
        .onDisappear {
            speechManager.onAudioFinished = nil
            speechManager.stopCurrentAudio()
            isAudioPlaying = false
        }
    }

    @ViewBuilder
    private func puzzleActiveView(round: PortraitJigsawRoundBuilt) -> some View {
        let rows = round.pattern.rows
        let cols = round.pattern.cols
        VStack(spacing: 16) {
            Text("Round \(currentRoundIndex + 1) of 3")
                .font(.headline)
                .foregroundColor(.secondary)
            Text(bucketTitle(round.bucket))
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
                        PortraitJigsawPieceImage(
                            imageName: round.creature.imageName,
                            emojiFallback: round.creature.icon,
                            boardSide: side,
                            rows: rows,
                            cols: cols,
                            row: piece.row,
                            col: piece.col
                        )
                        .frame(width: cw, height: ch)
                        .position(piece.center)
                        .zIndex(pieceZIndex(piece))
                        .shadow(color: .black.opacity(piece.isLocked ? 0 : 0.18), radius: 4, y: 2)
                        .gesture(
                            DragGesture()
                                .onChanged { g in
                                    guard !piece.isLocked, !isAudioPlaying else { return }
                                    if dragStartById[piece.id] == nil {
                                        draggingPieceId = piece.id
                                        bringPieceToFront(piece.id)
                                        dragStartById[piece.id] = piece.center
                                    }
                                    guard let start = dragStartById[piece.id],
                                          let idx = pieces.firstIndex(where: { $0.id == piece.id })
                                    else { return }
                                    let raw = CGPoint(
                                        x: start.x + g.translation.width,
                                        y: start.y + g.translation.height
                                    )
                                    pieces[idx].center = clampPieceCenter(raw, side: side, rows: rows, cols: cols)
                                }
                                .onEnded { _ in
                                    dragStartById[piece.id] = nil
                                    if draggingPieceId == piece.id {
                                        draggingPieceId = nil
                                    }
                                    if let idx = pieces.firstIndex(where: { $0.id == piece.id }),
                                       !pieces[idx].isLocked {
                                        pieces[idx].center = clampPieceCenter(
                                            pieces[idx].center,
                                            side: side,
                                            rows: rows,
                                            cols: cols
                                        )
                                    }
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
                    announceRoundCladeIfNeeded(r)
                }
                .onChange(of: side) { _, newSide in
                    guard let r = currentRound, newSide > 40 else { return }
                    boardSide = newSide
                    if pieces.contains(where: { $0.isLocked }) {
                        let rows = r.pattern.rows
                        let cols = r.pattern.cols
                        for i in pieces.indices where !pieces[i].isLocked {
                            pieces[i].center = clampPieceCenter(
                                pieces[i].center,
                                side: newSide,
                                rows: rows,
                                cols: cols
                            )
                        }
                        return
                    }
                    setupPieces(for: r, side: newSide)
                }
            }
            .frame(minHeight: 320)
        }
        .padding()
        .allowsHitTesting(!isAudioPlaying)
        .opacity(isAudioPlaying ? 0.75 : 1)
    }

    private var puzzleEndSequenceView: some View {
        let creatures = rounds.map(\.creature)
        return VictorySplitColumnView(
            listScrollHeight: puzzleVictoryListHeight,
            showSuccessPhase: endSequenceStep == 2,
            endHighlightIndex: endHighlightIndex,
            gameTitle: line.navigationTitle,
            scrollRows: {
                ForEach(Array(creatures.enumerated()), id: \.offset) { index, creature in
                    StandardVictoryRecapRowView(
                        item: VictoryRecapDisplayItem(
                            id: "\(creature.id)",
                            title: creature.name,
                            imageAssetName: creature.imageName,
                            fallbackEmoji: creature.icon
                        ),
                        isHighlighted: endSequenceStep >= 1 && index == endHighlightIndex
                    )
                    .id(index)
                }
            },
            successPhase: {
                LandGameVictorySuccessStingerThenContinue(
                    candidateSuccessImageNames: line.successImageCandidateNames,
                    catalogGameIdForStinger: line.catalogGameId,
                    imageSide: GameCatalogImageMetrics.nameThatVictorySuccessImageSide,
                    speechManager: speechManager,
                    onContinue: playGoodJobAndCrowdThenDismiss
                )
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endHighlightIndex = 0
            if creatures.isEmpty {
                endSequenceStep = 2
            } else {
                endSequenceStep = 1
                let d = creatures[0]
                let key = d.imageName ?? d.name.lowercased().replacingOccurrences(of: " ", with: "-")
                speechManager.speak(audioKey: key, fallbackText: d.name)
                speechManager.onAudioFinished = { advanceEndHighlight() }
            }
        }
    }
}
