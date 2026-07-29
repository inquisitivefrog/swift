//
//  GameCatalog.swift
//  Games
//

import Foundation

enum GameGenre: String, CaseIterable, Identifiable, Comparable {
    case puzzle
    case strategy
    case card
    case trivia
    case arcade
    case ar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .puzzle: "Puzzle"
        case .strategy: "Strategy"
        case .card: "Card"
        case .trivia: "Trivia"
        case .arcade: "Arcade"
        case .ar: "AR"
        }
    }

    var systemImage: String {
        switch self {
        case .puzzle: "puzzlepiece.fill"
        case .strategy: "brain.head.profile"
        case .card: "rectangle.stack.fill"
        case .trivia: "questionmark.circle.fill"
        case .arcade: "gamecontroller.fill"
        case .ar: "arkit"
        }
    }

    private var sortOrder: Int {
        switch self {
        case .puzzle: 0
        case .strategy: 1
        case .card: 2
        case .trivia: 3
        case .arcade: 4
        case .ar: 5
        }
    }

    static func < (lhs: GameGenre, rhs: GameGenre) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

enum GameDifficulty: String, CaseIterable {
    case easy
    case medium
    case hard

    var title: String {
        rawValue.capitalized
    }
}

enum GameID: String, Hashable, CaseIterable {
    case ticTacToe
    case sudoku
    case easyFrench
    case undergroundMaze
    case sideScroller
    case gridMovement
}

struct GameEntry: Identifiable, Hashable {
    let id: GameID
    let title: String
    let subtitle: String
    let genre: GameGenre
    let difficulty: GameDifficulty
    let systemImage: String
    let isAvailable: Bool
}

enum GameCatalog {
    static let games: [GameEntry] = [
        GameEntry(
            id: .ticTacToe,
            title: "Tic-Tac-Toe",
            subtitle: "Classic 3×3 — two players",
            genre: .puzzle,
            difficulty: .easy,
            systemImage: "grid",
            isAvailable: true
        ),
        GameEntry(
            id: .sudoku,
            title: "Sudoku",
            subtitle: "Fill the 9×9 grid",
            genre: .puzzle,
            difficulty: .easy,
            systemImage: "tablecells",
            isAvailable: true
        ),
        GameEntry(
            id: .easyFrench,
            title: "Easy French",
            subtitle: "Flashcards & quizzes — 11 topics",
            genre: .trivia,
            difficulty: .medium,
            systemImage: "character.book.closed.fill",
            isAvailable: true
        ),
        GameEntry(
            id: .undergroundMaze,
            title: "Underground Maze",
            subtitle: "3 levels · find the treasure",
            genre: .arcade,
            difficulty: .medium,
            systemImage: "flame.fill",
            isAvailable: true
        ),
        GameEntry(
            id: .sideScroller,
            title: "Side Scroller",
            subtitle: "Run, jump, reach the goal",
            genre: .arcade,
            difficulty: .medium,
            systemImage: "figure.run",
            isAvailable: true
        ),
        GameEntry(
            id: .gridMovement,
            title: "Grid Movement",
            subtitle: "16×16 map · 4×4 scrolling view",
            genre: .strategy,
            difficulty: .easy,
            systemImage: "square.grid.3x3.topleft.filled",
            isAvailable: true
        ),
    ]

    /// Available games grouped by genre, genres sorted, games A–Z within each genre.
    static var sections: [(genre: GameGenre, games: [GameEntry])] {
        let available = games.filter(\.isAvailable)
        let grouped = Dictionary(grouping: available, by: \.genre)
        return grouped.keys.sorted().map { genre in
            let sortedGames = (grouped[genre] ?? []).sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            return (genre, sortedGames)
        }
    }

    static func entry(for id: GameID) -> GameEntry? {
        games.first { $0.id == id }
    }
}
