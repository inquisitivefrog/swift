//
//  GuessGameConfigs+Silhouette.swift
//  DinoGames
//
//  Shared builder for multi-round silhouette identification (Name That Pterosaur pattern).
//

import Foundation

extension GuessGameConfigs {
    /// Random silhouette rounds: body images use `bodyImagePrefix` (e.g. `ptero-`); clues use `{stem}-silhouette-{slug}`.
    static func makeSilhouetteGuessGame(
        id: String,
        title: String,
        introAudio: String,
        bodyImagePrefix: String,
        pool: [Dinosaur],
        roundCount: Int
    ) -> GuessGameConfig {
        guard roundCount >= 1, pool.count >= roundCount else {
            fatalError("\(title): need pool.count (\(pool.count)) >= roundCount (\(roundCount))")
        }
        let stem = bodyImagePrefix.hasSuffix("-") ? String(bodyImagePrefix.dropLast()) : bodyImagePrefix
        let silhouettePrefix = "\(stem)-silhouette-"
        let shuffledPool = pool.shuffled()
        let questionCreatures = Array(shuffledPool.prefix(roundCount))
        guard questionCreatures.count == roundCount,
              Set(questionCreatures.map(\.id)).count == roundCount else {
            fatalError("\(title): could not pick \(roundCount) unique creatures")
        }
        var rounds: [RoundQuestion] = []
        for (roundNumber, questionCreature) in questionCreatures.enumerated() {
            let roundId = roundNumber + 1
            let decoyCandidates = pool.filter { $0.id != questionCreature.id }
            guard decoyCandidates.count >= 2 else {
                fatalError("\(title): not enough decoys in round \(roundId) (pool size \(pool.count))")
            }
            let decoys = Array(decoyCandidates.shuffled().prefix(2))
            var options = [questionCreature] + decoys
            options.shuffle()
            let baseName = questionCreature.imageName?.replacingOccurrences(of: bodyImagePrefix, with: "") ?? ""
            let silhouetteImageName = "\(silhouettePrefix)\(baseName)"
            rounds.append(RoundQuestion(
                id: roundId,
                questionImageName: silhouetteImageName,
                questionImageFallback: questionCreature.imageName,
                correctAnswerId: questionCreature.id,
                options: options
            ))
        }
        return GuessGameConfig(
            id: id,
            title: title,
            introAudio: introAudio,
            rounds: rounds,
            availableDinosaurs: pool
        )
    }
}
