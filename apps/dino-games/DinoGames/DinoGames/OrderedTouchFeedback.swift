//
//  OrderedTouchFeedback.swift
//  DinoGames
//
//  Shared narration for pre-reader handrails: tap out of order, slow success, wrong try.
//  Audio lives under Assets/Audio/Feedback/ (resolved via SpeechManager).
//

import Foundation

/// Tracks elapsed time for slow-vs-fast success feedback; pauses while hints overlay is open.
struct GuessChoiceTimer {
    private(set) var startTime: Date?
    private var hintsPauseStart: Date?

    mutating func start(at date: Date = Date()) {
        startTime = date
        hintsPauseStart = nil
    }

    mutating func reset() {
        startTime = nil
        hintsPauseStart = nil
    }

    mutating func pauseForHints(at date: Date = Date()) {
        guard startTime != nil, hintsPauseStart == nil else { return }
        hintsPauseStart = date
    }

    mutating func resumeAfterHints(at date: Date = Date()) {
        guard let pauseStart = hintsPauseStart, let start = startTime else {
            hintsPauseStart = nil
            return
        }
        startTime = start.addingTimeInterval(date.timeIntervalSince(pauseStart))
        hintsPauseStart = nil
    }

    func elapsed(at date: Date = Date()) -> TimeInterval {
        guard let start = startTime else { return 0 }
        var elapsed = date.timeIntervalSince(start)
        if let pauseStart = hintsPauseStart {
            elapsed -= date.timeIntervalSince(pauseStart)
        }
        return max(0, elapsed)
    }
}

enum OrderedTouchFeedback {
    static let pickDinosaurFirst = "pick-a-dinosaur-first"
    static let pickPterosaurFirst = "pick-a-pterosaur-first"
    static let wowThatWasTricky = "wow-that-was-tricky"
    static let greatMatch = "great-match"
    static let tryAgain = "try-again"
    static let pickAnotherOne = "pick-another-one"
    static let thatsRightYouGuessedIt = "thats-right-you-guessed-it"

    /// Default pair-completion threshold (Dino Ages, Flora, Smile, Eggs).
    static let defaultSlowThresholdSeconds: TimeInterval = 5
    /// Dino Diets uses a longer thinking window.
    static let dietSlowThresholdSeconds: TimeInterval = 10

    static func successMatchAudio(elapsed: TimeInterval, slowThreshold: TimeInterval = defaultSlowThresholdSeconds) -> String {
        elapsed > slowThreshold ? wowThatWasTricky : greatMatch
    }

    /// Eggs / guess games: fast correct uses celebration clip; slow uses tricky feedback.
    static func guessSuccessAudio(elapsed: TimeInterval, slowThreshold: TimeInterval = defaultSlowThresholdSeconds) -> String {
        elapsed > slowThreshold ? wowThatWasTricky : thatsRightYouGuessedIt
    }

    @MainActor
    static func speak(_ key: String, speechManager: SpeechManager, onFinished: (() -> Void)? = nil) {
        if let onFinished {
            speechManager.onAudioFinished = onFinished
        }
        if let url = speechManager.urlForAudio(key: key) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(key)
        }
    }
}
