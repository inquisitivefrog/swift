//
//  GuessGameView.swift
//  DinoGames
//
//  Created by Timothy Stilwell on 1/26/26.
//

import SwiftUI
import AVFoundation

// MARK: - Data Models

struct RoundQuestion: Identifiable {
    let id: Int // Round number (1, 2, 3)
    let questionImageName: String // Silhouette image name
    let questionImageFallback: String? // Fallback full image name
    let correctAnswerId: Int // ID of the correct dinosaur
    let options: [Dinosaur] // 3 dinosaurs: 1 correct + 2 decoys (all unique)
}

// MARK: - Game Configuration

struct GuessGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let rounds: [RoundQuestion] // 3 rounds of questions
    let availableDinosaurs: [Dinosaur] // All available dinosaurs for options
}

// MARK: - Main View

struct GuessGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: GuessGameConfig
    
    @State private var speechManager = SpeechManager()
    @State private var currentRound = 1 // 1, 2, or 3
    @State private var selectedDinosaur: Dinosaur?
    @State private var isAudioPlaying = false
    @State private var errorCount = 0 // Track errors across all rounds
    @State private var successCount = 0 // Track successful rounds
    @State private var wrongGuessesThisRound = 0 // End round after 2 wrong (obvious answer is last)
    @State private var isGameComplete = false
    @State private var isProcessingAnswer = false
    
    // Get current round question
    private var currentQuestion: RoundQuestion? {
        gameConfig.rounds.first { $0.id == currentRound }
    }
    
    // Reset game state
    private func resetGameState() {
        currentRound = 1
        selectedDinosaur = nil
        errorCount = 0
        successCount = 0
        wrongGuessesThisRound = 0
        isGameComplete = false
        isProcessingAnswer = false
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Title
                Text(gameConfig.title)
                    .font(.largeTitle)
                    .padding(.top)
                
                if let question = currentQuestion, !isGameComplete {
                    // Main game area - one question at a time
                    VStack(spacing: 40) {
                        // Top: Question image (silhouette), then round label below
                        VStack(spacing: 10) {
                            // Silhouette image
                            if UIImage(named: question.questionImageName) != nil {
                                Image(question.questionImageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 250, height: 250)
                            } else if let fallback = question.questionImageFallback, !fallback.isEmpty {
                                // Fallback: use full image with silhouette effect
                                Image(fallback)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 250, height: 250)
                                    .colorMultiply(.black)
                                    .opacity(0.8)
                            } else {
                                // Ultimate fallback: placeholder
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 250, height: 250)
                            }
                            Text("Round \(currentRound) of 3")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        
                        // Bottom: 3 dinosaur options in a row (tighter spacing so they fit on screen)
                        HStack(spacing: 8) {
                            ForEach(question.options) { dinosaur in
                                DinosaurOptionCard(
                                    dinosaur: dinosaur,
                                    isSelected: selectedDinosaur?.id == dinosaur.id,
                                    isDisabled: isProcessingAnswer || isAudioPlaying,
                                    onTap: {
                                        handleDinosaurTap(dinosaur, question: question)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .frame(maxWidth: .infinity)
                } else if isGameComplete {
                    // Game complete - show results
                    VStack(spacing: 20) {
                        Text(errorCount == 0 ? "Perfect! All rounds completed!" : "Game Over")
                            .font(.title)
                            .foregroundColor(errorCount == 0 ? .green : .red)
                        
                        Text("Rounds: \(successCount) / 3")
                            .font(.headline)
                    }
                    .padding()
                }
            }
            .padding()
            .onAppear {
                resetGameState()
                speechManager.isPlaying = false
                speechManager.onAudioFinished = nil
                speechManager.onAudioFinished = {
                    isAudioPlaying = false
                }
                // Intro already played on the transition screen (can-you-name-the-dinosaur.m4a / name-that-dinosaur); don't play again
            }
            .onDisappear {
                speechManager.onAudioFinished = nil
                speechManager.stopCurrentAudio()
                isAudioPlaying = false
            }
            .allowsHitTesting(!isAudioPlaying && !isProcessingAnswer)
            .opacity((isAudioPlaying || isProcessingAnswer) ? 0.7 : 1.0)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func handleDinosaurTap(_ dinosaur: Dinosaur, question: RoundQuestion) {
        guard !isProcessingAnswer && !isAudioPlaying else { return }
        
        selectedDinosaur = dinosaur
        isAudioPlaying = true
        
        // Wait for dinosaur name to finish before playing thats-right / try-again (avoids truncation)
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.checkAnswer(dinosaur: dinosaur, question: question)
        }
        speechManager.speak(dinosaur.name)
    }
    
    private func checkAnswer(dinosaur: Dinosaur, question: RoundQuestion) {
        isProcessingAnswer = true
        let isCorrectAnswer = dinosaur.id == question.correctAnswerId
        
        if isCorrectAnswer {
            // Correct! Play success audio; round/game advances after it finishes (no feedback text)
            successCount += 1
            wrongGuessesThisRound = 0
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                DispatchQueue.main.async {
                    self.selectedDinosaur = nil
                    if self.currentRound < 3 {
                        self.currentRound += 1
                        self.wrongGuessesThisRound = 0
                        self.isProcessingAnswer = false
                        self.isAudioPlaying = false
                    } else {
                        self.isGameComplete = true
                        if self.errorCount == 0 {
                            self.speechManager.speak("good-job-you-got-them-all")
                            self.speechManager.onAudioFinished = {
                                self.speechManager.onAudioFinished = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    self.isPresented = false
                                }
                            }
                        } else {
                            // Had errors: pause after thats-right, then you-didnt-get-them-all-right, then dismiss
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                self.speechManager.speak("you-didnt-get-them-all-right")
                                self.speechManager.onAudioFinished = {
                                    self.speechManager.onAudioFinished = nil
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                        self.isPresented = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
            speechManager.speak("thats-right-you-guessed-it")
        } else {
            // Wrong answer: first wrong = try-again; second wrong = skipping-this-round, then advance
            wrongGuessesThisRound += 1
            errorCount += 1
            isAudioPlaying = true
            if wrongGuessesThisRound >= 2 {
                speechManager.speak("skipping-this-round")
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    DispatchQueue.main.async {
                        self.advanceAfterRoundEnd()
                    }
                }
            } else {
                speechManager.speak("try-again")
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    DispatchQueue.main.async {
                        self.isAudioPlaying = false
                        self.selectedDinosaur = nil
                        self.isProcessingAnswer = false
                    }
                }
            }
        }
    }
    
    /// Advance to next round or game over (used after correct answer or after 2 wrong guesses in a round).
    private func advanceAfterRoundEnd() {
        isAudioPlaying = false
        selectedDinosaur = nil
        wrongGuessesThisRound = 0
        isProcessingAnswer = false
        if currentRound < 3 {
            currentRound += 1
        } else {
            isGameComplete = true
            if self.errorCount == 0 {
                self.speechManager.speak("good-job-you-got-them-all")
                self.speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.isPresented = false
                    }
                }
            } else {
                // Pause before you-didnt-get-them-all-right so it doesn't run into previous audio
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.speechManager.speak("you-didnt-get-them-all-right")
                    self.speechManager.onAudioFinished = {
                        self.speechManager.onAudioFinished = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.isPresented = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Dinosaur Option Card View

struct DinosaurOptionCard: View {
    let dinosaur: Dinosaur
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Dinosaur image or emoji
                if let imageName = dinosaur.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 90, height: 90)
                } else {
                    Text(dinosaur.icon)
                        .font(.system(size: 60))
                }
                
                // Dinosaur name (shown when selected)
                if isSelected {
                    Text(dinosaur.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .frame(width: 100, height: isSelected ? 140 : 120)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

// MARK: - Game Configurations

struct GuessGameConfigs {
    // Create a random game configuration with 3 rounds (identify by silhouette = Name that Dinosaur)
    static var nameThatDinosaur: GuessGameConfig {
        // Get all available dinosaurs
        let allDinosaurs = MatchingGameConfigs.allDinosaurs
        
        // Ensure we have at least 3 dinosaurs
        guard allDinosaurs.count >= 3 else {
            fatalError("Need at least 3 dinosaurs for guess game, but only have \(allDinosaurs.count)")
        }
        
        // Pick 3 unique dinosaurs to use as questions (all have silhouette assets)
        let shuffledAll = allDinosaurs.shuffled()
        let questionDinosaurs = Array(shuffledAll.prefix(3))
        guard questionDinosaurs.count == 3,
              Set(questionDinosaurs.map { $0.id }).count == 3 else {
            fatalError("Need at least 3 unique dinosaurs for guess game")
        }
        
        var rounds: [RoundQuestion] = []
        
        for (roundNumber, questionDinosaur) in questionDinosaurs.enumerated() {
            let roundId = roundNumber + 1
            
            // Get 2 unique decoys (any dinosaurs other than this round's question)
            let decoyCandidates = allDinosaurs.filter { $0.id != questionDinosaur.id }
            guard decoyCandidates.count >= 2 else {
                fatalError("Not enough dinosaurs for decoys in round \(roundId)")
            }
            let decoys = Array(decoyCandidates.shuffled().prefix(2))
            
            // Verify decoys are unique
            let decoyIds = Set(decoys.map { $0.id })
            assert(decoyIds.count == 2, "Both decoys must be unique")
            assert(!decoyIds.contains(questionDinosaur.id), "Decoys must not match question")
            
            // Combine: 1 correct + 2 decoys, then shuffle
            var options = [questionDinosaur] + decoys
            options.shuffle()
            
            // Verify all 3 options are unique
            let optionIds = Set(options.map { $0.id })
            assert(optionIds.count == 3, "All 3 options must be unique")
            
            // Create silhouette image name
            let baseName = questionDinosaur.imageName?.replacingOccurrences(of: "dino-", with: "") ?? ""
            let silhouetteImageName = "silhouette-\(baseName)"
            
            let round = RoundQuestion(
                id: roundId,
                questionImageName: silhouetteImageName,
                questionImageFallback: questionDinosaur.imageName,
                correctAnswerId: questionDinosaur.id,
                options: options
            )
            
            rounds.append(round)
        }
        
        // Verify all rounds have unique question dinosaurs (no duplicate silhouettes)
        let questionIds = Set(rounds.map { $0.correctAnswerId })
        assert(questionIds.count == 3, "All 3 rounds must have unique question dinosaurs")
        
        return GuessGameConfig(
            id: "name-that-dinosaur",
            title: "Name That Dinosaur!",
            introAudio: "can-you-name-the-dinosaur",
            rounds: rounds,
            availableDinosaurs: allDinosaurs
        )
    }
    
    // Future: Add a more sophisticated "Guess the Dinosaur!" game; this one is identify-by-silhouette (Name that Dinosaur).
    // Example:
    // static var dinosaurExperts: GuessGameConfig {
    //     // Similar structure but with different question types
    // }
}
