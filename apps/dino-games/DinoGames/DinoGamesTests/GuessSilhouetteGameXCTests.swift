//
//  GuessSilhouetteGameXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class GuessSilhouetteGameXCTests: XCTestCase {

    private func makeTestPool() -> [Dinosaur] {
        [
            Dinosaur(id: 9001, name: "Alpha", icon: "🦕", imageName: "xx-alpha", characteristicIds: []),
            Dinosaur(id: 9002, name: "Beta", icon: "🦕", imageName: "xx-beta", characteristicIds: []),
            Dinosaur(id: 9003, name: "Gamma", icon: "🦕", imageName: "xx-gamma", characteristicIds: []),
            Dinosaur(id: 9004, name: "Delta", icon: "🦕", imageName: "xx-delta", characteristicIds: []),
        ]
    }

    func testSilhouetteGuessRoundStructure() {
        let pool = makeTestPool()
        let config = GuessGameConfigs.makeSilhouetteGuessGame(
            id: "test-silhouette",
            title: "Test",
            introAudio: "test-intro",
            bodyImagePrefix: "xx-",
            pool: pool,
            roundCount: 3
        )
        XCTAssertEqual(config.rounds.count, 3)
        let correctIds = config.rounds.map(\.correctAnswerId)
        XCTAssertEqual(Set(correctIds).count, 3, "Each round should feature a distinct correct creature")

        for round in config.rounds {
            XCTAssertEqual(round.options.count, 3)
            XCTAssertEqual(Set(round.options.map(\.id)).count, 3)
            guard let correct = round.options.first(where: { $0.id == round.correctAnswerId }) else {
                XCTFail("Correct id not in options")
                continue
            }
            let slug = correct.imageName?.replacingOccurrences(of: "xx-", with: "") ?? ""
            XCTAssertEqual(round.questionImageName, "xx-silhouette-\(slug)")
            XCTAssertEqual(round.questionImageFallback, correct.imageName)
        }
    }

    func testSilhouetteGuessUsesFullPoolRoundCountEqPoolSize() {
        let pool = makeTestPool()
        let config = GuessGameConfigs.makeSilhouetteGuessGame(
            id: "test-silhouette-4",
            title: "Test",
            introAudio: "test-intro",
            bodyImagePrefix: "xx-",
            pool: pool,
            roundCount: 4
        )
        XCTAssertEqual(config.rounds.count, 4)
        XCTAssertEqual(Set(config.rounds.map(\.correctAnswerId)), Set(pool.map(\.id)))
    }
}
