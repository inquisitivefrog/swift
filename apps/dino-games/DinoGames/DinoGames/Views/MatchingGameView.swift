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
    private var secondaryPlayer: AVAudioPlayer? // For simultaneous play (e.g. crowd-cheering + winner name)
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
    
    /// Returns bundle URL for a given audio key (e.g. "crowd-cheering", "Allosaurus") if found; nil otherwise.
    func urlForAudio(key: String) -> URL? {
        guard let path = audioFilePath(for: key) else { return nil }
        return resolveURL(forPath: path)
    }

    /// Resolve path (e.g. "Feedback/crowd-cheering") to first found bundle URL (.m4a or .mp3).
    private func resolveURL(forPath audioPath: String) -> URL? {
        let fileName = (audioPath as NSString).lastPathComponent
        let paths = [
            "DinoGames/Assets/Audio/\(audioPath)",
            "Assets/Audio/\(audioPath)",
            "assets/Audio/\(audioPath)",
            "Audio/\(audioPath)",
            audioPath,
            fileName
        ]
        for path in paths {
            for ext in ["m4a", "mp3"] {
                if let url = Bundle.main.url(forResource: path, withExtension: ext) { return url }
            }
        }
        // Try subdirectory lookup (e.g. Feedback/congratulations → resource "congratulations" in "Audio/Feedback")
        if audioPath.contains("/") {
            let subdir = "Audio/\((audioPath as NSString).deletingLastPathComponent)"
            for ext in ["m4a", "mp3"] {
                if let url = Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: subdir) { return url }
            }
        }
        if let resourcePath = Bundle.main.resourcePath, let enumerator = FileManager.default.enumerator(atPath: resourcePath) {
            while let file = enumerator.nextObject() as? String {
                let lower = file.lowercased()
                if lower.hasSuffix("\(fileName).m4a") || lower.hasSuffix("\(fileName).mp3") {
                    return URL(fileURLWithPath: (resourcePath as NSString).appendingPathComponent(file))
                }
            }
        }
        return nil
    }

    /// Play two audio files simultaneously; calls whenLongestFinished after the longer one ends (plus short buffer).
    func playTogether(url1: URL, url2: URL, whenLongestFinished: @escaping () -> Void) {
        stopCurrentAudio()
        secondaryPlayer?.stop()
        secondaryPlayer = nil
        do {
            let p1 = try AVAudioPlayer(contentsOf: url1)
            let p2 = try AVAudioPlayer(contentsOf: url2)
            p1.prepareToPlay()
            p2.prepareToPlay()
            currentPlayer = p1
            secondaryPlayer = p2
            isPlaying = true
            p1.play()
            p2.play()
            let d1 = p1.duration
            let d2 = p2.duration
            let delay = max(d1, d2) + 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.currentPlayer = nil
                self?.secondaryPlayer = nil
                self?.isPlaying = false
                whenLongestFinished()
            }
        } catch {
            currentPlayer = nil
            secondaryPlayer = nil
            if let u2 = try? AVAudioPlayer(contentsOf: url2) {
                currentPlayer = u2
                u2.prepareToPlay()
                u2.play()
                u2.delegate = self
                isPlaying = true
                onAudioFinished = { [weak self] in
                    self?.onAudioFinished = nil
                    whenLongestFinished()
                }
            } else {
                whenLongestFinished()
            }
        }
    }

    // Stop current audio with fade-out to prevent click sounds
    // Needs to be accessible from other views (e.g. CategorySelectionView onDisappear, GuessGameView onDisappear).
    func stopCurrentAudio() {
        secondaryPlayer?.stop()
        secondaryPlayer = nil
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
        
        // Dino Lunch: tray contents audio (Trays/contents-{slug})
        if normalized.hasPrefix("contents-") {
            return "Trays/\(normalized)"
        }
        // Dino Lunch: teen dinosaur intro audio (Teens/teen-{diet}-{slug}), e.g. Teens/teen-herbivore-triceratops.m4a
        if normalized.hasPrefix("teen-") {
            return "Teens/\(normalized)"
        }
        // Find Mama: clue audio (Clues/clue-{dinosaur}-{hint}), e.g. Clues/clue-trex-egg-size.m4a
        if normalized.hasPrefix("clue-") {
            return "Clues/\(normalized)"
        }
        
        // Map common phrases to file names (matching your recorded files)
        switch normalized {
        // Dinosaurs - file names use dino- prefix; T-Rex uses "trex" (no hyphen) to match image assets
        case "t-rex", "t rex", "trex", "tyrannosaurus":
            return "Dinosaurs/dino-trex"
        case "triceratops":
            return "Dinosaurs/dino-triceratops"
        case "stegosaurus":
            return "Dinosaurs/dino-stegosaurus"
        case "troodon":
            return "Dinosaurs/dino-troodon"
        case "velociraptor":
            return "Dinosaurs/dino-velociraptor"
        case "iguanodon":
            return "Dinosaurs/dino-iguanodon"
        case "ankylosaurus":
            return "Dinosaurs/dino-ankylosaurus"
        case "therizinosaurus":
            return "Dinosaurs/dino-therizinosaurus"
        case "spinosaurus":
            return "Dinosaurs/dino-spinosaurus"
        case "apatosaurus":
            return "Dinosaurs/dino-apatosaurus"
        case "allosaurus":
            return "Dinosaurs/dino-allosaurus"
        case "brontosaurus":
            return "Dinosaurs/dino-brontosaurus"
        case "corythosaurus":
            return "Dinosaurs/dino-corythosaurus"
        case "parasaurolophus":
            return "Dinosaurs/dino-parasaurolophus"
        case "edmontosaurus":
            return "Dinosaurs/dino-edmontosaurus"
        case "diplodocus":
            return "Dinosaurs/dino-diplodocus"
        case "compsognathus":
            return "Dinosaurs/dino-compsognathus"
        case "gallimimus":
            return "Dinosaurs/dino-gallimimus"
        case "albertosaurus":
            return "Dinosaurs/dino-albertosaurus"
        case "pachycephalosaurus":
            return "Dinosaurs/dino-pachycephalosaurus"
        case "baryonyx":
            return "Dinosaurs/dino-baryonyx"

        // Pterosaurs (Match the Pterosaur game) - name audio in Pterosaurs/ with ptero- prefix (like dino- for Dinosaurs/)
        case "pterodactylus", "pterodactyl":
            return "Pterosaurs/ptero-pteradactylus"
        case "pteranodon":
            return "Pterosaurs/ptero-pteranodon"
        case "quetzalcoatlus", "quetzacoatlus":
            return "Pterosaurs/ptero-quetzacoatlus"
        case "rhamphorhynchus":
            return "Pterosaurs/ptero-rhamphorhynchus"
        case "dimorphodon":
            return "Pterosaurs/ptero-dimorphodon"
        case "anurognathus":
            return "Pterosaurs/ptero-anuragnathus"  // filename on disk: ptero-anuragnathus.m4a
        case "dsungaripterus":
            return "Pterosaurs/ptero-dsungarpiterus"  // filename on disk: ptero-dsungarpiterus.m4a
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
        case "toe-claw", "toe claw", "toe-claws", "toe claws":
            return "Dino-Characteristics/toe-claws"
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
            return "Ptero-Characteristics/ptero-char-small"  // ptero-char-small.m4a (avoids matching Find Mama clue-egg-size-small.m4a)
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
        case "game-intro-pterosaur", "game intro pterosaur":
            return "Feedback/game-intro-pterosaur"
        case "welcome-to-dino-games", "welcome", "welcome to dino games":
            // Check Games folder first (where user placed it), fallback to Feedback if needed
            return "Games/welcome-to-dino-games"
        // Cover page sequence (play in order; enable category image after each)
        case "cover-choose-a-game-type", "cover choose a game type":
            return "Cover/cover-choose-a-game-type"
        case "cover-welcome-to-dino-games", "cover welcome to dino games":
            return "Cover/cover-welcome-to-dino-games"
        case "cover-dinosaurs-on-land", "cover dinosaurs on land":
            return "Cover/cover-dinosaurs-on-land"
        case "cover-pterosaurs-in-the-sky", "cover pterosaurs in the sky":
            return "Cover/cover-pterosaurs-in-the-sky"
        case "cover-and-marine-reptiles-in-the-sea", "cover and marine reptiles in the sea":
            return "Cover/cover-and-marine-reptiles-in-the-sea"
        case "cover-choose-a-period", "cover choose a period":
            return "Cover/cover-choose-a-period"
        case "cover-jurassic", "cover jurassic":
            return "Cover/cover-jurassic"
        case "cover-cretaceous", "cover cretaceous":
            return "Cover/cover-cretaceous"
        case "choose-a-dinosaur-game", "choose a dinosaur game", "choose game":
            return "Cover/cover-choose-a-dinosaur-game"
        case "choose-a-pterosaur-game", "choose a pterosaur game":
            return "Cover/cover-choose-a-pterosaur-game"
        case "choose-a-marine-reptile-game", "choose a marine reptile game":
            return "Cover/cover-choose-a-marine-reptile-game"
        case "you-didnt-get-them-all-right", "you didnt get them all right":
            return "Feedback/you-didnt-get-them-all-right"
        case "good-job-you-got-them-all", "good job you got them all", "good job":
            return "Feedback/good-job-you-got-them-all"
        case "starting-whistle", "starting whistle", "starting-gun", "starting gun":
            return "Feedback/starting-whistle"
        case "crowd-cheering", "we-have-a-winner", "we have a winner":
            return "Feedback/crowd-cheering"
        case "you-did-it", "you did it":
            return "Feedback/you-did-it"
        case "not-that-one", "not that one":
            return "Feedback/not-that-one"
        case "wow-that-was-tricky", "wow that was tricky":
            return "Feedback/wow-that-was-tricky"
        case "you-have-to-select-a-dinosaur-first", "you have to select a dinosaur first", "pick-a-dinosaur-first", "pick a dinosaur first":
            return "Feedback/pick-a-dinosaur-first"
        case "pick-a-pterosaur-first", "pick a pterosaur first":
            return "Feedback/pick-a-pterosaur-first"
        case "you-cannot-use-me-twice", "you cannot use me twice", "already matched", "pick-another-one", "pick another one":
            return "Feedback/pick-another-one"
        // Balance the Dinosaurs handrails
        case "pick-someone-heavier", "pick someone heavier", "game-balance-pick-someone-heavier":
            return "Feedback/game-balance-pick-someone-heavier"
        case "thats-good-keep-going", "that's good keep going":
            return "Feedback/thats-good-keep-going"
        case "getting-closer", "getting closer":
            return "Feedback/getting-closer"
        case "good-job-you-did-it", "good job you did it":
            return "Feedback/good-job-you-did-it"
        case "congratulations", "congratulations!":
            return "Feedback/congratulations"

        // Categories (Land / Sea / Air)
        // You currently placed these files in `Assets/Audio/Games/`:
        // Category cards (cover view): Dinosaurs, Marine Reptiles, Pterosaurs
        case "dinosaurs", "category-land", "land":
            return "Cover/cover-dinosaurs"
        case "marine reptiles", "marine-reptiles", "category-sea", "sea":
            return "Cover/cover-marine-reptiles"
        case "pterosaurs", "category-air", "air":
            return "Cover/cover-pterosaurs"
        
        // Game intro audio files
        case "can-you-match-each-dinosaur", "can you match each dinosaur":
            return "Games/game-can-you-match-each-dinosaur"
        case "can-you-match-each-pterosaur", "can you match each pterosaur":
            return "Games/game-can-you-match-each-pterosaur"
        case "guess-which-dinosaur-is-heavier", "guess which dinosaur is heavier":
            return "Games/game-guess-which-dinosaur-is-heavier"
        case "guess-which-pterosaur-is-heavier", "guess which pterosaur is heavier":
            return "Games/game-guess-which-pterosaur-is-heavier"
        case "can-you-name-the-dinosaur", "can you name the dinosaur", "game-intro-guess-dinosaur":
            return "Games/game-can-you-name-the-dinosaur"
        case "name-that-dinosaur", "name that dinosaur":
            return "Games/name-that-dinosaur"
        case "can-you-name-that-dinosaur", "can you name that dinosaur":
            return "Games/game-can-you-name-that-dinosaur"
        case "can-you-name-the-pterosaur", "can you name the pterosaur":
            return "Games/game-can-you-name-the-pterosaur"
        case "toothache":
            return "Games/toothache"
        case "can-you-return-the-tooth", "can you return the tooth":
            return "Games/game-can-you-return-the-tooth"
        case "racing-dinosaurs", "racing dinosaurs":
            return "Games/game-racing-dinosaurs"
        case "racing-pterosaurs", "racing pterosaurs", "game-racing-pterosaurs", "game racing pterosaurs":
            return "Games/game-racing-pterosaurs"
        case "game-can-you-balance-the-dinosaurs", "game can you balance the dinosaurs":
            return "Games/game-can-you-balance-the-dinosaurs"
        case "game-balance-choose-a-heavy-dinosaur", "choose a heavy dinosaur":
            return "Games/game-balance-choose-a-heavy-dinosaur"
        case "game-balance-this-game-will-end-quick", "this game will end quick":
            return "Feedback/game-balance-this-game-will-end-quick"
        case "game-balance-see-i-told-you", "game-balance-see-I-told-you", "see I told you", "see i told you":
            return "Feedback/game-balance-see-I-told-you"
        case "game-balance-good-job-keep-going", "good job keep going":
            return "Feedback/game-balance-good-job-keep-going"
        case "game-balance-almost-there", "almost there":
            return "Feedback/game-balance-almost-there"
        case "game-intro-balance", "game balance the dinosaurs", "game-balance-the-dinosaurs":
            return "Games/game-balance-the-dinosaurs"
        case "game-racer-choose-your-first-dinosaur-to-race", "choose your first dinosaur to race":
            return "Games/game-racer-choose-your-first-dinosaur-to-race"
        case "game-racer-choose-your-second-dinosaur-to-race", "choose your second dinosaur to race":
            return "Games/game-racer-choose-your-second-dinosaur-to-race"
        case "game-racer-choose-your-first-pterosaur-to-race", "choose your first pterosaur to race":
            return "Games/game-racer-choose-your-first-pterosaur-to-race"
        case "game-racer-choose-your-second-pterosaur-to-race", "choose your second pterosaur to race":
            return "Games/game-racer-choose-your-second-pterosaur-to-race"
        case "racing-the-winner-is", "the winner is":
            return "Games/racing-the-winner-is"
        case "game-matrix-materials", "matrix materials":
            return "Games/game-matrix-materials"
        case "game-matrix-which-one", "which one is it", "tap the one":
            return "Games/game-matrix-which-one"
        case "game-find-mama", "find mama", "find-mama", "game-mama-match", "mama match":
            return "Games/game-find-mama"
        case "game-find-mama-return-the-egg", "find-mama-return-the-egg", "return-the-egg":
            return "Games/game-find-mama-return-the-egg"
        case "game-find-mama-help-the-paleontologist", "help-the-paleontologist", "find-mama-help-the-paleontologist":
            return "Games/game-find-mama-help-the-paleontologist"
        case "game-dino-lunch", "dino lunch":
            return "Games/game-dino-lunch"
        case "game-give-this-nutritious-lunch", "give this nutritious lunch":
            return "Games/game-give-this-nutritious-lunch"
        case "game-dino-footprints", "dino footprints":
            return "Games/game-dino-footprints"
        case "game-dino-footprints-identify-the-footprint", "identify the footprint":
            return "Games/game-dino-footprints-identify-the-footprint"
        case "game-hint", "game dino footprints hint", "dino footprints hint":
            return "Games/game-hint"
        case "footprint-therapod", "therapod":
            return "Footprints/therapod"
        case "footprint-sauropod", "sauropod":
            return "Footprints/sauropod"
        case "footprint-hadrosaur", "hadrosaur":
            return "Footprints/hadrosaur"
        case "footprint-ceratopsian", "ceratopsian":
            return "Footprints/ceratopsian"
        case "footprint-ankylosaur", "ankylosaur":
            return "Footprints/ankylosaur"

        // Game name-only intros (walk + transition): game-{slug} → Games/game-{slug}
        case _ where normalized.hasPrefix("game-"):
            return "Games/\(normalized)"
        // Level picker intro (play when level picker is shown): Levels/choose-a-level
        case "choose-a-level", "choose a level":
            return "Levels/choose-a-level"
        // Level intros for Dinosaurs (e.g. "Level One Really Easy Games"): level-* → Levels/level-*
        case _ where normalized.hasPrefix("level-"):
            return "Levels/\(normalized)"
        // Dino Formations: formation name from Audio/Formations/{slug}-formation.m4a. Key: formation-name-{slug}
        case _ where normalized.hasPrefix("formation-name-"):
            let slug = String(normalized.dropFirst("formation-name-".count))
            return "Formations/\(slug)-formation"
        // Dinosaurs: Audio/Dinosaurs/{key}.m4a for any dino-* key (e.g. dino-camarasaurus) so all dinosaur name files are used when present
        case _ where normalized.hasPrefix("dino-"):
            return "Dinosaurs/\(normalized)"
        // Pterosaurs: Audio/Pterosaurs/{key}.m4a for any ptero-* key (e.g. ptero-pteranodon) so Match the Pterosaur uses recorded name audio
        case _ where normalized.hasPrefix("ptero-"):
            return "Pterosaurs/\(normalized)"

        // Matrix Materials game: material names → Audio/Materials/{slug}.m4a
        case "limestone", "mudstone", "bentonite", "sandstone", "siltstone", "tuff", "amber", "shale",
             "ironstone", "claystone", "lignite", "phosphorite", "conglomerate":
            return "Materials/\(normalized)"

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
            // Still notify so sequences (e.g. intro walk) don't get stuck with a permanent highlight
            onAudioFinished?()
            return
        }
        lastPlayTime = now
        
        // Stop any current audio with fade-out to prevent clicks
        stopCurrentAudio()
        
        // Small delay to let stop complete and prevent HALC overload; shorter when chaining clips
        let delay: TimeInterval = chainDelay ? 0.03 : 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Try to play recorded audio first (use same resolution as urlForAudio, including subdirectory lookup)
            if let audioPath = self.audioFilePath(for: text) {
                let foundURL = self.resolveURL(forPath: audioPath)
                if let url = foundURL {
                    self.playAudioFile(url: url, fallbackSpeakText: text)
                    print("🔊 Playing audio: \(url.lastPathComponent)")
                } else {
                    print("⚠️ No audio file found for '\(text)' (path: \(audioPath))")
                    self.startSpeaking(text)
                }
            } else {
                // No mapping found, use TTS
                print("🔊 No mapping for '\(text)', using TTS")
                self.startSpeaking(text)
            }
        }
    }
    
    /// Use when playing dinosaur (or creature) name audio: look up by audioKey (e.g. dino imageName) so Audio/Dinosaurs/*.m4a is used when present; use fallbackText for TTS if no file is found.
    func speak(audioKey: String, fallbackText: String, chainDelay: Bool = false) {
        let now = Date()
        guard now.timeIntervalSince(lastPlayTime) >= minimumPlayInterval else {
            onAudioFinished?()
            return
        }
        lastPlayTime = now
        stopCurrentAudio()
        let delay: TimeInterval = chainDelay ? 0.03 : 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if let url = self.urlForAudio(key: audioKey) {
                self.playAudioFile(url: url, fallbackSpeakText: fallbackText)
            } else {
                self.startSpeaking(fallbackText)
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
    @State private var currentConfig: MatchingGameConfig
    @State private var currentRound: Int = 1
    private let totalRounds: Int = 3
    @State private var selectedDinosaur: Dinosaur?
    @State private var selectedCharacteristic: Characteristic?
    @State private var matchedPairs: Set<MatchedPair> = [] // Track specific matched pairs
    @State private var failedAttempts: Set<MatchedPair> = [] // Track failed attempts (visual only, doesn't block)
    @State private var showFeedback = false
    @State private var feedbackMessage = ""
    @State private var isCorrect = false
    @State private var audioTestMessage = ""
    @State private var isAudioPlaying = false // Track if audio is currently playing
    @State private var showVictory = false // Show victory screen: vertical list, highlight + name audio, then good-job + crowd
    @State private var victoryShownAt: Date? // When victory view was shown; used to enforce minimum display time
    @State private var matchChoiceStartTime: Date? // When dinosaur was selected; used to measure time until characteristic selected
    /// End sequence: -1 none, 1 = walking list (highlight + name audio), 2 = good-job + crowd then dismiss
    @State private var endSequenceStep: Int = -1
    @State private var endHighlightIndex: Int = 0
    /// All dinosaurs from all 3 rounds (3 per round = 9 total) for victory list; accumulated when each round completes.
    @State private var victoryDinosaurs: [Dinosaur] = []
    /// Intro walk each round: step 0..2 = dinosaurs, 3..7 = characteristics; when complete, gameplay is enabled.
    @State private var introWalkComplete = false
    @State private var introWalkStep: Int = 0
    /// Creature ids (dinosaur or pterosaur) already used this game; rounds 2 and 3 exclude these so no reuse.
    @State private var usedCreatureIds: Set<Int> = []
    
    // Convenience accessors
    private var dinosaurs: [Dinosaur] { currentConfig.selectedDinosaurs }
    private var characteristics: [Characteristic] { currentConfig.selectedCharacteristics }
    
    init(isPresented: Binding<Bool>, gameConfig: MatchingGameConfig) {
        self._isPresented = isPresented
        self.gameConfig = gameConfig
        self._currentConfig = State(initialValue: gameConfig)
    }
    
    // Reset game state when view appears (allows replay)
    private func resetGameState() {
        matchedPairs.removeAll()
        failedAttempts.removeAll()
        selectedDinosaur = nil
        selectedCharacteristic = nil
        showFeedback = false
        feedbackMessage = ""
        showVictory = false
        victoryShownAt = nil
        matchChoiceStartTime = nil
        endSequenceStep = -1
        endHighlightIndex = 0
        introWalkComplete = false
        introWalkStep = 0
    }
    
    private func startNextRound() {
        currentRound += 1
        // New random config each round; exclude creatures already used so no reuse across rounds
        currentConfig = (currentConfig.id == "match-the-pterosaur")
            ? MatchingGameConfigs.pterosaurFeatures(excluding: usedCreatureIds)
            : MatchingGameConfigs.dinoFeatures(excluding: usedCreatureIds)
        speechManager.characteristicSubfolder = currentConfig.id == "match-the-pterosaur" ? "Ptero-Characteristics" : "Dino-Characteristics"
        resetGameState()
        // Run intro walk for this round (dinosaurs then traits). Delay so rate limiting doesn't skip the first speak and leave the first creature stuck highlighted.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startIntroWalkIfNeeded()
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if showVictory {
                    // Victory: horizontal row of 3 creatures + good-job-you-got-them-all audio
                    victoryView
                } else {
                    mainGameView
                }
            }
            .padding()
            .onAppear {
                // Reset game state for fresh play (allows replay)
                currentRound = 1
                currentConfig = gameConfig
                victoryDinosaurs = []
                usedCreatureIds = []
                resetGameState()
                // Use correct characteristic audio folder for this game type
                speechManager.characteristicSubfolder = currentConfig.id == "match-the-pterosaur" ? "Ptero-Characteristics" : "Dino-Characteristics"
                // Do not set a global onAudioFinished here: the intro walk (and every other speak) sets its own callback; overwriting would stop the walk after the first dinosaur.
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
    
    // MARK: - Victory: vertical list of all 9 dinosaurs (3 per round × 3 rounds), scrollable; highlight each + name audio, then good-job + crowd
    private var victoryView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(victoryDinosaurs.enumerated()), id: \.offset) { index, dinosaur in
                        let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                        HStack(spacing: 16) {
                            matchingEndImage(dinosaur: dinosaur, isHighlighted: isHighlighted)
                            Text(dinosaur.name)
                                .font(.title2)
                                .fontWeight(isHighlighted ? .semibold : .regular)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .opacity(isHighlighted ? 1.0 : 0.5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .id(index)
                    }
                    // Good job! shown after the list so it stays visible when scrolling (9 dinosaurs)
                    Text("Good job!")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .onChange(of: endHighlightIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            if victoryDinosaurs.isEmpty {
                playMatchingGoodJobAndCrowdThenDismiss()
            } else {
                let d = victoryDinosaurs[0]
                speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
                speechManager.onAudioFinished = { advanceMatchingEndHighlight() }
            }
        }
    }

    private func matchingEndImage(dinosaur: Dinosaur, isHighlighted: Bool) -> some View {
        Group {
            if let imageName = dinosaur.imageName, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .opacity(isHighlighted ? 1.0 : 0.4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
            } else {
                Text(dinosaur.icon)
                    .font(.system(size: 40))
                    .frame(width: 72, height: 72)
                    .opacity(isHighlighted ? 1.0 : 0.4)
            }
        }
    }

    private func advanceMatchingEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < victoryDinosaurs.count {
            let d = victoryDinosaurs[endHighlightIndex]
            speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
            speechManager.onAudioFinished = { advanceMatchingEndHighlight() }
        } else {
            playMatchingGoodJobAndCrowdThenDismiss()
        }
    }

    private func playMatchingGoodJobAndCrowdThenDismiss() {
        endSequenceStep = 2
        let goodJobURL = speechManager.urlForAudio(key: "good-job-you-got-them-all")
        let crowdURL = speechManager.urlForAudio(key: "crowd-cheering")
        if let u1 = goodJobURL, let u2 = crowdURL {
            speechManager.playTogether(url1: u1, url2: u2) {
                self.speechManager.onAudioFinished = nil
                self.isAudioPlaying = false
                self.isPresented = false
            }
        } else if let u = goodJobURL ?? crowdURL {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.isAudioPlaying = false
                self.isPresented = false
            }
            speechManager.playAudioFile(url: u)
        } else {
            isAudioPlaying = false
            isPresented = false
        }
    }
    
    private var mainGameView: some View {
            VStack(spacing: 20) {
                // Title
                VStack(spacing: 4) {
                    Text(currentConfig.title)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    Text("Round \(currentRound) of \(totalRounds)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Main game area (centered)
                HStack(spacing: 20) {
                    // Left: Dinosaurs or Pterosaurs (dynamic by game)
                    VStack(spacing: 15) {
                        Text(currentConfig.id == "match-the-pterosaur" ? "Pterosaurs" : "Dinosaurs")
                            .font(.headline)
                        
                        ForEach(Array(dinosaurs.enumerated()), id: \.element.id) { index, dinosaur in
                            DinosaurCard(
                                dinosaur: dinosaur,
                                isSelected: selectedDinosaur?.id == dinosaur.id,
                                isMatched: matchedPairs.contains { $0.dinosaurId == dinosaur.id },
                                hasFailedAttempt: failedAttempts.contains { $0.dinosaurId == dinosaur.id },
                                isIntroHighlighted: !introWalkComplete && introWalkStep == index,
                                onTap: {
                                    handleDinosaurTap(dinosaur)
                                }
                            )
                        }
                    }
                    
                    // Right: Special Features (Characteristics / Traits)
                    VStack(spacing: 15) {
                        Text("Special Feature")
                            .font(.headline)
                        
                        ForEach(Array(characteristics.enumerated()), id: \.element.id) { index, characteristic in
                            CharacteristicCard(
                                characteristic: characteristic,
                                isSelected: selectedCharacteristic?.id == characteristic.id,
                                isMatched: matchedPairs.contains { $0.characteristicId == characteristic.id },
                                hasFailedAttempt: failedAttempts.contains { $0.characteristicId == characteristic.id },
                                isIntroHighlighted: !introWalkComplete && introWalkStep == index + 3,
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
            }
            .id(currentRound)
            .onAppear {
                // Only start intro walk from here for round 1; rounds 2–3 are started from startNextRound() to avoid double-start and rate-limit stuck highlight
                if currentRound == 1 {
                    startIntroWalkIfNeeded()
                }
            }
    }
    
    /// Before gameplay each round: walk dinosaurs then characteristics (name/trait audio + highlight); then enable tapping.
    private func startIntroWalkIfNeeded() {
        guard !introWalkComplete, dinosaurs.count >= 3, characteristics.count >= 5 else {
            if !introWalkComplete && (dinosaurs.count < 3 || characteristics.count < 5) {
                introWalkComplete = true
                isAudioPlaying = false
            }
            return
        }
        introWalkStep = 0
        isAudioPlaying = true
        speechManager.onAudioFinished = { advanceIntroWalk() }
        let d0 = dinosaurs[0]
        speechManager.speak(audioKey: d0.imageName ?? d0.name, fallbackText: d0.name)
    }
    
    private func advanceIntroWalk() {
        speechManager.onAudioFinished = nil
        introWalkStep += 1
        if introWalkStep >= 8 {
            introWalkComplete = true
            isAudioPlaying = false
            return
        }
        speechManager.onAudioFinished = { advanceIntroWalk() }
        if introWalkStep < 3 {
            let d = dinosaurs[introWalkStep]
            speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
        } else {
            speechManager.speak(characteristics[introWalkStep - 3].type)
        }
    }
    
    private func handleDinosaurTap(_ dinosaur: Dinosaur) {
        // Don't allow interaction while audio is playing
        guard !isAudioPlaying else { return }
        
        // If this dinosaur is fully matched (all characteristics matched), play handrail and don't allow selection
        let dinosaurCharacteristics = characteristics.filter { $0.dinosaurId == dinosaur.id }
        let matchedCount = matchedPairs.filter { $0.dinosaurId == dinosaur.id }.count
        if matchedCount >= dinosaurCharacteristics.count {
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                DispatchQueue.main.async { self.isAudioPlaying = false }
            }
            speechManager.speak("pick-another-one")
            return
        }
        
        // If tapping the same dinosaur again, deselect it (no audio)
        if selectedDinosaur?.id == dinosaur.id {
            selectedDinosaur = nil
            return
        }
        
        // Play audio feedback only when selecting (not deselecting); re-enable taps when name finishes
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            DispatchQueue.main.async { self.isAudioPlaying = false }
        }
        speechManager.speak(audioKey: dinosaur.imageName ?? dinosaur.name, fallbackText: dinosaur.name)
        
        selectedDinosaur = dinosaur
        selectedCharacteristic = nil // Reset characteristic selection
        matchChoiceStartTime = Date() // Start timer for this choice
        
        // Don't check match yet - wait for user to select characteristic
    }
    
    private func handleCharacteristicTap(_ characteristic: Characteristic) {
        // Don't allow interaction while audio is playing
        guard !isAudioPlaying else { return }
        
        // Handrail: must select a creature first (dinosaur or pterosaur by game type)
        if selectedDinosaur == nil {
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                DispatchQueue.main.async { self.isAudioPlaying = false }
            }
            let pickFirstKey = gameConfig.id == "match-the-pterosaur" ? "pick-a-pterosaur-first" : "pick-a-dinosaur-first"
            speechManager.speak(pickFirstKey)
            return
        }
        
        // If this specific characteristic is already matched, play handrail and don't allow selection
        if matchedPairs.contains(where: { $0.characteristicId == characteristic.id }) {
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                DispatchQueue.main.async { self.isAudioPlaying = false }
            }
            speechManager.speak("pick-another-one")
            return
        }
        
        // If tapping the same characteristic again, deselect it (no audio)
        if selectedCharacteristic?.id == characteristic.id {
            selectedCharacteristic = nil
            return
        }
        
        selectedCharacteristic = characteristic
        
        // Play characteristic name; when it finishes, check match so result audio doesn't cut it off
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            DispatchQueue.main.async {
                // Clear this one-shot callback, but do NOT overwrite any callback that `checkMatch()`
                // installs for chaining (e.g. last match → advance round).
                self.speechManager.onAudioFinished = nil
                if self.selectedDinosaur != nil && self.selectedCharacteristic != nil {
                    self.checkMatch()
                } else {
                    self.isAudioPlaying = false
                }
            }
        }
        speechManager.speak(characteristic.type)
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
            // Success! Measure time from dinosaur tap to characteristic tap
            let elapsed = matchChoiceStartTime.map { Date().timeIntervalSince($0) } ?? 0
            
            feedbackMessage = "Great Match!"
            isAudioPlaying = true
            
            // Add this specific pair to matched pairs
            let newPair = MatchedPair(dinosaurId: dinosaur.id, characteristicId: characteristic.id)
            matchedPairs.insert(newPair)
            let matchCount = matchedPairs.count
            
            if matchCount == dinosaurs.count {
                // Third match: play great-match (or wow-that-was-tricky) then advance round (or finish game on last round).
                matchChoiceStartTime = nil // Reset timer after choosing audio
                let matchAudio = elapsed > 5 ? "wow-that-was-tricky" : "great-match"
                speechManager.onAudioFinished = {
                    DispatchQueue.main.async {
                        // Accumulate this round's dinosaurs; keep list unique by id (first appearance order) so walk-the-list and ForEach work correctly
                        for d in self.dinosaurs {
                            if !self.victoryDinosaurs.contains(where: { $0.id == d.id }) {
                                self.victoryDinosaurs.append(d)
                            }
                        }
                        if self.currentRound < self.totalRounds {
                            // Mark this round's creatures as used so next round won't reuse them
                            self.usedCreatureIds.formUnion(self.dinosaurs.map(\.id))
                            // Short pause so the last match feels complete, then start the next round.
                            self.isAudioPlaying = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                self.startNextRound()
                            }
                        } else {
                            // Last round complete: show victory view; it will walk all 9 (highlight + name audio) then good-job + crowd then dismiss.
                            self.showVictory = true
                            self.isAudioPlaying = true
                        }
                    }
                }
                speechManager.speak(matchAudio)
            } else {
                // First or second match: play great-match if ≤ 5 s, wow-that-was-tricky if > 5 s
                let matchAudio = elapsed > 5 ? "wow-that-was-tricky" : "great-match"
                matchChoiceStartTime = nil // Reset timer after choosing audio
                speechManager.onAudioFinished = {
                    DispatchQueue.main.async {
                        self.isAudioPlaying = false
                        self.selectedDinosaur = nil
                        self.selectedCharacteristic = nil
                        self.showFeedback = false
                    }
                }
                speechManager.speak(matchAudio)
            }
        } else {
            // Wrong match - encouragement and permission to continue (no failure count, no game over)
            feedbackMessage = "Try again!"
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                DispatchQueue.main.async {
                    self.isAudioPlaying = false
                    self.selectedDinosaur = nil
                    self.selectedCharacteristic = nil
                    self.showFeedback = false
                }
            }
            speechManager.speak("not-that-one")
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
    
    // Create a random game configuration from the full pool.
    // excludingCreatureIds: creatures already used in earlier rounds this game (no reuse).
    // Ensures no duplicate characteristic types (e.g. only one "Crest") so labels are unique.
    static func createRandom(
        from allDinosaurs: [Dinosaur],
        allCharacteristics: [Characteristic],
        id: String = "match-the-dinosaur",
        title: String = "Match the Dinosaur!",
        introAudio: String = "game-intro-matching",
        excludingCreatureIds: Set<Int> = []
    ) -> MatchingGameConfig {
        let pool: [Dinosaur] = {
            if excludingCreatureIds.isEmpty { return allDinosaurs }
            let available = allDinosaurs.filter { !excludingCreatureIds.contains($0.id) }
            return available.count >= 3 ? available : allDinosaurs
        }()
        var selected: [Dinosaur] = []
        var gameCharacteristics: [Characteristic] = []
        var selectedIds: Set<Int> = []
        let maxAttempts = 15

        for _ in 0..<maxAttempts {
            // Randomly select 3 unique dinosaurs from pool (excluding already-used this game)
            let shuffled = pool.shuffled()
            selected = Array(shuffled.prefix(3))
            selectedIds = Set(selected.map(\.id))

            // From each selected dinosaur, pick exactly ONE characteristic with a type not yet used (no duplicate labels).
            gameCharacteristics = []
            var seenTypes: Set<String> = []
            for dino in selected {
                let dinoChars = allCharacteristics.filter { $0.dinosaurId == dino.id }
                let available = dinoChars.filter { !seenTypes.contains($0.type) }
                guard let one = available.shuffled().first else { break }
                gameCharacteristics.append(one)
                seenTypes.insert(one.type)
            }

            // We need exactly 3 characteristics (one per dino) with distinct types to have 3 matches.
            if gameCharacteristics.count == 3 { break }
        }

        var seenTypes = Set(gameCharacteristics.map(\.type))

        // Pad to 5 using only characteristics from dinosaurs NOT in the selected 3 (unique types only)
        if gameCharacteristics.count < 5 {
            let paddingPool = allCharacteristics.filter { !selectedIds.contains($0.dinosaurId) }
            for c in paddingPool.shuffled() {
                guard gameCharacteristics.count < 5 else { break }
                if !seenTypes.contains(c.type) {
                    seenTypes.insert(c.type)
                    gameCharacteristics.append(c)
                }
            }
        }

        // Take exactly 5, shuffle
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
    let isIntroHighlighted: Bool
    let onTap: () -> Void
    
    private var backgroundColor: Color {
        if isMatched {
            return Color.green.opacity(0.3)
        } else if isSelected || isIntroHighlighted {
            return Color.blue.opacity(0.3)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private var strokeColor: Color {
        if isMatched {
            return Color.green
        } else if isSelected || isIntroHighlighted {
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
                    
                    // Show text only when selected, intro-highlighted, or matched (for parents)
                    if isSelected || isIntroHighlighted || isMatched {
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
            .frame(width: 180, height: isSelected || isIntroHighlighted || isMatched ? 120 : 100)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(backgroundColor)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(strokeColor, lineWidth: 3)
            }
            .scaleEffect(isSelected || isIntroHighlighted ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
            .animation(.spring(response: 0.3), value: isIntroHighlighted)
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
    let isIntroHighlighted: Bool
    let onTap: () -> Void
    
    private var backgroundColor: Color {
        if isMatched {
            return Color.green.opacity(0.3)
        } else if isSelected || isIntroHighlighted {
            return Color.blue.opacity(0.3)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private var strokeColor: Color {
        if isMatched {
            return Color.green
        } else if isSelected || isIntroHighlighted {
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
                    
                    // Show text only when selected, intro-highlighted, or matched (for parents)
                    if isSelected || isIntroHighlighted || isMatched {
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
            .frame(width: 180, height: isSelected || isIntroHighlighted || isMatched ? 120 : 100)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(backgroundColor)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(strokeColor, lineWidth: 3)
            }
            .scaleEffect(isSelected || isIntroHighlighted ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
            .animation(.spring(response: 0.3), value: isIntroHighlighted)
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
        Dinosaur(id: 1, name: "T-Rex", icon: "🦖", imageName: "dino-trex", characteristicIds: [1, 2, 24]),
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
        Dinosaur(id: 13, name: "Edmontosaurus", icon: "🦆", imageName: "dino-edmontosaurus", characteristicIds: [25, 27]),
        Dinosaur(id: 38, name: "Masiakasaurus", icon: "🦖", imageName: "dino-masiakasaurus", characteristicIds: []),
        Dinosaur(id: 39, name: "Torvosaurus", icon: "🦖", imageName: "dino-torvosaurus", characteristicIds: []),
        Dinosaur(id: 40, name: "Rapetosaurus", icon: "🦕", imageName: "dino-rapetosaurus", characteristicIds: []),
        Dinosaur(id: 41, name: "Majungasaurus", icon: "🦖", imageName: "dino-majungasaurus", characteristicIds: []),
        Dinosaur(id: 42, name: "Allosaurus", icon: "🦖", imageName: "dino-allosaurus", characteristicIds: []),
        Dinosaur(id: 43, name: "Oviraptor", icon: "🦅", imageName: "dino-oviraptor", characteristicIds: []),
    ]
    
    // Full pool of available characteristics (can be expanded)
    // Image sets: dino-char-<characteristic> (e.g. dino-char-teeth, dino-char-crest)
    static let allCharacteristics: [Characteristic] = [
        // T-Rex characteristics (high EQ – Smart alongside Teeth/Footprints)
        Characteristic(id: 1, type: "Teeth", icon: "🦷", imageName: "dino-char-teeth", dinosaurId: 1),
        Characteristic(id: 2, type: "Footprints", icon: "👣", imageName: "dino-char-footprints", dinosaurId: 1),
        Characteristic(id: 24, type: "Smart", icon: "🧠", imageName: "dino-char-smart", dinosaurId: 1),
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
        // Edmontosaurus characteristics (hadrosaur; no bony crest — flat head / soft-tissue comb)
        Characteristic(id: 25, type: "Duck Bill", icon: "🦆", imageName: "dino-char-duck-bill", dinosaurId: 13),
        Characteristic(id: 27, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 13),
    ]
    
    // Create a random game configuration (3 dinosaurs, 5 characteristics)
    // Image: game-match-the-dinosaur.imageset
    static var dinoFeatures: MatchingGameConfig {
        dinoFeatures(excluding: [])
    }
    
    static func dinoFeatures(excluding usedCreatureIds: Set<Int>) -> MatchingGameConfig {
        MatchingGameConfig.createRandom(
            from: allDinosaurs,
            allCharacteristics: allCharacteristics,
            id: "match-the-dinosaur",
            title: "Match the Dinosaur!",
            introAudio: "game-intro-matching",
            excludingCreatureIds: usedCreatureIds
        )
    }
    
    // Full pool of available pterosaurs (flying reptiles) — 10 total
    static let allPterosaurs: [Dinosaur] = [
        Dinosaur(id: 101, name: "Pterodactylus", icon: "🦅", imageName: "ptero-pteradactylus", characteristicIds: [101, 102, 103]),
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
        // Pterodactylus characteristics
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
        pterosaurFeatures(excluding: [])
    }
    
    static func pterosaurFeatures(excluding usedCreatureIds: Set<Int>) -> MatchingGameConfig {
        MatchingGameConfig.createRandom(
            from: allPterosaurs,
            allCharacteristics: allPterosaurCharacteristics,
            id: "match-the-pterosaur",
            title: "Match the Pterosaur!",
            introAudio: "game-intro-pterosaur",
            excludingCreatureIds: usedCreatureIds
        )
    }
    
    // Future games can be added here:
    // static let dinoHabitat = MatchingGameConfig(...)
    // static let dinoFood = MatchingGameConfig(...)
}
