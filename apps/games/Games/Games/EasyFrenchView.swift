//
//  EasyFrenchView.swift
//  Games
//

import SwiftUI

struct EasyFrenchView: View {
    var body: some View {
        List(FrenchCategory.allCases) { category in
            NavigationLink(value: category) {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.title)
                            .font(.headline)
                        Text("10 words")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: category.systemImage)
                        .foregroundStyle(.tint)
                }
            }
        }
        .navigationTitle("Easy French")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: FrenchCategory.self) { category in
            EasyFrenchCategoryView(category: category)
        }
    }
}

private struct EasyFrenchCategoryView: View {
    let category: FrenchCategory
    @State private var mode: EasyFrenchMode = .quiz

    var body: some View {
        VStack(spacing: 16) {
            Picker("Mode", selection: $mode) {
                ForEach(EasyFrenchMode.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            switch mode {
            case .study:
                EasyFrenchStudyView(category: category)
            case .quiz:
                EasyFrenchQuizView(category: category)
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct EasyFrenchStudyView: View {
    @State private var session: EasyFrenchStudySession
    @State private var speaker = FrenchSpeechSynthesizer()

    init(category: FrenchCategory) {
        _session = State(initialValue: EasyFrenchStudySession(category: category))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(session.progressText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    session.flip()
                }
                speakCardSide()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.background)
                        .shadow(color: .black.opacity(0.08), radius: 8, y: 3)

                    VStack(spacing: 12) {
                        Text(session.isFlipped ? session.answerLabel : session.promptLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(session.isFlipped ? session.backText : session.frontText)
                            .font(.largeTitle.weight(.bold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .contentTransition(.opacity)

                        Text(session.isFlipped ? "Tap to hide" : "Tap to flip")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            Button {
                speakCardSide()
            } label: {
                Label("Hear word", systemImage: "speaker.wave.2.fill")
            }
            .buttonStyle(.bordered)

            HStack(spacing: 12) {
                Button {
                    session.previous()
                    speakCardSide()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
                .disabled(session.index == 0)

                Button {
                    session.next()
                    speakCardSide()
                } label: {
                    Label("Next", systemImage: "chevron.right")
                }
                .buttonStyle(.borderedProminent)
                .disabled(session.index >= session.cards.count - 1)
            }

            HStack(spacing: 12) {
                Button("Shuffle") {
                    session.shuffle()
                    speakCardSide()
                }
                .buttonStyle(.bordered)
                Button(session.showingFrench ? "EN → FR" : "FR → EN") {
                    session.toggleDirection()
                    speakCardSide()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            speakCardSide()
        }
        .onDisappear {
            speaker.stop()
        }
    }

    private func speakCardSide() {
        if session.isFlipped {
            if session.showingFrench {
                speaker.speakEnglish(session.current.english)
            } else {
                speaker.speakFrench(session.current.frenchSpeechText)
            }
        } else if session.showingFrench {
            speaker.speakFrench(session.current.frenchSpeechText)
        } else {
            speaker.speakEnglish(session.current.english)
        }
    }
}

private struct EasyFrenchQuizView: View {
    @State private var session: EasyFrenchQuizSession
    @State private var speaker = FrenchSpeechSynthesizer()
    @State private var recognizer = FrenchSpeechRecognizer()

    init(category: FrenchCategory) {
        _session = State(initialValue: EasyFrenchQuizSession(category: category))
    }

    var body: some View {
        VStack(spacing: 20) {
            if session.isFinished {
                results
            } else {
                quizPrompt
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal)
        .task {
            await recognizer.prepare()
        }
        .onAppear {
            speakCurrentPrompt()
        }
        .onChange(of: session.index) { _, _ in
            speakCurrentPrompt()
        }
        .onChange(of: session.isFinished) { _, finished in
            if finished {
                recognizer.stop()
                speaker.stop()
            }
        }
        .onDisappear {
            recognizer.stop()
            speaker.stop()
        }
    }

    private var quizPrompt: some View {
        VStack(spacing: 16) {
            HStack {
                Text(session.progressText)
                Spacer()
                Text("Score \(session.score)")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("What is the French word for")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(session.prompt)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)

                Button {
                    speakCurrentPrompt()
                } label: {
                    Label("Hear prompt", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 16))

            voiceAnswerSection

            VStack(spacing: 10) {
                Text("Or tap an answer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(session.choices, id: \.self) { choice in
                    Button {
                        recognizer.stop()
                        session.select(choice)
                        speakAnswerFeedback()
                    } label: {
                        Text(choice)
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.bordered)
                    .tint(choiceTint(choice))
                    .disabled(session.hasAnswered)
                }
            }

            if session.hasAnswered {
                Text(session.isCorrect ? "Correct!" : "Answer: \(session.current.french)")
                    .font(.headline)
                    .foregroundStyle(session.isCorrect ? .green : .orange)

                if let heard = session.heardTranscript, !session.choices.contains(heard) {
                    Text("Heard: \(heard)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button(session.index >= session.queue.count - 1 ? "See Results" : "Next") {
                    recognizer.stop()
                    session.advance()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private var voiceAnswerSection: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    speaker.stop()
                    if !recognizer.isAvailable {
                        await recognizer.prepare()
                    }
                    recognizer.toggleListening { transcript in
                        session.submitSpoken(transcript)
                        speakAnswerFeedback()
                    }
                }
            } label: {
                Label(
                    recognizer.isListening ? "Listening… tap to stop" : "Say the French word",
                    systemImage: recognizer.isListening ? "mic.fill" : "mic"
                )
                .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(recognizer.isListening ? .red : .accentColor)
            .disabled(session.hasAnswered)

            if recognizer.isListening, !recognizer.partialTranscript.isEmpty {
                Text(recognizer.partialTranscript)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let message = recognizer.errorMessage, !recognizer.isListening {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var results: some View {
        VStack(spacing: 16) {
            Text("Quiz complete")
                .font(.title2.bold())
            Text("\(session.score) / \(session.queue.count)")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.tint)
            Text(scoreMessage)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                session.restart()
                speakCurrentPrompt()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.top, 40)
    }

    private var scoreMessage: String {
        switch session.score {
        case 10: return "Parfait!"
        case 7...9: return "Très bien!"
        case 4...6: return "Pas mal — keep practicing."
        default: return "Try Study mode, then quiz again."
        }
    }

    private func choiceTint(_ choice: String) -> Color? {
        guard let selected = session.selectedAnswer else { return nil }
        if choice == session.current.french { return .green }
        if choice == selected { return .red }
        return nil
    }

    private func speakCurrentPrompt() {
        guard !session.isFinished else { return }
        recognizer.stop()
        speaker.speakEnglish(session.prompt)
    }

    private func speakAnswerFeedback() {
        // Always reinforce the correct French pronunciation after a guess.
        speaker.speakFrench(session.current.frenchSpeechText)
    }
}

#Preview {
    NavigationStack {
        EasyFrenchView()
    }
}
