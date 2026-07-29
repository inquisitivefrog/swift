//
//  UndergroundMazeGame.swift
//  Games
//

import Foundation

enum MazeTile: Equatable {
    case wall
    case path
    case exit
    case treasure
}

enum MazeDirection: CaseIterable {
    case up, down, left, right

    var delta: (row: Int, column: Int) {
        switch self {
        case .up: (-1, 0)
        case .down: (1, 0)
        case .left: (0, -1)
        case .right: (0, 1)
        }
    }
}

enum MazeStatus: Equatable {
    case playing
    case levelCleared(Int)
    case won
}

enum MazeGoalKind: Equatable {
    case exit
    case treasure
}

struct MazePoint: Hashable {
    let row: Int
    let column: Int
}

struct MazeLevel: Equatable {
    let number: Int
    let name: String
    let grid: [[MazeTile]]
    let start: MazePoint

    var rows: Int { grid.count }
    var columns: Int { grid.first?.count ?? 0 }

    func tile(at row: Int, column: Int) -> MazeTile? {
        guard row >= 0, column >= 0, row < rows, column < columns else { return nil }
        return grid[row][column]
    }
}

@Observable
final class UndergroundMazeGame {
    private(set) var levels: [MazeLevel]
    private(set) var levelIndex: Int
    private(set) var level: MazeLevel
    private(set) var playerRow: Int
    private(set) var playerColumn: Int
    private(set) var status: MazeStatus
    private(set) var moves: Int

    init(startingAtLevel index: Int = 0, seed: UInt64? = nil) {
        let generated = MazeDungeon.generateDungeon(seed: seed)
        levels = generated
        let clamped = min(max(index, 0), generated.count - 1)
        levelIndex = clamped
        let first = generated[clamped]
        level = first
        playerRow = first.start.row
        playerColumn = first.start.column
        status = .playing
        moves = 0
    }

    var levelTitle: String {
        "Level \(level.number): \(level.name)"
    }

    var totalLevels: Int {
        levels.count
    }

    func move(_ direction: MazeDirection) {
        guard status == .playing else { return }

        let nextRow = playerRow + direction.delta.row
        let nextColumn = playerColumn + direction.delta.column
        guard let tile = level.tile(at: nextRow, column: nextColumn), tile != .wall else {
            return
        }

        playerRow = nextRow
        playerColumn = nextColumn
        moves += 1

        switch tile {
        case .exit:
            if levelIndex >= levels.count - 1 {
                status = .won
            } else {
                status = .levelCleared(level.number)
            }
        case .treasure:
            status = .won
        case .path, .wall:
            break
        }
    }

    func advanceAfterLevelCleared() {
        guard case .levelCleared = status else { return }
        let nextIndex = levelIndex + 1
        guard levels.indices.contains(nextIndex) else {
            status = .won
            return
        }
        levelIndex = nextIndex
        level = levels[nextIndex]
        playerRow = level.start.row
        playerColumn = level.start.column
        status = .playing
    }

    func restartLevel() {
        let current = levels[levelIndex]
        level = current
        playerRow = current.start.row
        playerColumn = current.start.column
        status = .playing
    }

    /// Starts a brand-new dungeon with freshly randomized mazes, stairs, and treasure.
    func restartDungeon(seed: UInt64? = nil) {
        levels = MazeDungeon.generateDungeon(seed: seed)
        levelIndex = 0
        level = levels[0]
        playerRow = level.start.row
        playerColumn = level.start.column
        status = .playing
        moves = 0
    }
}

enum MazeDungeon {
    private static let blueprint: [(number: Int, name: String, width: Int, height: Int, goal: MazeGoalKind)] = [
        (1, "Torchlight Tunnel", 9, 9, .exit),
        (2, "Crystal Cavern", 11, 11, .exit),
        (3, "Treasure Vault", 13, 13, .treasure),
    ]

    static func generateDungeon(seed: UInt64? = nil) -> [MazeLevel] {
        var rng = SeededGenerator(seed: seed ?? UInt64.random(in: .min ... .max))
        return blueprint.map { spec in
            generateLevel(
                number: spec.number,
                name: spec.name,
                width: spec.width,
                height: spec.height,
                goal: spec.goal,
                rng: &rng
            )
        }
    }

    static func generateLevel(
        number: Int,
        name: String,
        width: Int,
        height: Int,
        goal: MazeGoalKind,
        rng: inout some RandomNumberGenerator
    ) -> MazeLevel {
        // Odd sizes keep carved corridors on a clean lattice.
        let cols = width % 2 == 0 ? width + 1 : width
        let rows = height % 2 == 0 ? height + 1 : height

        var grid = Array(
            repeating: Array(repeating: MazeTile.wall, count: cols),
            count: rows
        )

        func carve(_ point: MazePoint) {
            grid[point.row][point.column] = .path
        }

        let startCarve = MazePoint(row: 1, column: 1)
        carve(startCarve)

        var stack = [startCarve]
        while let current = stack.last {
            let neighbors = MazeDirection.allCases.compactMap { direction -> MazePoint? in
                let between = MazePoint(
                    row: current.row + direction.delta.row,
                    column: current.column + direction.delta.column
                )
                let next = MazePoint(
                    row: current.row + direction.delta.row * 2,
                    column: current.column + direction.delta.column * 2
                )
                guard next.row > 0, next.column > 0,
                      next.row < rows - 1, next.column < cols - 1,
                      grid[next.row][next.column] == .wall
                else { return nil }
                _ = between
                return next
            }

            if let chosen = neighbors.randomElement(using: &rng) {
                let between = MazePoint(
                    row: (current.row + chosen.row) / 2,
                    column: (current.column + chosen.column) / 2
                )
                carve(between)
                carve(chosen)
                stack.append(chosen)
            } else {
                stack.removeLast()
            }
        }

        let paths = pathCells(in: grid)
        precondition(!paths.isEmpty, "Generated maze has no open cells")

        let start = paths.randomElement(using: &rng)!
        let distances = distancesFrom(start, in: grid)
        let farthestDistance = distances.values.max() ?? 0
        let distant = paths.filter { (distances[$0] ?? 0) >= max(farthestDistance / 2, 1) }
        let goalCandidates = distant.isEmpty ? paths.filter { $0 != start } : distant.filter { $0 != start }
        let goalPoint = (goalCandidates.isEmpty ? paths.filter { $0 != start } : goalCandidates)
            .randomElement(using: &rng) ?? start

        switch goal {
        case .exit:
            grid[goalPoint.row][goalPoint.column] = .exit
        case .treasure:
            grid[goalPoint.row][goalPoint.column] = .treasure
        }

        return MazeLevel(number: number, name: name, grid: grid, start: start)
    }

    private static func pathCells(in grid: [[MazeTile]]) -> [MazePoint] {
        var points: [MazePoint] = []
        for row in grid.indices {
            for column in grid[row].indices where grid[row][column] != .wall {
                points.append(MazePoint(row: row, column: column))
            }
        }
        return points
    }

    private static func distancesFrom(_ start: MazePoint, in grid: [[MazeTile]]) -> [MazePoint: Int] {
        var distances: [MazePoint: Int] = [start: 0]
        var queue = [start]
        var head = 0

        while head < queue.count {
            let point = queue[head]
            head += 1
            let base = distances[point] ?? 0
            for direction in MazeDirection.allCases {
                let next = MazePoint(
                    row: point.row + direction.delta.row,
                    column: point.column + direction.delta.column
                )
                guard next.row >= 0, next.column >= 0,
                      next.row < grid.count, next.column < grid[next.row].count,
                      grid[next.row][next.column] != .wall,
                      distances[next] == nil
                else { continue }
                distances[next] = base + 1
                queue.append(next)
            }
        }
        return distances
    }
}

/// Deterministic RNG for tests; production uses a random seed.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
