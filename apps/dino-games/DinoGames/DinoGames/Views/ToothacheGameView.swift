//
//  ToothacheGameView.swift
//  DinoGames
//
//  Toothache: A paleontologist found a tooth. Match it to the correct grumpy dinosaur.
//

import SwiftUI
import AVFoundation
import UIKit

/// Seconds after success/game-over audio starts before auto-returning to game list (players 4–6 cannot read a button).
private let autoReturnDelay: TimeInterval = 5.5

// MARK: - Data Models

struct ToothacheRound: Identifiable {
    let id: Int // Round number (1, 2, 3)
    let toothImageName: String // Tooth image (tooth-*)
    let correctAnswerId: Int // ID of the correct dinosaur
    let options: [Dinosaur] // 3 dinosaurs: 1 correct + 2 decoys
}

// MARK: - Game Configuration

struct ToothacheGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let rounds: [ToothacheRound]
    let availableDinosaurs: [Dinosaur]
}

// MARK: - Main View

struct ToothacheGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: ToothacheGameConfig
    
    @State private var speechManager = SpeechManager()
    @State private var currentRound = 1
    @State private var selectedDinosaur: Dinosaur?
    @State private var isAudioPlaying = false
    @State private var errorCount = 0
    @State private var successCount = 0
    @State private var wrongGuessesThisRound = 0
    @State private var isGameComplete = false
    @State private var isProcessingAnswer = false
    
    private var currentQuestion: ToothacheRound? {
        gameConfig.rounds.first { $0.id == currentRound }
    }
    
    private func resetGameState() {
        currentRound = 1
        selectedDinosaur = nil
        errorCount = 0
        successCount = 0
        wrongGuessesThisRound = 0
        isGameComplete = false
        isProcessingAnswer = false
    }
    
    /// Grumpy image name for a dinosaur: grumpy- + slug from imageName (e.g. dino-trex → grumpy-trex).
    private func grumpyImageName(for dinosaur: Dinosaur) -> String {
        let slug = dinosaur.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(dinosaur.id)"
        return "grumpy-\(slug)"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text(gameConfig.title)
                    .font(.largeTitle)
                    .padding(.top)
                
                if let question = currentQuestion, !isGameComplete {
                    VStack(spacing: 40) {
                        // Top: Tooth image (the one the paleontologist found)
                        VStack(spacing: 10) {
                            if UIImage(named: question.toothImageName) != nil {
                                Image(question.toothImageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 220, height: 220)
                            } else {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.brown.opacity(0.4))
                                    .frame(width: 220, height: 220)
                                    .overlay(
                                        Text("Tooth")
                                            .font(.title2)
                                            .foregroundColor(.secondary)
                                    )
                            }
                            Text("Round \(currentRound) of 3")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        
                        // Bottom: 3 grumpy dinosaur options
                        HStack(spacing: 8) {
                            ForEach(question.options) { dinosaur in
                                GrumpyOptionCard(
                                    dinosaur: dinosaur,
                                    grumpyImageName: grumpyImageName(for: dinosaur),
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
                // Play game intro when view loads (transition already played toothache.m4a)
                isAudioPlaying = true
                speechManager.speak("can-you-return-the-tooth")
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
    
    private func handleDinosaurTap(_ dinosaur: Dinosaur, question: ToothacheRound) {
        guard !isProcessingAnswer && !isAudioPlaying else { return }
        
        selectedDinosaur = dinosaur
        isAudioPlaying = true
        
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.checkAnswer(dinosaur: dinosaur, question: question)
        }
        speechManager.speak(dinosaur.name)
    }
    
    private func checkAnswer(dinosaur: Dinosaur, question: ToothacheRound) {
        isProcessingAnswer = true
        let isCorrect = dinosaur.id == question.correctAnswerId
        
        if isCorrect {
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
                        // Use successCount (just incremented) as source of truth: 3 correct = win. Auto-return after audio + pause (no button for 4–6 year olds).
                        if self.successCount == 3 {
                            self.speechManager.speak("good-job-you-got-them-all")
                            DispatchQueue.main.asyncAfter(deadline: .now() + autoReturnDelay) {
                                self.isPresented = false
                            }
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                self.speechManager.speak("you-didnt-get-them-all-right")
                                DispatchQueue.main.asyncAfter(deadline: .now() + autoReturnDelay) {
                                    self.isPresented = false
                                }
                            }
                        }
                    }
                }
            }
            speechManager.speak("thats-right-you-guessed-it")
        } else {
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
    
    private func advanceAfterRoundEnd() {
        isAudioPlaying = false
        selectedDinosaur = nil
        wrongGuessesThisRound = 0
        isProcessingAnswer = false
        if currentRound < 3 {
            currentRound += 1
        } else {
            isGameComplete = true
            if successCount == 3 {
                speechManager.speak("good-job-you-got-them-all")
                DispatchQueue.main.asyncAfter(deadline: .now() + autoReturnDelay) {
                    self.isPresented = false
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.speechManager.speak("you-didnt-get-them-all-right")
                    DispatchQueue.main.asyncAfter(deadline: .now() + autoReturnDelay) {
                        self.isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Grumpy Option Card

struct GrumpyOptionCard: View {
    let dinosaur: Dinosaur
    let grumpyImageName: String
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                if UIImage(named: grumpyImageName) != nil {
                    Image(grumpyImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 90, height: 90)
                } else {
                    Text(dinosaur.icon)
                        .font(.system(size: 60))
                }
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

struct ToothacheGameConfigs {
    /// Dinosaurs that have both tooth-* and grumpy-* imagesets (used so we only show rounds we can render).
    private static var dinosaursWithToothAndGrumpyImages: [Dinosaur] {
        MatchingGameConfigs.allDinosaurs.filter { dino in
            let slug = dino.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(dino.id)"
            let toothName = "tooth-\(slug)"
            let grumpyName = "grumpy-\(slug)"
            return UIImage(named: toothName) != nil && UIImage(named: grumpyName) != nil
        }
    }
    
    /// Toothache: match the tooth to the correct grumpy dinosaur. Uses only dinosaurs that have tooth-* and grumpy-* imagesets.
    static var toothache: ToothacheGameConfig {
        let pool = dinosaursWithToothAndGrumpyImages
        guard pool.count >= 3 else {
            fatalError("Need at least 3 dinosaurs with tooth+grumpy images for Toothache, but only have \(pool.count). Add tooth-* and grumpy-* imagesets for more dinosaurs.")
        }
        
        let shuffledAll = pool.shuffled()
        let questionDinosaurs = Array(shuffledAll.prefix(3))
        guard questionDinosaurs.count == 3,
              Set(questionDinosaurs.map { $0.id }).count == 3 else {
            fatalError("Need at least 3 unique dinosaurs for Toothache")
        }
        
        var rounds: [ToothacheRound] = []
        
        for (roundNumber, correctDinosaur) in questionDinosaurs.enumerated() {
            let roundId = roundNumber + 1
            let decoyCandidates = pool.filter { $0.id != correctDinosaur.id }
            guard decoyCandidates.count >= 2 else { continue }
            let decoys = Array(decoyCandidates.shuffled().prefix(2))
            var options = [correctDinosaur] + decoys
            options.shuffle()
            
            let slug = correctDinosaur.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(correctDinosaur.id)"
            let toothImageName = "tooth-\(slug)"
            
            let round = ToothacheRound(
                id: roundId,
                toothImageName: toothImageName,
                correctAnswerId: correctDinosaur.id,
                options: options
            )
            rounds.append(round)
        }
        
        return ToothacheGameConfig(
            id: "toothache",
            title: "Toothache!",
            introAudio: "toothache",
            rounds: rounds,
            availableDinosaurs: pool
        )
    }
}
