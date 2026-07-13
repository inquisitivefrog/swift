//
//  CategoryGuidedCompletionAudio.swift
//  DinoGames
//
//  Sequential celebration audio for guided category completion (land, air, sea).
//

import Foundation

@MainActor
enum CategoryGuidedCompletionAudio {
    /// Plays congratulations, then crowd cheering, then runs `onComplete`.
    static func playCelebrationSequence(
        speechManager: SpeechManager,
        onComplete: @escaping () -> Void
    ) {
        if UITestConfiguration.skipAudioPlayback {
            onComplete()
            return
        }
        playClip(at: 0, speechManager: speechManager, onComplete: onComplete)
    }

    private static func playClip(
        at index: Int,
        speechManager: SpeechManager,
        onComplete: @escaping () -> Void
    ) {
        let keys = CategoryGuidedCompletion.celebrationAudioKeys
        guard index < keys.count else {
            onComplete()
            return
        }
        let key = keys[index]
        guard let url = speechManager.urlForAudio(key: key) else {
            playClip(at: index + 1, speechManager: speechManager, onComplete: onComplete)
            return
        }
        speechManager.onAudioFinished = {
            speechManager.onAudioFinished = nil
            playClip(at: index + 1, speechManager: speechManager, onComplete: onComplete)
        }
        speechManager.playAudioFile(url: url)
    }
}
