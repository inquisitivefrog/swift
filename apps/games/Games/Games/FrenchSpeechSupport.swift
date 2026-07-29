//
//  FrenchSpeechSupport.swift
//  Games
//

import AVFoundation
import Foundation
import Speech

@Observable
@MainActor
final class FrenchSpeechSynthesizer: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speakFrench(_ text: String) {
        speak(text, language: "fr-FR")
    }

    func speakEnglish(_ text: String) {
        speak(text, language: "en-US")
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    private func speak(_ text: String, language: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
            ?? AVSpeechSynthesisVoice(language: String(language.prefix(2)))
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}

@Observable
@MainActor
final class FrenchSpeechRecognizer {
    private(set) var isListening = false
    private(set) var transcript = ""
    private(set) var partialTranscript = ""
    private(set) var errorMessage: String?
    private(set) var isAvailable = false

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))

    init() {
        isAvailable = recognizer?.isAvailable ?? false
    }

    func prepare() async {
        let speechOK = await requestSpeechAuthorization()
        let micOK = await requestMicrophoneAuthorization()
        isAvailable = speechOK && micOK && (recognizer?.isAvailable ?? false)
        if !speechOK {
            errorMessage = "Speech recognition permission is required for voice answers."
        } else if !micOK {
            errorMessage = "Microphone permission is required for voice answers."
        } else {
            errorMessage = nil
        }
    }

    func toggleListening(onFinalResult: @escaping (String) -> Void) {
        if isListening {
            stop()
        } else {
            start(onFinalResult: onFinalResult)
        }
    }

    func start(onFinalResult: @escaping (String) -> Void) {
        guard !isListening else { return }
        errorMessage = nil
        transcript = ""
        partialTranscript = ""

        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition isn’t available right now."
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Couldn’t configure the microphone."
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = false
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Couldn’t start listening."
            stop()
            return
        }

        isListening = true
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    self.partialTranscript = text
                    if result.isFinal {
                        self.transcript = text
                        self.stop()
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onFinalResult(trimmed)
                        }
                    }
                }
                if let error, (error as NSError).code != 216 /* canceled */ {
                    if self.isListening {
                        self.errorMessage = "Didn’t catch that — try again or tap an answer."
                    }
                    self.stop()
                }
            }
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isListening = false
    }

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }
}

extension FrenchWord {
    /// Text spoken for French TTS (handles alphabet entries like `A (a)`).
    var frenchSpeechText: String {
        if let open = french.firstIndex(of: "("),
           let close = french.firstIndex(of: ")"),
           open < close {
            return String(french[french.index(after: open)..<close])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return french
    }

    func matchesFrenchSpeech(_ transcript: String) -> Bool {
        let spoken = Self.normalizeSpeech(transcript)
        guard !spoken.isEmpty else { return false }

        let candidates = [french, frenchSpeechText]
            .map(Self.normalizeSpeech)
            .filter { !$0.isEmpty }

        for candidate in candidates {
            if spoken == candidate {
                return true
            }
            // Avoid weak substring matches on very short words (a, e, un).
            if candidate.count <= 2 {
                continue
            }
            if spoken.contains(candidate) || candidate.contains(spoken) {
                return true
            }
        }
        return false
    }

    static func normalizeSpeech(_ text: String) -> String {
        text
            .replacingOccurrences(of: "œ", with: "oe")
            .replacingOccurrences(of: "Œ", with: "oe")
            .replacingOccurrences(of: "æ", with: "ae")
            .replacingOccurrences(of: "Æ", with: "ae")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
