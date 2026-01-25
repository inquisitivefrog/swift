//
//  MatchingGameView.swift
//  DinoGames
//
//  Created by Timothy Stilwell on 1/23/26.
//

import SwiftUI
import AVFoundation
import UIKit

// Track specific dinosaur-characteristic pairs that have been matched
struct MatchedPair: Hashable {
    let dinosaurId: Int
    let characteristicId: Int
}

// Shared audio manager for playing recorded audio files
@MainActor
class SpeechManager: NSObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var currentPlayer: AVAudioPlayer?
    private var lastPlayTime: Date = Date.distantPast
    private let minimumPlayInterval: TimeInterval = 0.3 // Prevent rapid-fire audio
    
    // Callback for when audio finishes playing
    var onAudioFinished: (() -> Void)?
    var isPlaying: Bool = false
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // Map text to audio file paths (case-insensitive matching)
    private func audioFilePath(for text: String) -> String? {
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "!", with: "")
        
        // Map common phrases to file names (matching your recorded files)
        switch normalized {
        // Dinosaurs - matching your data: "T-Rex", "Triceratops", "Stegosaurus"
        case "t-rex", "t rex", "tyrannosaurus":
            return "Dinosaurs/t-rex"
        case "triceratops":
            return "Dinosaurs/triceratops"
        case "stegosaurus":
            return "Dinosaurs/stegosaurus"
            
        // Characteristics - matching your data: "Teeth", "Footprints", "Eggs", "Skin", "Spikes"
        case "teeth":
            return "Characteristics/teeth"
        case "footprints":
            return "Characteristics/footprints"
        case "eggs":
            return "Characteristics/eggs"
        case "skin":
            return "Characteristics/skin"
        case "spikes":
            return "Characteristics/spikes"
            
        // Feedback
        case "great-match", "great match":
            return "Feedback/great-match"
        case "try-again", "try again":
            return "Feedback/try-again"
        case "game-intro-matching", "game intro", "game intro matching":
            return "Feedback/game-intro-matching"
        case "success-all-matches", "successallmatches", "success all matches", "you did it", "all matches found":
            return "Feedback/success-all-matches"
            
        default:
            // Debug output to help diagnose mapping issues
            if text.contains("success") || text.contains("matches") {
                print("   ⚠️ No match for '\(text)' → normalized: '\(normalized)'")
            }
            return nil
        }
    }
    
    func speak(_ text: String) {
        // Rate limiting: prevent audio overload from rapid taps
        let now = Date()
        guard now.timeIntervalSince(lastPlayTime) >= minimumPlayInterval else {
            print("⏸️ Skipping audio (too soon after last): \(text)")
            return
        }
        lastPlayTime = now
        
        // Stop any current audio
        currentPlayer?.stop()
        synthesizer.stopSpeaking(at: .immediate)
        
        // Small delay to let stop complete and prevent HALC overload
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // Try to play recorded audio first
            if let audioPath = self.audioFilePath(for: text) {
                // Try different path formats - files are in bundle with full paths like DinoGames/Assets/Audio/...
                // Extract just the filename from the path (e.g., "Dinosaurs/t-rex" -> "t-rex")
                let fileName = (audioPath as NSString).lastPathComponent
            
                let paths = [
                    "DinoGames/Assets/Audio/\(audioPath)",  // Full path as shown in bundle
                    "Assets/Audio/\(audioPath)",           // Assets/Audio/Dinosaurs/t-rex
                    "assets/Audio/\(audioPath)",            // assets/Audio/Dinosaurs/t-rex (lowercase)
                    "Audio/\(audioPath)",                   // Audio/Dinosaurs/t-rex
                    audioPath,                              // Dinosaurs/t-rex
                    fileName                                // Just filename: t-rex (if flattened)
                ]
                
                var foundURL: URL?
                for path in paths {
                    if let url = Bundle.main.url(forResource: path, withExtension: "m4a") {
                        foundURL = url
                        print("   ✅ Found at path: \(path)")
                        break
                    }
                }
                
                // Also try searching in subdirectories if direct path fails
                if foundURL == nil {
                    // Search for just the filename in all bundle resources
                    if let resourcePath = Bundle.main.resourcePath {
                        let fileManager = FileManager.default
                        if let enumerator = fileManager.enumerator(atPath: resourcePath) {
                            while let file = enumerator.nextObject() as? String {
                                if file.hasSuffix("\(fileName).m4a") {
                                    let fullPath = (resourcePath as NSString).appendingPathComponent(file)
                                    foundURL = URL(fileURLWithPath: fullPath)
                                    print("   ✅ Found by searching: \(file)")
                                    break
                                }
                            }
                        }
                    }
                }
                
                if let url = foundURL {
                    self.playAudioFile(url: url)
                    print("🔊 Playing audio: \(audioPath).m4a")
                } else {
                    // Fallback to text-to-speech if no audio file found
                    print("⚠️ No audio file found for '\(text)' (tried: \(paths.joined(separator: ", ")))")
                    
                    // Debug: List what's actually in the bundle
                    if let resourcePath = Bundle.main.resourcePath {
                        print("   📦 Bundle resource path: \(resourcePath)")
                        
                        // Search recursively for .m4a files
                        let fileManager = FileManager.default
                        if let enumerator = fileManager.enumerator(atPath: resourcePath) {
                            var foundFiles: [String] = []
                            while let file = enumerator.nextObject() as? String {
                                if file.hasSuffix(".m4a") {
                                    foundFiles.append(file)
                                }
                            }
                            if !foundFiles.isEmpty {
                                print("   📁 Found .m4a files in bundle: \(foundFiles.prefix(10).joined(separator: ", "))")
                            } else {
                                print("   ❌ No .m4a files found in bundle at all!")
                            }
                        }
                    }
                    
                    self.startSpeaking(text)
                }
            } else {
                // No mapping found, use TTS
                print("🔊 No mapping for '\(text)', using TTS")
                self.startSpeaking(text)
            }
        }
    }
    
    func playAudioFile(url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1.0 // Maximum volume
            player.delegate = self // Set delegate to detect when playback finishes
            player.prepareToPlay()
            player.play()
            currentPlayer = player
            isPlaying = true
            print("🔊 Playing at volume: \(player.volume)")
        } catch {
            print("❌ Error playing audio file: \(error)")
            isPlaying = false
            // Fallback to TTS on error
            startSpeaking(url.lastPathComponent)
        }
    }
    
    // AVAudioPlayerDelegate method - called when audio finishes
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        onAudioFinished?()
    }
    
    // Handle audio interruption
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlaying = false
        onAudioFinished?()
    }
    
    // AVSpeechSynthesizerDelegate - called when TTS finishes
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPlaying = false
            onAudioFinished?()
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPlaying = false
            onAudioFinished?()
        }
    }
    
    func startSpeaking(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Slower for children
        utterance.volume = 1.0 // Full volume
        
        // Delegate is set in init
        isPlaying = true
        synthesizer.speak(utterance)
    }
}

struct MatchingGameView: View {
    @Binding var isPresented: Bool // For navigation back to game selection
    let gameConfig: MatchingGameConfig // Game-specific configuration
    
    @State private var speechManager = SpeechManager()
    @State private var selectedDinosaur: Dinosaur?
    @State private var selectedCharacteristic: Characteristic?
    @State private var matchedPairs: Set<MatchedPair> = [] // Track specific matched pairs
    @State private var failedAttempts: Set<MatchedPair> = [] // Track failed attempts (visual only, doesn't block)
    @State private var showFeedback = false
    @State private var feedbackMessage = ""
    @State private var isCorrect = false
    @State private var audioTestMessage = ""
    @State private var isAudioPlaying = false // Track if audio is currently playing
    
    // Convenience accessors
    private var dinosaurs: [Dinosaur] { gameConfig.dinosaurs }
    private var characteristics: [Characteristic] { gameConfig.characteristics }
    
    // Reset game state when view appears (allows replay)
    private func resetGameState() {
        matchedPairs.removeAll()
        failedAttempts.removeAll()
        selectedDinosaur = nil
        selectedCharacteristic = nil
        showFeedback = false
        feedbackMessage = ""
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title
                Text(gameConfig.title)
                    .font(.largeTitle)
                    .padding()
                
                // Main game area (centered)
                HStack(spacing: 20) {
                    // Left: Dinosaurs
                    VStack(spacing: 15) {
                        Text("Dinosaurs")
                            .font(.headline)
                        
                        ForEach(dinosaurs) { dinosaur in
                            DinosaurCard(
                                dinosaur: dinosaur,
                                isSelected: selectedDinosaur?.id == dinosaur.id,
                                isMatched: matchedPairs.contains { $0.dinosaurId == dinosaur.id },
                                hasFailedAttempt: failedAttempts.contains { $0.dinosaurId == dinosaur.id },
                                onTap: {
                                    handleDinosaurTap(dinosaur)
                                }
                            )
                        }
                    }
                    
                    // Right: Special Features
                    VStack(spacing: 15) {
                        Text("Special Feature")
                            .font(.headline)
                        
                        ForEach(characteristics) { characteristic in
                            CharacteristicCard(
                                characteristic: characteristic,
                                isSelected: selectedCharacteristic?.id == characteristic.id,
                                isMatched: matchedPairs.contains { $0.characteristicId == characteristic.id },
                                hasFailedAttempt: failedAttempts.contains { $0.characteristicId == characteristic.id },
                                onTap: {
                                    handleCharacteristicTap(characteristic)
                                }
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
                .padding(.vertical)
                
                // Feedback message
                if showFeedback {
                    Text(feedbackMessage)
                        .font(.headline)
                        .foregroundColor(isCorrect ? .green : .orange)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isCorrect ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        )
                        .transition(.scale)
                }
                
            // Progress indicator (matches = number of dinosaurs matched)
            Text("Matches: \(matchedPairs.count) / \(dinosaurs.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding()
            .onAppear {
                // Reset game state for fresh play (allows replay)
                resetGameState()
                // Set up audio finished callback
                speechManager.onAudioFinished = {
                    isAudioPlaying = false
                }
                // Play game introduction when view appears
                isAudioPlaying = true
                speechManager.speak(gameConfig.introAudio)
            }
            .allowsHitTesting(!isAudioPlaying) // Disable interaction while audio plays
            .opacity(isAudioPlaying ? 0.7 : 1.0) // Visual indicator that interaction is disabled
            .navigationBarTitleDisplayMode(.inline)
        } // End NavigationView
    } // End body
    
    private func handleDinosaurTap(_ dinosaur: Dinosaur) {
        // If this dinosaur is fully matched (all characteristics matched), don't allow selection
        let dinosaurCharacteristics = characteristics.filter { $0.dinosaurId == dinosaur.id }
        let matchedCount = matchedPairs.filter { $0.dinosaurId == dinosaur.id }.count
        guard matchedCount < dinosaurCharacteristics.count else { return }
        
        // If tapping the same dinosaur again, deselect it (no audio)
        if selectedDinosaur?.id == dinosaur.id {
            selectedDinosaur = nil
            return
        }
        
        // Play audio feedback only when selecting (not deselecting)
        isAudioPlaying = true
        speechManager.speak(dinosaur.name)
        
        selectedDinosaur = dinosaur
        selectedCharacteristic = nil // Reset characteristic selection
        
        // Don't check match yet - wait for user to select characteristic
    }
    
    private func handleCharacteristicTap(_ characteristic: Characteristic) {
        // If this specific characteristic is already matched, don't allow selection
        guard !matchedPairs.contains(where: { $0.characteristicId == characteristic.id }) else { return }
        
        // If tapping the same characteristic again, deselect it (no audio)
        if selectedCharacteristic?.id == characteristic.id {
            selectedCharacteristic = nil
            return
        }
        
        selectedCharacteristic = characteristic
        
        // Play audio feedback for characteristic only when selecting (not deselecting)
        isAudioPlaying = true
        speechManager.speak(characteristic.type)
        
        // Wait longer for the characteristic name to be fully spoken before checking match
        // This prevents "try-again" from interrupting the characteristic name
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // Only check match if we still have both selected (user didn't deselect)
            if self.selectedDinosaur != nil && self.selectedCharacteristic != nil {
                self.checkMatch()
            }
        }
    }
    
    private func checkMatch() {
        guard let dinosaur = selectedDinosaur,
              let characteristic = selectedCharacteristic else {
            return
        }
        
        // Check if this characteristic belongs to this dinosaur
        let isMatch = characteristic.dinosaurId == dinosaur.id
        
        isCorrect = isMatch
        showFeedback = true
        
        if isMatch {
            // Success!
            feedbackMessage = "🎉 Great match! \(dinosaur.name) has \(characteristic.type)!"
            isAudioPlaying = true
            speechManager.speak("great-match")
            
            // Add this specific pair to matched pairs
            let newPair = MatchedPair(dinosaurId: dinosaur.id, characteristicId: characteristic.id)
            matchedPairs.insert(newPair)
            
            // Check if game is complete IMMEDIATELY after adding match
            // Each dinosaur can only be matched once, so game is complete when
            // we have as many matches as there are dinosaurs
            let allDinosaursMatched = matchedPairs.count == dinosaurs.count
            
            if allDinosaursMatched {
                // Game complete! Show success message and return to home
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.feedbackMessage = "🎊 You did it! All matches found!"
                    // Use exact string that matches the audio file name
                    self.isAudioPlaying = true
                    self.speechManager.speak("success-all-matches")
                    self.showFeedback = true
                    
                    // Return to game selection after showing success message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        self.isPresented = false
                    }
                }
            } else {
                // Not complete yet - reset selection normally
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.selectedDinosaur = nil
                    self.selectedCharacteristic = nil
                    self.showFeedback = false
                }
            }
        } else {
            // Try again - track failed attempt (visual only, doesn't block)
            let failedPair = MatchedPair(dinosaurId: dinosaur.id, characteristicId: characteristic.id)
            failedAttempts.insert(failedPair)
            
            feedbackMessage = "Try again! Find the right match."
            isAudioPlaying = true
            speechManager.speak("try-again")
            
            // Reset selection after delay (pregnant pause for "Try Again" to be heard)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                selectedDinosaur = nil
                selectedCharacteristic = nil
                showFeedback = false
                
                // Clear failed attempt indicator after showing it for a bit
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    failedAttempts.remove(failedPair)
                }
            }
        }
    }
}

// MARK: - Game Configuration

struct MatchingGameConfig {
    let id: String // Unique identifier (e.g., "dino-features", "dino-habitat", "dino-food")
    let title: String // Game title shown to player
    let introAudio: String // Audio file name for game intro (e.g., "game-intro-matching")
    let dinosaurs: [Dinosaur]
    let characteristics: [Characteristic]
    
    // Helper to get all characteristics for a specific dinosaur
    func characteristics(for dinosaurId: Int) -> [Characteristic] {
        characteristics.filter { $0.dinosaurId == dinosaurId }
    }
}

// MARK: - Data Models

struct Dinosaur: Identifiable {
    let id: Int
    let name: String
    let icon: String // Can be emoji string or image name
    let imageName: String? // Optional image name from Assets.xcassets
    let characteristicIds: [Int] // IDs of characteristics that belong to this dinosaur
    
    // Helper to determine if we should use image or emoji
    var hasImage: Bool {
        imageName != nil
    }
}

struct Characteristic: Identifiable {
    let id: Int
    let type: String
    let icon: String // Can be emoji string or image name
    let imageName: String? // Optional image name from Assets.xcassets
    let dinosaurId: Int // Which dinosaur this belongs to
    
    // Helper to determine if we should use image or emoji
    var hasImage: Bool {
        imageName != nil
    }
}

// MARK: - Card Components

struct DinosaurCard: View {
    let dinosaur: Dinosaur
    let isSelected: Bool
    let isMatched: Bool
    let hasFailedAttempt: Bool
    let onTap: () -> Void
    
    private var backgroundColor: Color {
        if isMatched {
            return Color.green.opacity(0.3)
        } else if isSelected {
            return Color.blue.opacity(0.3)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private var strokeColor: Color {
        if isMatched {
            return Color.green
        } else if isSelected {
            return Color.blue
        } else if hasFailedAttempt {
            return Color.red.opacity(0.5)
        } else {
            return Color.clear
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                VStack(spacing: 8) {
                    // Large visual - use image if available, otherwise emoji
                    if let imageName = dinosaur.imageName {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .onAppear {
                                // Debug: Check if image exists
                                if UIImage(named: imageName) == nil {
                                    print("⚠️ Dinosaur image not found: '\(imageName)' - using emoji fallback")
                                }
                            }
                    } else {
                        Text(dinosaur.icon)
                            .font(.system(size: 60))
                    }
                    
                    // Show text only when selected or matched (for parents)
                    if isSelected || isMatched {
                        if isMatched {
                            Text("✓")
                                .font(.title)
                                .foregroundColor(.green)
                        } else {
                            Text(dinosaur.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                
                // Show X for failed attempt (temporary, fades)
                if hasFailedAttempt && !isMatched {
                    Text("✗")
                        .font(.system(size: 40))
                        .foregroundColor(.red.opacity(0.7))
                        .transition(.opacity)
                }
            }
            .frame(width: 180, height: isSelected || isMatched ? 120 : 100)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(backgroundColor)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(strokeColor, lineWidth: 3)
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
            .animation(.spring(response: 0.3), value: isMatched)
            .animation(.easeOut(duration: 0.5), value: hasFailedAttempt)
        }
        .disabled(isMatched)
    }
}

struct CharacteristicCard: View {
    let characteristic: Characteristic
    let isSelected: Bool
    let isMatched: Bool
    let hasFailedAttempt: Bool
    let onTap: () -> Void
    
    private var backgroundColor: Color {
        if isMatched {
            return Color.green.opacity(0.3)
        } else if isSelected {
            return Color.blue.opacity(0.3)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private var strokeColor: Color {
        if isMatched {
            return Color.green
        } else if isSelected {
            return Color.blue
        } else if hasFailedAttempt {
            return Color.red.opacity(0.5)
        } else {
            return Color.clear
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                VStack(spacing: 8) {
                    // Large visual - use image if available, otherwise emoji
                    if let imageName = characteristic.imageName {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .onAppear {
                                // Debug: Check if image exists
                                if UIImage(named: imageName) == nil {
                                    print("⚠️ Characteristic image not found: '\(imageName)' - using emoji fallback")
                                }
                            }
                    } else {
                        Text(characteristic.icon)
                            .font(.system(size: 60))
                    }
                    
                    // Show text only when selected or matched (for parents)
                    if isSelected || isMatched {
                        if isMatched {
                            Text("✓")
                                .font(.title)
                                .foregroundColor(.green)
                        } else {
                            Text(characteristic.type)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                
                // Show X for failed attempt (temporary, fades)
                if hasFailedAttempt && !isMatched {
                    Text("✗")
                        .font(.system(size: 40))
                        .foregroundColor(.red.opacity(0.7))
                        .transition(.opacity)
                }
            }
            .frame(width: 180, height: isSelected || isMatched ? 120 : 100)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(backgroundColor)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(strokeColor, lineWidth: 3)
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
            .animation(.spring(response: 0.3), value: isMatched)
            .animation(.easeOut(duration: 0.5), value: hasFailedAttempt)
        }
        .disabled(isMatched)
    }
}

#Preview {
    MatchingGameView(isPresented: .constant(true), gameConfig: MatchingGameConfigs.dinoFeatures)
}

// MARK: - Game Configurations

struct MatchingGameConfigs {
    // Current game: Match dinosaurs to their special features
    static let dinoFeatures = MatchingGameConfig(
        id: "dino-features",
        title: "Match the Dinosaur!",
        introAudio: "game-intro-matching",
        dinosaurs: [
            Dinosaur(id: 1, name: "T-Rex", icon: "🦖", imageName: "dino-trex", characteristicIds: [1, 2]),
            Dinosaur(id: 2, name: "Triceratops", icon: "🦏", imageName: "dino-triceratops", characteristicIds: [3, 4]),
            Dinosaur(id: 3, name: "Stegosaurus", icon: "🦎", imageName: "dino-stegosaurus", characteristicIds: [5])
        ],
        characteristics: [
            Characteristic(id: 1, type: "Teeth", icon: "🦷", imageName: "char-teeth", dinosaurId: 1),
            Characteristic(id: 2, type: "Footprints", icon: "👣", imageName: "char-footprints", dinosaurId: 1),
            Characteristic(id: 3, type: "Eggs", icon: "🥚", imageName: "char-eggs", dinosaurId: 2),
            Characteristic(id: 4, type: "Skin", icon: "🐍", imageName: "char-skin", dinosaurId: 2),
            Characteristic(id: 5, type: "Spikes", icon: "🔺", imageName: "char-spikes", dinosaurId: 3)
        ]
    )
    
    // Future games can be added here:
    // static let dinoHabitat = MatchingGameConfig(...)
    // static let dinoFood = MatchingGameConfig(...)
}
