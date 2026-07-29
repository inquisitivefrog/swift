//
//  TicTacToeGame.swift
//  Games
//

import Foundation

enum Player: String, CaseIterable {
    case x
    case o

    var opponent: Player {
        self == .x ? .o : .x
    }

    var symbolName: String {
        self == .x ? "xmark" : "circle"
    }
}

enum GameStatus: Equatable {
    case playing
    case won(Player)
    case draw
}

@Observable
final class TicTacToeGame {
    private(set) var board: [Player?]
    private(set) var currentPlayer: Player
    private(set) var status: GameStatus
    /// Board indices of the three winning cells, when `status` is `.won`.
    private(set) var winningLine: [Int]?

    static let winningLines: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6],
    ]

    init() {
        board = Array(repeating: nil, count: 9)
        currentPlayer = .x
        status = .playing
        winningLine = nil
    }

    func mark(at index: Int) {
        guard status == .playing,
              board.indices.contains(index),
              board[index] == nil
        else { return }

        board[index] = currentPlayer

        if let result = winningResult() {
            status = .won(result.player)
            winningLine = result.line
        } else if board.allSatisfy({ $0 != nil }) {
            status = .draw
        } else {
            currentPlayer = currentPlayer.opponent
        }
    }

    func reset() {
        board = Array(repeating: nil, count: 9)
        currentPlayer = .x
        status = .playing
        winningLine = nil
    }

    private func winningResult() -> (player: Player, line: [Int])? {
        for line in Self.winningLines {
            let marks = line.map { board[$0] }
            if let first = marks.first,
               let player = first,
               marks.allSatisfy({ $0 == player }) {
                return (player, line)
            }
        }
        return nil
    }
}
