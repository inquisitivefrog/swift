//
//  GuessSilhouetteGameSwiftTests.swift
//  DinoGamesTests
//
//  Swift Testing (`import Testing`).

import Foundation
import Testing
@testable import DinoGames

@Suite("Silhouette guess game builder")
struct GuessSilhouetteGameSwiftTests {

    private static func testPool() -> [Dinosaur] {
        [
            Dinosaur(id: 8001, name: "A", icon: "🌊", imageName: "ab-a", characteristicIds: []),
            Dinosaur(id: 8002, name: "B", icon: "🌊", imageName: "ab-b", characteristicIds: []),
            Dinosaur(id: 8003, name: "C", icon: "🌊", imageName: "ab-c", characteristicIds: []),
        ]
    }

    @Test("Three rounds, three options, silhouette names")
    func structure() {
        let pool = Self.testPool()
        let config = GuessGameConfigs.makeSilhouetteGuessGame(
            id: "swift-test-silhouette",
            title: "Swift Test",
            introAudio: "swift-test-intro",
            bodyImagePrefix: "ab-",
            pool: pool,
            roundCount: 3
        )
        #expect(config.rounds.count == 3)
        #expect(Set(config.rounds.map(\.correctAnswerId)).count == 3)

        for round in config.rounds {
            #expect(round.options.count == 3)
            #expect(Set(round.options.map(\.id)).count == 3)
            let correct = round.options.first { $0.id == round.correctAnswerId }
            #expect(correct != nil)
            let slug = correct!.imageName!.replacingOccurrences(of: "ab-", with: "")
            #expect(round.questionImageName == "ab-silhouette-\(slug)")
        }
    }
}
