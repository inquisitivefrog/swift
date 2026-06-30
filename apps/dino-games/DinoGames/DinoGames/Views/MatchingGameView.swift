//
//  MatchingGameView.swift
//  DinoGames
//
//  Created by Timothy Stilwell on 1/23/26.
//

import SwiftUI
@preconcurrency import AVFoundation
import UIKit
import Combine

// Track specific dinosaur-characteristic pairs that have been matched
struct MatchedPair: Hashable {
    let dinosaurId: Int
    let characteristicId: Int
}

// Shared audio manager for playing recorded audio files
@MainActor
class SpeechManager: NSObject, ObservableObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var currentPlayer: AVAudioPlayer?
    private var secondaryPlayer: AVAudioPlayer? // For simultaneous play (e.g. crowd-cheering + winner name)
    private var lastPlayTime: Date = Date.distantPast
    private let minimumPlayInterval: TimeInterval = 0.3 // Prevent rapid-fire audio
    
    // Callback for when audio finishes playing
    var onAudioFinished: (() -> Void)?
    @Published var isPlaying: Bool = false
    
    /// Safety timeout when audio session fails and delegate never fires (e.g. ATAudioSession activation failed).
    private static let completionTimeoutSeconds: TimeInterval = 20
    private var completionTimeoutWorkItem: DispatchWorkItem?
    
    /// Folder for characteristic audio: "Dino-Characteristics" or "Ptero-Characteristics" (set by MatchingGameView so shared words like "crest" load from the right place).
    var characteristicSubfolder: String = "Dino-Characteristics"
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    private func scheduleCompletionTimeout() {
        cancelCompletionTimeout()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.completionTimeoutWorkItem = nil
                self.isPlaying = false
                let cb = self.onAudioFinished
                self.onAudioFinished = nil
                cb?()
            }
        }
        completionTimeoutWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.completionTimeoutSeconds, execute: work)
    }
    
    private func cancelCompletionTimeout() {
        completionTimeoutWorkItem?.cancel()
        completionTimeoutWorkItem = nil
    }
    
    /// Returns bundle URL for a given audio key (e.g. "crowd-cheering", "Allosaurus") if found; nil otherwise.
    func urlForAudio(key: String) -> URL? {
        let normalized = key.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
        // Prefer `Dinosaur-Clades/clade-{slug}.m4a` (clear stem on disk); fall back to legacy `Dinosaur-Clades/{slug}.m4a`.
        if normalized.hasPrefix("dino-clade-") {
            let slug = String(normalized.dropFirst("dino-clade-".count))
            let preferredPath = "Dinosaur-Clades/clade-\(slug)"
            if let url = resolveURL(forPath: preferredPath) { return url }
            if let legacyPath = audioFilePath(for: key) {
                return resolveURL(forPath: legacyPath)
            }
            return nil
        }
        if normalized.hasPrefix("ptero-footprints-") {
            if let url = resolveURL(forPath: "Ptero-Footprints/\(normalized)") { return url }
            if let legacyPath = audioFilePath(for: key) {
                return resolveURL(forPath: legacyPath)
            }
            return nil
        }
        if normalized.hasPrefix("marine-footprints-") {
            let locomotion = String(normalized.dropFirst("marine-footprints-".count))
            if let url = resolveURL(forPath: "Marine-Footprints/\(locomotion)") { return url }
            if let legacyPath = audioFilePath(for: key) {
                return resolveURL(forPath: legacyPath)
            }
            return nil
        }
        if normalized.hasPrefix("ptero-clade-") {
            let slug = String(normalized.dropFirst("ptero-clade-".count))
            let preferredPath = "Pterosaur-Clades/clade-\(slug)"
            if let url = resolveURL(forPath: preferredPath) { return url }
            if let legacyPath = audioFilePath(for: key) {
                return resolveURL(forPath: legacyPath)
            }
            return nil
        }
        if normalized.hasPrefix("marine-clade-") {
            let slug = String(normalized.dropFirst("marine-clade-".count))
            let preferredPath = "Marine-Reptile-Clades/clade-\(slug)"
            if let url = resolveURL(forPath: preferredPath) { return url }
            if let legacyPath = audioFilePath(for: key) {
                return resolveURL(forPath: legacyPath)
            }
            return nil
        }
        // Weigh the Marine Reptile card / transition uses `game-weigh-the-marine-reptile`; allow alternate stem without “the”.
        if normalized == "game-weigh-the-marine-reptile" {
            let candidates = [
                "Games/game-weigh-the-marine-reptile",
                "Games/game-weigh-marine-reptile",
            ]
            for path in candidates {
                if let url = resolveURL(forPath: path) { return url }
            }
            return nil
        }
        // Level 2 intro may be bundled without numeric prefix (`more-really-easy-games.m4a`).
        if normalized == "level-2-more-really-easy-games" {
            let candidates = [
                "Levels/level-2-more-really-easy-games",
                "Levels/more-really-easy-games",
            ]
            for path in candidates {
                if let url = resolveURL(forPath: path) { return url }
            }
            return nil
        }
        if normalized.hasPrefix("ptero-flora-") {
            for plant in pteroFloraPlants where plant.audioKey == normalized {
                if let url = resolveURL(forPath: "Ptero-Flora/\(plant.formationFolder)/\(plant.audioKey)") {
                    return url
                }
            }
            return nil
        }
        if normalized.hasPrefix("marine-flora-") {
            for plant in marineFloraPlants where plant.audioKey == normalized {
                if let url = resolveURL(forPath: "Marine-Flora/\(plant.formationFolder)/\(plant.audioKey)") {
                    return url
                }
            }
            return nil
        }
        // Flora category hints: Audio/{Pack}-Flora/hints/{key}.m4a
        if normalized.hasPrefix("dino-hint-") {
            if let url = resolveURL(forPath: "Dino-Flora/hints/\(normalized)") { return url }
            return nil
        }
        if normalized.hasPrefix("ptero-hint-") {
            if let url = resolveURL(forPath: "Ptero-Eggs/hints/\(normalized)") { return url }
            if let url = resolveURL(forPath: "Ptero-Flora/hints/\(normalized)") { return url }
            return nil
        }
        if normalized.hasPrefix("marine-hint-") {
            if let url = resolveURL(forPath: "Marine-Flora/hints/\(normalized)") { return url }
            return nil
        }
        // Legacy dino flora hint keys (flora-hint-* → Dino-Flora/hints/dino-hint-*)
        if normalized.hasPrefix("flora-hint-") {
            let slug = String(normalized.dropFirst("flora-hint-".count))
            if let url = resolveURL(forPath: "Dino-Flora/hints/dino-hint-\(slug)") { return url }
            return nil
        }
        // Dino Diets!: diet option clips under `Audio/Dino-Diets/` (`dino-diet-*`; legacy `diet-*` still resolved).
        if normalized.hasPrefix("dino-diet-") {
            if let url = resolveURL(forPath: "Dino-Diets/\(normalized)") { return url }
            return nil
        }
        if normalized.hasPrefix("diet-") {
            let slug = String(normalized.dropFirst("diet-".count))
            if let url = resolveURL(forPath: "Dino-Diets/dino-diet-\(slug)") { return url }
            return nil
        }
        // Ptero Diets!: diet option clips under `Audio/Ptero-Diets/` (`ptero-diets-*`; legacy `ptero-diet-*` still resolved).
        if normalized.hasPrefix("ptero-diets-") || normalized.hasPrefix("ptero-diet-") {
            if let url = resolveURL(forPath: "Ptero-Diets/\(normalized)") { return url }
            return nil
        }
        // Marine Diets!: diet option clips under `Audio/Marine-Diets/` (`marine-diets-*`).
        if normalized.hasPrefix("marine-diets-") {
            if let url = resolveURL(forPath: "Marine-Diets/\(normalized)") { return url }
            return nil
        }
        // Racing clips: `Games/{file}` or `Games/racing-dinosaurs|pterosaurs/{file}` (shared keys like outside-track may live in either pack folder).
        if normalized.hasPrefix("game-racing-") {
            if let url = resolveURL(forPath: "Games/\(normalized)") { return url }
        }
        if normalized == "racing-pterosaurs" {
            if let url = resolveURL(forPath: "Games/game-racing-pterosaurs") { return url }
        }
        if normalized == "racing-marine-reptiles" || normalized == "racing marine reptiles" {
            if let url = resolveURL(forPath: "Games/game-racing-marine-reptiles") { return url }
        }
        if normalized == "racing-dinosaurs" || normalized == "racing dinosaurs" {
            if let url = resolveURL(forPath: "Games/game-racing-dinosaurs") { return url }
        }
        // Dino Eggs UI clips: `Games/{file}` or `Games/dino-eggs/{file}` (egg morphotype keys `dino-eggs-*` stay under `Audio/Eggs/`).
        if normalized.hasPrefix("game-dino-eggs") {
            if let url = resolveURL(forPath: "Games/\(normalized)") { return url }
        }
        if normalized == "dino-eggs" {
            if let url = resolveURL(forPath: "Games/game-dino-eggs") { return url }
        }
        if normalized.hasPrefix("game-marine-eggs") {
            if let url = resolveURL(forPath: "Games/\(normalized)") { return url }
        }
        if normalized == "marine-eggs-shape" {
            if let url = resolveURL(forPath: "Marine-Eggs/hints/marine-eggs-shape") { return url }
        }
        if normalized == "marine-eggs" {
            if let url = resolveURL(forPath: "Games/game-marine-eggs") { return url }
        }
        // Dino / Ptero / Marine Ages!: bundled under `Assets/Audio/Games/` (period covers, find-in, hints).
        if normalized.hasPrefix("game-dino-ages")
            || normalized.hasPrefix("game-ptero-ages")
            || normalized.hasPrefix("game-marine-ages") {
            if let url = resolveURL(forPath: "Games/\(normalized)") { return url }
        }
        // Dino Fossil Hunt site clips: `Games/{file}` or `Games/dino-fossil-hunt/{file}` (hint keys → `Audio/Fossil/`).
        if normalized.hasPrefix("game-dino-fossil-hunt") && !normalized.hasPrefix("game-dino-fossil-hunt-hint") {
            if let url = resolveURL(forPath: "Games/\(normalized)") { return url }
        }
        if normalized == "dino-fossil-hunt" {
            if let url = resolveURL(forPath: "Games/game-dino-fossil-hunt") { return url }
        }
        if normalized.hasPrefix("game-dino-matrix") || normalized.hasPrefix("game-ptero-matrix") || normalized.hasPrefix("game-marine-matrix") {
            if let url = resolveURL(forPath: "Games/\(normalized)") { return url }
        }
        // Matrix stone narration (`dino-limestone`, etc.) under `Audio/*-Materials/` — before generic `dino-*` dinosaur routing.
        if let matrixPath = Self.matrixMaterialAudioPath(for: normalized) {
            if let url = resolveURL(forPath: matrixPath) { return url }
        }
        // Dino Flora plants: `dino-flora-{formation}-{taxon}` → `Dino-Flora/{FormationFolder}/{stem}.m4a`
        if normalized.hasPrefix("dino-flora-") {
            for plant in dinoFloraPlants where plant.audioKey == normalized {
                if let url = resolveURL(forPath: "Dino-Flora/\(plant.formationFolder)/\(plant.audioKey)") {
                    return url
                }
            }
        }
        // Legacy dino flora keys (`flora-{slug}`) during transition — map via plant registry when possible.
        if normalized.hasPrefix("flora-") && !normalized.hasPrefix("flora-hint-") {
            let legacySlug = String(normalized.dropFirst("flora-".count))
            if let plant = dinoFloraPlants.first(where: { $0.taxon == legacySlug || $0.id == legacySlug }) {
                if let url = resolveURL(forPath: "Dino-Flora/\(plant.formationFolder)/\(plant.audioKey)") {
                    return url
                }
            }
        }
        guard let path = audioFilePath(for: key) else { return nil }
        return resolveURL(forPath: path)
    }

    /// Tool name clips under `Assets/Audio/Tools/<category>/` — tries `field-{slug}` then `{slug}` in each folder (matches on-disk layout).
    private static let toolsAudioSubdirectories: [String] = [
        "discovery", "excavate", "preserve", "transport",
        "basecamp", "cleanup", "paperwork",
        "lab", "art",
    ]

    /// Nested folders under `Assets/Audio/Games/` (game-specific packs). Flat `Games/{file}` is tried first; then each subfolder.
    private static let gamesNestedSubfolders: [String] = [
        "racing-dinosaurs",
        "racing-pterosaurs",
        "racing-marine-reptiles",
        "dino-eggs",
        "dino-fossil-hunt",
    ]

    /// Order for nested `Games/` lookup: prefer the pack folder that matches the filename prefix.
    private static func gamesNestedSubfolders(forFileName fileName: String) -> [String] {
        let stem = fileName.lowercased()
        let preferred: String?
        if stem.hasPrefix("game-racing-marine-reptiles") || stem == "game-racing-marine-reptiles" {
            preferred = "racing-marine-reptiles"
        } else if stem.hasPrefix("game-racing-pterosaurs") || stem == "game-racing-pterosaurs" {
            preferred = "racing-pterosaurs"
        } else if stem.hasPrefix("game-racing-dinosaurs") || stem == "game-racing-dinosaurs" {
            preferred = "racing-dinosaurs"
        } else if stem.hasPrefix("game-dino-eggs") {
            preferred = "dino-eggs"
        } else if stem.hasPrefix("game-dino-fossil-hunt") {
            preferred = "dino-fossil-hunt"
        } else {
            preferred = nil
        }
        guard let preferred else { return gamesNestedSubfolders }
        var ordered = [preferred]
        ordered.append(contentsOf: gamesNestedSubfolders.filter { $0 != preferred })
        return ordered
    }

    /// Looks up `Tools/{subdir}/field-{slug}` then `Tools/{subdir}/{slug}`; returns first hit (e.g. Dino Fossil Hunt intro walk + taps).
    func urlForToolsAudio(slug: String) -> URL? {
        let slug = slug.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !slug.isEmpty else { return nil }
        let bases = ["field-\(slug)", slug]
        for subdir in Self.toolsAudioSubdirectories {
            for base in bases {
                let path = "Tools/\(subdir)/\(base)"
                if let url = resolveURL(forPath: path) { return url }
            }
        }
        return nil
    }

    /// Direct bundle lookup for an exact relative path under `Assets/Audio/` (no fuzzy search, no nested `Games/` fallbacks).
    private func bundleURLForExactAudioPath(_ audioPath: String) -> URL? {
        let fileName = (audioPath as NSString).lastPathComponent
        let paths = [
            "DinoGames/Assets/Audio/\(audioPath)",
            "Assets/Audio/\(audioPath)",
            "assets/Audio/\(audioPath)",
            "Audio/\(audioPath)",
            audioPath,
            fileName,
        ]
        for resourcePath in paths {
            for ext in ["m4a", "mp3", "wav"] {
                if let url = Bundle.main.url(forResource: resourcePath, withExtension: ext) { return url }
            }
        }
        if audioPath.contains("/") {
            let pathDir = (audioPath as NSString).deletingLastPathComponent
            let subdirs = [
                "Audio/\(pathDir)",
                "Assets/Audio/\(pathDir)",
                "DinoGames/Assets/Audio/\(pathDir)",
            ]
            for subdir in subdirs {
                for ext in ["m4a", "mp3", "wav"] {
                    if let url = Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: subdir) { return url }
                }
            }
        }
        return nil
    }

    /// Resolve path (e.g. "Feedback/crowd-cheering") to first found bundle URL (.m4a, .mp3, or .wav).
    private func resolveURL(forPath audioPath: String) -> URL? {
        if let url = bundleURLForExactAudioPath(audioPath) { return url }
        if let url = Self.resolveMatrixMaterialLegacyURL(forPath: audioPath, lookup: bundleURLForExactAudioPath) {
            return url
        }
        if audioPath.hasPrefix("Dino-Materials/") {
            let legacy = (audioPath as NSString).replacingOccurrences(of: "Dino-Materials/", with: "Materials/")
            if let url = bundleURLForExactAudioPath(legacy) { return url }
        } else if audioPath.hasPrefix("Materials/") {
            let preferred = (audioPath as NSString).replacingOccurrences(of: "Materials/", with: "Dino-Materials/")
            if let url = bundleURLForExactAudioPath(preferred) { return url }
        }
        if audioPath.hasPrefix("Games/") {
            let fileName = (audioPath as NSString).lastPathComponent
            for nested in Self.gamesNestedSubfolders(forFileName: fileName) {
                if let url = bundleURLForExactAudioPath("Games/\(nested)/\(fileName)") { return url }
            }
        }
        let fileName = (audioPath as NSString).lastPathComponent
        if let resourcePath = Bundle.main.resourcePath, let enumerator = FileManager.default.enumerator(atPath: resourcePath) {
            // Require the parent folder in the match path so e.g. `Dinosaur-Clades/stegosaur` does not pick up
            // `Eggs/dino-eggs-stegosaur.m4a` (same basename suffix) during fuzzy search.
            let requiredSubdir: String?
            if audioPath.contains("/") {
                let dir = ((audioPath as NSString).deletingLastPathComponent as String).lowercased()
                requiredSubdir = "/\(dir)/"
            } else {
                requiredSubdir = nil
            }
            let fileStem = fileName.lowercased()
            var suffixFallbackMatches: [String] = []
            while let file = enumerator.nextObject() as? String {
                let lower = file.lowercased()
                if let sub = requiredSubdir, !lower.contains(sub) { continue }
                let basename = (file as NSString).lastPathComponent.lowercased()
                let ext = (basename as NSString).pathExtension.lowercased()
                guard ["m4a", "mp3", "wav"].contains(ext) else { continue }
                let stem = (basename as NSString).deletingPathExtension
                // Prefer exact basename stem so we never pick the wrong species when multiple files share a suffix.
                if stem == fileStem {
                    return URL(fileURLWithPath: (resourcePath as NSString).appendingPathComponent(file))
                }
                // Legacy: longer stems that end with the requested stem (e.g. `ptero-basal-rhamphorhynchus` for key `ptero-rhamphorhynchus`).
                if stem.hasSuffix(fileStem), stem.count > fileStem.count {
                    suffixFallbackMatches.append(file)
                }
            }
            // If several suffix matches exist (e.g. `ptero-pteranodon` vs `ptero-ornitho-pteranodon` for key `ptero-pteranodon`), prefer the shortest stem.
            if let best = suffixFallbackMatches.min(by: {
                let a = (($0 as NSString).lastPathComponent as NSString).deletingPathExtension.count
                let b = (($1 as NSString).lastPathComponent as NSString).deletingPathExtension.count
                return a < b
            }) {
                return URL(fileURLWithPath: (resourcePath as NSString).appendingPathComponent(best))
            }
        }
        return nil
    }

    /// Play two audio files simultaneously; calls whenLongestFinished after the longer one ends (plus short buffer).
    func playTogether(url1: URL, url2: URL, whenLongestFinished: @escaping () -> Void) {
        ensureAudioSessionActive()
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
        cancelCompletionTimeout()
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
    
    /// Maps a body-segment slug to `Audio/Body/{stem}.m4a` filename stem (Whose Bones?).
    private func bodySegmentAudioStem(_ slug: String) -> String {
        switch slug {
        case "rib-cage", "ribs", "ribcage", "dorsal-vertebrae": return "ribcage"
        case "shoulder", "shoulders", "shoulder-blade", "shoulder-blades": return "shoulder"
        case "fore-leg", "foreleg": return "foreleg"
        case "hind-leg", "hindleg": return "hindleg"
        case "cervical-vertebrae": return "neck"
        default: return slug
        }
    }

    private static let dinoMatrixMaterialStems: Set<String> = [
        "limestone", "mudstone", "sandstone", "siltstone", "tuff", "shale",
        "ironstone", "claystone", "lignite", "conglomerate",
    ]
    private static let pteroMatrixMaterialStems: Set<String> = [
        "bentonite", "chalk", "lignite", "sandstone", "shale", "tuff",
    ]
    private static let marineMatrixMaterialStems: Set<String> = [
        "chalk", "claystone", "ironstone", "limestone", "phosphorite", "shale", "tuff",
    ]

    /// Matrix stone keys (`dino-limestone`, bare `limestone`, etc.) → `Audio/{Category}-Materials/{prefix}-{stem}.m4a`.
    /// Must run before generic `dino-*` / `ptero-*` / `marine-*` dinosaur name routing.
    private static func matrixMaterialAudioPath(for normalized: String) -> String? {
        func prefixedPath(folder: String, prefix: String, stem: String) -> String {
            "\(folder)/\(prefix)-\(stem)"
        }
        if normalized.hasPrefix("dino-") {
            let stem = String(normalized.dropFirst("dino-".count))
            if dinoMatrixMaterialStems.contains(stem) {
                return prefixedPath(folder: "Dino-Materials", prefix: "dino", stem: stem)
            }
        }
        if dinoMatrixMaterialStems.contains(normalized) {
            return prefixedPath(folder: "Dino-Materials", prefix: "dino", stem: normalized)
        }
        if normalized.hasPrefix("ptero-") {
            let stem = String(normalized.dropFirst("ptero-".count))
            if pteroMatrixMaterialStems.contains(stem) {
                return prefixedPath(folder: "Ptero-Materials", prefix: "ptero", stem: stem)
            }
        }
        if normalized.hasPrefix("marine-") {
            let stem = String(normalized.dropFirst("marine-".count))
            if marineMatrixMaterialStems.contains(stem) {
                return prefixedPath(folder: "Marine-Materials", prefix: "marine", stem: stem)
            }
        }
        return nil
    }

    /// Tries `{folder}/{prefix}-{stem}` ↔ `{folder}/{stem}` for matrix material folders.
    private static func resolveMatrixMaterialLegacyURL(
        forPath audioPath: String,
        lookup: (String) -> URL?
    ) -> URL? {
        let matrixFolders: [(folder: String, prefix: String)] = [
            ("Dino-Materials", "dino-"),
            ("Ptero-Materials", "ptero-"),
            ("Marine-Materials", "marine-"),
        ]
        for entry in matrixFolders where audioPath.hasPrefix("\(entry.folder)/") {
            let fileName = (audioPath as NSString).lastPathComponent
            if fileName.hasPrefix(entry.prefix) {
                let without = String(fileName.dropFirst(entry.prefix.count))
                if let url = lookup("\(entry.folder)/\(without)") { return url }
            } else if let url = lookup("\(entry.folder)/\(entry.prefix)\(fileName)") { return url }
        }
        return nil
    }

    // Map text to audio file paths (case-insensitive matching)
    private func audioFilePath(for text: String) -> String? {
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "!", with: "")

        if let matrixPath = Self.matrixMaterialAudioPath(for: normalized) {
            return matrixPath
        }
        
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
        // Dino Diets!: dinosaur diet clips (Audio/Dino-Diets/dino-diet-{slug}.m4a; legacy diet-* still resolved)
        if normalized.hasPrefix("dino-diet-") {
            return "Dino-Diets/\(normalized)"
        }
        if normalized.hasPrefix("diet-") {
            let slug = String(normalized.dropFirst("diet-".count))
            return "Dino-Diets/dino-diet-\(slug)"
        }
        // Ptero Diets!: pterosaur diet clips (Audio/Ptero-Diets/ptero-diets-{slug}.m4a; legacy ptero-diet-* still resolved)
        if normalized.hasPrefix("ptero-diets-") || normalized.hasPrefix("ptero-diet-") {
            return "Ptero-Diets/\(normalized)"
        }
        // Marine Diets!: marine reptile diet clips (Audio/Marine-Diets/marine-diets-{slug}.m4a)
        if normalized.hasPrefix("marine-diets-") {
            return "Marine-Diets/\(normalized)"
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
            // Canonical catalog + audio stem: `ptero-azhd-quetzalcoatlus` (same as creature imageName).
            return "Pterosaurs/ptero-azhd-quetzalcoatlus"
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
        case "is-longer", "is longer":
            return "Feedback/is-longer"
        case "they-both-weigh-about-the-same", "they both weigh about the same":
            return "Feedback/they-both-weigh-about-the-same"
        case "they-are-about-the-same-height", "they are about the same height":
            return "Feedback/they-are-about-the-same-height"
        case "about-the-same-length", "about the same length":
            return "Feedback/about-the-same-length"
        case "is-as-tall-as", "is as tall as":
            return "Feedback/is-as-tall-as"
        case "and":
            return "Feedback/and"
        // Measure the Dinosaur: count before dinosaur name when stack has multiple (e.g. "3 T-Rex"); keys "1"–"5" → Feedback/1.m4a etc.
        case "1": return "Feedback/1"
        case "2": return "Feedback/2"
        case "3": return "Feedback/3"
        case "4": return "Feedback/4"
        case "5": return "Feedback/5"
        case "you-cannot-choose-that-one-now", "you cannot choose that one now":
            return "Feedback/you-cannot-choose-that-one-now"
        case "thats-too-small-to-see", "that's too small to see", "too small to see":
            return "Feedback/thats-too-small-to-see"
        case "thats-too-big-to-see", "that's too big to see", "too big to see":
            return "Feedback/thats-too-big-to-see"

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
        case "game-name-that-marine-reptile-thats-right":
            return "Games/game-name-that-marine-reptile-thats-right"
        case "try-again", "try again":
            return "Feedback/try-again"
        case "game-name-that-marine-reptile-try-again":
            return "Games/game-name-that-marine-reptile-try-again"
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
        case "cover-both", "cover both":
            return "Cover/cover-both"
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
        case "game-name-that-marine-reptile-good-job":
            return "Games/game-name-that-marine-reptile-good-job"
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
        case "game-measure-close-enough-for-government-work", "close enough for government work":
            return "Feedback/game-measure-close-enough-for-government-work"
        case "game-measure-you-cant-be-serious", "game measure you cant be serious":
            return "Games/game-measure-you-cant-be-serious"
        case "game-measure-that-dinosaur-is-too-tall", "game measure that dinosaur is too tall":
            return "Games/game-measure-that-dinosaur-is-too-tall"
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
        case "marine reptiles", "marine-reptiles", "category-sea", "sea",
             "mosasaurs", "category-mosasaurs",
             "plesiosaurs", "category-plesiosaurs",
             "ichthyosaurs", "category-ichthyosaurs",
             "category-marine-reptiles":
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
        case "game-weigh-marine-reptile", "game weight marine reptile":
            return "Games/game-weigh-marine-reptile"
        case "game-weigh-the-marine-reptile":
            return "Games/game-weigh-the-marine-reptile"
        case "can-you-name-the-dinosaur", "can you name the dinosaur", "game-intro-guess-dinosaur",
             "can-you-name-that-dinosaur", "can you name that dinosaur":
            return "Games/game-can-you-name-that-dinosaur"
        case "name-that-dinosaur", "name that dinosaur":
            return "Games/game-name-that-dinosaur"
        case "can-you-name-the-pterosaur", "can you name the pterosaur":
            return "Games/game-can-you-name-that-pterosaur"
        case "can-you-name-the-mosasaur", "can you name the mosasaur":
            return "Games/game-can-you-name-the-mosasaur"
        case "name-that-mosasaur", "name that mosasaur":
            return "Games/name-that-mosasaur"
        case "can-you-name-the-plesiosaur", "can you name the plesiosaur":
            return "Games/game-can-you-name-the-plesiosaur"
        case "name-that-plesiosaur", "name that plesiosaur":
            return "Games/name-that-plesiosaur"
        case "can-you-name-the-ichthyosaur", "can you name the ichthyosaur":
            return "Games/game-can-you-name-the-ichthyosaur"
        case "name-that-ichthyosaur", "name that ichthyosaur":
            return "Games/name-that-ichthyosaur"
        case "can-you-name-the-marine-reptile", "can you name the marine reptile",
             "can-you-name-that-marine-reptile", "can you name that marine reptile":
            return "Games/game-can-you-name-that-marine-reptile"
        case "name-that-marine-reptile", "name that marine reptile":
            return "Games/name-that-marine-reptile"
        case "toothache", "dino-toothache", "game-dino-toothache":
            return "Games/game-dino-toothache"
        case "game-dino-smile", "dino-smile", "smiling-dinos":
            return "Games/game-dino-smile"
        case "game-ptero-smile", "ptero-smile":
            return "Games/game-ptero-smile"
        case "game-ptero-smile-gameplay-directions":
            return "Games/game-ptero-smile-gameplay-directions"
        case "game-dino-smile-gameplay-directions":
            return "Games/game-dino-smile-gameplay-directions"
        case "game-ptero-eggs", "ptero-eggs":
            return "Games/game-ptero-eggs"
        case "game-ptero-eggs-beep":
            return "Games/game-ptero-eggs-beep"
        case "game-ptero-eggs-scan-failed":
            return "Games/game-ptero-eggs-scan-failed"
        case "game-ptero-eggs-tap-the-pterosaur":
            return "Games/game-ptero-eggs-tap-the-pterosaur"
        case "game-ptero-eggs-tap-the-image":
            return "Games/game-ptero-eggs-tap-the-image"
        case "game-ptero-eggs-gameplay-directions", "games-ptero-eggs-gameplay-directions":
            return "Games/game-ptero-eggs-gameplay-directions"
        case "game-dino-eggs", "dino-eggs":
            return "Games/game-dino-eggs"
        case "game-dino-eggs-beep":
            return "Games/game-dino-eggs-beep"
        case "game-dino-eggs-scan-failed":
            return "Games/game-dino-eggs-scan-failed"
        case "game-dino-eggs-shape":
            return "Games/game-dino-eggs-shape"
        case "game-dino-eggs-color":
            return "Games/game-dino-eggs-color"
        case "game-dino-eggs-tap-the-dinosaur":
            return "Games/game-dino-eggs-tap-the-dinosaur"
        case "game-dino-eggs-tap-the-sem":
            return "Games/game-dino-eggs-tap-the-sem"
        case "game-dino-eggs-tap-the-scanner":
            return "Games/game-dino-eggs-tap-the-scanner"
        case "game-dino-eggs-tap-magnifying-glass-first":
            return "Games/game-dino-eggs-tap-magnifying-glass-first"
        case "game-dino-eggs-tap-sem-microscope-first":
            return "Games/game-dino-eggs-tap-sem-microscope-first"
        case "game-dino-eggs-gameplay-directions", "games-dino-eggs-gameplay-directions",
             "tap-the-dinosaur-when-you-see-the-egg":
            return "Games/game-dino-eggs-gameplay-directions"
        case _ where normalized.hasPrefix("game-dino-eggs-nest-"):
            return "Games/\(normalized)"
        case "game-dino-tools", "dino-tools":
            return "Games/game-dino-tools"
        case "game-dino-tools-beep":
            return "Games/game-dino-tools-beep"
        case "game-dino-tools-scan-failed":
            return "Games/game-dino-tools-scan-failed"
        case "game-dino-tools-tap-the-dinosaur":
            return "Games/game-dino-tools-tap-the-dinosaur"
        case "game-dino-tools-tap-the-sem":
            return "Games/game-dino-tools-tap-the-sem"
        case "game-dino-tools-tap-the-scanner":
            return "Games/game-dino-tools-tap-the-scanner"
        case "game-dino-tools-tap-magnifying-glass-first":
            return "Games/game-dino-tools-tap-magnifying-glass-first"
        case "game-dino-tools-tap-sem-microscope-first":
            return "Games/game-dino-tools-tap-sem-microscope-first"
        case "game-dino-tools-gameplay-directions", "games-dino-tools-gameplay-directions":
            return "Games/game-dino-tools-gameplay-directions"
        case "game-dino-fossil-hunt", "dino-fossil-hunt":
            return "Games/game-dino-fossil-hunt"
        /// Dino Fossil Hunt hint tiles: `Assets/Audio/Fossil/{phase}.m4a` (not under Games/).
        case "game-dino-fossil-hunt-hint-discovery":
            return "Fossil/discovery"
        case "game-dino-fossil-hunt-hint-excavate":
            return "Fossil/excavate"
        case "game-dino-fossil-hunt-hint-preserve":
            return "Fossil/preserve"
        case "game-dino-fossil-hunt-hint-transport":
            return "Fossil/transport"
        case _ where normalized.hasPrefix("game-dino-fossil-hunt-"):
            return "Games/\(normalized)"
        case "can-you-return-the-tooth", "can you return the tooth":
            return "Games/game-can-you-return-the-tooth"
        case "game-dino-toothache-this-dinosaur-lost-its-tooth":
            return "Games/game-dino-toothache-this-dinosaur-lost-its-tooth"
        case "games-dino-toothache-this-dinosaur-lost-its-tooth":
            return "Games/games-dino-toothache-this-dinosaur-lost-its-tooth"
        case "racing-dinosaurs", "racing dinosaurs":
            return "Games/game-racing-dinosaurs"
        case "racing-pterosaurs", "racing pterosaurs", "game-racing-pterosaurs", "game racing pterosaurs":
            return "Games/game-racing-pterosaurs"
        case "racing-marine-reptiles", "racing marine reptiles", "game-racing-marine-reptiles", "game racing marine reptiles":
            return "Games/game-racing-marine-reptiles"
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
        case "game-choose-your-first-marine-reptile", "choose your first marine reptile":
            return "Games/game-choose-your-first-marine-reptile"
        case "game-choose-your-second-marine-reptile", "choose your second marine reptile":
            return "Games/game-choose-your-second-marine-reptile"
        case "game-racer-choose-your-first-marine-reptile-to-race", "choose your first marine reptile to race":
            return "Games/game-choose-your-first-marine-reptile"
        case "game-racer-choose-your-second-marine-reptile-to-race", "choose your second marine reptile to race":
            return "Games/game-choose-your-second-marine-reptile"
        case "game-racing-outside-track", "racing outside track":
            return "Games/game-racing-outside-track"
        case "game-racing-inside-track", "racing inside track":
            return "Games/game-racing-inside-track"
        case "game-racing-first-position", "racing first position":
            return "Games/game-racing-first-position"
        case "game-racing-second-position", "racing second position":
            return "Games/game-racing-second-position"
        case "game-racing-dinosaurs-ready":
            return "Games/game-racing-dinosaurs-ready"
        case "game-racing-dinosaurs-set":
            return "Games/game-racing-dinosaurs-set"
        case "game-racing-dinosaurs-go":
            return "Games/game-racing-dinosaurs-go"
        case "game-racing-pterosaurs-ready":
            return "Games/game-racing-pterosaurs-ready"
        case "game-racing-pterosaurs-set":
            return "Games/game-racing-pterosaurs-set"
        case "game-racing-pterosaurs-go":
            return "Games/game-racing-pterosaurs-go"
        case "game-racing-marine-reptiles-ready":
            return "Games/game-racing-marine-reptiles-ready"
        case "game-racing-marine-reptiles-set":
            return "Games/game-racing-marine-reptiles-set"
        case "game-racing-marine-reptiles-go":
            return "Games/game-racing-marine-reptiles-go"
        case "game-racing-ready-set", "racing ready set":
            return "Games/game-racing-ready-set"
        case "racing-the-winner-is", "the winner is":
            return "Games/racing-the-winner-is"
        case "game-racing-the-winner-is":
            return "Games/game-racing-the-winner-is"
        case "game-racing-its-a-tie", "its a tie":
            return "Games/game-racing-its-a-tie"
        case "game-dino-matrix", "dino matrix", "game-matrix-materials", "matrix materials":
            return "Games/game-dino-matrix"
        case "game-dino-matrix-identify-the-stone", "game-matrix-identify-the-stone":
            return "Games/game-dino-matrix-identify-the-stone"
        case "game-ptero-matrix-identify-the-stone":
            return "Games/game-ptero-matrix-identify-the-stone"
        case "game-dino-matrix-which-one", "game-matrix-which-one", "which one is it", "tap the one":
            return "Games/game-dino-matrix-which-one"
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
        case "game-ptero-footprints", "ptero footprints":
            return "Games/game-ptero-footprints"
        // Shared by Dino / Pterosaur / Marine “Footprints” games (generic filenames under Games/).
        case "game-footprints-identify-the-footprint", "game-dino-footprints-identify-the-footprint", "identify the footprint":
            return "Games/game-footprints-identify-the-footprint"
        case "game-footprints-tap-the-footprint-to-hear-description", "game-dino-footprints-tap-the-footprint-to-hear-description":
            return "Games/game-footprints-tap-the-footprint-to-hear-description"
        case "game-whose-bones", "whose bones", "whose bones?":
            return "Games/game-whose-bones"
        case "game-whose-bones-gameplay":
            return "Games/game-whose-bones-gameplay"
        case "game-whose-bones-success":
            return "Games/game-whose-bones-success"
        case "game-dino-bones", "dino bones":
            return "Games/game-dino-bones"
        case "game-dino-bones-identify-the-skeleton", "identify the skeleton":
            return "Games/game-dino-bones-identify-the-skeleton"
        case "game-dino-flora-which-three-dinosaurs":
            return "Games/game-dino-flora-which-three-dinosaurs"
        case "game-marine-flora-which-three-marine-reptiles":
            return "Games/game-marine-flora-which-three-marine-reptiles"
        case "game-marine-flora-tap-the-plant-to-hear-description":
            return "Games/game-marine-flora-tap-the-plant-to-hear-description"
        case "game-dino-fauna-which-three-dinosaurs-bugs":
            return "Games/game-dino-fauna-which-three-dinosaurs-bugs"
        case "game-dino-fauna-which-three-dinosaurs-animals":
            return "Games/game-dino-fauna-which-three-dinosaurs-animals"
        case "game-dino-flora-tap-the-plant-to-hear-description":
            return "Games/game-dino-flora-tap-the-plant-to-hear-description"
        case "game-dino-flora-tap-the-image":
            return "Games/game-dino-flora-tap-the-image"
        case "flora-hint-browsers", "dino-hint-browsers":
            return "Dino-Flora/hints/dino-hint-browsers"
        case "flora-hint-periods", "dino-hint-periods":
            return "Dino-Flora/hints/dino-hint-periods"
        case "flora-hint-diets", "dino-hint-diets":
            return "Dino-Flora/hints/dino-hint-diets"
        case "ptero-hint-size":
            return "Ptero-Flora/hints/ptero-hint-size"
        case "ptero-hint-period":
            return "Ptero-Flora/hints/ptero-hint-period"
        case "ptero-hint-diets":
            return "Ptero-Flora/hints/ptero-hint-diets"
        case "marine-hint-protection":
            return "Marine-Flora/hints/marine-hint-protection"
        case "marine-hint-periods":
            return "Marine-Flora/hints/marine-hint-periods"
        case "marine-hint-diets":
            return "Marine-Flora/hints/marine-hint-diets"
        case "game-dino-push", "dino push":
            return "Games/game-dino-push"
        case "game-dino-push-choose-two-dinosaurs", "choose two dinosaurs":
            return "Games/game-dino-push-choose-two-dinosaurs"
        case "game-push-choose-your-first-strong-dinosaur", "choose your first strong dinosaur":
            return "Games/game-push-choose-your-first-strong-dinosaur"
        case "game-push-choose-your-second-strong-dinosaur", "choose your second strong dinosaur":
            return "Games/game-push-choose-your-second-strong-dinosaur"
        case "game-dino-push-choose-period", "choose a period":
            return "Games/game-dino-push-choose-period"
        case "game-dino-push-jurassic":
            return "Games/game-dino-push-jurassic"
        case "game-dino-push-cretaceous":
            return "Games/game-dino-push-cretaceous"
        case "game-dino-push-both":
            return "Games/game-dino-push-both"
        case "game-dino-push-its-a-tie":
            return "Games/game-dino-push-its-a-tie"
        case "game-dino-push-wins":
            return "Games/game-dino-push-wins"
        case "game-dino-push-choose-first", "choose your first dinosaur to push":
            return "Games/game-dino-push-choose-first"
        case "game-dino-push-choose-second", "choose your second dinosaur to push":
            return "Games/game-dino-push-choose-second"
        case "game-hint", "game dino footprints hint", "dino footprints hint":
            return "Games/game-hint"
        case "footprint-therapod", "therapod", "theropod":
            return "Footprints/dino-theropod"
        case "footprint-sauropod", "sauropod":
            return "Footprints/dino-sauropod"
        case "footprint-hadrosaur", "hadrosaur":
            return "Footprints/dino-hadrosaur"
        case "footprint-ceratopsian", "ceratopsian":
            return "Footprints/dino-ceratopsian"
        case "footprint-ankylosaur", "ankylosaur":
            return "Footprints/dino-ankylosaur"
        case "footprint-ornithischian", "ornithischian":
            return "Footprints/dino-ornithischian"
        case "footprint-ornithomimid", "ornithomimid":
            return "Footprints/dino-ornithomimid"
        case "footprint-spinosaurid", "spinosaurid":
            return "Footprints/dino-spinosaurid"
        case "footprint-stegosaur", "stegosaur":
            return "Footprints/dino-stegosaur"
        // Ptero Footprints hints: key `ptero-footprints-{clade}` → `Ptero-Footprints/ptero-footprints-{clade}.m4a`
        case _ where normalized.hasPrefix("ptero-footprints-"):
            return "Ptero-Footprints/\(normalized)"
        // Pterosaur clades: key `ptero-clade-{slug}` → `Pterosaur-Clades/clade-{slug}.m4a` (see `urlForAudio` preferred path)
        case _ where normalized.hasPrefix("ptero-clade-"):
            let slug = String(normalized.dropFirst("ptero-clade-".count))
            return "Pterosaur-Clades/clade-\(slug)"
        // Marine reptile groups: key `marine-clade-{slug}` → `Marine-Reptile-Clades/clade-{slug}.m4a` (see `urlForAudio` preferred path)
        case _ where normalized.hasPrefix("marine-clade-"):
            let slug = String(normalized.dropFirst("marine-clade-".count))
            return "Marine-Reptile-Clades/clade-\(slug)"
        // Dinosaur clades: key `dino-clade-{slug}` → prefer `Dinosaur-Clades/clade-{slug}.m4a` (see `urlForAudio`), legacy `Dinosaur-Clades/{slug}.m4a`
        case _ where normalized.hasPrefix("dino-clade-"):
            let slug = String(normalized.dropFirst("dino-clade-".count))
            return "Dinosaur-Clades/\(slug)"

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
        // Dino Habitats: habitat name from Audio/Habitats/{slug}.m4a. Key: habitat-name-{slug}
        case _ where normalized.hasPrefix("habitat-name-"):
            let slug = String(normalized.dropFirst("habitat-name-".count))
            return "Habitats/\(slug)"
        // Dino Habitats: kid-friendly nickname from Audio/Habitats/nickname-{slug}.m4a. Prefer when exists.
        case _ where normalized.hasPrefix("habitat-nickname-"):
            let slug = String(normalized.dropFirst("habitat-nickname-".count))
            return "Habitats/nickname-\(slug)"
        // Dino-Characteristics: when key is dino-char-* (characteristic imageName), use Dino-Characteristics/{suffix} so tail-spike.m4a / tail-club.m4a etc. are found
        case _ where normalized.hasPrefix("dino-char-"):
            var suffix = String(normalized.dropFirst("dino-char-".count))
            if suffix == "tail-spikes" { suffix = "tail-spike" } // audio file is tail-spike.m4a
            return "\(characteristicSubfolder)/\(suffix)"
        // Dino Flora plant intros: key `dino-flora-{formation}-{taxon}` → `Dino-Flora/{folder}/{key}.m4a` (see `urlForAudio` plant registry).
        case _ where normalized.hasPrefix("dino-flora-") && !normalized.hasPrefix("dino-flora-hint"):
            if let plant = dinoFloraPlants.first(where: { $0.audioKey == normalized }) {
                return "Dino-Flora/\(plant.formationFolder)/\(plant.audioKey)"
            }
            return nil
        // Legacy dino flora plant keys: `flora-{slug}` (prefer plant registry in `urlForAudio`).
        case _ where normalized.hasPrefix("flora-") && !normalized.hasPrefix("flora-hint-"):
            let slug = String(normalized.dropFirst("flora-".count))
            if let plant = dinoFloraPlants.first(where: { $0.taxon == slug || $0.id == slug }) {
                return "Dino-Flora/\(plant.formationFolder)/\(plant.audioKey)"
            }
            return "Flora/Dinosaurs/dino-flora-\(slug)"
        // Fauna: fauna-{slug} → Fauna/{slug}.m4a for Dino Fauna species intros
        case _ where normalized.hasPrefix("fauna-"):
            let slug = String(normalized.dropFirst("fauna-".count))
            return "Fauna/\(slug)"
        // Dino Smile: dino-smile-* → Dino-Smile/dino-smile-{toothType}.m4a for tooth intro audio
        case _ where normalized.hasPrefix("dino-smile-"):
            return "Dino-Smile/\(normalized)"
        // Ptero Smile: ptero-smile-* → Ptero-Smile/ptero-smile-{beakType}.m4a for beak intro audio
        case _ where normalized.hasPrefix("ptero-smile-"):
            return "Ptero-Smile/\(normalized)"
        // Marine Smile (when bundled): marine-smile-* → Marine-Smile/{key}.m4a
        case _ where normalized.hasPrefix("marine-smile-"):
            return "Marine-Smile/\(normalized)"
        // Ptero Eggs: ptero-eggs-{clade} / ptero-nests-{clade} → Eggs/Pterosaurs/{key}.m4a
        case _ where normalized.hasPrefix("ptero-eggs-") || normalized.hasPrefix("ptero-nests-"):
            return "Eggs/Pterosaurs/\(normalized)"
        // Marine Eggs: marine-eggs-{slug} → Eggs/Marine-Reptiles/{key}.m4a (when bundled)
        case _ where normalized.hasPrefix("marine-eggs-"):
            return "Eggs/Marine-Reptiles/\(normalized)"
        // Dino Eggs: dino-eggs-* → Eggs/dino-eggs-{eggType}.m4a for egg intro audio
        case _ where normalized.hasPrefix("dino-eggs-"):
            return "Eggs/\(normalized)"
        // Dino Toothache: dino-toothache-* → Toothache/dino-toothache-{slug}.m4a for tooth intro audio
        case _ where normalized.hasPrefix("dino-toothache-"):
            return "Toothache/\(normalized)"
        // Body segments: Audio/Body/{stem}.m4a (Whose Bones? segment names). Keys: body-{slug} or bare slug after space→hyphen normalization.
        case _ where normalized.hasPrefix("body-"):
            let slug = String(normalized.dropFirst("body-".count))
            return "Body/\(bodySegmentAudioStem(slug))"
        case "skull", "neck", "pelvis", "tail", "foreleg", "hindleg", "shoulder", "ribcage":
            return "Body/\(normalized)"
        case "rib-cage", "ribs", "dorsal-vertebrae":
            return "Body/ribcage"
        case "shoulders", "shoulder-blade", "shoulder-blades":
            return "Body/shoulder"
        case "fore-leg":
            return "Body/foreleg"
        case "hind-leg":
            return "Body/hindleg"
        case "cervical-vertebrae":
            return "Body/neck"
        // Ptero Flora plant intros: key `ptero-flora-{formation}-{taxon}` → `Ptero-Flora/{folder}/{key}.m4a` (see `urlForAudio` plant registry).
        case _ where normalized.hasPrefix("ptero-flora-"):
            if let plant = pteroFloraPlants.first(where: { $0.audioKey == normalized }) {
                return "Ptero-Flora/\(plant.formationFolder)/\(plant.audioKey)"
            }
            return nil
        // Marine Flora plant intros: key `marine-flora-{formation}-{taxon}` → `Marine-Flora/{folder}/{key}.m4a`.
        case _ where normalized.hasPrefix("marine-flora-"):
            if let plant = marineFloraPlants.first(where: { $0.audioKey == normalized }) {
                return "Marine-Flora/\(plant.formationFolder)/\(plant.audioKey)"
            }
            return nil
        // Dinosaurs: Audio/Dinosaurs/{key}.m4a for any other dino-* key (e.g. dino-camarasaurus) for dinosaur name audio
        case _ where normalized.hasPrefix("dino-"):
            return "Dinosaurs/\(normalized)"
        // Pterosaurs: Audio/Pterosaurs/{key}.m4a for any ptero-* key (e.g. ptero-pteranodon) so Match the Pterosaur uses recorded name audio
        case _ where normalized.hasPrefix("ptero-"):
            return "Pterosaurs/\(normalized)"
        // Marine reptiles: use explicit marine-* keys from Assets/Audio/Marine-Reptiles/.
        case _ where normalized.hasPrefix("marine-"):
            return "Marine-Reptiles/\(normalized)"
        // Legacy marine keys kept for compatibility with old data.
        case _ where normalized.hasPrefix("mosa-"):
            return "Marine/\(normalized)"
        case _ where normalized.hasPrefix("plesio-"):
            return "Marine/\(normalized)"
        case _ where normalized.hasPrefix("ichthyo-"):
            return "Marine/\(normalized)"

        default:
            // Debug output to help diagnose mapping issues
            if text.contains("success") || text.contains("matches") {
                print("   ⚠️ No match for '\(text)' → normalized: '\(normalized)'")
            }
            return nil
        }
    }
    
    /// - Parameter chainDelay: If true, use a shorter delay (e.g. when chaining name + "is heavier") so the gap between clips is smaller.
    /// When `chainDelay` is true, rate limiting is skipped so scripted sequences (e.g. speak → `playAudioFile` → speak) are not dropped.
    func speak(_ text: String, chainDelay: Bool = false) {
        let now = Date()
        if !chainDelay {
            // Rate limiting: prevent audio overload from rapid taps (not applied to intentional chains).
            guard now.timeIntervalSince(lastPlayTime) >= minimumPlayInterval else {
                print("⏸️ Skipping audio (too soon after last): \(text)")
                // Still notify so sequences (e.g. intro walk) don't get stuck with a permanent highlight
                onAudioFinished?()
                return
            }
        }
        lastPlayTime = now
        
        // Stop any current audio with fade-out to prevent clicks
        stopCurrentAudio()
        
        let playBlock = {
            if let url = self.urlForAudio(key: text) {
                self.playAudioFile(url: url, fallbackSpeakText: text)
                print("🔊 Playing audio: \(url.lastPathComponent)")
            } else if let audioPath = self.audioFilePath(for: text) {
                print("⚠️ No audio file found for '\(text)' (path: \(audioPath))")
                self.startSpeaking(text)
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
        if !chainDelay {
            guard now.timeIntervalSince(lastPlayTime) >= minimumPlayInterval else {
                onAudioFinished?()
                return
            }
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
    
    /// Re-activate audio session before playback. Handles cases where session was deactivated (app update, YouTube, phone call).
    private func ensureAudioSessionActive() {
        let session = AVAudioSession.sharedInstance()
        // Use non-mixing playback so game audio interrupts background apps instead of mixing.
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

    func playAudioFile(url: URL, fallbackSpeakText: String? = nil) {
        ensureAudioSessionActive()
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
            // Keep rate limiting aligned with `speak` so a file clip after `speak` does not leave `lastPlayTime` stale.
            lastPlayTime = Date()
            
            // If file has no duration (empty/corrupt), fall back to TTS so we don't get stuck
            if player.duration <= 0 {
                isPlaying = false
                onAudioFinished?()
                let fallback = fallbackSpeakText ?? url.deletingPathExtension().lastPathComponent
                startSpeaking(fallback)
                return
            }
            
            scheduleCompletionTimeout()
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
            return
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
        cancelCompletionTimeout()
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
        cancelCompletionTimeout()
        if currentPlayer === player {
            currentPlayer = nil
        }
        isPlaying = false
        onAudioFinished?()
    }
    
    // AVSpeechSynthesizerDelegate - called when TTS finishes
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.cancelCompletionTimeout()
            isPlaying = false
            onAudioFinished?()
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.cancelCompletionTimeout()
            isPlaying = false
            onAudioFinished?()
        }
    }

    /// Preferred TTS voice: enhanced en-US if available (more natural), else default. Cached for performance.
    private static var _preferredVoice: AVSpeechSynthesisVoice?
    private static var preferredVoice: AVSpeechSynthesisVoice? {
        if let v = _preferredVoice { return v }
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let enUS = voices.filter { $0.language.hasPrefix("en-US") }
        let enhanced = enUS.first { $0.quality == .enhanced }
        let premium = enUS.first { $0.quality == .premium }
        _preferredVoice = premium ?? enhanced ?? enUS.first
        return _preferredVoice
    }

    /// IPA pronunciations for dinosaur names and other tricky words. Add entries as needed.
    private static let ttsPronunciationIPA: [String: String] = [
        "Parasaurolophus": "ˌpɛ.rə.sɔ.ˈrɑ.lə.fəs",
    ]

    func startSpeaking(_ text: String) {
        ensureAudioSessionActive()
        let utterance: AVSpeechUtterance
        if let attributed = buildAttributedStringWithIPA(text) {
            utterance = AVSpeechUtterance(attributedString: attributed)
        } else {
            utterance = AVSpeechUtterance(string: text)
        }
        utterance.voice = Self.preferredVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Slower for children
        utterance.volume = 1.0 // Full volume

        isPlaying = true
        scheduleCompletionTimeout()
        synthesizer.speak(utterance)
    }

    /// Builds attributed string with IPA for known words. Returns nil if no IPA mappings apply.
    private func buildAttributedStringWithIPA(_ text: String) -> NSAttributedString? {
        let lower = text.lowercased()
        var attributed: NSMutableAttributedString?
        for (word, ipa) in Self.ttsPronunciationIPA {
            let search = word.lowercased()
            guard lower.contains(search) else { continue }
            if attributed == nil {
                attributed = NSMutableAttributedString(string: text)
            }
            let range = (text as NSString).range(of: word, options: .caseInsensitive)
            if range.location != NSNotFound {
                attributed?.addAttribute(NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute), value: ipa, range: range)
            }
        }
        return attributed
    }
}

struct MatchingGameView: View {
    @Binding var isPresented: Bool // For navigation back to game selection
    let gameConfig: MatchingGameConfig // Game-specific configuration
    
    @StateObject private var speechManager = SpeechManager()
    @State private var currentConfig: MatchingGameConfig
    @State private var currentRound: Int = 1
    private let totalRounds: Int = 3
    @State private var selectedDinosaur: Dinosaur?
    @State private var selectedCharacteristic: Characteristic?
    @State private var matchedPairs: Set<MatchedPair> = [] // Track specific matched pairs
    @State private var failedAttempts: Set<MatchedPair> = [] // Track failed attempts (visual only, doesn't block)
    @State private var audioTestMessage = ""
    @State private var showVictory = false // Show victory screen: vertical list, highlight + name audio, then good-job + crowd
    @State private var victoryShownAt: Date? // When victory view was shown; used to enforce minimum display time
    @State private var matchChoiceStartTime: Date? // When dinosaur was selected; used to measure time until characteristic selected
    /// End sequence: -1 none, 1 = walking list (highlight + name audio), 2 = good-job + crowd then dismiss
    @State private var endSequenceStep: Int = -1
    @State private var endHighlightIndex: Int = 0
    /// All dinosaurs from all 3 rounds (3 per round = 9 total) for victory list; accumulated when each round completes.
    @State private var victoryDinosaurs: [Dinosaur] = []
    /// Dino Diets!: unique matched diet types across all rounds (Herbivore, Carnivore, etc.) for victory recap.
    @State private var victoryDiets: [Characteristic] = []
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
        currentConfig = switch currentConfig.id {
        case "match-the-pterosaur":
            MatchingGameConfigs.pterosaurFeatures(excluding: usedCreatureIds)
        case "match-the-diet":
            MatchingGameConfigs.dinoDietFeatures(excluding: usedCreatureIds)
        case "ptero-diets":
            MatchingGameConfigs.pteroDietFeatures(excluding: usedCreatureIds)
        case "marine-diets":
            MatchingGameConfigs.marineDietFeatures(excluding: usedCreatureIds)
        default:
            MatchingGameConfigs.dinoFeatures(excluding: usedCreatureIds)
        }
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
                victoryDiets = []
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
            .allowsHitTesting(!speechManager.isPlaying) // Disable interaction while audio plays
            .opacity(speechManager.isPlaying ? 0.7 : 1.0) // Visual indicator that interaction is disabled
            .gameSheetDismissDisabledWhileAudioPlaying(speechManager.isPlaying)
            .navigationBarTitleDisplayMode(.inline)
        } // End NavigationView
    } // End body
    
    private var isDietMatchingGame: Bool {
        gameConfig.id == "match-the-diet" || gameConfig.id == "ptero-diets" || gameConfig.id == "marine-diets"
    }

    private var dietMatchingDisplayTitle: String {
        switch gameConfig.id {
        case "match-the-diet": return "Dino Diets!"
        case "ptero-diets": return "Ptero Diets!"
        case "marine-diets": return "Marine Diets!"
        default: return currentConfig.title
        }
    }

    private var isPterosaurMatchingGame: Bool {
        gameConfig.id == "match-the-pterosaur" || gameConfig.id == "ptero-diets"
    }

    private var isMarineMatchingGame: Bool {
        gameConfig.id == "marine-diets"
    }

    private var matchingCreatureColumnTitle: String {
        if isMarineMatchingGame { return "Marine Reptiles" }
        if isPterosaurMatchingGame { return "Pterosaurs" }
        return "Dinosaurs"
    }

    private var victoryRecapRowCount: Int {
        isDietMatchingGame ? victoryDiets.count : victoryDinosaurs.count
    }

    /// Fixed viewport: up to `StandardVictoryLayout.maxVisibleRecapRows` recap rows visible; longer lists scroll.
    private var victoryListVisibleHeight: CGFloat {
        StandardVictoryLayout.recapListScrollHeight(itemCount: victoryRecapRowCount)
    }

    private var matchingVictorySuccessImageSide: CGFloat {
        GameCatalogImageMetrics.nameThatVictorySuccessImageSide
    }

    // MARK: - Victory: scrolling list in top half (highlight + name audio); bottom half success card + optional stinger, then good-job + crowd and dismiss
    private var victoryView: some View {
        VictorySplitColumnView(
                listScrollHeight: victoryListVisibleHeight,
                showSuccessPhase: endSequenceStep == 2,
                endHighlightIndex: endHighlightIndex,
                gameTitle: dietMatchingDisplayTitle,
                scrollRows: {
                    if isDietMatchingGame {
                        ForEach(Array(victoryDiets.enumerated()), id: \.element.type) { index, diet in
                            let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                            StandardVictoryRecapRowView(
                                item: VictoryRecapDisplayItem(
                                    id: "\(diet.id)",
                                    title: diet.type,
                                    imageAssetName: diet.imageName,
                                    fallbackEmoji: diet.icon
                                ),
                                isHighlighted: isHighlighted
                            )
                            .id(index)
                        }
                    } else {
                        ForEach(Array(victoryDinosaurs.enumerated()), id: \.element.id) { index, dinosaur in
                            let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                            StandardVictoryRecapRowView(
                                item: VictoryRecapDisplayItem(
                                    id: "\(dinosaur.id)",
                                    title: dinosaur.name,
                                    imageAssetName: dinosaur.imageName,
                                    fallbackEmoji: dinosaur.icon
                                ),
                                isHighlighted: isHighlighted
                            )
                            .id(index)
                        }
                    }
                },
                successPhase: {
                    LandGameVictorySuccessStingerThenContinue(
                        candidateSuccessImageNames: matchingVictorySuccessCandidateAssetNames(),
                        catalogGameIdForStinger: gameConfig.id,
                        imageSide: matchingVictorySuccessImageSide,
                        speechManager: speechManager,
                        onContinue: playMatchingGoodJobAndCrowdThenDismiss
                    )
                }
            )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            if victoryRecapRowCount == 0 {
                endSequenceStep = 2 // Skip walk if empty, go straight to success image
            } else {
                speakMatchingVictoryRecap(at: 0)
                speechManager.onAudioFinished = { advanceMatchingEndHighlight() }
            }
        }
    }

    private func creatureDietType(for creature: Dinosaur) -> String? {
        switch gameConfig.id {
        case "match-the-diet":
            return MatchingGameConfigs.dinosaurDietById[creature.id]
        case "ptero-diets":
            return AirPterosaurData.pterosaurDietById[creature.id]
        case "marine-diets":
            return SeaMarineReptileData.marineReptileDietById[creature.id]
        default:
            return nil
        }
    }

    private func dietAudioKey(for characteristic: Characteristic) -> String {
        switch gameConfig.id {
        case "marine-diets":
            return SeaMarineReptileData.dietAudioKey(for: characteristic.type)
        case "ptero-diets":
            return AirPterosaurData.pterosaurDietAudioKey(for: characteristic.type)
        default:
            return LandDinosaurData.dinosaurDietAudioKey(for: characteristic.type)
        }
    }

    private func speakMatchingVictoryRecap(at index: Int) {
        if isDietMatchingGame, index < victoryDiets.count {
            let diet = victoryDiets[index]
            speechManager.speak(audioKey: dietAudioKey(for: diet), fallbackText: diet.type)
        } else if index < victoryDinosaurs.count {
            let d = victoryDinosaurs[index]
            speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
        }
    }

    private func matchingVictorySuccessCandidateAssetNames() -> [String] {
        if gameConfig.id == "match-the-diet" {
            return ["game-dino-diets-success", "game-dino-diets", "game-match-the-diet-success", "game-match-the-diet"]
        }
        if gameConfig.id == "ptero-diets" {
            return ["game-ptero-diets-success", "game-ptero-diets", "game-ptero-diet-success", "game-ptero-diet"]
        }
        if gameConfig.id == "marine-diets" {
            return ["game-marine-diets-success", "game-marine-diets"]
        }
        return ["game-\(currentConfig.id)-success", "game-\(currentConfig.id)"]
    }

    private func advanceMatchingEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < victoryRecapRowCount {
            speakMatchingVictoryRecap(at: endHighlightIndex)
            speechManager.onAudioFinished = { advanceMatchingEndHighlight() }
        } else {
            // Walk complete: transition to success card
            endSequenceStep = 2
        }
    }

    /// Appends this round's matched diets (Dino Diets) or dinosaurs (other matching games) for the victory walk.
    private func accumulateVictoryRecapForCompletedRound() {
        if isDietMatchingGame {
            for dino in dinosaurs {
                guard let pair = matchedPairs.first(where: { $0.dinosaurId == dino.id }),
                      let diet = characteristics.first(where: { $0.id == pair.characteristicId }),
                      !victoryDiets.contains(where: { $0.type == diet.type }) else { continue }
                victoryDiets.append(diet)
            }
        } else {
            for d in dinosaurs {
                if !victoryDinosaurs.contains(where: { $0.id == d.id }) {
                    victoryDinosaurs.append(d)
                }
            }
        }
    }

    private func playMatchingGoodJobAndCrowdThenDismiss() {
        StandardVictorySequence.dismissAfterVictory(
            configId: gameConfig.id,
            isPresented: $isPresented,
            speechManager: speechManager
        )
    }

    private var mainGameView: some View {
            VStack(spacing: 20) {
                // Title (use gameConfig so Dino Diets! always shows "Dino Diets!" not config.title)
                VStack(spacing: 4) {
                    Text(dietMatchingDisplayTitle)
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
                        Text(matchingCreatureColumnTitle)
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
                        Text(isDietMatchingGame ? "Diet" : "Special Feature")
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
            }
            return
        }
        introWalkStep = 0
        if gameConfig.id == "match-the-diet" {
            // Dino Diets!: play instruction (block tapping), then walk dinosaurs, then diets, then unblock
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = { self.advanceIntroWalk() }
                let d0 = self.dinosaurs[0]
                self.speechManager.speak(audioKey: d0.imageName ?? d0.name, fallbackText: d0.name)
            }
            speechManager.speak("game-dino-diets-match-each-dinosaur")
        } else if gameConfig.id == "ptero-diets" {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = { self.advanceIntroWalk() }
                let d0 = self.dinosaurs[0]
                self.speechManager.speak(audioKey: d0.imageName ?? d0.name, fallbackText: d0.name)
            }
            speechManager.speak(audioKey: "game-ptero-diets", fallbackText: "game-ptero-diet")
        } else if gameConfig.id == "marine-diets" {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = { self.advanceIntroWalk() }
                let d0 = self.dinosaurs[0]
                self.speechManager.speak(audioKey: d0.imageName ?? d0.name, fallbackText: d0.name)
            }
            speechManager.speak(audioKey: "game-marine-diets", fallbackText: "game-marine-diets")
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
            return
        }
        speechManager.onAudioFinished = { advanceIntroWalk() }
        if introWalkStep < 3 {
            let d = dinosaurs[introWalkStep]
            speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
        } else {
            let c = characteristics[introWalkStep - 3]
            if isDietMatchingGame {
                speechManager.speak(dietAudioKey(for: c))
            } else {
                speechManager.speak(c.type)
            }
        }
    }
    
    private func handleDinosaurTap(_ dinosaur: Dinosaur) {
        // Don't allow interaction while audio is playing
        guard !speechManager.isPlaying else { return }
        
        // If this creature is fully matched, play handrail and don't allow selection.
        if isDietMatchingGame {
            if matchedPairs.contains(where: { $0.dinosaurId == dinosaur.id }) {
                speechManager.onAudioFinished = {
                    DispatchQueue.main.async {  }
                }
                speechManager.speak("pick-another-one")
                return
            }
        } else {
        // When dinosaurCharacteristics is empty (round config bug), allow selection instead of "pick another one".
        let dinosaurCharacteristics = characteristics.filter { $0.dinosaurId == dinosaur.id }
        let matchedCount = matchedPairs.filter { $0.dinosaurId == dinosaur.id }.count
        if !dinosaurCharacteristics.isEmpty && matchedCount >= dinosaurCharacteristics.count {
            speechManager.onAudioFinished = {
                DispatchQueue.main.async {  }
            }
            speechManager.speak("pick-another-one")
            return
        }
        }
        
        // If tapping the same dinosaur again, deselect it (no audio)
        if selectedDinosaur?.id == dinosaur.id {
            selectedDinosaur = nil
            return
        }
        
        // Play audio feedback only when selecting (not deselecting); re-enable taps when name finishes
        speechManager.onAudioFinished = {
            DispatchQueue.main.async {  }
        }
        speechManager.speak(audioKey: dinosaur.imageName ?? dinosaur.name, fallbackText: dinosaur.name)
        
        selectedDinosaur = dinosaur
        selectedCharacteristic = nil // Reset characteristic selection
        matchChoiceStartTime = Date() // Start timer for this choice
        
        // Don't check match yet - wait for user to select characteristic
    }
    
    private func handleCharacteristicTap(_ characteristic: Characteristic) {
        // Don't allow interaction while audio is playing
        guard !speechManager.isPlaying else { return }
        
        // Handrail: must select a creature first (dinosaur or pterosaur by game type)
        if selectedDinosaur == nil {
            speechManager.onAudioFinished = {
                DispatchQueue.main.async {  }
            }
            let pickFirstKey: String = {
                if isMarineMatchingGame { return OrderedTouchFeedback.pickDinosaurFirst }
                if isPterosaurMatchingGame { return OrderedTouchFeedback.pickPterosaurFirst }
                return OrderedTouchFeedback.pickDinosaurFirst
            }()
            OrderedTouchFeedback.speak(pickFirstKey, speechManager: speechManager)
            return
        }
        
        // If this specific characteristic is already matched, play handrail and don't allow selection
        if matchedPairs.contains(where: { $0.characteristicId == characteristic.id }) {
            speechManager.onAudioFinished = {
                DispatchQueue.main.async {  }
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
        speechManager.onAudioFinished = {
            DispatchQueue.main.async {
                // Clear this one-shot callback, but do NOT overwrite any callback that `checkMatch()`
                // installs for chaining (e.g. last match → advance round).
                self.speechManager.onAudioFinished = nil
                if self.selectedDinosaur != nil && self.selectedCharacteristic != nil {
                    self.checkMatch()
                } else {
                }
            }
        }
        if isDietMatchingGame {
            speechManager.speak(dietAudioKey(for: characteristic))
        } else {
            speechManager.speak(characteristic.type)
        }
    }
    
    private func checkMatch() {
        guard let dinosaur = selectedDinosaur,
              let characteristic = selectedCharacteristic else {
            return
        }
        
        let isMatch: Bool = {
            if isDietMatchingGame {
                guard let expectedDiet = creatureDietType(for: dinosaur) else { return false }
                return characteristic.type == expectedDiet
            }
            return characteristic.dinosaurId == dinosaur.id
        }()
        
        if isMatch {
            // Success! Measure time from dinosaur tap to characteristic tap
            let elapsed = matchChoiceStartTime.map { Date().timeIntervalSince($0) } ?? 0
            
            // Add this specific pair to matched pairs
            let newPair = MatchedPair(dinosaurId: dinosaur.id, characteristicId: characteristic.id)
            matchedPairs.insert(newPair)
            let matchCount = matchedPairs.count
            
            if matchCount == dinosaurs.count {
                // Third match: Dino Diets! uses 10 s threshold and great-match / wow-that-was-tricky; others use 5 s and great-match / wow-that-was-tricky
                matchChoiceStartTime = nil // Reset timer after choosing audio
                let slowThreshold = isDietMatchingGame
                    ? OrderedTouchFeedback.dietSlowThresholdSeconds
                    : OrderedTouchFeedback.defaultSlowThresholdSeconds
                let matchAudio = OrderedTouchFeedback.successMatchAudio(elapsed: elapsed, slowThreshold: slowThreshold)
                speechManager.onAudioFinished = {
                    DispatchQueue.main.async {
                        self.accumulateVictoryRecapForCompletedRound()
                        if self.currentRound < self.totalRounds {
                            // Mark this round's creatures as used so next round won't reuse them
                            self.usedCreatureIds.formUnion(self.dinosaurs.map(\.id))
                            // Short pause so the last match feels complete, then start the next round.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                self.startNextRound()
                            }
                        } else {
                            // Last round complete: show victory view; it will walk all 9 (highlight + name audio) then good-job + crowd then dismiss.
                            self.showVictory = true
                        }
                    }
                }
                OrderedTouchFeedback.speak(matchAudio, speechManager: speechManager)
            } else {
                // First or second match: Dino Diets! uses 10 s and great-match / wow-that-was-tricky; others use 5 s and great-match / wow-that-was-tricky
                let slowThreshold = isDietMatchingGame
                    ? OrderedTouchFeedback.dietSlowThresholdSeconds
                    : OrderedTouchFeedback.defaultSlowThresholdSeconds
                let matchAudio = OrderedTouchFeedback.successMatchAudio(elapsed: elapsed, slowThreshold: slowThreshold)
                matchChoiceStartTime = nil // Reset timer after choosing audio
                speechManager.onAudioFinished = {
                    DispatchQueue.main.async {
                        self.selectedDinosaur = nil
                        self.selectedCharacteristic = nil
                    }
                }
                OrderedTouchFeedback.speak(matchAudio, speechManager: speechManager)
            }
        } else {
            // Wrong match - encouragement and permission to continue (no failure count, no game over)
            speechManager.onAudioFinished = {
                DispatchQueue.main.async {
                    self.selectedDinosaur = nil
                    self.selectedCharacteristic = nil
                }
            }
            let wrongKey = isDietMatchingGame ? "thats-not-right-try-again" : "try-again"
            speechManager.speak(wrongKey)
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
        let cladeById = (id == "match-the-pterosaur") ? [:] : LandDinosaurCladeCatalog.cladeByCreatureId
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

// MARK: - Diet game icons (file-private; used by static config builders without MainActor isolation)

private func matchingDinoDietIcon(for diet: String) -> String {
    switch diet {
    case "Herbivore": return "🌿"
    case "Carnivore": return "🥩"
    case "Piscivore": return "🐟"
    case "Insectivore": return "🦗"
    case "Omnivore": return "🍎"
    default: return "🍽️"
    }
}

private func matchingPterosaurDietIcon(for diet: String) -> String {
    switch diet {
    case "Frugivore": return "🍇"
    case "Carnivore": return "🥩"
    case "Piscivore": return "🐟"
    case "Insectivore": return "🦗"
    case "Filter Feeder": return "🦐"
    default: return "🍽️"
    }
}

private func matchingMarineDietIcon(for diet: String) -> String {
    switch diet {
    case "Herbivore": return "🌿"
    case "Piscivore": return "🐟"
    case "Apex Predator": return "🦈"
    case "Durophage": return "🦀"
    case "Teuthivore": return "🦑"
    default: return "🍽️"
    }
}

// MARK: - Game Configurations

struct MatchingGameConfigs {
    static let allDinosaurs = LandDinosaurData.allDinosaurs
    static let dinosaurDietById = LandDinosaurData.dinosaurDietById
    static let dinosaurEstimatedWeightKgById = LandDinosaurData.dinosaurEstimatedWeightKgById
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
        Characteristic(id: 198, type: "Armor", icon: "🛡️", imageName: "dino-char-armor", dinosaurId: 55),
        Characteristic(id: 199, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 55),
        Characteristic(id: 200, type: "Armor", icon: "🛡️", imageName: "dino-char-armor", dinosaurId: 56),
        Characteristic(id: 201, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 56),
        Characteristic(id: 202, type: "Horns", icon: "🦏", imageName: "dino-char-horns", dinosaurId: 57),
        Characteristic(id: 203, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 57),
        Characteristic(id: 204, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 58),
        Characteristic(id: 205, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 58),
        Characteristic(id: 206, type: "Long Neck", icon: "🦒", imageName: "dino-char-long-neck", dinosaurId: 59),
        Characteristic(id: 207, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 59),
        Characteristic(id: 208, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 60),
        Characteristic(id: 209, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 60),
        Characteristic(id: 210, type: "Horns", icon: "🦏", imageName: "dino-char-horns", dinosaurId: 61),
        Characteristic(id: 211, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 61),
        Characteristic(id: 212, type: "Beak", icon: "🦜", imageName: "dino-char-beak", dinosaurId: 62),
        Characteristic(id: 213, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 62),
        Characteristic(id: 214, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 63),
        Characteristic(id: 215, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 63),
        Characteristic(id: 216, type: "Small", icon: "🐦", imageName: "dino-char-small", dinosaurId: 64),
        Characteristic(id: 217, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 64),
        Characteristic(id: 218, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 65),
        Characteristic(id: 219, type: "Big", icon: "🐘", imageName: "dino-char-big", dinosaurId: 65),
        Characteristic(id: 220, type: "Long Neck", icon: "🦒", imageName: "dino-char-long-neck", dinosaurId: 66),
        Characteristic(id: 221, type: "Four Feet", icon: "🦎", imageName: "dino-char-four-feet", dinosaurId: 66),
        Characteristic(id: 222, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 67),
        Characteristic(id: 223, type: "Small", icon: "🐦", imageName: "dino-char-small", dinosaurId: 67),
        Characteristic(id: 224, type: "Long Snout", icon: "🐊", imageName: "dino-char-long-snout", dinosaurId: 68),
        Characteristic(id: 225, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 68),
        Characteristic(id: 226, type: "Two Feet", icon: "🦖", imageName: "dino-char-two-feet", dinosaurId: 69),
        Characteristic(id: 227, type: "Small", icon: "🐦", imageName: "dino-char-small", dinosaurId: 69),
    ]
    
    /// Resolves diet option art: `{category}-diets-{slug}` (e.g. `dino-diets-herbivore`, `marine-diets-apex-predator`).
    private static func dietImageAssetName(categoryPrefix: String, diet: String) -> String? {
        let slug: String = {
            if categoryPrefix == "marine" {
                return SeaMarineReptileData.dietAssetSlug(for: diet)
            }
            if categoryPrefix == "ptero" {
                return AirPterosaurData.pterosaurDietAssetSlug(for: diet)
            }
            return diet.lowercased()
        }()
        let name = "\(categoryPrefix)-diets-\(slug)"
        return ImageAssetCache.imageExists(named: name) ? name : nil
    }

    /// One right-column diet tile per label (not tied to a creature id). Matching is by diet *type*.
    static func canonicalDietOptions(
        dietTypes: [String],
        categoryPrefix: String,
        idBase: Int,
        icon: (String) -> String
    ) -> [Characteristic] {
        dietTypes.enumerated().compactMap { index, dietType in
            guard let imageName = dietImageAssetName(categoryPrefix: categoryPrefix, diet: dietType) else { return nil }
            return Characteristic(
                id: idBase + index,
                type: dietType,
                icon: icon(dietType),
                imageName: imageName,
                dinosaurId: 0
            )
        }
    }

    /// Picks three creatures with three different diets from `candidates`.
    private static func selectThreeWithDistinctDiets(
        from candidates: [Dinosaur],
        dietById: [Int: String],
        allowedDiets: Set<String>
    ) -> [Dinosaur] {
        let byDiet = Dictionary(grouping: candidates) { dietById[$0.id] ?? "" }
            .filter { allowedDiets.contains($0.key) && !$0.key.isEmpty }
        let diets = byDiet.keys.shuffled()
        guard diets.count >= 3 else { return [] }
        return diets.prefix(3).compactMap { byDiet[$0]?.randomElement() }
    }

    /// Creates a config for diet matching games: 3 creatures, always 5 diet choices (one per diet label).
    static func createRandomDiet(
        from allCreatures: [Dinosaur],
        dietOptions: [Characteristic],
        dietById: [Int: String],
        groupKey: (Dinosaur) -> String,
        dietTypes: [String] = ["Herbivore", "Carnivore", "Piscivore", "Insectivore", "Omnivore"],
        id: String = "match-the-diet",
        title: String = "Dino Diets!",
        introAudio: String = "game-intro-dino-diets",
        excludingCreatureIds: Set<Int> = []
    ) -> MatchingGameConfig {
        let allowedDiets = Set(dietTypes)
        let rightColumnDiets = dietOptions.filter { allowedDiets.contains($0.type) }
        precondition(
            rightColumnDiets.count == dietTypes.count,
            "Diet game \(id) needs \(dietTypes.count) diet images; got \(rightColumnDiets.count)"
        )

        let pool: [Dinosaur] = {
            if excludingCreatureIds.isEmpty { return allCreatures }
            let available = allCreatures.filter { !excludingCreatureIds.contains($0.id) }
            return available.count >= 3 ? available : allCreatures
        }()

        let playable = pool.filter { creature in
            guard let diet = dietById[creature.id] else { return false }
            return allowedDiets.contains(diet)
        }

        var selected: [Dinosaur] = []
        let maxAttempts = 40

        for _ in 0..<maxAttempts {
            let byGroup = Dictionary(grouping: playable) { groupKey($0) }
            let groupsWithCreatures = byGroup.keys.filter { !(byGroup[$0] ?? []).isEmpty }.shuffled()
            guard groupsWithCreatures.count >= 3 else { continue }
            let pick = (0..<3).compactMap { i -> Dinosaur? in
                let group = groupsWithCreatures[i]
                let candidates = (byGroup[group] ?? []).filter { !excludingCreatureIds.contains($0.id) }
                return candidates.shuffled().first
            }
            guard pick.count == 3, Set(pick.map(\.id)).count == 3 else { continue }
            let diets = pick.compactMap { dietById[$0.id] }
            guard Set(diets).count == 3, Set(diets).isSubset(of: allowedDiets) else { continue }
            selected = pick
            break
        }

        if selected.count != 3 {
            selected = selectThreeWithDistinctDiets(
                from: playable.filter { !excludingCreatureIds.contains($0.id) },
                dietById: dietById,
                allowedDiets: allowedDiets
            )
        }
        if selected.count != 3 {
            selected = selectThreeWithDistinctDiets(from: playable, dietById: dietById, allowedDiets: allowedDiets)
        }
        if selected.count != 3 {
            selected = selectThreeWithDistinctDiets(
                from: allCreatures.filter { allowedDiets.contains(dietById[$0.id] ?? "") },
                dietById: dietById,
                allowedDiets: allowedDiets
            )
        }
        if selected.count != 3 && !excludingCreatureIds.isEmpty {
            return createRandomDiet(
                from: allCreatures,
                dietOptions: dietOptions,
                dietById: dietById,
                groupKey: groupKey,
                dietTypes: dietTypes,
                id: id,
                title: title,
                introAudio: introAudio,
                excludingCreatureIds: []
            )
        }

        var gameCharacteristics = rightColumnDiets
        gameCharacteristics.shuffle()
        return MatchingGameConfig(
            id: id,
            title: title,
            introAudio: introAudio,
            selectedDinosaurs: selected,
            selectedCharacteristics: gameCharacteristics
        )
    }

    /// Five diet tiles for Dino Diets! (`dino-diets-*`). Matching is by diet label, not creature id on the tile.
    static var dinoDietOptions: [Characteristic] {
        canonicalDietOptions(
            dietTypes: ["Herbivore", "Carnivore", "Piscivore", "Insectivore", "Omnivore"],
            categoryPrefix: "dino",
            idBase: 2000,
            icon: matchingDinoDietIcon(for:)
        )
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
        MatchingGameConfigs.createRandomDiet(
            from: allDinosaurs,
            dietOptions: dinoDietOptions,
            dietById: dinosaurDietById,
            groupKey: { dinosaur in
                LandDinosaurCladeCatalog.cladeByCreatureId[dinosaur.id]?.rawValue ?? "unknown"
            },
            id: "match-the-diet",
            title: "Dino Diets!",
            introAudio: "game-intro-dino-diets",
            excludingCreatureIds: usedCreatureIds
        )
    }
    
    static let allPterosaurs = AirPterosaurData.allPterosaurs

    /// Image sets: `ptero-char-*` (e.g. ptero-char-wings, ptero-char-crest). Rows live in `AirPterosaurData` with the expanded pool.
    static let allPterosaurCharacteristics: [Characteristic] = AirPterosaurData.allPterosaurCharacteristics
    
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

    /// Five diet tiles for Ptero Diets! (`ptero-diets-*`).
    static var pteroDietOptions: [Characteristic] {
        canonicalDietOptions(
            dietTypes: AirPterosaurData.pterosaurDietTypes,
            categoryPrefix: "ptero",
            idBase: 2700,
            icon: matchingPterosaurDietIcon(for:)
        )
    }

    static var pteroDietFeatures: MatchingGameConfig {
        pteroDietFeatures(excluding: [])
    }

    static func pteroDietFeatures(excluding usedCreatureIds: Set<Int>) -> MatchingGameConfig {
        MatchingGameConfigs.createRandomDiet(
            from: allPterosaurs.filter { $0.imageName?.hasPrefix("ptero-") == true },
            dietOptions: pteroDietOptions,
            dietById: AirPterosaurData.pterosaurDietById,
            groupKey: { pterosaur in
                PterosaurGuessGroup.guessGroup(forImageName: pterosaur.imageName ?? "")?.rawValue ?? "unknown"
            },
            dietTypes: AirPterosaurData.pterosaurDietTypes,
            id: "ptero-diets",
            title: "Ptero Diets!",
            introAudio: "game-ptero-diets",
            excludingCreatureIds: usedCreatureIds
        )
    }

    /// Five diet tiles for Marine Diets! (`marine-diets-*`).
    static var marineDietOptions: [Characteristic] {
        canonicalDietOptions(
            dietTypes: SeaMarineReptileData.marineDietTypes,
            categoryPrefix: "marine",
            idBase: 2900,
            icon: matchingMarineDietIcon(for:)
        )
    }

    static var marineDietFeatures: MatchingGameConfig {
        marineDietFeatures(excluding: [])
    }

    static func marineDietFeatures(excluding usedCreatureIds: Set<Int>) -> MatchingGameConfig {
        MatchingGameConfigs.createRandomDiet(
            from: SeaMarineReptileData.allMarineReptiles,
            dietOptions: marineDietOptions,
            dietById: SeaMarineReptileData.marineReptileDietById,
            groupKey: { SeaMarineReptileData.marineCladeRawValue(for: $0) },
            dietTypes: SeaMarineReptileData.marineDietTypes,
            id: "marine-diets",
            title: "Marine Diets!",
            introAudio: "game-marine-diets",
            excludingCreatureIds: usedCreatureIds
        )
    }
    
    // Future games can be added here:
    // static let dinoHabitat = MatchingGameConfig(...)
    // static let dinoFood = MatchingGameConfig(...)
}
