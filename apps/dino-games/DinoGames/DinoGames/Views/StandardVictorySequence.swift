//
//  StandardVictorySequence.swift
//  DinoGames
//
//  Shared victory flow for land (and related) games:
//  1. Re-introduce recap rows (scroll + highlight + concept audio)
//  2. Crowd cheering + success game card (`game-{id}-success`)
//  3. Dismiss and notify progress
//
//  Recap content is game-specific (dinosaurs, footprints, eggs, matrix materials, flora, diets, teeth, …)
//  but the phase order and dismissal are identical everywhere this module is used.
//

import SwiftUI

// MARK: - Recap concept (documentation + future routing)

/// What the victory recap re-introduces. Each game builds `[VictoryRecapDisplayItem]` for its concept.
enum StandardVictoryRecapConcept {
    case dinosaurs
    case footprints
    case eggs
    case matrixMaterials
    case flora
    case diets
    case teeth
    case plants
    case tools
    case mixed
}

// MARK: - Audio + dismissal

enum StandardVictorySequence {
    private static let crowdAudioKey = "crowd-cheering"

    /// Plays crowd cheering once, then runs `onComplete` (typically dismiss).
    static func playCrowdCheeringThen(speechManager: SpeechManager, onComplete: @escaping () -> Void) {
        if let url = speechManager.urlForAudio(key: crowdAudioKey) {
            speechManager.onAudioFinished = {
                speechManager.onAudioFinished = nil
                onComplete()
            }
            speechManager.playAudioFile(url: url)
        } else {
            onComplete()
        }
    }

    /// After crowd + success card: notify catalog progress and close the game sheet.
    static func dismissAfterVictory(
        configId: String,
        isPresented: Binding<Bool>,
        speechManager: SpeechManager,
        beforeDismiss: (() -> Void)? = nil
    ) {
        beforeDismiss?()
        speechManager.onAudioFinished = nil
        switch GameCategory.forCatalogConfigId(configId) {
        case .land:
            LandDinosaurProgress.notifyCompletionIfLandGame(configId: configId)
        case .air:
            PterosaurProgress.notifyCompletionIfPterosaurGame(configId: configId)
        case .marineReptiles:
            MarineReptileProgress.notifyCompletionIfMarineGame(configId: configId)
        case nil:
            // Do not notify every category — that eagerly builds all catalogs (e.g. Ptero Matrix) and can crash.
            LandDinosaurProgress.notifyCompletionIfLandGame(configId: configId)
        }
        isPresented.wrappedValue = false
    }

    /// Candidate asset names for the success-phase game card (`game-{id}-success` then `game-{id}`).
    static func defaultSuccessImageCandidates(gameConfigId: String) -> [String] {
        ["game-\(gameConfigId)-success", "game-\(gameConfigId)"]
    }

    // MARK: - Recap walk helper

    /// Advance highlight after item audio finishes; speaks the next row or calls `onRecapComplete`.
    static func advanceRecapHighlight(
        from index: Int,
        itemCount: Int,
        speechManager: SpeechManager,
        speakItem: @escaping (Int) -> Void,
        setEndHighlightIndex: @escaping (Int) -> Void,
        onRecapComplete: @escaping () -> Void
    ) {
        speechManager.onAudioFinished = nil
        let nextIndex = index + 1
        setEndHighlightIndex(nextIndex)
        if nextIndex < itemCount {
            speakItem(nextIndex)
            speechManager.onAudioFinished = {
                advanceRecapHighlight(
                    from: nextIndex,
                    itemCount: itemCount,
                    speechManager: speechManager,
                    speakItem: speakItem,
                    setEndHighlightIndex: setEndHighlightIndex,
                    onRecapComplete: onRecapComplete
                )
            }
        } else {
            onRecapComplete()
        }
    }

    /// Start recap at index 0 when the victory view appears.
    static func beginRecapWalk(
        itemCount: Int,
        setEndSequenceStep: @escaping (Int) -> Void,
        setEndHighlightIndex: @escaping (Int) -> Void,
        speechManager: SpeechManager,
        speakItem: @escaping (Int) -> Void,
        onRecapComplete: @escaping () -> Void
    ) {
        setEndSequenceStep(1)
        setEndHighlightIndex(0)
        guard itemCount > 0 else {
            setEndSequenceStep(2)
            return
        }
        speakItem(0)
        speechManager.onAudioFinished = {
            advanceRecapHighlight(
                from: 0,
                itemCount: itemCount,
                speechManager: speechManager,
                speakItem: speakItem,
                setEndHighlightIndex: setEndHighlightIndex,
                onRecapComplete: onRecapComplete
            )
        }
    }
}
