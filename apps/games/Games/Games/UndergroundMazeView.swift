//
//  UndergroundMazeView.swift
//  Games
//

import SwiftUI

struct UndergroundMazeView: View {
    @State private var game = UndergroundMazeGame()

    private let stone = Color(red: 0.18, green: 0.16, blue: 0.14)
    private let path = Color(red: 0.32, green: 0.28, blue: 0.22)
    private let torch = Color(red: 1.0, green: 0.78, blue: 0.35)

    var body: some View {
        VStack(spacing: 16) {
            header

            mazeBoard
                .gesture(swipeGesture)

            if case .levelCleared(let number) = game.status {
                levelClearedBanner(number)
            } else if game.status == .won {
                victoryBanner
            } else {
                controls
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.black, stone],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Underground Maze")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(game.levelTitle)
                .font(.headline)
                .foregroundStyle(torch)
            Text("Moves \(game.moves) · Level \(game.level.number)/\(game.totalLevels)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(statusHint)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
    }

    private var statusHint: String {
        switch game.status {
        case .playing:
            return game.level.number < 3
                ? "Find the stairs deeper underground."
                : "Reach the treasure!"
        case .levelCleared:
            return "A stairway opens below…"
        case .won:
            return "You found the treasure!"
        }
    }

    private var mazeBoard: some View {
        let level = game.level
        let rows = level.rows
        let columns = level.columns

        return GeometryReader { proxy in
            let cell = min(
                proxy.size.width / CGFloat(max(columns, 1)),
                proxy.size.height / CGFloat(max(rows, 1))
            )

            VStack(spacing: 0) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<columns, id: \.self) { column in
                            cellView(
                                tile: level.tile(at: row, column: column) ?? .wall,
                                isPlayer: game.playerRow == row && game.playerColumn == column,
                                size: cell
                            )
                        }
                    }
                }
            }
            .frame(width: cell * CGFloat(columns), height: cell * CGFloat(rows))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(torch.opacity(0.35), lineWidth: 2)
            }
        }
        .id(game.levelIndex) // Rebuild board when maze dimensions change (avoids ForEach OOB crash).
        .aspectRatio(
            CGFloat(max(columns, 1)) / CGFloat(max(rows, 1)),
            contentMode: .fit
        )
        .frame(maxHeight: 420)
        .animation(.easeInOut(duration: 0.15), value: game.playerRow)
        .animation(.easeInOut(duration: 0.15), value: game.playerColumn)
    }

    private func cellView(tile: MazeTile, isPlayer: Bool, size: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(tile == .wall ? stone : path)

            if tile == .exit && !isPlayer {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(torch)
            }

            if tile == .treasure && !isPlayer {
                Image(systemName: "crown.fill")
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(Color.yellow)
            }

            if isPlayer {
                Image(systemName: "figure.walk")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(accessibilityLabel(tile: tile, isPlayer: isPlayer))
    }

    private func accessibilityLabel(tile: MazeTile, isPlayer: Bool) -> String {
        if isPlayer { return "Player" }
        switch tile {
        case .wall: return "Wall"
        case .path: return "Path"
        case .exit: return "Stairs"
        case .treasure: return "Treasure"
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            controlButton(.up, systemImage: "chevron.up")
            HStack(spacing: 10) {
                controlButton(.left, systemImage: "chevron.left")
                controlButton(.down, systemImage: "chevron.down")
                controlButton(.right, systemImage: "chevron.right")
            }
            Button("Restart Level", action: game.restartLevel)
                .buttonStyle(.bordered)
                .tint(.white)
        }
    }

    private func controlButton(_ direction: MazeDirection, systemImage: String) -> some View {
        Button {
            game.move(direction)
        } label: {
            Image(systemName: systemImage)
                .font(.title2.weight(.bold))
                .frame(width: 64, height: 48)
        }
        .buttonStyle(.borderedProminent)
        .tint(torch.opacity(0.85))
    }

    private func levelClearedBanner(_ number: Int) -> some View {
        VStack(spacing: 12) {
            Text("Level \(number) cleared!")
                .font(.title3.bold())
                .foregroundStyle(torch)
            Button("Descend") {
                game.advanceAfterLevelCleared()
            }
            .buttonStyle(.borderedProminent)
            .tint(torch)
            .controlSize(.large)
        }
    }

    private var victoryBanner: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            Text("Treasure claimed!")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Total moves: \(game.moves)")
                .foregroundStyle(.white.opacity(0.75))
            Button("Play Again") {
                game.restartDungeon()
            }
                .buttonStyle(.borderedProminent)
                .tint(torch)
                .controlSize(.large)
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                guard game.status == .playing else { return }
                let dx = value.translation.width
                let dy = value.translation.height
                if abs(dx) > abs(dy) {
                    game.move(dx > 0 ? .right : .left)
                } else {
                    game.move(dy > 0 ? .down : .up)
                }
            }
    }
}

#Preview {
    NavigationStack {
        UndergroundMazeView()
    }
}
