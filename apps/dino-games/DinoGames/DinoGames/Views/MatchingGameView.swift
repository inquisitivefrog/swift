//
//  MatchingGameView.swift
//  DinoGames
//
//  Created by Timothy Stilwell on 1/23/26.
//

import SwiftUI
@preconcurrency import AVFoundation
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
    
    /// Folder for characteristic audio: "Dino-Characteristics" or "Ptero-Characteristics" (set by MatchingGameView so shared words like "crest" load from the right place).
    var characteristicSubfolder: String = "Dino-Characteristics"
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // Stop current audio with fade-out to prevent click sounds
    // Needs to be accessible from other views (e.g. CategorySelectionView onDisappear, GuessGameView onDisappear).
    func stopCurrentAudio() {
        if let player = currentPlayer, player.isPlaying {
            let targetID = ObjectIdentifier(player)
            Task { @MainActor in
                await self.fadeAndStopCurrentPlayerIfMatches(targetID: targetID, duration: 0.2)
            }
        } else {
            // Not playing or no player, stop immediately
            currentPlayer?.stop()
            currentPlayer = nil
        }
        
        // Stop TTS if speaking
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
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
        case "troodon":
            return "Dinosaurs/troodon"
        case "velociraptor":
            return "Dinosaurs/velociraptor"
        case "iguanodon":
            return "Dinosaurs/iguanodon"
        case "ankylosaurus":
            return "Dinosaurs/ankylosaurus"
        case "therizinosaurus":
            return "Dinosaurs/therizinosaurus"
        case "spinosaurus":
            return "Dinosaurs/spinosaurus"
        case "apatosaurus":
            return "Dinosaurs/apatosaurus"
        case "corythosaurus":
            return "Dinosaurs/corythosaurus"
        case "parasaurolophus":
            return "Dinosaurs/parasaurolophus"
        case "diplodocus":
            return "Dinosaurs/diplodocus"
        case "pachycephalosaurus":
            return "Dinosaurs/pachycephalosaurus"

        // Pterosaurs (Match the Pterosaur game) - name audio in Pterosaurs/ with ptero- prefix (like dino- for Dinosaurs/)
        case "pterodactyl", "pteradactyl":
            return "Pterosaurs/ptero-pteradactyl"
        case "pteranodon":
            return "Pterosaurs/ptero-pteranodon"
        case "quetzalcoatlus", "quetzacoatlus":
            return "Pterosaurs/ptero-quetzacoatlus"
        case "rhamphorhynchus":
            return "Pterosaurs/ptero-rhamphorhynchus"
        case "dimorphodon":
            return "Pterosaurs/ptero-dimorphodon"
        case "anurognathus":
            return "Pterosaurs/ptero-anurognathus"
        case "dsungaripterus":
            return "Pterosaurs/ptero-dsungaripterus"
        case "nyctosaurus":
            return "Pterosaurs/ptero-nyctosaurus"
        case "tapejara":
            return "Pterosaurs/ptero-tapejara"
        case "tupandactylus":
            return "Pterosaurs/ptero-tupandactylus"
            
        // Weigh game: "X is heavier" (one phrase file after dinosaur name)
        case "is-heavier", "is heavier":
            return "Feedback/is-heavier"
        case "they-both-weigh-about-the-same", "they both weigh about the same":
            return "Feedback/they-both-weigh-about-the-same"

        // Dinosaur characteristics (Dino-Characteristics folder)
        case "teeth":
            return "\(characteristicSubfolder)/teeth"
        case "footprints":
            return "Dino-Characteristics/footprints"
        case "frill":
            return "Dino-Characteristics/frill"
        case "horns":
            return "Dino-Characteristics/horns"
        case "spikes":
            return "Dino-Characteristics/spikes"
        case "claws", "claw":
            return "Dino-Characteristics/claws"
        case "toe-claw", "toe claw":
            return "Dino-Characteristics/toe-claw"
        case "fast":
            return "Dino-Characteristics/fast"
        case "long-claws", "long claws":
            return "Dino-Characteristics/long-claws"
        case "feathers":
            return "Dino-Characteristics/feathers"
        case "sail":
            return "Dino-Characteristics/sail"
        case "swims":
            return "Dino-Characteristics/swims"
        case "long-neck", "long neck":
            return "\(characteristicSubfolder)/long-neck"
        case "big":
            return "\(characteristicSubfolder)/big"
        case "armor":
            return "Dino-Characteristics/armor"
        case "club-tail", "club tail":
            return "Dino-Characteristics/club-tail"
        case "crest":
            return "\(characteristicSubfolder)/crest"
        case "duck-bill", "duck bill":
            return "Dino-Characteristics/duck-bill"
        case "long-crest", "long crest":
            return "\(characteristicSubfolder)/crest"
        case "thumb-spikes", "thumb spikes", "thumb-spike", "thumb spike":
            return "Dino-Characteristics/thumb-spike"
        case "smart":
            return "Dino-Characteristics/smart"
        case "big-eyes", "big eyes":
            return "Dino-Characteristics/big-eyes"
        // Pterosaur-only characteristics (Ptero-Characteristics folder)
        case "wings":
            return "Ptero-Characteristics/wings"
        case "small":
            return "Ptero-Characteristics/small"
        case "no-teeth", "no teeth":
            return "Ptero-Characteristics/no-teeth"
        case "long-tail", "long tail":
            return "Ptero-Characteristics/long-tail"
        case "big-head", "big head":
            return "Ptero-Characteristics/big-head"
            
        // Feedback
        case "great-match", "great match":
            return "Feedback/great-match"
        case "thats-right-you-guessed-it", "that's right you guessed it":
            return "Feedback/thats-right-you-guessed-it"
        case "try-again", "try again":
            return "Feedback/try-again"
        case "thats-not-right-try-again", "that's not right try again":
            return "Feedback/thats-not-right-try-again"
        case "thats-still-not-right", "that's still not right":
            return "Feedback/thats-still-not-right"
        case "thats-not-right", "that's not right":
            return "Feedback/thats-not-right"
        case "skipping-this-round", "skipping this round":
            return "Feedback/skipping-this-round"
        case "game-intro-pterosaur", "game intro pterosaur":
            return "Feedback/game-intro-pterosaur"
        case "welcome-to-dino-games", "welcome", "welcome to dino games":
            // Check Games folder first (where user placed it), fallback to Feedback if needed
            return "Games/welcome-to-dino-games"
        case "choose-a-dinosaur-game", "choose a dinosaur game", "choose game":
            return "Games/choose-a-dinosaur-game"
        case "choose-a-pterosaur-game", "choose a pterosaur game":
            return "Games/choose-a-pterosaur-game"
        case "choose-a-marine-reptile-game", "choose a marine reptile game":
            return "Games/choose-a-marine-reptile-game"
        case "sorry-game-over", "sorry game over", "game over":
            return "Feedback/sorry-game-over"
        case "you-didnt-get-them-all-right", "you didnt get them all right":
            return "Feedback/you-didnt-get-them-all-right"
        case "success-all-matches", "successallmatches", "success all matches", "you did it", "all matches found":
            return "Feedback/success-all-matches"
        case "good-job-you-got-them-all", "good job you got them all", "good job":
            return "Feedback/good-job-you-got-them-all"
        case "great-job-you-weighed-six-dinosaurs", "great job you weighed six dinosaurs":
            return "Feedback/great-job-you-weighed-six-dinosaurs"

        // Categories (Land / Sea / Air)
        // You currently placed these files in `Assets/Audio/Games/`:
        // Category cards (cover view): Dinosaurs, Marine Reptiles, Pterosaurs
        case "dinosaurs", "category-land", "land":
            return "Games/dinosaurs"
        case "marine reptiles", "marine-reptiles", "category-sea", "sea":
            return "Games/marine-reptiles"
        case "pterosaurs", "category-air", "air":
            return "Games/pterosaurs"
        
        // Game intro audio files
        case "can-you-match-each-dinosaur", "can you match each dinosaur":
            return "Games/can-you-match-each-dinosaur"
        case "can-you-match-each-pterosaur", "can you match each pterosaur":
            return "Games/can-you-match-each-pterosaur"
        case "guess-which-dinosaur-is-heavier", "guess which dinosaur is heavier":
            return "Games/guess-which-dinosaur-is-heavier"
        case "guess-which-pterosaur-is-heavier", "guess which pterosaur is heavier":
            return "Games/guess-which-pterosaur-is-heavier"
        case "can-you-name-the-dinosaur", "can you name the dinosaur", "game-intro-guess-dinosaur":
            return "Games/can-you-name-the-dinosaur"
        case "name-that-dinosaur", "name that dinosaur":
            return "Games/name-that-dinosaur"
        case "can-you-name-that-dinosaur", "can you name that dinosaur":
            return "Games/can-you-name-that-dinosaur"
        case "can-you-name-the-pterosaur", "can you name the pterosaur":
            return "Games/can-you-name-the-pterosaur"
        case "toothache":
            return "Games/toothache"
        case "can-you-return-the-tooth", "can you return the tooth":
            return "Games/can-you-return-the-tooth"
            
        default:
            // Debug output to help diagnose mapping issues
            if text.contains("success") || text.contains("matches") {
                print("   ⚠️ No match for '\(text)' → normalized: '\(normalized)'")
            }
            return nil
        }
    }
    
    /// - Parameter chainDelay: If true, use a shorter delay (e.g. when chaining name + "is heavier") so the gap between clips is smaller.
    func speak(_ text: String, chainDelay: Bool = false) {
        // Rate limiting: prevent audio overload from rapid taps
        let now = Date()
        guard now.timeIntervalSince(lastPlayTime) >= minimumPlayInterval else {
            print("⏸️ Skipping audio (too soon after last): \(text)")
            return
        }
        lastPlayTime = now
        
        // Stop any current audio with fade-out to prevent clicks
        stopCurrentAudio()
        
        // Small delay to let stop complete and prevent HALC overload; shorter when chaining clips
        let delay: TimeInterval = chainDelay ? 0.03 : 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
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
                    self.playAudioFile(url: url, fallbackSpeakText: text)
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
    
    func playAudioFile(url: URL, fallbackSpeakText: String? = nil) {
        do {
            // Stop any current player immediately (volume to 0 first to reduce click) before starting next
            if let old = currentPlayer {
                old.volume = 0
                old.stop()
                currentPlayer = nil
            }
            
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0 // Start at 0 to avoid click at start
            player.delegate = self // Set delegate to detect when playback finishes
            player.numberOfLoops = 0
            player.prepareToPlay()
            player.play()
            currentPlayer = player
            isPlaying = true
            
            // If file has no duration (empty/corrupt), fall back to TTS so we don't get stuck
            if player.duration <= 0 {
                isPlaying = false
                onAudioFinished?()
                let fallback = fallbackSpeakText ?? url.deletingPathExtension().lastPathComponent
                startSpeaking(fallback)
                return
            }
            
            let fadeInDuration: TimeInterval = 0.12
            let fadeOutDuration: TimeInterval = 0.2
            let targetID = ObjectIdentifier(player)
            let duration = player.duration
            Task { @MainActor in
                // Fade in to prevent click at start
                await self.fadeInPlayerIfMatches(targetID: targetID, duration: fadeInDuration)
                // Fade out in the last stretch to prevent click at end
                if duration > fadeInDuration + fadeOutDuration, let p = self.currentPlayer, ObjectIdentifier(p) == targetID, p.isPlaying {
                    let waitTime = max(0, duration - fadeOutDuration - fadeInDuration)
                    try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                    await self.fadeCurrentPlayerIfMatches(targetID: targetID, duration: fadeOutDuration)
                }
            }
            
            print("🔊 Playing at volume: \(player.volume)")
        } catch {
            print("❌ Error playing audio file: \(error)")
            isPlaying = false
            // Fallback to TTS with original text (e.g. "Pteranodon") not filename
            let fallback = fallbackSpeakText ?? url.deletingPathExtension().lastPathComponent
            startSpeaking(fallback)
        }
    }
    
    // Fade in the current player (only if it still matches) to prevent click at start.
    private func fadeInPlayerIfMatches(targetID: ObjectIdentifier, duration: TimeInterval) async {
        let fadeSteps = 15
        let fadeInterval = duration / Double(fadeSteps)
        
        for step in 1...fadeSteps {
            guard let player = currentPlayer,
                  ObjectIdentifier(player) == targetID,
                  player.isPlaying else {
                return
            }
            
            let newVolume = Double(step) / Double(fadeSteps)
            player.volume = min(1.0, Float(newVolume))
            try? await Task.sleep(nanoseconds: UInt64(fadeInterval * 1_000_000_000))
        }
        
        if let player = currentPlayer, ObjectIdentifier(player) == targetID {
            player.volume = 1.0
        }
    }
    
    // Fade out the current player (only if it still matches) to prevent clicks.
    private func fadeCurrentPlayerIfMatches(targetID: ObjectIdentifier, duration: TimeInterval) async {
        let fadeSteps = 25
        let fadeInterval = duration / Double(fadeSteps)
        
        for step in 1...fadeSteps {
            guard let player = currentPlayer,
                  ObjectIdentifier(player) == targetID,
                  player.isPlaying else {
                return
            }
            
            let newVolume = 1.0 - (Double(step) / Double(fadeSteps))
            player.volume = max(0.0, Float(newVolume))
            try? await Task.sleep(nanoseconds: UInt64(fadeInterval * 1_000_000_000))
        }
        
        if let player = currentPlayer, ObjectIdentifier(player) == targetID {
            player.volume = 0
        }
    }
    
    // Fade out and stop the current player (only if it still matches).
    private func fadeAndStopCurrentPlayerIfMatches(targetID: ObjectIdentifier, duration: TimeInterval) async {
        let fadeSteps = 20
        let fadeInterval = duration / Double(fadeSteps)
        
        for step in 1...fadeSteps {
            guard let player = currentPlayer,
                  ObjectIdentifier(player) == targetID,
                  player.isPlaying else {
                return
            }
            
            let newVolume = 1.0 - (Double(step) / Double(fadeSteps))
            player.volume = max(0.0, Float(newVolume))
            try? await Task.sleep(nanoseconds: UInt64(fadeInterval * 1_000_000_000))
        }
        
        if let player = currentPlayer, ObjectIdentifier(player) == targetID {
            player.volume = 0
            player.stop()
            currentPlayer = nil
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
    @State private var failedAttemptCount = 0 // Track total failed attempts (max 2)
    @State private var firstWrongDinosaurId: Int? // First wrong guess: which creature (for second-guess audio: same vs different)
    @State private var isGameOver = false // Track if game is over due to failures
    
    // Convenience accessors
    private var dinosaurs: [Dinosaur] { gameConfig.selectedDinosaurs }
    private var characteristics: [Characteristic] { gameConfig.selectedCharacteristics }
    
    // Reset game state when view appears (allows replay)
    private func resetGameState() {
        matchedPairs.removeAll()
        failedAttempts.removeAll()
        selectedDinosaur = nil
        selectedCharacteristic = nil
        showFeedback = false
        feedbackMessage = ""
        failedAttemptCount = 0
        firstWrongDinosaurId = nil
        isGameOver = false
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title
                Text(gameConfig.title)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Main game area (centered)
                HStack(spacing: 20) {
                    // Left: Dinosaurs or Pterosaurs (dynamic by game)
                    VStack(spacing: 15) {
                        Text(gameConfig.id == "match-the-pterosaur" ? "Pterosaurs" : "Dinosaurs")
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
            if !isGameOver {
                Text("Matches: \(matchedPairs.count) / \(dinosaurs.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Game Over - Too many wrong guesses")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            }
            .padding()
            .onAppear {
                // Reset game state for fresh play (allows replay)
                resetGameState()
                // Use correct characteristic audio folder for this game type
                speechManager.characteristicSubfolder = gameConfig.id == "match-the-pterosaur" ? "Ptero-Characteristics" : "Dino-Characteristics"
                // Set up audio finished callback
                speechManager.onAudioFinished = {
                    isAudioPlaying = false
                }
                // Intro not played here: dinosaur matching uses can-you-match-each-dinosaur on transition; pterosaur uses can-you-match-each-pterosaur on transition.
                
                // Debug: Print selected dinosaurs and characteristics
                print("🎮 Game started with \(dinosaurs.count) dinosaurs: \(dinosaurs.map { $0.name }.joined(separator: ", "))")
                print("🎮 Game has \(characteristics.count) characteristics: \(characteristics.map { $0.type }.joined(separator: ", "))")
            }
            .allowsHitTesting(!isAudioPlaying) // Disable interaction while audio plays
            .opacity(isAudioPlaying ? 0.7 : 1.0) // Visual indicator that interaction is disabled
            .navigationBarTitleDisplayMode(.inline)
        } // End NavigationView
    } // End body
    
    private func handleDinosaurTap(_ dinosaur: Dinosaur) {
        // Don't allow interaction while audio is playing or game is over
        guard !isAudioPlaying && !isGameOver else { return }
        
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
        // Don't allow interaction while audio is playing or game is over
        guard !isAudioPlaying && !isGameOver else { return }
        
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
            feedbackMessage = "Great Match!"
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
                // Game complete! Play success audio and return to home (no text message)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.isAudioPlaying = true
                    self.speechManager.speak("good-job-you-got-them-all")
                    
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
            // Wrong match - track failed attempt
            let failedPair = MatchedPair(dinosaurId: dinosaur.id, characteristicId: characteristic.id)
            failedAttempts.insert(failedPair)
            failedAttemptCount += 1
            
            isAudioPlaying = true
            
            if failedAttemptCount == 1 {
                // First wrong guess: text "Try again!" + audio "That's not right, try again"
                feedbackMessage = "Try again!"
                speechManager.speak("thats-not-right-try-again")
                firstWrongDinosaurId = dinosaur.id
                // Reset selection after delay so they can try again
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    selectedDinosaur = nil
                    selectedCharacteristic = nil
                    showFeedback = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        failedAttempts.remove(failedPair)
                    }
                }
            } else {
                // Second wrong guess: show matching text + audio, then game over
                let sameCreature = dinosaur.id == firstWrongDinosaurId
                feedbackMessage = sameCreature ? "That's still not right." : "That's not right."
                let secondWrongAudio = sameCreature ? "thats-still-not-right" : "thats-not-right"
                speechManager.speak(secondWrongAudio)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isGameOver = true
                    self.feedbackMessage = "Game Over"
                    self.isAudioPlaying = true
                    self.speechManager.speak("you-didnt-get-them-all-right")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Game Configuration

struct MatchingGameConfig {
    let id: String // Unique identifier (e.g., "match-the-dinosaur", "match-the-pterosaur")
    let title: String // Game title shown to player
    let introAudio: String // Audio file name for game intro (e.g., "game-intro-matching")
    let selectedDinosaurs: [Dinosaur] // 3 randomly selected dinosaurs for this game
    let selectedCharacteristics: [Characteristic] // 5 characteristics (from selected + padding)
    
    // Helper to get all characteristics for a specific dinosaur
    func characteristics(for dinosaurId: Int) -> [Characteristic] {
        selectedCharacteristics.filter { $0.dinosaurId == dinosaurId }
    }
    
    // Create a random game configuration from the full pool
    static func createRandom(
        from allDinosaurs: [Dinosaur],
        allCharacteristics: [Characteristic],
        id: String = "match-the-dinosaur",
        title: String = "Match the Dinosaur!",
        introAudio: String = "game-intro-matching"
    ) -> MatchingGameConfig {
        // Randomly select 3 unique dinosaurs
        let shuffled = allDinosaurs.shuffled()
        let selected = Array(shuffled.prefix(3))
        
        // Get characteristics for selected dinosaurs, then deduplicate by type so we don't show duplicate "Wings", "Crest", etc.
        var gameCharacteristics: [Characteristic] = []
        var seenTypes: Set<String> = []
        for dino in selected {
            let dinoChars = allCharacteristics.filter { $0.dinosaurId == dino.id }
            for c in dinoChars.shuffled() {
                if !seenTypes.contains(c.type) {
                    seenTypes.insert(c.type)
                    gameCharacteristics.append(c)
                }
            }
        }
        
        // If less than 5 unique types, pad with characteristics from the full pool (still no duplicates by type)
        if gameCharacteristics.count < 5 {
            let allCharsShuffled = allCharacteristics.shuffled()
            for c in allCharsShuffled {
                guard gameCharacteristics.count < 5 else { break }
                if !seenTypes.contains(c.type) {
                    seenTypes.insert(c.type)
                    gameCharacteristics.append(c)
                }
            }
        }
        
        // Take exactly 5 (we may have more than 5 from the first loop)
        gameCharacteristics = Array(gameCharacteristics.prefix(5))
        gameCharacteristics.shuffle()
        
        return MatchingGameConfig(
            id: id,
            title: title,
            introAudio: introAudio,
            selectedDinosaurs: selected,
            selectedCharacteristics: gameCharacteristics
        )
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
    // Full pool of available dinosaurs (can be expanded)
    static let allDinosaurs: [Dinosaur] = [
        Dinosaur(id: 1, name: "T-Rex", icon: "🦖", imageName: "dino-trex", characteristicIds: [1, 2]),
        Dinosaur(id: 2, name: "Triceratops", icon: "🦏", imageName: "dino-triceratops", characteristicIds: [3, 4]),
        Dinosaur(id: 3, name: "Stegosaurus", icon: "🦎", imageName: "dino-stegosaurus", characteristicIds: [5]),
        Dinosaur(id: 4, name: "Velociraptor", icon: "🦖", imageName: "dino-velociraptor", characteristicIds: [6, 7, 23]),
        Dinosaur(id: 5, name: "Therizinosaurus", icon: "🦕", imageName: "dino-therizinosaurus", characteristicIds: [8, 9]),
        Dinosaur(id: 6, name: "Spinosaurus", icon: "🦖", imageName: "dino-spinosaurus", characteristicIds: [10, 11]),
        Dinosaur(id: 7, name: "Apatosaurus", icon: "🦕", imageName: "dino-apatosaurus", characteristicIds: [12, 13]),
        Dinosaur(id: 8, name: "Ankylosaurus", icon: "🛡️", imageName: "dino-ankylosaurus", characteristicIds: [14, 15]),
        Dinosaur(id: 9, name: "Corythosaurus", icon: "🦆", imageName: "dino-corythosaurus", characteristicIds: [16, 17]),
        Dinosaur(id: 10, name: "Parasaurolophus", icon: "🦆", imageName: "dino-parasaurolophus", characteristicIds: [18, 19]),
        Dinosaur(id: 11, name: "Iguanodon", icon: "🦎", imageName: "dino-iguanodon", characteristicIds: [20]),
        Dinosaur(id: 12, name: "Troodon", icon: "🦉", imageName: "dino-troodon", characteristicIds: [21, 22]),
        // Add more dinosaurs here as they become available:
        // Dinosaur(id: 13, name: "Brachiosaurus", icon: "🦕", imageName: "dino-brachiosaurus", characteristicIds: [23, 24]),
        // etc.
    ]
    
    // Full pool of available characteristics (can be expanded)
    // Image sets: dino-char-<characteristic> (e.g. dino-char-teeth, dino-char-crest)
    static let allCharacteristics: [Characteristic] = [
        // T-Rex characteristics
        Characteristic(id: 1, type: "Teeth", icon: "🦷", imageName: "dino-char-teeth", dinosaurId: 1),
        Characteristic(id: 2, type: "Footprints", icon: "👣", imageName: "dino-char-footprints", dinosaurId: 1),
        // Triceratops characteristics
        Characteristic(id: 3, type: "Frill", icon: "🦎", imageName: "dino-char-frill", dinosaurId: 2),
        Characteristic(id: 4, type: "Horns", icon: "🦏", imageName: "dino-char-horns", dinosaurId: 2),
        // Stegosaurus characteristics
        Characteristic(id: 5, type: "Spikes", icon: "🔺", imageName: "dino-char-spikes", dinosaurId: 3),
        // Velociraptor characteristics
        Characteristic(id: 6, type: "Claws", icon: "🦅", imageName: "dino-char-claws", dinosaurId: 4),
        Characteristic(id: 7, type: "Fast", icon: "💨", imageName: "dino-char-fast", dinosaurId: 4),
        Characteristic(id: 23, type: "Toe Claw", icon: "🦅", imageName: "dino-char-toe-claw", dinosaurId: 4),
        // Therizinosaurus characteristics
        Characteristic(id: 8, type: "Long Claws", icon: "✂️", imageName: "dino-char-long-claws", dinosaurId: 5),
        Characteristic(id: 9, type: "Feathers", icon: "🪶", imageName: "dino-char-feathers", dinosaurId: 5),
        // Spinosaurus characteristics
        Characteristic(id: 10, type: "Sail", icon: "⛵", imageName: "dino-char-sail", dinosaurId: 6),
        Characteristic(id: 11, type: "Swims", icon: "🏊", imageName: "dino-char-swims", dinosaurId: 6),
        // Apatosaurus characteristics
        Characteristic(id: 12, type: "Long Neck", icon: "🦒", imageName: "dino-char-long-neck", dinosaurId: 7),
        Characteristic(id: 13, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 7),
        // Ankylosaurus characteristics
        Characteristic(id: 14, type: "Armor", icon: "🛡️", imageName: "dino-char-armor", dinosaurId: 8),
        Characteristic(id: 15, type: "Club Tail", icon: "🔨", imageName: "dino-char-club-tail", dinosaurId: 8),
        // Corythosaurus characteristics
        Characteristic(id: 16, type: "Crest", icon: "🪖", imageName: "dino-char-crest", dinosaurId: 9),
        Characteristic(id: 17, type: "Duck Bill", icon: "🦆", imageName: "dino-char-duck-bill", dinosaurId: 9),
        // Parasaurolophus characteristics
        Characteristic(id: 18, type: "Crest", icon: "📯", imageName: "dino-char-crest", dinosaurId: 10),
        Characteristic(id: 19, type: "Duck Bill", icon: "🦆", imageName: "dino-char-duck-bill", dinosaurId: 10),
        // Iguanodon characteristics
        Characteristic(id: 20, type: "Thumb Spike", icon: "👍", imageName: "dino-char-thumb-spike", dinosaurId: 11),
        // Troodon characteristics
        Characteristic(id: 21, type: "Smart", icon: "🧠", imageName: "dino-char-smart", dinosaurId: 12),
        Characteristic(id: 22, type: "Big Eyes", icon: "👀", imageName: "dino-char-big-eyes", dinosaurId: 12),
        // Add more characteristics here as dinosaurs are added:
        // Brachiosaurus characteristics
        // Characteristic(id: 23, type: "Long Neck", icon: "🦒", imageName: nil, dinosaurId: 13),
        // Characteristic(id: 24, type: "Big Feet", icon: "🐘", imageName: nil, dinosaurId: 13),
        // etc.
    ]
    
    // Create a random game configuration (3 dinosaurs, 5 characteristics)
    // Image: game-match-the-dinosaur.imageset
    static var dinoFeatures: MatchingGameConfig {
        MatchingGameConfig.createRandom(
            from: allDinosaurs,
            allCharacteristics: allCharacteristics,
            id: "match-the-dinosaur",
            title: "Match the Dinosaur!",
            introAudio: "game-intro-matching"
        )
    }
    
    // Full pool of available pterosaurs (flying reptiles) — 10 total
    static let allPterosaurs: [Dinosaur] = [
        Dinosaur(id: 101, name: "Pterodactyl", icon: "🦅", imageName: "ptero-pteradactyl", characteristicIds: [101, 102, 103]),
        Dinosaur(id: 102, name: "Pteranodon", icon: "🦅", imageName: "ptero-pteranodon", characteristicIds: [104, 105, 106]),
        Dinosaur(id: 103, name: "Quetzalcoatlus", icon: "🦅", imageName: "ptero-quetzacoatlus", characteristicIds: [107, 108, 109]),
        Dinosaur(id: 104, name: "Rhamphorhynchus", icon: "🦅", imageName: "ptero-rhamphorhynchus", characteristicIds: [110, 111, 112]),
        Dinosaur(id: 105, name: "Dimorphodon", icon: "🦅", imageName: "ptero-dimorphodon", characteristicIds: [113, 114, 115]),
        Dinosaur(id: 106, name: "Anurognathus", icon: "🦅", imageName: "ptero-anurognathus", characteristicIds: [116, 117, 118]),
        Dinosaur(id: 107, name: "Dsungaripterus", icon: "🦅", imageName: "ptero-dsungaripterus", characteristicIds: [119, 120, 121]),
        Dinosaur(id: 108, name: "Nyctosaurus", icon: "🦅", imageName: "ptero-nyctosaurus", characteristicIds: [122, 123, 124]),
        Dinosaur(id: 109, name: "Tapejara", icon: "🦅", imageName: "ptero-tapejara", characteristicIds: [125, 126, 127]),
        Dinosaur(id: 110, name: "Tupandactylus", icon: "🦅", imageName: "ptero-tupandactylus", characteristicIds: [128, 129, 130]),
    ]
    
    // Full pool of available pterosaur characteristics
    // Image sets: ptero-char-<characteristic> (e.g. ptero-char-wings, ptero-char-crest)
    static let allPterosaurCharacteristics: [Characteristic] = [
        // Pterodactyl characteristics
        Characteristic(id: 101, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 101),
        Characteristic(id: 102, type: "Small", icon: "🐦", imageName: "ptero-char-small", dinosaurId: 101),
        Characteristic(id: 103, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 101),
        // Pteranodon characteristics
        Characteristic(id: 104, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 102),
        Characteristic(id: 105, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 102),
        Characteristic(id: 106, type: "No Teeth", icon: "🦷", imageName: "ptero-char-no-teeth", dinosaurId: 102),
        // Quetzalcoatlus characteristics
        Characteristic(id: 107, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 103),
        Characteristic(id: 108, type: "Big", icon: "🐘", imageName: "ptero-char-big", dinosaurId: 103),
        Characteristic(id: 109, type: "Long Neck", icon: "🦒", imageName: "ptero-char-long-neck", dinosaurId: 103),
        // Rhamphorhynchus characteristics
        Characteristic(id: 110, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 104),
        Characteristic(id: 111, type: "Long Tail", icon: "🦎", imageName: "ptero-char-long-tail", dinosaurId: 104),
        Characteristic(id: 112, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 104),
        // Dimorphodon characteristics
        Characteristic(id: 113, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 105),
        Characteristic(id: 114, type: "Big Head", icon: "🧠", imageName: "ptero-char-big-head", dinosaurId: 105),
        Characteristic(id: 115, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 105),
        // Anurognathus characteristics
        Characteristic(id: 116, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 106),
        Characteristic(id: 117, type: "Small", icon: "🐦", imageName: "ptero-char-small", dinosaurId: 106),
        Characteristic(id: 118, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 106),
        // Dsungaripterus characteristics
        Characteristic(id: 119, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 107),
        Characteristic(id: 120, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 107),
        Characteristic(id: 121, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 107),
        // Nyctosaurus characteristics
        Characteristic(id: 122, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 108),
        Characteristic(id: 123, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 108),
        Characteristic(id: 124, type: "No Teeth", icon: "🦷", imageName: "ptero-char-no-teeth", dinosaurId: 108),
        // Tapejara characteristics
        Characteristic(id: 125, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 109),
        Characteristic(id: 126, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 109),
        Characteristic(id: 127, type: "Teeth", icon: "🦷", imageName: "ptero-char-teeth", dinosaurId: 109),
        // Tupandactylus characteristics
        Characteristic(id: 128, type: "Wings", icon: "🪽", imageName: "ptero-char-wings", dinosaurId: 110),
        Characteristic(id: 129, type: "Crest", icon: "🪖", imageName: "ptero-char-crest", dinosaurId: 110),
        Characteristic(id: 130, type: "Big Head", icon: "🧠", imageName: "ptero-char-big-head", dinosaurId: 110),
    ]
    
    // Create a random pterosaur game configuration (3 pterosaurs, 5 characteristics)
    // Image: add game-match-the-pterosaur.imageset with match-the-pterosaur-1024.png
    static var pterosaurFeatures: MatchingGameConfig {
        MatchingGameConfig.createRandom(
            from: allPterosaurs,
            allCharacteristics: allPterosaurCharacteristics,
            id: "match-the-pterosaur",
            title: "Match the Pterosaur!",
            introAudio: "game-intro-pterosaur"
        )
    }
    
    // Future games can be added here:
    // static let dinoHabitat = MatchingGameConfig(...)
    // static let dinoFood = MatchingGameConfig(...)
}
