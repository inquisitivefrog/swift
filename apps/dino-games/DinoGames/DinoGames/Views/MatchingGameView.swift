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
        // Dino Diets!: diet trait audio (Audio/Diets/diet-{slug}.m4a), e.g. diet-herbivore, diet-carnivore
        if normalized.hasPrefix("diet-") {
            return "Diets/\(normalized)"
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
        // Who Is Taller: "X is taller" (one phrase file after dinosaur name)
        case "is-taller", "is taller":
            return "Feedback/is-taller"
        case "they-both-weigh-about-the-same", "they both weigh about the same":
            return "Feedback/they-both-weigh-about-the-same"
        case "they-are-about-the-same-height", "they are about the same height":
            return "Feedback/they-are-about-the-same-height"
        case "is-as-tall-as", "is as tall as":
            return "Feedback/is-as-tall-as"
        case "and":
            return "Feedback/and"
        case "you-cannot-choose-that-one-now", "you cannot choose that one now":
            return "Feedback/you-cannot-choose-that-one-now"
        case "thats-too-small-to-see", "that's too small to see", "too small to see":
            return "Feedback/thats-too-small-to-see"

        // Dinosaur characteristics (Dino-Characteristics folder)
        case "teeth":
            return "\(characteristicSubfolder)/teeth"
        case "frill":
            return "Dino-Characteristics/frill"
        case "horns":
            return "Dino-Characteristics/horns"
        case "spikes", "plates":
            return "Dino-Characteristics/plates"
        case "tail-spikes", "tail spikes":
            return "Dino-Characteristics/tail-spike"
        case "club-tail", "club tail", "tail-club", "tail club":
            return "Dino-Characteristics/tail-club"
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
        case "proto-feathers", "proto feathers":
            return "Dino-Characteristics/proto-feathers"
        case "sail":
            return "Dino-Characteristics/sail"
        case "swims":
            return "Dino-Characteristics/swims"
        case "long-neck", "long neck":
            return "\(characteristicSubfolder)/long-neck"
        case "big":
            return "\(characteristicSubfolder)/big"
        case "huge":
            return "\(characteristicSubfolder)/huge"
        case "armor":
            return "Dino-Characteristics/armor"
        case "crest":
            return "\(characteristicSubfolder)/crest"
        case "duck-bill", "duck bill":
            return "Dino-Characteristics/duck-bill"
        case "beak", "parrot beak", "parrot-beak":
            return "Dino-Characteristics/beak"
        case "same-size", "same size":
            return "Dino-Characteristics/same-size"
        case "herbivore":
            return "Dino-Characteristics/herbivore"
        case "carnivore":
            return "Dino-Characteristics/carnivore"
        case "piscivore":
            return "Dino-Characteristics/piscivore"
        case "insectivore":
            return "Dino-Characteristics/insectivore"
        case "omnivore":
            return "Dino-Characteristics/omnivore"
        case "long-crest", "long crest":
            return "\(characteristicSubfolder)/crest"
        case "thumb-spikes", "thumb spikes", "thumb-spike", "thumb spike":
            return "Dino-Characteristics/thumb-spike"
        case "smart":
            return "Dino-Characteristics/smart"
        case "big-eyes", "big eyes":
            return "Dino-Characteristics/big-eyes"
        case "two-feet", "two feet":
            return "\(characteristicSubfolder)/two-feet"
        case "four-feet", "four feet":
            return "\(characteristicSubfolder)/four-feet"
        case "long-tail", "long tail":
            return "\(characteristicSubfolder)/long-tail"
        case "dome-head", "dome head":
            return "\(characteristicSubfolder)/dome-head"
        case "long-snout", "long snout":
            return "\(characteristicSubfolder)/long-snout"
        case "croc-snout", "croc snout":
            return "\(characteristicSubfolder)/croc-snout"
        case "small":
            return characteristicSubfolder == "Ptero-Characteristics" ? "Ptero-Characteristics/ptero-char-small" : "Dino-Characteristics/small"
        // Pterosaur-only characteristics (Ptero-Characteristics folder)
        case "wings":
            return "Ptero-Characteristics/wings"
        case "no-teeth", "no teeth":
            return "Ptero-Characteristics/no-teeth"
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
        case "you-cant-be-serious-that-will-take-forever", "you can't be serious that will take forever":
            return "Feedback/you-cant-be-serious-that-will-take-forever"
        case "game-measure-stack-too-tall", "that stack is too tall", "stack too tall":
            return "Feedback/game-measure-stack-too-tall"
        case "that-dinosaur-is-too-tall", "that dinosaur is too tall":
            return "Feedback/that-dinosaur-is-too-tall"
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
        case "congratulations-you-did-it", "congratulations you did it":
            return "Feedback/congratulations-you-did-it"

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
        case "game-match-choose":
            return "Games/game-match-choose"
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
        case "game-balance-now-choose-dinosaurs", "now choose dinosaurs":
            return "Games/game-balance-now-choose-dinosaurs"
        case "game-balance-now-choose-pterosaurs", "now choose pterosaurs":
            return "Games/game-balance-now-choose-pterosaurs"
        case "game-balance-this-game-will-end-quick", "this game will end quick":
            return "Games/game-balance-this-game-will-end-quick"
        case "game-balance-see-i-told-you", "game-balance-see-I-told-you", "see I told you", "see i told you":
            return "Feedback/game-balance-see-I-told-you"
        case "game-balance-good-job-keep-going", "game-measure-good-job-keep-going", "good job keep going":
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
        case "game-racing-outside-track", "racing outside track":
            return "Games/game-racing-outside-track"
        case "game-racing-inside-track", "racing inside track":
            return "Games/game-racing-inside-track"
        case "game-racing-ready-set", "racing ready set":
            return "Games/game-racing-ready-set"
        case "racing-the-winner-is", "the winner is":
            return "Games/racing-the-winner-is"
        case "game-racing-the-winner-is":
            return "Games/game-racing-the-winner-is"
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
        // Dino-Characteristics: when key is dino-char-* (characteristic imageName), use Dino-Characteristics/{suffix} so tail-spike.m4a / tail-club.m4a etc. are found
        case _ where normalized.hasPrefix("dino-char-"):
            var suffix = String(normalized.dropFirst("dino-char-".count))
            if suffix == "tail-spikes" { suffix = "tail-spike" } // audio file is tail-spike.m4a
            return "\(characteristicSubfolder)/\(suffix)"
        // Dinosaurs: Audio/Dinosaurs/{key}.m4a for any other dino-* key (e.g. dino-camarasaurus) for dinosaur name audio
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
        
        let playBlock = {
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
                print("🔊 No mapping for '\(text)', using TTS")
                self.startSpeaking(text)
            }
        }
        if chainDelay {
            playBlock()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { playBlock() }
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
        let playBlock = {
            if let url = self.urlForAudio(key: audioKey) {
                self.playAudioFile(url: url, fallbackSpeakText: fallbackText)
            } else {
                self.startSpeaking(fallbackText)
            }
        }
        if chainDelay {
            playBlock()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { playBlock() }
        }
    }
    
    func playAudioFile(url: URL, fallbackSpeakText: String? = nil) {
        do {
            // Stop any current player (only if still playing—e.g. interrupted) to avoid click when chaining
            if let old = currentPlayer, old.isPlaying {
                old.volume = 0
                old.stop()
            }
            currentPlayer = nil
            
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
            
            let fadeInDuration: TimeInterval = 0.2
            let fadeOutDuration: TimeInterval = 0.5
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
            
        } catch {
            print("❌ Error playing audio file: \(error)")
            isPlaying = false
            // Fallback to TTS with original text (e.g. "Pteranodon") not filename
            let fallback = fallbackSpeakText ?? url.deletingPathExtension().lastPathComponent
            startSpeaking(fallback)
        }
    }
    
    // Fade in the current player (only if it still matches) to prevent click at start.
    // Uses quadratic ease-in so we ramp up gradually from silence.
    private func fadeInPlayerIfMatches(targetID: ObjectIdentifier, duration: TimeInterval) async {
        let fadeSteps = 20
        let fadeInterval = duration / Double(fadeSteps)
        
        for step in 1...fadeSteps {
            guard let player = currentPlayer,
                  ObjectIdentifier(player) == targetID,
                  player.isPlaying else {
                return
            }
            let t = Double(step) / Double(fadeSteps)
            let eased = t * t // Ease-in: start slow to avoid click
            player.volume = min(1.0, Float(eased))
            try? await Task.sleep(nanoseconds: UInt64(fadeInterval * 1_000_000_000))
        }
        
        if let player = currentPlayer, ObjectIdentifier(player) == targetID {
            player.volume = 1.0
        }
    }
    
    // Fade out the current player (only if it still matches) to prevent clicks.
    // Uses easing: slower near the end (quadratic) for a smoother tail.
    private func fadeCurrentPlayerIfMatches(targetID: ObjectIdentifier, duration: TimeInterval) async {
        let fadeSteps = 45
        let fadeInterval = duration / Double(fadeSteps)
        
        for step in 1...fadeSteps {
            guard let player = currentPlayer,
                  ObjectIdentifier(player) == targetID,
                  player.isPlaying else {
                return
            }
            // Quadratic ease-out: (1-t)^2 so we approach 0 more gradually at the end
            let t = Double(step) / Double(fadeSteps)
            let eased = (1.0 - t) * (1.0 - t)
            player.volume = max(0.0, Float(eased))
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
        // Clear currentPlayer before callback so chained playback doesn't call stop() on a finished player (reduces clicks)
        if currentPlayer === player {
            currentPlayer = nil
        }
        isPlaying = false
        // Brief delay before next clip lets the output buffer drain (reduces click when chaining)
        let callback = onAudioFinished
        onAudioFinished = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            callback?()
        }
    }
    
    // Handle audio interruption
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if currentPlayer === player {
            currentPlayer = nil
        }
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
            : (currentConfig.id == "match-the-diet"
                ? MatchingGameConfigs.dinoDietFeatures(excluding: usedCreatureIds)
                : MatchingGameConfigs.dinoFeatures(excluding: usedCreatureIds))
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
                    // Victory: top-half scrolling list of dinosaurs (same mechanism as Weigh the Dinosaurs), then good-job + crowd
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
    
    /// Fixed row height and scroll height so exactly 4 full rows are visible (no 4.5 or 5). Includes top/bottom padding.
    private let victoryRowHeight: CGFloat = 92
    private var victoryListVisibleHeight: CGFloat { 16 + 4 * victoryRowHeight + 3 * 12 + 16 }

    // MARK: - Victory: scrolling list in top half (highlight + name audio); bottom half shows "Good job!" then success image (no clear, image centered, no wrapper); then audio and dismiss
    private var victoryView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top half: scrolling list of dinosaurs (9 total), highlight + name audio, scroll to center — fixed height so ~4 visible (consistent across games)
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
                                        .lineLimit(3)
                                        .minimumScaleFactor(0.5)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .opacity(isHighlighted ? 1.0 : 0.5)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .frame(height: victoryRowHeight)
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
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    }
                    .frame(height: victoryListVisibleHeight)
                    .onChange(of: endHighlightIndex) { _, newIndex in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // Bottom half: during walk show empty space; after walk show success image only (centered, no wrapper)
                Group {
                    if endSequenceStep == 2 {
                        successImageView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    playMatchingGoodJobAndCrowdThenDismiss()
                                }
                            }
                    } else {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            if victoryDinosaurs.isEmpty {
                endSequenceStep = 2 // Skip walk if no dinosaurs, go straight to success image
            } else {
                let d = victoryDinosaurs[0]
                speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
                speechManager.onAudioFinished = { advanceMatchingEndHighlight() }
            }
        }
    }

    /// Success image only (no card wrapper); used in victory bottom half, centered.
    private var successImageView: some View {
        ZStack {
            successImageContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var successImageContent: some View {
        Group {
            let successImageName = successImageNameForGame()
            if let imageName = successImageName, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else {
                let fallbackImageName = currentConfig.id == "match-the-diet" ? "game-dino-diets" : "game-\(currentConfig.id)"
                if UIImage(named: fallbackImageName) != nil {
                    Image(fallbackImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 280, height: 280)
                } else {
                    Text("🎉")
                        .font(.system(size: 100))
                }
            }
        }
    }
    
    // Get success image name for current game (e.g., "game-dino-diets-success")
    private func successImageNameForGame() -> String? {
        // Try game-specific success image (e.g., game-dino-diets-success)
        if currentConfig.id == "match-the-diet" {
            return "game-dino-diets-success"
        }
        // For other games, construct from config id (e.g., match-the-dinosaur -> game-match-the-dinosaur-success)
        return "game-\(currentConfig.id)-success"
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
            // Walk complete: transition to success card
            endSequenceStep = 2
        }
    }

    private func playMatchingGoodJobAndCrowdThenDismiss() {
        endSequenceStep = 2
        // Dino Diets!: after walking the list of dinosaurs used, play only crowd-cheering then return to level. Others: good-job + crowd.
        let isDinoDiets = currentConfig.id == "match-the-diet"
        let goodJobURL = speechManager.urlForAudio(key: "good-job-you-got-them-all")
        let crowdURL = speechManager.urlForAudio(key: "crowd-cheering")
        if isDinoDiets {
            if let u = crowdURL {
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
        } else if let u1 = goodJobURL, let u2 = crowdURL {
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
                // Title (use gameConfig so Dino Diets! always shows "Dino Diets!" not config.title)
                VStack(spacing: 4) {
                    Text(gameConfig.id == "match-the-diet" ? "Dino Diets!" : currentConfig.title)
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
                    
                    // Right: Diets (for Dino Diets!) or Special Feature (Match the Dinosaur / Pterosaur)
                    VStack(spacing: 15) {
                        Text(currentConfig.id == "match-the-diet" ? "Diet" : "Special Feature")
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
                
                // Feedback message (padding from bottom so wrapper isn't truncated by screen edge)
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
                        .padding(.bottom, 32)
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
    
    /// Before gameplay each round: walk dinosaurs then characteristics (name/trait audio + highlight); then enable tapping. Dino Diets! plays instruction first (game-dino-diets-match-each-dinosaur), then dinosaurs, then diets.
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
        if gameConfig.id == "match-the-diet" {
            // Dino Diets!: play instruction (block tapping), then walk dinosaurs, then diets, then unblock
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = { self.advanceIntroWalk() }
                let d0 = self.dinosaurs[0]
                self.speechManager.speak(audioKey: d0.imageName ?? d0.name, fallbackText: d0.name)
            }
            speechManager.speak("game-dino-diets-match-each-dinosaur")
        } else if gameConfig.id == "match-the-dinosaur" {
            // Match the Dinosaur: play directions (game-match-choose) then walk dinosaurs and characteristics (each round)
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = { self.advanceIntroWalk() }
                let d0 = self.dinosaurs[0]
                self.speechManager.speak(audioKey: d0.imageName ?? d0.name, fallbackText: d0.name)
            }
            speechManager.speak("game-match-choose")
        } else {
            speechManager.onAudioFinished = { advanceIntroWalk() }
            let d0 = dinosaurs[0]
            speechManager.speak(audioKey: d0.imageName ?? d0.name, fallbackText: d0.name)
        }
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
            let c = characteristics[introWalkStep - 3]
            if gameConfig.id == "match-the-diet" {
                speechManager.speak("diet-\(c.type.lowercased())")
            } else {
                speechManager.speak(c.type)
            }
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
        if gameConfig.id == "match-the-diet" {
            speechManager.speak("diet-\(characteristic.type.lowercased())")
        } else {
            speechManager.speak(characteristic.type)
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
            // Success! Measure time from dinosaur tap to characteristic tap
            let elapsed = matchChoiceStartTime.map { Date().timeIntervalSince($0) } ?? 0
            
            feedbackMessage = "Great Match!"
            isAudioPlaying = true
            
            // Add this specific pair to matched pairs
            let newPair = MatchedPair(dinosaurId: dinosaur.id, characteristicId: characteristic.id)
            matchedPairs.insert(newPair)
            let matchCount = matchedPairs.count
            
            if matchCount == dinosaurs.count {
                // Third match: Dino Diets! uses 10 s threshold and great-match / wow-that-was-tricky; others use 5 s and great-match / wow-that-was-tricky
                matchChoiceStartTime = nil // Reset timer after choosing audio
                let matchAudio: String
                if gameConfig.id == "match-the-diet" {
                    matchAudio = elapsed > 10 ? "wow-that-was-tricky" : "great-match"
                } else {
                    matchAudio = elapsed > 5 ? "wow-that-was-tricky" : "great-match"
                }
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
                // First or second match: Dino Diets! uses 10 s and great-match / wow-that-was-tricky; others use 5 s and great-match / wow-that-was-tricky
                let matchAudio: String
                if gameConfig.id == "match-the-diet" {
                    matchAudio = elapsed > 10 ? "wow-that-was-tricky" : "great-match"
                } else {
                    matchAudio = elapsed > 5 ? "wow-that-was-tricky" : "great-match"
                }
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
            let wrongKey = gameConfig.id == "match-the-diet" ? "thats-not-right-try-again" : "not-that-one"
            speechManager.speak(wrongKey)
        }
    }
}

// MARK: - Clade (for Match the Dinosaur round variety)

/// Dinosaur clade for round selection. Each round picks one dinosaur per clade so the three choices look and behave differently (e.g. one theropod, one sauropod, one hadrosaur), avoiding "which theropod?" when art is simple.
enum DinoClade: String, CaseIterable {
    case theropod
    case sauropod
    case ceratopsian
    case ankylosaurid
    case hadrosaur
    case spinosaurid
    case stegosaur
    case ornithopod
    case pachycephalosaur
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
    // Picks one dinosaur per clade per round so the three choices are from different groups (e.g. one theropod, one sauropod, one hadrosaur) for clearer matching when art is simple.
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
        let cladeById = (id == "match-the-pterosaur") ? [:] : MatchingGameConfigs.dinosaurCladeById
        var selected: [Dinosaur] = []
        var gameCharacteristics: [Characteristic] = []
        var selectedIds: Set<Int> = []
        let maxAttempts = 15

        for _ in 0..<maxAttempts {
            if !cladeById.isEmpty {
                // Match the Dinosaur: pick one dinosaur per clade so the three look distinct (no "which theropod?").
                let playable = pool.filter { d in allCharacteristics.contains(where: { $0.dinosaurId == d.id }) }
                let byClade = Dictionary(grouping: playable) { cladeById[$0.id] ?? .theropod }
                let cladesWithDinos = byClade.keys.filter { !(byClade[$0] ?? []).isEmpty }.shuffled()
                if cladesWithDinos.count >= 3 {
                    selected = (0..<3).compactMap { i in
                        let clade = cladesWithDinos[i]
                        let candidates = (byClade[clade] ?? []).filter { !excludingCreatureIds.contains($0.id) }
                        return candidates.shuffled().first
                    }
                    if selected.count == 3, Set(selected.map(\.id)).count == 3 {
                        selectedIds = Set(selected.map(\.id))
                        var seenTypes: Set<String> = []
                        for dino in selected {
                            let dinoChars = allCharacteristics.filter { $0.dinosaurId == dino.id }
                            let available = dinoChars.filter { !seenTypes.contains($0.type) }
                            guard let one = available.shuffled().first else { break }
                            gameCharacteristics.append(one)
                            seenTypes.insert(one.type)
                        }
                        if gameCharacteristics.count == 3 { break }
                    }
                }
                selected = []
                gameCharacteristics = []
            }
            // Fallback: random 3 (pterosaur or when too few clades)
            let shuffled = pool.shuffled()
            selected = Array(shuffled.prefix(3))
            selectedIds = Set(selected.map(\.id))

            gameCharacteristics = []
            var seenTypes: Set<String> = []
            for dino in selected {
                let dinoChars = allCharacteristics.filter { $0.dinosaurId == dino.id }
                let available = dinoChars.filter { !seenTypes.contains($0.type) }
                guard let one = available.shuffled().first else { break }
                gameCharacteristics.append(one)
                seenTypes.insert(one.type)
            }

            if gameCharacteristics.count == 3 { break }
        }
        selectedIds = Set(selected.map(\.id))

        var seenTypes = Set(gameCharacteristics.map(\.type))

        // Types that any selected dinosaur has: decoys must not use these (so we don't show e.g. "Long Neck" when Argentinosaurus is in the round).
        let selectedDinoTypeSet: Set<String> = {
            let ids = Set(selected.map(\.id))
            return Set(allCharacteristics.filter { ids.contains($0.dinosaurId) }.map(\.type))
        }()

        // Pad to 5 using characteristics from dinosaurs NOT in the selected 3, and whose type is not shared by any selected dinosaur (unique types only, no ambiguous decoys).
        if gameCharacteristics.count < 5 {
            let paddingPool = allCharacteristics.filter {
                !selectedIds.contains($0.dinosaurId) && !selectedDinoTypeSet.contains($0.type)
            }
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

        // Don't show Big and Huge in the same round — too confusing for children. Prefer Big; replace or remove Huge and refill.
        // Important: each selected dinosaur must keep exactly one characteristic in the round. If we remove a selected dinosaur's only trait (Huge), they would have 0 and tapping them would incorrectly play "pick-another-one". So we replace selected-dino Huge with another trait from the same dinosaur when possible; only remove decoy Huge.
        var typesInRound = Set(gameCharacteristics.map(\.type))
        if typesInRound.contains("Big") && typesInRound.contains("Huge") {
            // Only run removal if every selected-dino Huge has a replacement; otherwise round could be left uncompletable
            var canSafelyRemoveHuge = true
            for c in gameCharacteristics where c.type == "Huge" && selectedIds.contains(c.dinosaurId) {
                let hasReplacement = allCharacteristics.contains { other in
                    other.dinosaurId == c.dinosaurId && other.type != "Huge" && !typesInRound.contains(other.type)
                }
                if !hasReplacement { canSafelyRemoveHuge = false; break }
            }
            if canSafelyRemoveHuge {
            for (index, c) in gameCharacteristics.enumerated() where c.type == "Huge" {
                if selectedIds.contains(c.dinosaurId) {
                    let replacement = allCharacteristics.first { other in
                        other.dinosaurId == c.dinosaurId && other.type != "Huge" && !typesInRound.contains(other.type)
                    }
                    if let r = replacement {
                        gameCharacteristics[index] = r
                        typesInRound.insert(r.type)
                    }
                }
            }
            // Remove only Huge that are from non-selected dinosaurs (decoys)
            gameCharacteristics.removeAll { $0.type == "Huge" && !selectedIds.contains($0.dinosaurId) }
            var seenTypes = Set(gameCharacteristics.map(\.type))
            let refillPool = allCharacteristics.filter {
                !selectedIds.contains($0.dinosaurId) && !seenTypes.contains($0.type) && $0.type != "Big" && $0.type != "Huge"
            }
            for c in refillPool.shuffled() {
                guard gameCharacteristics.count < 5 else { break }
                seenTypes.insert(c.type)
                gameCharacteristics.append(c)
            }
            // If still short of 5 (refill pool exhausted), add any unused type so round has exactly 5 and can complete
            if gameCharacteristics.count < 5 {
                let fallbackPool = allCharacteristics.filter {
                    !selectedIds.contains($0.dinosaurId) && !seenTypes.contains($0.type)
                }
                for c in fallbackPool.shuffled() {
                    guard gameCharacteristics.count < 5 else { break }
                    seenTypes.insert(c.type)
                    gameCharacteristics.append(c)
                }
            }
            gameCharacteristics.shuffle()
            }
        }

        return MatchingGameConfig(
            id: id,
            title: title,
            introAudio: introAudio,
            selectedDinosaurs: selected,
            selectedCharacteristics: gameCharacteristics
        )
    }

    /// Creates a config for Dino Diets!: 3 dinosaurs, 5 characteristics (always the 5 diets). Same gameplay as Match the Dinosaur but traits are Herbivore/Carnivore/Piscivore/Insectivore/Omnivore.
    static func createRandomDiet(
        from allDinosaurs: [Dinosaur],
        allDietCharacteristics: [Characteristic],
        id: String = "match-the-diet",
        title: String = "Dino Diets!",
        introAudio: String = "game-intro-dino-diets",
        excludingCreatureIds: Set<Int> = []
    ) -> MatchingGameConfig {
        let pool: [Dinosaur] = {
            if excludingCreatureIds.isEmpty { return allDinosaurs }
            let available = allDinosaurs.filter { !excludingCreatureIds.contains($0.id) }
            return available.count >= 3 ? available : allDinosaurs
        }()
        let cladeById = MatchingGameConfigs.dinosaurCladeById
        let dietTypes = ["Herbivore", "Carnivore", "Piscivore", "Insectivore", "Omnivore"]
        var selected: [Dinosaur] = []
        var gameCharacteristics: [Characteristic] = []
        let maxAttempts = 20

        for _ in 0..<maxAttempts {
            let playable = pool.filter { d in allDietCharacteristics.contains(where: { $0.dinosaurId == d.id }) }
            let byClade = Dictionary(grouping: playable) { cladeById[$0.id] ?? .theropod }
            let cladesWithDinos = byClade.keys.filter { !(byClade[$0] ?? []).isEmpty }.shuffled()
            guard cladesWithDinos.count >= 3 else { continue }
            selected = (0..<3).compactMap { i in
                let clade = cladesWithDinos[i]
                let candidates = (byClade[clade] ?? []).filter { !excludingCreatureIds.contains($0.id) }
                return candidates.shuffled().first
            }
            guard selected.count == 3, Set(selected.map(\.id)).count == 3 else { continue }
            // Require three distinct diets so we never get e.g. three herbivores in one round.
            let selectedDiets = selected.compactMap { MatchingGameConfigs.dinosaurDietById[$0.id] }
            guard Set(selectedDiets).count == 3 else { continue }
            // All 5 diet types, each exactly once: use selected dinosaur’s characteristic when it matches that diet, else a decoy. Then shuffle for random order.
            gameCharacteristics = dietTypes.compactMap { dietType in
                if let match = selected.first(where: { d in allDietCharacteristics.contains(where: { $0.dinosaurId == d.id && $0.type == dietType }) }),
                   let c = allDietCharacteristics.first(where: { $0.dinosaurId == match.id && $0.type == dietType }) {
                    return c
                }
                return allDietCharacteristics.first(where: { $0.type == dietType })
            }
            guard gameCharacteristics.count == 5 else { continue }
            break
        }
        if gameCharacteristics.count != 5 {
            // Fallback: pick 3 from pool with 3 distinct diets (retry until satisfied)
            for _ in 0..<maxAttempts {
                let shuffled = pool.shuffled()
                selected = Array(shuffled.prefix(3))
                let diets = selected.compactMap { MatchingGameConfigs.dinosaurDietById[$0.id] }
                guard Set(diets).count == 3 else { continue }
                gameCharacteristics = dietTypes.compactMap { dietType in
                    if let match = selected.first(where: { d in allDietCharacteristics.contains(where: { $0.dinosaurId == d.id && $0.type == dietType }) }),
                       let c = allDietCharacteristics.first(where: { $0.dinosaurId == match.id && $0.type == dietType }) {
                        return c
                    }
                    return allDietCharacteristics.first(where: { $0.type == dietType })
                }
                if gameCharacteristics.count == 5 { break }
            }
        }
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
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.65)
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
            .frame(width: 180, height: isSelected || isIntroHighlighted || isMatched ? 130 : 100)
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
    // Full pool of available dinosaurs (54 total; matches app assets and docs/DINOSAUR_CHARACTERISTICS_4-6.md)
    static let allDinosaurs: [Dinosaur] = [
        Dinosaur(id: 1, name: "T-Rex", icon: "🦖", imageName: "dino-trex", characteristicIds: [1, 24, 119, 120]),
        Dinosaur(id: 2, name: "Triceratops", icon: "🦏", imageName: "dino-triceratops", characteristicIds: [3, 4, 117, 121, 122]),
        Dinosaur(id: 3, name: "Stegosaurus", icon: "🦎", imageName: "dino-stegosaurus", characteristicIds: [5, 113, 114, 196]),
        Dinosaur(id: 4, name: "Velociraptor", icon: "🦖", imageName: "dino-velociraptor", characteristicIds: [6, 7, 23, 123, 124]),
        Dinosaur(id: 5, name: "Therizinosaurus", icon: "🦕", imageName: "dino-therizinosaurus", characteristicIds: [8, 9, 125, 126]),
        Dinosaur(id: 6, name: "Spinosaurus", icon: "🦖", imageName: "dino-spinosaurus", characteristicIds: [10, 11, 115, 127, 128]),
        Dinosaur(id: 7, name: "Apatosaurus", icon: "🦕", imageName: "dino-apatosaurus", characteristicIds: [12, 13, 116, 129]),
        Dinosaur(id: 8, name: "Ankylosaurus", icon: "🛡️", imageName: "dino-ankylosaurus", characteristicIds: [14, 15, 130, 131]),
        Dinosaur(id: 9, name: "Corythosaurus", icon: "🦆", imageName: "dino-corythosaurus", characteristicIds: [16, 17, 132, 133]),
        Dinosaur(id: 10, name: "Parasaurolophus", icon: "🦆", imageName: "dino-parasaurolophus", characteristicIds: [18, 19, 134, 135]),
        Dinosaur(id: 11, name: "Iguanodon", icon: "🦎", imageName: "dino-iguanodon", characteristicIds: [20, 118, 136, 137]),
        Dinosaur(id: 12, name: "Troodon", icon: "🦉", imageName: "dino-troodon", characteristicIds: [21, 22, 138]),
        Dinosaur(id: 13, name: "Edmontosaurus", icon: "🦆", imageName: "dino-edmontosaurus", characteristicIds: [25, 27, 139]),
        Dinosaur(id: 14, name: "Camarasaurus", icon: "🦕", imageName: "dino-camarasaurus", characteristicIds: [45, 46, 140, 197]),
        Dinosaur(id: 15, name: "Dryosaurus", icon: "🦎", imageName: "dino-dryosaurus", characteristicIds: [28, 41, 141, 142]),
        Dinosaur(id: 16, name: "Gallimimus", icon: "🦖", imageName: "dino-gallimimus", characteristicIds: [47, 48, 143]),
        Dinosaur(id: 17, name: "Pachycephalosaurus", icon: "🦎", imageName: "dino-pachycephalosaurus", characteristicIds: [49, 50, 144]),
        Dinosaur(id: 18, name: "Albertosaurus", icon: "🦖", imageName: "dino-albertosaurus", characteristicIds: [51, 52, 145]),
        Dinosaur(id: 19, name: "Anchiornis", icon: "🦅", imageName: "dino-anchiornis", characteristicIds: [53, 54, 146]),
        Dinosaur(id: 20, name: "Archaeopteryx", icon: "🦅", imageName: "dino-archaeopteryx", characteristicIds: [55, 56, 147]),
        Dinosaur(id: 21, name: "Argentinosaurus", icon: "🦕", imageName: "dino-argentinosaurus", characteristicIds: [57, 58, 148, 149]),
        Dinosaur(id: 22, name: "Baryonyx", icon: "🦖", imageName: "dino-baryonyx", characteristicIds: [59, 60, 150, 151]),
        Dinosaur(id: 23, name: "Brachiosaurus", icon: "🦕", imageName: "dino-brachiosaurus", characteristicIds: [61, 62, 152]),
        Dinosaur(id: 24, name: "Ceratosaurus", icon: "🦖", imageName: "dino-ceratosaurus", characteristicIds: [63, 64, 153, 154]),
        Dinosaur(id: 25, name: "Chasmosaurus", icon: "🦏", imageName: "dino-chasmosaurus", characteristicIds: [65, 66, 155, 156, 157]),
        Dinosaur(id: 26, name: "Compsognathus", icon: "🦖", imageName: "dino-compsognathus", characteristicIds: [67, 68]),
        Dinosaur(id: 27, name: "Deinonychus", icon: "🦖", imageName: "dino-deinonychus", characteristicIds: [69, 70, 158, 159]),
        Dinosaur(id: 28, name: "Diplodocus", icon: "🦕", imageName: "dino-diplodocus", characteristicIds: [71, 72, 160]),
        Dinosaur(id: 29, name: "Dromaeosaurus", icon: "🦖", imageName: "dino-dromaeosaurus", characteristicIds: [73, 74, 161]),
        Dinosaur(id: 30, name: "Eosinopteryx", icon: "🦅", imageName: "dino-eosinopteryx", characteristicIds: [75, 76]),
        Dinosaur(id: 31, name: "Giganotosaurus", icon: "🦖", imageName: "dino-giganotosaurus", characteristicIds: [77, 78, 162]),
        Dinosaur(id: 32, name: "Kosmoceratops", icon: "🦏", imageName: "dino-kosmoceratops", characteristicIds: [79, 80, 163, 164, 165]),
        Dinosaur(id: 33, name: "Microraptor", icon: "🦅", imageName: "dino-microraptor", characteristicIds: [81, 82, 166]),
        Dinosaur(id: 34, name: "Pedopenna", icon: "🦅", imageName: "dino-pedopenna", characteristicIds: [83, 84, 167]),
        Dinosaur(id: 35, name: "Torosaurus", icon: "🦏", imageName: "dino-torosaurus", characteristicIds: [85, 86, 168, 169, 170]),
        Dinosaur(id: 36, name: "Utahraptor", icon: "🦖", imageName: "dino-utahraptor", characteristicIds: [87, 88, 171, 172]),
        Dinosaur(id: 37, name: "Xiaotingia", icon: "🦅", imageName: "dino-xiaotingia", characteristicIds: [89, 90, 173]),
        Dinosaur(id: 38, name: "Masiakasaurus", icon: "🦖", imageName: "dino-masiakasaurus", characteristicIds: [29, 42, 174]),
        Dinosaur(id: 39, name: "Torvosaurus", icon: "🦖", imageName: "dino-torvosaurus", characteristicIds: [30, 43, 175]),
        Dinosaur(id: 40, name: "Rapetosaurus", icon: "🦕", imageName: "dino-rapetosaurus", characteristicIds: [31, 32, 176, 195]),
        Dinosaur(id: 41, name: "Majungasaurus", icon: "🦖", imageName: "dino-majungasaurus", characteristicIds: [33, 44, 177]),
        Dinosaur(id: 42, name: "Allosaurus", icon: "🦖", imageName: "dino-allosaurus", characteristicIds: [34, 35, 178]),
        Dinosaur(id: 43, name: "Oviraptor", icon: "🦅", imageName: "dino-oviraptor", characteristicIds: [36, 37, 179]),
        Dinosaur(id: 44, name: "Brontosaurus", icon: "🦕", imageName: "dino-brontosaurus", characteristicIds: [91, 92, 180]),
        Dinosaur(id: 45, name: "Kentrosaurus", icon: "🦎", imageName: "dino-kentrosaurus", characteristicIds: [93, 94, 181]),
        Dinosaur(id: 46, name: "Edmontonia", icon: "🛡️", imageName: "dino-edmontonia", characteristicIds: [95, 96, 182]),
        Dinosaur(id: 47, name: "Lambeosaurus", icon: "🦆", imageName: "dino-lambeosaurus", characteristicIds: [97, 98, 183, 184]),
        Dinosaur(id: 48, name: "Maiasaura", icon: "🦆", imageName: "dino-maiasaura", characteristicIds: [99, 100, 185, 186]),
        Dinosaur(id: 49, name: "Stegoceras", icon: "🦎", imageName: "dino-stegoceras", characteristicIds: [101, 102, 187]),
        Dinosaur(id: 50, name: "Stygimoloch", icon: "🦎", imageName: "dino-stygimoloch", characteristicIds: [103, 104]),
        Dinosaur(id: 51, name: "Nodosaurus", icon: "🛡️", imageName: "dino-nodosaurus", characteristicIds: [105, 106, 189]),
        Dinosaur(id: 52, name: "Huayangosaurus", icon: "🦎", imageName: "dino-huayangosaurus", characteristicIds: [107, 108, 190]),
        Dinosaur(id: 53, name: "Ouranosaurus", icon: "🦎", imageName: "dino-ouranosaurus", characteristicIds: [109, 110, 191, 192]),
        Dinosaur(id: 54, name: "Suchomimus", icon: "🦖", imageName: "dino-suchomimus", characteristicIds: [111, 112, 193, 194]),
    ]
    
    /// Diet per dinosaur for Dino Diets! (Herbivore, Carnivore, Piscivore, Insectivore, Omnivore). Child-friendly; used only in match-the-diet game.
    static let dinosaurDietById: [Int: String] = [
        1: "Carnivore", 2: "Herbivore", 3: "Herbivore", 4: "Carnivore", 5: "Herbivore", 6: "Piscivore",
        7: "Herbivore", 8: "Herbivore", 9: "Herbivore", 10: "Herbivore", 11: "Herbivore", 12: "Carnivore",
        13: "Herbivore", 14: "Herbivore", 15: "Herbivore", 16: "Omnivore", 17: "Herbivore", 18: "Carnivore",
        19: "Carnivore", 20: "Carnivore", 21: "Herbivore", 22: "Piscivore", 23: "Herbivore", 24: "Carnivore",
        25: "Herbivore", 26: "Insectivore", 27: "Carnivore", 28: "Herbivore", 29: "Carnivore", 30: "Insectivore",
        31: "Carnivore", 32: "Herbivore", 33: "Carnivore", 34: "Insectivore", 35: "Herbivore", 36: "Carnivore",
        37: "Carnivore", 38: "Carnivore", 39: "Carnivore", 40: "Herbivore", 41: "Carnivore", 42: "Carnivore",
        43: "Omnivore", 44: "Herbivore", 45: "Herbivore", 46: "Herbivore", 47: "Herbivore", 48: "Herbivore",
        49: "Herbivore", 50: "Herbivore", 51: "Herbivore", 52: "Herbivore", 53: "Herbivore", 54: "Piscivore",
    ]

    /// Estimated adult body mass in kg per dinosaur id (1–54). Used by Weigh and Balance games for seesaw ordering.
    static let dinosaurEstimatedWeightKgById: [Int: Double] = [
        1: 8_000,   2: 9_000,   3: 4_500,   4: 20,      5: 5_000,   6: 7_000,   7: 25_000,  8: 6_000,
        9: 3_500,   10: 2_700,  11: 4_500,  12: 50,     13: 4_000,  14: 15_000, 15: 100,    16: 400,
        17: 450,    18: 2_500,  19: 0.5,    20: 0.5,    21: 70_000, 22: 2_000,  23: 35_000, 24: 1_000,
        25: 3_000,  26: 3,      27: 70,     28: 15_000, 29: 25,     30: 0.5,    31: 13_000, 32: 2_500,
        33: 1,      34: 0.5,    35: 6_000,  36: 500,    37: 0.5,    38: 20,     39: 2_000,  40: 15_000,
        41: 1_500,  42: 2_000,  43: 40,     44: 18_000, 45: 2_000,  46: 3_000,  47: 3_500,  48: 3_000,
        49: 40,     50: 80,     51: 3_000,  52: 1_000,  53: 2_500,  54: 3_000,
    ]

    /// Clade per dinosaur (for Match the Dinosaur). Used so each round picks one dinosaur per clade for clear, varied choices.
    static let dinosaurCladeById: [Int: DinoClade] = [
        1: .theropod, 2: .ceratopsian, 3: .stegosaur, 4: .theropod, 5: .theropod, 6: .spinosaurid,
        7: .sauropod, 8: .ankylosaurid, 9: .hadrosaur, 10: .hadrosaur, 11: .ornithopod, 12: .theropod, 13: .hadrosaur,
        14: .sauropod, 15: .ornithopod, 16: .theropod, 17: .pachycephalosaur, 18: .theropod, 19: .theropod, 20: .theropod,
        21: .sauropod, 22: .spinosaurid, 23: .sauropod, 24: .theropod, 25: .ceratopsian, 26: .theropod, 27: .theropod,
        28: .sauropod, 29: .theropod, 30: .theropod, 31: .theropod, 32: .ceratopsian, 33: .theropod, 34: .theropod,
        35: .ceratopsian, 36: .theropod, 37: .theropod, 38: .theropod, 39: .theropod, 40: .sauropod, 41: .theropod,
        42: .theropod, 43: .theropod, 44: .sauropod, 45: .stegosaur, 46: .ankylosaurid, 47: .hadrosaur, 48: .hadrosaur,
        49: .pachycephalosaur, 50: .pachycephalosaur, 51: .ankylosaurid, 52: .stegosaur, 53: .ornithopod,
        54: .spinosaurid,
    ]
    
    // Full pool of available characteristics (can be expanded)
    // Image sets: dino-char-<characteristic> (e.g. dino-char-teeth, dino-char-crest)
    // Feathers: we use one type, "Feathers", with image dino-char-proto-feathers (proto-feathers). Diet traits (carnivore, herbivore, etc.) are not used here; reserved for a future game.
    static let allCharacteristics: [Characteristic] = [
        // T-Rex characteristics (Teeth, Smart; Footprints removed – use Two Feet / Four Feet for locomotion)
        Characteristic(id: 1, type: "Teeth", icon: "🦷", imageName: "dino-char-teeth", dinosaurId: 1),
        Characteristic(id: 24, type: "Smart", icon: "🧠", imageName: "dino-char-smart", dinosaurId: 1),
        // Triceratops characteristics
        Characteristic(id: 3, type: "Frill", icon: "🦎", imageName: "dino-char-frill", dinosaurId: 2),
        Characteristic(id: 4, type: "Horns", icon: "🦏", imageName: "dino-char-horns", dinosaurId: 2),
        Characteristic(id: 117, type: "Beak", icon: "🦜", imageName: "dino-char-beak", dinosaurId: 2),
        // Stegosaurus characteristics
        Characteristic(id: 5, type: "Plates", icon: "🔺", imageName: "dino-char-plates", dinosaurId: 3),
        Characteristic(id: 113, type: "Tail Spikes", icon: "🔺", imageName: "dino-char-tail-spikes", dinosaurId: 3),
        Characteristic(id: 114, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 3),
        Characteristic(id: 196, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 3),
        // Velociraptor characteristics
        Characteristic(id: 6, type: "Claws", icon: "🦅", imageName: "dino-char-claws", dinosaurId: 4),
        Characteristic(id: 7, type: "Fast", icon: "💨", imageName: "dino-char-fast", dinosaurId: 4),
        Characteristic(id: 23, type: "Toe Claw", icon: "🦅", imageName: "dino-char-toe-claw", dinosaurId: 4),
        // Therizinosaurus characteristics
        Characteristic(id: 8, type: "Long Claws", icon: "✂️", imageName: "dino-char-long-claws", dinosaurId: 5),
        Characteristic(id: 9, type: "Feathers", icon: "🪶", imageName: "dino-char-proto-feathers", dinosaurId: 5),
        // Spinosaurus characteristics
        Characteristic(id: 10, type: "Sail", icon: "⛵", imageName: "dino-char-sail", dinosaurId: 6),
        Characteristic(id: 11, type: "Swims", icon: "🏊", imageName: "dino-char-swims", dinosaurId: 6),
        Characteristic(id: 115, type: "Long Snout", icon: "🐊", imageName: "dino-char-long-snout", dinosaurId: 6),
        // Apatosaurus characteristics
        Characteristic(id: 12, type: "Long Neck", icon: "🦒", imageName: "dino-char-long-neck", dinosaurId: 7),
        Characteristic(id: 13, type: "Huge", icon: "🐘", imageName: "dino-char-huge", dinosaurId: 7),
        Characteristic(id: 116, type: "Long Tail", icon: "🦎", imageName: "dino-char-long-tail", dinosaurId: 7),
        // Ankylosaurus characteristics
        Characteristic(id: 14, type: "Armor", icon: "🛡️", imageName: "dino-char-armor", dinosaurId: 8),
        Characteristic(id: 15, type: "Tail Club", icon: "🔨", imageName: "dino-char-tail-club", dinosaurId: 8),
        // Corythosaurus characteristics
        Characteristic(id: 16, type: "Crest", icon: "🪖", imageName: "dino-char-crest", dinosaurId: 9),
        Characteristic(id: 17, type: "Duck Bill", icon: "🦆", imageName: "dino-char-duck-bill", dinosaurId: 9),
        // Parasaurolophus characteristics
        Characteristic(id: 18, type: "Crest", icon: "📯", imageName: "dino-char-crest", dinosaurId: 10),
        Characteristic(id: 19, type: "Duck Bill", icon: "🦆", imageName: "dino-char-duck-bill", dinosaurId: 10),
        // Iguanodon characteristics
        Characteristic(id: 20, type: "Thumb Spike", icon: "👍", imageName: "dino-char-thumb-spike", dinosaurId: 11),
        Characteristic(id: 118, type: "Beak", icon: "🦜", imageName: "dino-char-beak", dinosaurId: 11),
        // Troodon characteristics
        Characteristic(id: 21, type: "Smart", icon: "🧠", imageName: "dino-char-smart", dinosaurId: 12),
        Characteristic(id: 22, type: "Big Eyes", icon: "👀", imageName: "dino-char-big-eyes", dinosaurId: 12),
        // Edmontosaurus characteristics (hadrosaur; no bony crest — flat head / soft-tissue comb)
        Characteristic(id: 25, type: "Duck Bill", icon: "🦆", imageName: "dino-char-duck-bill", dinosaurId: 13),
        Characteristic(id: 27, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 13),
        // Dryosaurus (15)
        Characteristic(id: 28, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 15),
        Characteristic(id: 41, type: "Fast", icon: "💨", imageName: "dino-char-fast", dinosaurId: 15),
        // Masiakasaurus (38)
        Characteristic(id: 29, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 38),
        Characteristic(id: 42, type: "Teeth", icon: "🦷", imageName: "dino-char-teeth", dinosaurId: 38),
        // Torvosaurus (39)
        Characteristic(id: 30, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 39),
        Characteristic(id: 43, type: "Teeth", icon: "🦷", imageName: "dino-char-teeth", dinosaurId: 39),
        // Rapetosaurus (40)
        Characteristic(id: 31, type: "Long Neck", icon: "🦒", imageName: "dino-char-long-neck", dinosaurId: 40),
        Characteristic(id: 32, type: "Long Tail", icon: "🦎", imageName: "dino-char-long-tail", dinosaurId: 40),
        // Majungasaurus (41)
        Characteristic(id: 33, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 41),
        Characteristic(id: 44, type: "Teeth", icon: "🦷", imageName: "dino-char-teeth", dinosaurId: 41),
        // Allosaurus (42)
        Characteristic(id: 34, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 42),
        Characteristic(id: 35, type: "Horns", icon: "🦏", imageName: "dino-char-horns", dinosaurId: 42),
        // Oviraptor (43)
        Characteristic(id: 36, type: "Crest", icon: "🪖", imageName: "dino-char-crest", dinosaurId: 43),
        Characteristic(id: 37, type: "Feathers", icon: "🪶", imageName: "dino-char-proto-feathers", dinosaurId: 43),
        // Camarasaurus (14) — classic sauropod: long neck, long tail, four feet, huge
        Characteristic(id: 45, type: "Long Neck", icon: "🦒", imageName: "dino-char-long-neck", dinosaurId: 14),
        Characteristic(id: 46, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 14),
        Characteristic(id: 197, type: "Long Tail", icon: "🦎", imageName: "dino-char-long-tail", dinosaurId: 14),
        // Gallimimus (16)
        Characteristic(id: 47, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 16),
        Characteristic(id: 48, type: "Fast", icon: "💨", imageName: "dino-char-fast", dinosaurId: 16),
        // Pachycephalosaurus (17)
        Characteristic(id: 49, type: "Dome Head", icon: "🦎", imageName: "dino-char-dome-head", dinosaurId: 17),
        Characteristic(id: 50, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 17),
        // Albertosaurus (18)
        Characteristic(id: 51, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 18),
        Characteristic(id: 52, type: "Teeth", icon: "🦷", imageName: "dino-char-teeth", dinosaurId: 18),
        // Anchiornis (19)
        Characteristic(id: 53, type: "Feathers", icon: "🪶", imageName: "dino-char-proto-feathers", dinosaurId: 19),
        Characteristic(id: 54, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 19),
        // Archaeopteryx (20)
        Characteristic(id: 55, type: "Feathers", icon: "🪶", imageName: "dino-char-proto-feathers", dinosaurId: 20),
        Characteristic(id: 56, type: "Small", icon: "🐦", imageName: "dino-char-small", dinosaurId: 20),
        // Argentinosaurus (21)
        Characteristic(id: 57, type: "Long Neck", icon: "🦒", imageName: "dino-char-long-neck", dinosaurId: 21),
        Characteristic(id: 58, type: "Huge", icon: "🐘", imageName: "dino-char-huge", dinosaurId: 21),
        // Baryonyx (22)
        Characteristic(id: 59, type: "Long Snout", icon: "🐊", imageName: "dino-char-long-snout", dinosaurId: 22),
        Characteristic(id: 60, type: "Claws", icon: "🦅", imageName: "dino-char-claws", dinosaurId: 22),
        // Brachiosaurus (23)
        Characteristic(id: 61, type: "Long Neck", icon: "🦒", imageName: "dino-char-long-neck", dinosaurId: 23),
        Characteristic(id: 62, type: "Huge", icon: "🐘", imageName: "dino-char-huge", dinosaurId: 23),
        // Ceratosaurus (24)
        Characteristic(id: 63, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 24),
        Characteristic(id: 64, type: "Horns", icon: "🦏", imageName: "dino-char-horns", dinosaurId: 24),
        // Chasmosaurus (25)
        Characteristic(id: 65, type: "Frill", icon: "🦎", imageName: "dino-char-frill", dinosaurId: 25),
        Characteristic(id: 66, type: "Horns", icon: "🦏", imageName: "dino-char-horns", dinosaurId: 25),
        // Compsognathus (26)
        Characteristic(id: 67, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 26),
        Characteristic(id: 68, type: "Small", icon: "🐦", imageName: "dino-char-small", dinosaurId: 26),
        // Deinonychus (27)
        Characteristic(id: 69, type: "Claws", icon: "🦅", imageName: "dino-char-claws", dinosaurId: 27),
        Characteristic(id: 70, type: "Toe Claw", icon: "🦅", imageName: "dino-char-toe-claw", dinosaurId: 27),
        // Diplodocus (28)
        Characteristic(id: 71, type: "Long Neck", icon: "🦒", imageName: "dino-char-long-neck", dinosaurId: 28),
        Characteristic(id: 72, type: "Long Tail", icon: "🦎", imageName: "dino-char-long-tail", dinosaurId: 28),
        // Dromaeosaurus (29)
        Characteristic(id: 73, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 29),
        Characteristic(id: 74, type: "Claws", icon: "🦅", imageName: "dino-char-claws", dinosaurId: 29),
        // Eosinopteryx (30)
        Characteristic(id: 75, type: "Feathers", icon: "🪶", imageName: "dino-char-proto-feathers", dinosaurId: 30),
        Characteristic(id: 76, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 30),
        // Giganotosaurus (31)
        Characteristic(id: 77, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 31),
        Characteristic(id: 78, type: "Teeth", icon: "🦷", imageName: "dino-char-teeth", dinosaurId: 31),
        // Kosmoceratops (32)
        Characteristic(id: 79, type: "Frill", icon: "🦎", imageName: "dino-char-frill", dinosaurId: 32),
        Characteristic(id: 80, type: "Horns", icon: "🦏", imageName: "dino-char-horns", dinosaurId: 32),
        // Microraptor (33)
        Characteristic(id: 81, type: "Feathers", icon: "🪶", imageName: "dino-char-proto-feathers", dinosaurId: 33),
        Characteristic(id: 82, type: "Small", icon: "🐦", imageName: "dino-char-small", dinosaurId: 33),
        // Pedopenna (34)
        Characteristic(id: 83, type: "Feathers", icon: "🪶", imageName: "dino-char-proto-feathers", dinosaurId: 34),
        Characteristic(id: 84, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 34),
        // Torosaurus (35)
        Characteristic(id: 85, type: "Frill", icon: "🦎", imageName: "dino-char-frill", dinosaurId: 35),
        Characteristic(id: 86, type: "Horns", icon: "🦏", imageName: "dino-char-horns", dinosaurId: 35),
        // Utahraptor (36)
        Characteristic(id: 87, type: "Claws", icon: "🦅", imageName: "dino-char-claws", dinosaurId: 36),
        Characteristic(id: 88, type: "Toe Claw", icon: "🦅", imageName: "dino-char-toe-claw", dinosaurId: 36),
        // Xiaotingia (37)
        Characteristic(id: 89, type: "Feathers", icon: "🪶", imageName: "dino-char-proto-feathers", dinosaurId: 37),
        Characteristic(id: 90, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 37),
        // Brontosaurus (44)
        Characteristic(id: 91, type: "Long Neck", icon: "🦒", imageName: "dino-char-long-neck", dinosaurId: 44),
        Characteristic(id: 92, type: "Long Tail", icon: "🦎", imageName: "dino-char-long-tail", dinosaurId: 44),
        // Kentrosaurus (45) – stegosaur
        Characteristic(id: 93, type: "Tail Spikes", icon: "🔺", imageName: "dino-char-tail-spikes", dinosaurId: 45),
        Characteristic(id: 94, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 45),
        // Edmontonia (46) – ankylosaurid (nodosaurid; armor, no club)
        Characteristic(id: 95, type: "Armor", icon: "🛡️", imageName: "dino-char-armor", dinosaurId: 46),
        Characteristic(id: 96, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 46),
        // Lambeosaurus (47) – hadrosaur
        Characteristic(id: 97, type: "Crest", icon: "🪖", imageName: "dino-char-crest", dinosaurId: 47),
        Characteristic(id: 98, type: "Duck Bill", icon: "🦆", imageName: "dino-char-duck-bill", dinosaurId: 47),
        // Maiasaura (48) – hadrosaur
        Characteristic(id: 99, type: "Duck Bill", icon: "🦆", imageName: "dino-char-duck-bill", dinosaurId: 48),
        Characteristic(id: 100, type: "Crest", icon: "🪖", imageName: "dino-char-crest", dinosaurId: 48),
        // Stegoceras (49) – pachycephalosaur
        Characteristic(id: 101, type: "Dome Head", icon: "🦎", imageName: "dino-char-dome-head", dinosaurId: 49),
        Characteristic(id: 102, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 49),
        // Stygimoloch (50) – pachycephalosaur
        Characteristic(id: 103, type: "Dome Head", icon: "🦎", imageName: "dino-char-dome-head", dinosaurId: 50),
        Characteristic(id: 104, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 50),
        // Nodosaurus (51) – ankylosaurid (nodosaurid; armor, no club)
        Characteristic(id: 105, type: "Armor", icon: "🛡️", imageName: "dino-char-armor", dinosaurId: 51),
        Characteristic(id: 106, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 51),
        // Huayangosaurus (52) – stegosaur
        Characteristic(id: 107, type: "Plates", icon: "🔺", imageName: "dino-char-plates", dinosaurId: 52),
        Characteristic(id: 108, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 52),
        // Ouranosaurus (53) – ornithopod (sail-backed)
        Characteristic(id: 109, type: "Sail", icon: "⛵", imageName: "dino-char-sail", dinosaurId: 53),
        Characteristic(id: 110, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 53),
        // Suchomimus (54) – spinosaurid
        Characteristic(id: 111, type: "Long Snout", icon: "🐊", imageName: "dino-char-long-snout", dinosaurId: 54),
        Characteristic(id: 112, type: "Swims", icon: "🏊", imageName: "dino-char-swims", dinosaurId: 54),
        // One characteristic per dinosaur for feet/size/beak (so rounds can pick distinct traits)
        Characteristic(id: 119, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 1),
        Characteristic(id: 120, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 1),
        Characteristic(id: 121, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 2),
        Characteristic(id: 122, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 2),
        Characteristic(id: 123, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 4),
        Characteristic(id: 124, type: "Small", icon: "🐦", imageName: "dino-char-small", dinosaurId: 4),
        Characteristic(id: 125, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 5),
        Characteristic(id: 126, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 5),
        Characteristic(id: 127, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 6),
        Characteristic(id: 128, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 6),
        Characteristic(id: 129, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 7),
        Characteristic(id: 130, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 8),
        Characteristic(id: 131, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 8),
        Characteristic(id: 132, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 9),
        Characteristic(id: 133, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 9),
        Characteristic(id: 134, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 10),
        Characteristic(id: 135, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 10),
        Characteristic(id: 136, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 11),
        Characteristic(id: 137, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 11),
        Characteristic(id: 138, type: "Small", icon: "🐦", imageName: "dino-char-small", dinosaurId: 12),
        Characteristic(id: 139, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 13),
        Characteristic(id: 140, type: "Huge", icon: "🐘", imageName: "dino-char-huge", dinosaurId: 14),
        Characteristic(id: 141, type: "Beak", icon: "🦜", imageName: "dino-char-beak", dinosaurId: 15),
        Characteristic(id: 142, type: "Small", icon: "🐦", imageName: "dino-char-small", dinosaurId: 15),
        Characteristic(id: 143, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 16),
        Characteristic(id: 144, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 17),
        Characteristic(id: 145, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 18),
        Characteristic(id: 146, type: "Small", icon: "🐦", imageName: "dino-char-small", dinosaurId: 19),
        Characteristic(id: 147, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 20),
        Characteristic(id: 148, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 21),
        Characteristic(id: 149, type: "Long Tail", icon: "🦎", imageName: "dino-char-long-tail", dinosaurId: 21),
        Characteristic(id: 150, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 22),
        Characteristic(id: 151, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 22),
        Characteristic(id: 152, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 23),
        Characteristic(id: 153, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 24),
        Characteristic(id: 154, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 24),
        Characteristic(id: 155, type: "Beak", icon: "🦜", imageName: "dino-char-beak", dinosaurId: 25),
        Characteristic(id: 156, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 25),
        Characteristic(id: 157, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 25),
        Characteristic(id: 158, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 27),
        Characteristic(id: 159, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 27),
        Characteristic(id: 160, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 28),
        Characteristic(id: 161, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 29),
        Characteristic(id: 162, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 31),
        Characteristic(id: 163, type: "Beak", icon: "🦜", imageName: "dino-char-beak", dinosaurId: 32),
        Characteristic(id: 164, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 32),
        Characteristic(id: 165, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 32),
        Characteristic(id: 166, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 33),
        Characteristic(id: 167, type: "Small", icon: "🐦", imageName: "dino-char-small", dinosaurId: 34),
        Characteristic(id: 168, type: "Beak", icon: "🦜", imageName: "dino-char-beak", dinosaurId: 35),
        Characteristic(id: 169, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 35),
        Characteristic(id: 170, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 35),
        Characteristic(id: 171, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 36),
        Characteristic(id: 172, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 36),
        Characteristic(id: 173, type: "Small", icon: "🐦", imageName: "dino-char-small", dinosaurId: 37),
        Characteristic(id: 174, type: "Small", icon: "🐦", imageName: "dino-char-small", dinosaurId: 38),
        Characteristic(id: 175, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 39),
        Characteristic(id: 176, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 40),
        Characteristic(id: 195, type: "Huge", icon: "🐘", imageName: "dino-char-huge", dinosaurId: 40),
        Characteristic(id: 177, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 41),
        Characteristic(id: 178, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 42),
        Characteristic(id: 179, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 43),
        Characteristic(id: 180, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 44),
        Characteristic(id: 181, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 45),
        Characteristic(id: 182, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 46),
        Characteristic(id: 183, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 47),
        Characteristic(id: 184, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 47),
        Characteristic(id: 185, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 48),
        Characteristic(id: 186, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 48),
        Characteristic(id: 187, type: "Small", icon: "🐦", imageName: "dino-char-small", dinosaurId: 49),
        Characteristic(id: 189, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 51),
        Characteristic(id: 190, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 52),
        Characteristic(id: 191, type: "Beak", icon: "🦜", imageName: "dino-char-beak", dinosaurId: 53),
        Characteristic(id: 192, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 53),
        Characteristic(id: 193, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 54),
        Characteristic(id: 194, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 54),
    ]
    
    /// Diet characteristics for Dino Diets!: one per dinosaur (type = Herbivore/Carnivore/etc.). Images from Assets/Dinosaur-Diets with prefix diet- (e.g. diet-herbivore).
    static var allDietCharacteristics: [Characteristic] {
        allDinosaurs.compactMap { d in
            guard let diet = dinosaurDietById[d.id] else { return nil }
            let imageName = "diet-\(diet.lowercased())"
            let icon: String = {
                switch diet {
                case "Herbivore": return "🌿"
                case "Carnivore": return "🥩"
                case "Piscivore": return "🐟"
                case "Insectivore": return "🦗"
                case "Omnivore": return "🍎"
                default: return "🍽️"
                }
            }()
            return Characteristic(id: 200 + d.id - 1, type: diet, icon: icon, imageName: imageName, dinosaurId: d.id)
        }
    }

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

    /// Dino Diets!: match 3 dinosaurs to the 5 diets (always all 5 shown). Same gameplay as Match the Dinosaur; easier because only 5 options.
    static var dinoDietFeatures: MatchingGameConfig {
        dinoDietFeatures(excluding: [])
    }

    static func dinoDietFeatures(excluding usedCreatureIds: Set<Int>) -> MatchingGameConfig {
        MatchingGameConfig.createRandomDiet(
            from: allDinosaurs,
            allDietCharacteristics: allDietCharacteristics,
            id: "match-the-diet",
            title: "Dino Diets!",
            introAudio: "game-intro-dino-diets",
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
        Characteristic(id: 108, type: "Huge", icon: "🐘", imageName: "ptero-char-huge", dinosaurId: 103),
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
