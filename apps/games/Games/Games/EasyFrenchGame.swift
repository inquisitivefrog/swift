//
//  EasyFrenchGame.swift
//  Games
//

import Foundation

enum EasyFrenchMode: String, CaseIterable, Identifiable {
    case study
    case quiz

    var id: String { rawValue }

    var title: String {
        switch self {
        case .study: "Study"
        case .quiz: "Quiz"
        }
    }
}

@Observable
final class EasyFrenchStudySession {
    private(set) var category: FrenchCategory
    private(set) var cards: [FrenchWord]
    private(set) var index: Int
    private(set) var showingFrench: Bool
    private(set) var isFlipped: Bool

    init(category: FrenchCategory) {
        self.category = category
        self.cards = category.words.shuffled()
        self.index = 0
        self.showingFrench = true
        self.isFlipped = false
    }

    var current: FrenchWord {
        cards[index]
    }

    var progressText: String {
        "\(index + 1) / \(cards.count)"
    }

    var frontText: String {
        showingFrench ? current.french : current.english
    }

    var backText: String {
        showingFrench ? current.english : current.french
    }

    var promptLabel: String {
        showingFrench ? "French" : "English"
    }

    var answerLabel: String {
        showingFrench ? "English" : "French"
    }

    func flip() {
        isFlipped.toggle()
    }

    func next() {
        guard index < cards.count - 1 else { return }
        index += 1
        isFlipped = false
    }

    func previous() {
        guard index > 0 else { return }
        index -= 1
        isFlipped = false
    }

    func shuffle() {
        cards.shuffle()
        index = 0
        isFlipped = false
    }

    func toggleDirection() {
        showingFrench.toggle()
        isFlipped = false
    }
}

@Observable
final class EasyFrenchQuizSession {
    private(set) var category: FrenchCategory
    private(set) var queue: [FrenchWord]
    private(set) var index: Int
    private(set) var choices: [String]
    private(set) var selectedAnswer: String?
    private(set) var score: Int
    private(set) var isFinished: Bool
    private(set) var heardTranscript: String?

    init(category: FrenchCategory) {
        self.category = category
        self.queue = category.words.shuffled()
        self.index = 0
        self.choices = []
        self.selectedAnswer = nil
        self.score = 0
        self.isFinished = false
        self.heardTranscript = nil
        refreshChoices()
    }

    var current: FrenchWord {
        queue[index]
    }

    var progressText: String {
        "\(min(index + 1, queue.count)) / \(queue.count)"
    }

    var prompt: String {
        current.english
    }

    var hasAnswered: Bool {
        selectedAnswer != nil
    }

    var isCorrect: Bool {
        selectedAnswer == current.french
    }

    func select(_ answer: String) {
        guard selectedAnswer == nil, !isFinished else { return }
        selectedAnswer = answer
        if answer == current.french {
            score += 1
        }
    }

    /// Matches a spoken French answer to a choice or the correct word.
    func submitSpoken(_ transcript: String) {
        guard selectedAnswer == nil, !isFinished else { return }
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        heardTranscript = trimmed

        if current.matchesFrenchSpeech(trimmed) {
            select(current.french)
            return
        }
        if let match = choices.first(where: { FrenchWord(french: $0, english: "").matchesFrenchSpeech(trimmed) }) {
            select(match)
            return
        }
        selectedAnswer = trimmed
    }

    func advance() {
        guard selectedAnswer != nil else { return }
        if index >= queue.count - 1 {
            isFinished = true
            return
        }
        index += 1
        selectedAnswer = nil
        heardTranscript = nil
        refreshChoices()
    }

    func restart() {
        queue = category.words.shuffled()
        index = 0
        selectedAnswer = nil
        heardTranscript = nil
        score = 0
        isFinished = false
        refreshChoices()
    }

    private func refreshChoices() {
        let correct = current.french
        var options = Set([correct])
        let pool = category.words.map(\.french).filter { $0 != correct }
        for word in pool.shuffled() where options.count < 4 {
            options.insert(word)
        }
        choices = options.shuffled()
    }
}
