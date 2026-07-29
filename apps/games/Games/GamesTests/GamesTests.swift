//
//  GamesTests.swift
//  GamesTests
//
//  Created by Timothy Stilwell on 7/13/26.
//

import XCTest
@testable import Games

final class GamesTests: XCTestCase {

    func testCatalogSectionsGroupByGenre() {
        let sections = GameCatalog.sections
        XCTAssertFalse(sections.isEmpty)
        XCTAssertEqual(sections.first?.genre, .puzzle)
        let puzzleIDs = sections.first?.games.map(\.id) ?? []
        XCTAssertTrue(puzzleIDs.contains(.ticTacToe))
        XCTAssertTrue(puzzleIDs.contains(.sudoku))

        let trivia = sections.first(where: { $0.genre == .trivia })
        XCTAssertTrue(trivia?.games.contains(where: { $0.id == .easyFrench }) ?? false)

        let arcade = sections.first(where: { $0.genre == .arcade })
        let arcadeIDs = arcade?.games.map(\.id) ?? []
        XCTAssertTrue(arcadeIDs.contains(.undergroundMaze))
        XCTAssertTrue(arcadeIDs.contains(.sideScroller))

        let strategy = sections.first(where: { $0.genre == .strategy })
        XCTAssertTrue(strategy?.games.contains(where: { $0.id == .gridMovement }) ?? false)
    }

    func testXWinsOnTopRow() {
        let game = TicTacToeGame()
        game.mark(at: 0) // X
        game.mark(at: 3) // O
        game.mark(at: 1) // X
        game.mark(at: 4) // O
        game.mark(at: 2) // X

        XCTAssertEqual(game.status, .won(.x))
        XCTAssertEqual(game.winningLine, [0, 1, 2])
    }

    func testDiagonalWinningLine() {
        let game = TicTacToeGame()
        game.mark(at: 0) // X
        game.mark(at: 1) // O
        game.mark(at: 4) // X
        game.mark(at: 2) // O
        game.mark(at: 8) // X

        XCTAssertEqual(game.status, .won(.x))
        XCTAssertEqual(game.winningLine, [0, 4, 8])
    }

    func testDraw() {
        let game = TicTacToeGame()
        let moves = [0, 1, 2, 4, 3, 5, 7, 6, 8]
        for move in moves {
            game.mark(at: move)
        }

        XCTAssertEqual(game.status, .draw)
    }

    func testCannotOverwriteCell() {
        let game = TicTacToeGame()
        game.mark(at: 0)
        game.mark(at: 0)

        XCTAssertEqual(game.board[0], .x)
        XCTAssertEqual(game.currentPlayer, .o)
    }

    func testResetClearsBoard() {
        let game = TicTacToeGame()
        game.mark(at: 0)
        game.reset()

        XCTAssertTrue(game.board.allSatisfy { $0 == nil })
        XCTAssertEqual(game.currentPlayer, .x)
        XCTAssertEqual(game.status, .playing)
        XCTAssertNil(game.winningLine)
    }

    func testSudokuConflictInRow() {
        var values = Array(repeating: 0, count: 81)
        values[0] = 5
        values[1] = 5

        let conflicts = SudokuGame.conflicts(in: values)
        XCTAssertTrue(conflicts.contains(0))
        XCTAssertTrue(conflicts.contains(1))
    }

    func testSudokuCannotEditGivenCell() {
        let game = SudokuGame(puzzleIndex: 0)
        let givenIndex = game.isGiven.firstIndex(of: true)!
        game.select(givenIndex)
        let before = game.values[givenIndex]
        game.enter(9)
        XCTAssertEqual(game.values[givenIndex], before)
    }

    func testSudokuSolveFirstPuzzle() {
        let game = SudokuGame(puzzleIndex: 0)
        let solution = [
            5, 3, 4, 6, 7, 8, 9, 1, 2,
            6, 7, 2, 1, 9, 5, 3, 4, 8,
            1, 9, 8, 3, 4, 2, 5, 6, 7,
            8, 5, 9, 7, 6, 1, 4, 2, 3,
            4, 2, 6, 8, 5, 3, 7, 9, 1,
            7, 1, 3, 9, 2, 4, 8, 5, 6,
            9, 6, 1, 5, 3, 7, 2, 8, 4,
            2, 8, 7, 4, 1, 9, 6, 3, 5,
            3, 4, 5, 2, 8, 6, 1, 7, 9,
        ]

        for index in solution.indices where !game.isGiven[index] {
            game.select(index)
            game.enter(solution[index])
        }

        XCTAssertEqual(game.status, .solved)
        XCTAssertTrue(SudokuGame.isValidComplete(game.values))
    }

    func testFrenchCategoriesHaveTenWordsEach() {
        for category in FrenchCategory.allCases {
            XCTAssertEqual(category.words.count, 10, "\(category.title) should have 10 words")
        }
    }

    func testEasyFrenchQuizScoresCorrectAnswer() {
        let session = EasyFrenchQuizSession(category: .colors)
        let correct = session.current.french
        session.select(correct)
        XCTAssertTrue(session.isCorrect)
        XCTAssertEqual(session.score, 1)
    }

    func testEasyFrenchQuizDoesNotScoreTwice() {
        let session = EasyFrenchQuizSession(category: .numbers)
        session.select(session.current.french)
        session.select(session.current.french)
        XCTAssertEqual(session.score, 1)
    }

    func testFrenchSpeechMatchingIgnoresAccents() {
        let word = FrenchWord(french: "café", english: "coffee")
        // Use a real vocabulary word with accents.
        let soeur = FrenchWord(french: "sœur", english: "sister")
        XCTAssertTrue(soeur.matchesFrenchSpeech("soeur"))
        XCTAssertTrue(soeur.matchesFrenchSpeech("Sœur"))
        _ = word
    }

    func testFrenchSpeechMatchingAlphabetEntry() {
        let word = FrenchWord(french: "A (a)", english: "A")
        XCTAssertTrue(word.matchesFrenchSpeech("a"))
        XCTAssertEqual(word.frenchSpeechText, "a")
    }

    func testEasyFrenchSpokenAnswerScores() {
        let session = EasyFrenchQuizSession(category: .colors)
        session.submitSpoken(session.current.french)
        XCTAssertTrue(session.isCorrect)
        XCTAssertEqual(session.score, 1)
    }

    func testMazeHasThreeLevels() {
        let levels = MazeDungeon.generateDungeon(seed: 7)
        XCTAssertEqual(levels.count, 3)
        XCTAssertEqual(levels[2].name, "Treasure Vault")
    }

    func testMazeCannotWalkThroughWalls() {
        let game = UndergroundMazeGame(seed: 11)
        let startRow = game.playerRow
        let startColumn = game.playerColumn
        guard let blocked = MazeDirection.allCases.first(where: { direction in
            let row = startRow + direction.delta.row
            let column = startColumn + direction.delta.column
            return game.level.tile(at: row, column: column) == .wall
        }) else {
            return XCTFail("Expected a wall next to the start cell")
        }
        game.move(blocked)
        XCTAssertEqual(game.playerRow, startRow)
        XCTAssertEqual(game.playerColumn, startColumn)
        XCTAssertEqual(game.moves, 0)
    }

    func testMazeClearsLevelOneViaTopCorridor() {
        let game = UndergroundMazeGame(seed: 21)
        let path = Self.shortestPath(
            in: game.level,
            from: MazePoint(row: game.playerRow, column: game.playerColumn),
            goal: .exit
        )
        XCTAssertFalse(path.isEmpty)
        for step in path {
            game.move(step)
        }
        XCTAssertEqual(game.status, .levelCleared(1))
        game.advanceAfterLevelCleared()
        XCTAssertEqual(game.level.number, 2)
        XCTAssertEqual(game.status, .playing)
    }

    func testMazeTreasureTileWins() {
        let levels = MazeDungeon.generateDungeon(seed: 33)
        XCTAssertTrue(levels[2].grid.contains(where: { $0.contains(.treasure) }))
        XCTAssertFalse(levels[0].grid.contains(where: { $0.contains(.treasure) }))
        XCTAssertFalse(levels[1].grid.contains(where: { $0.contains(.treasure) }))
        XCTAssertTrue(levels[0].grid.contains(where: { $0.contains(.exit) }))
        XCTAssertTrue(levels[1].grid.contains(where: { $0.contains(.exit) }))
    }

    func testMazeReachingTreasureSetsWon() {
        let game = UndergroundMazeGame(startingAtLevel: 2, seed: 44)
        let path = Self.shortestPath(
            in: game.level,
            from: MazePoint(row: game.playerRow, column: game.playerColumn),
            goal: .treasure
        )
        XCTAssertFalse(path.isEmpty)
        for step in path {
            game.move(step)
        }
        XCTAssertEqual(game.status, .won)
    }

    func testMazeCanAdvanceThroughAllLevels() {
        let game = UndergroundMazeGame(seed: 55)
        for expectedLevel in 1...2 {
            let path = Self.shortestPath(
                in: game.level,
                from: MazePoint(row: game.playerRow, column: game.playerColumn),
                goal: .exit
            )
            XCTAssertFalse(path.isEmpty, "Level \(expectedLevel) should be solvable")
            for step in path {
                game.move(step)
            }
            XCTAssertEqual(game.status, .levelCleared(expectedLevel))
            game.advanceAfterLevelCleared()
            XCTAssertEqual(game.level.number, expectedLevel + 1)
        }

        let treasurePath = Self.shortestPath(
            in: game.level,
            from: MazePoint(row: game.playerRow, column: game.playerColumn),
            goal: .treasure
        )
        XCTAssertFalse(treasurePath.isEmpty)
        for step in treasurePath {
            game.move(step)
        }
        XCTAssertEqual(game.status, .won)
    }

    func testMazeGoalsVaryBetweenSeeds() {
        let a = MazeDungeon.generateDungeon(seed: 100)
        let b = MazeDungeon.generateDungeon(seed: 200)
        let goalsA = a.map(Self.goalPoint)
        let goalsB = b.map(Self.goalPoint)
        let startsA = a.map(\.start)
        let startsB = b.map(\.start)
        XCTAssertTrue(goalsA != goalsB || startsA != startsB)
    }

    private static func goalPoint(in level: MazeLevel) -> MazePoint? {
        for row in 0..<level.rows {
            for column in 0..<level.columns {
                let tile = level.grid[row][column]
                if tile == .exit || tile == .treasure {
                    return MazePoint(row: row, column: column)
                }
            }
        }
        return nil
    }

    private static func shortestPath(
        in level: MazeLevel,
        from start: MazePoint,
        goal: MazeTile
    ) -> [MazeDirection] {
        var queue: [(MazePoint, [MazeDirection])] = [(start, [])]
        var visited: Set<MazePoint> = [start]

        while !queue.isEmpty {
            let (point, path) = queue.removeFirst()
            if level.tile(at: point.row, column: point.column) == goal {
                return path
            }
            for direction in MazeDirection.allCases {
                let next = MazePoint(
                    row: point.row + direction.delta.row,
                    column: point.column + direction.delta.column
                )
                guard !visited.contains(next),
                      let tile = level.tile(at: next.row, column: next.column),
                      tile != .wall
                else { continue }
                visited.insert(next)
                queue.append((next, path + [direction]))
            }
        }
        return []
    }

    func testGridCameraCentersThenClamps() {
        // Near center → camera keeps dog centered (origin = player - 2).
        XCTAssertEqual(
            GridMovementGame.clampedCamera(centering: GridPoint(row: 8, column: 8)),
            GridPoint(row: 6, column: 6)
        )
        // Top-left → camera clamps at 0,0 (still a full 4×4).
        XCTAssertEqual(
            GridMovementGame.clampedCamera(centering: GridPoint(row: 1, column: 1)),
            GridPoint(row: 0, column: 0)
        )
        // Bottom-right walkable → camera clamps at 12,12.
        XCTAssertEqual(
            GridMovementGame.clampedCamera(centering: GridPoint(row: 14, column: 14)),
            GridPoint(row: 12, column: 12)
        )
    }

    func testGridMovementBlockedByWall() {
        let game = GridMovementGame()
        game.reset()
        // Walk to top interior row, then try into wall.
        while game.player.row > 1 {
            game.move(.up)
        }
        let before = game.player
        game.move(.up) // onto row 0 wall
        XCTAssertEqual(game.player, before)
        XCTAssertEqual(game.tile(at: GridPoint(row: 0, column: before.column)), .wall)
    }

    func testGridViewportAlwaysFourByFour() {
        let game = GridMovementGame()
        for _ in 0..<20 { game.move(.up) }
        for _ in 0..<20 { game.move(.left) }
        XCTAssertEqual(game.camera.row, 0)
        XCTAssertEqual(game.camera.column, 0)
        XCTAssertLessThanOrEqual(game.camera.row + GridMovementGame.viewSize, GridMovementGame.mapSize)
        XCTAssertLessThanOrEqual(game.camera.column + GridMovementGame.viewSize, GridMovementGame.mapSize)
    }
}
