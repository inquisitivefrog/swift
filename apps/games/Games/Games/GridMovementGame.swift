//
//  GridMovementGame.swift
//  Games
//

import Foundation

enum GridTileKind: Equatable {
    case wall
    case path
}

enum GridMoveDirection: CaseIterable {
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

struct GridPoint: Hashable, Equatable {
    var row: Int
    var column: Int
}

@Observable
final class GridMovementGame {
    static let mapSize = 16
    static let viewSize = 4

    private(set) var tiles: [[GridTileKind]]
    private(set) var player: GridPoint
    /// Top-left corner of the 4×4 window into the 16×16 map.
    private(set) var camera: GridPoint

    init() {
        tiles = Self.makeMap()
        let center = GridMovementGame.mapSize / 2
        let start = GridPoint(row: center, column: center)
        player = start
        camera = Self.clampedCamera(centering: start)
    }

    var playerLabel: String {
        "Row \(player.row), Col \(player.column)"
    }

    var cameraLabel: String {
        "View (\(camera.row)–\(camera.row + Self.viewSize - 1), \(camera.column)–\(camera.column + Self.viewSize - 1))"
    }

    func tile(at point: GridPoint) -> GridTileKind? {
        guard point.row >= 0, point.column >= 0,
              point.row < Self.mapSize, point.column < Self.mapSize
        else { return nil }
        return tiles[point.row][point.column]
    }

    func move(_ direction: GridMoveDirection) {
        let next = GridPoint(
            row: player.row + direction.delta.row,
            column: player.column + direction.delta.column
        )
        guard let kind = tile(at: next), kind != .wall else { return }
        player = next
        camera = Self.clampedCamera(centering: player)
    }

    func reset() {
        let center = Self.mapSize / 2
        player = GridPoint(row: center, column: center)
        camera = Self.clampedCamera(centering: player)
    }

    /// Ideal camera keeps the dog centered in the 4×4; clamp so the window never shrinks.
    static func clampedCamera(centering player: GridPoint) -> GridPoint {
        let half = viewSize / 2 // 2
        let maxOrigin = mapSize - viewSize // 12
        let row = min(max(player.row - half, 0), maxOrigin)
        let column = min(max(player.column - half, 0), maxOrigin)
        return GridPoint(row: row, column: column)
    }

    /// Dog’s position inside the current 4×4 window (0…3, 0…3).
    var playerInView: GridPoint {
        GridPoint(row: player.row - camera.row, column: player.column - camera.column)
    }

    private static func makeMap() -> [[GridTileKind]] {
        (0..<mapSize).map { row in
            (0..<mapSize).map { column in
                let onBorder = row == 0 || column == 0
                    || row == mapSize - 1 || column == mapSize - 1
                return onBorder ? .wall : .path
            }
        }
    }
}
