//
//  TicTacToeView.swift
//  Games
//

import SwiftUI

struct TicTacToeView: View {
    private static let cellSize: CGFloat = 88
    private static let spacing: CGFloat = 12
    private static let boardPadding: CGFloat = 16

    @State private var game = TicTacToeGame()

    var body: some View {
        VStack(spacing: 28) {
            Text(statusText)
                .font(.title3)
                .foregroundStyle(.secondary)
                .animation(.default, value: statusText)

            ZStack {
                Grid(horizontalSpacing: Self.spacing, verticalSpacing: Self.spacing) {
                    ForEach(0..<3, id: \.self) { row in
                        GridRow {
                            ForEach(0..<3, id: \.self) { column in
                                cellButton(at: row * 3 + column)
                            }
                        }
                    }
                }

                if case .won(let player) = game.status,
                   let line = game.winningLine {
                    WinningStrikeLine(
                        cells: line,
                        cellSize: Self.cellSize,
                        spacing: Self.spacing,
                        color: player == .x ? .blue : .orange
                    )
                    .frame(width: boardContentSize, height: boardContentSize)
                    .allowsHitTesting(false)
                }
            }
            .padding(Self.boardPadding)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 20))

            Button("New Game", action: game.reset)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Tic-Tac-Toe")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var boardContentSize: CGFloat {
        Self.cellSize * 3 + Self.spacing * 2
    }

    private var statusText: String {
        switch game.status {
        case .playing:
            return "\(game.currentPlayer.rawValue.uppercased())'s turn"
        case .won(let player):
            return "\(player.rawValue.uppercased()) wins!"
        case .draw:
            return "It's a draw"
        }
    }

    private func cellButton(at index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                game.mark(at: index)
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.06), radius: 2, y: 1)

                if let player = game.board[index] {
                    Image(systemName: player.symbolName)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(player == .x ? .blue : .orange)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: Self.cellSize, height: Self.cellSize)
        }
        .buttonStyle(.plain)
        .disabled(game.board[index] != nil || game.status != .playing)
        .accessibilityLabel(cellAccessibilityLabel(at: index))
    }

    private func cellAccessibilityLabel(at index: Int) -> String {
        let row = index / 3 + 1
        let column = index % 3 + 1
        if let player = game.board[index] {
            return "Row \(row), column \(column), \(player.rawValue.uppercased())"
        }
        return "Row \(row), column \(column), empty"
    }
}

private struct WinningStrikeLine: View {
    let cells: [Int]
    let cellSize: CGFloat
    let spacing: CGFloat
    let color: Color

    @State private var progress: CGFloat = 0

    var body: some View {
        Path { path in
            guard let first = cells.first, let last = cells.last else { return }
            path.move(to: center(for: first))
            path.addLine(to: center(for: last))
        }
        .trim(from: 0, to: progress)
        .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
        .onAppear(perform: animateIn)
        .onChange(of: cells) { _, _ in
            animateIn()
        }
    }

    private func animateIn() {
        progress = 0
        withAnimation(.easeOut(duration: 0.4)) {
            progress = 1
        }
    }

    private func center(for index: Int) -> CGPoint {
        let row = CGFloat(index / 3)
        let column = CGFloat(index % 3)
        let step = cellSize + spacing
        return CGPoint(
            x: column * step + cellSize / 2,
            y: row * step + cellSize / 2
        )
    }
}

#Preview {
    NavigationStack {
        TicTacToeView()
    }
}
