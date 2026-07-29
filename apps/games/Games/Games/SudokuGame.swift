//
//  SudokuGame.swift
//  Games
//

import Foundation

enum SudokuStatus: Equatable {
    case playing
    case solved
}

@Observable
final class SudokuGame {
    /// 81 cells; `0` means empty.
    private(set) var values: [Int]
    /// Clue cells that cannot be edited.
    private(set) var isGiven: [Bool]
    private(set) var selectedIndex: Int?
    private(set) var status: SudokuStatus
    private(set) var puzzleIndex: Int

    init(puzzleIndex: Int? = nil) {
        let index = puzzleIndex ?? SudokuPuzzleBank.randomIndex()
        let puzzle = SudokuPuzzleBank.puzzle(at: index)
        self.puzzleIndex = index
        self.values = puzzle
        self.isGiven = puzzle.map { $0 != 0 }
        self.selectedIndex = nil
        self.status = .playing
    }

    var conflictIndices: Set<Int> {
        Self.conflicts(in: values)
    }

    func select(_ index: Int) {
        guard values.indices.contains(index) else { return }
        selectedIndex = index
    }

    func enter(_ digit: Int) {
        guard status == .playing,
              (1...9).contains(digit),
              let index = selectedIndex,
              !isGiven[index]
        else { return }

        values[index] = digit
        refreshStatus()
    }

    func erase() {
        guard status == .playing,
              let index = selectedIndex,
              !isGiven[index]
        else { return }

        values[index] = 0
        status = .playing
    }

    func newGame() {
        let next = SudokuPuzzleBank.randomIndex(excluding: puzzleIndex)
        let puzzle = SudokuPuzzleBank.puzzle(at: next)
        puzzleIndex = next
        values = puzzle
        isGiven = puzzle.map { $0 != 0 }
        selectedIndex = nil
        status = .playing
    }

    func restart() {
        let puzzle = SudokuPuzzleBank.puzzle(at: puzzleIndex)
        values = puzzle
        isGiven = puzzle.map { $0 != 0 }
        selectedIndex = nil
        status = .playing
    }

    private func refreshStatus() {
        guard values.allSatisfy({ $0 != 0 }), conflictIndices.isEmpty else {
            status = .playing
            return
        }
        status = .solved
    }

    static func conflicts(in values: [Int]) -> Set<Int> {
        precondition(values.count == 81)
        var conflicts = Set<Int>()

        func markDuplicates(_ indices: [Int]) {
            var seen: [Int: Int] = [:]
            for index in indices {
                let value = values[index]
                guard value != 0 else { continue }
                if let first = seen[value] {
                    conflicts.insert(first)
                    conflicts.insert(index)
                } else {
                    seen[value] = index
                }
            }
        }

        for row in 0..<9 {
            markDuplicates((0..<9).map { row * 9 + $0 })
        }
        for column in 0..<9 {
            markDuplicates((0..<9).map { $0 * 9 + column })
        }
        for boxRow in 0..<3 {
            for boxColumn in 0..<3 {
                var indices: [Int] = []
                for row in 0..<3 {
                    for column in 0..<3 {
                        indices.append((boxRow * 3 + row) * 9 + (boxColumn * 3 + column))
                    }
                }
                markDuplicates(indices)
            }
        }

        return conflicts
    }

    static func isValidComplete(_ values: [Int]) -> Bool {
        values.count == 81
            && values.allSatisfy { (1...9).contains($0) }
            && conflicts(in: values).isEmpty
    }
}

enum SudokuPuzzleBank {
    /// Easy puzzles as 81 digits (`0` = empty).
    private static let puzzles: [[Int]] = [
        decode("""
        530070000
        600195000
        098000060
        800060003
        400803001
        700020006
        060000280
        000419005
        000080079
        """),
        decode("""
        200080300
        060070084
        030500209
        000105408
        000000000
        402706000
        301007040
        720040060
        004010003
        """),
        decode("""
        000000907
        000420180
        000705026
        060504000
        400000001
        000201070
        920108000
        034059000
        507000000
        """),
        decode("""
        003020600
        900305001
        001806400
        008102900
        700000008
        006708200
        002609500
        800203009
        005010300
        """),
    ]

    static var count: Int { puzzles.count }

    static func puzzle(at index: Int) -> [Int] {
        puzzles[index % puzzles.count]
    }

    static func randomIndex(excluding excluded: Int? = nil) -> Int {
        guard puzzles.count > 1, let excluded else {
            return Int.random(in: 0..<puzzles.count)
        }
        var index = Int.random(in: 0..<puzzles.count)
        if index == excluded {
            index = (index + 1) % puzzles.count
        }
        return index
    }

    private static func decode(_ grid: String) -> [Int] {
        let digits = grid.filter(\.isNumber).compactMap { Int(String($0)) }
        precondition(digits.count == 81, "Sudoku puzzle must have 81 digits")
        return digits
    }
}
