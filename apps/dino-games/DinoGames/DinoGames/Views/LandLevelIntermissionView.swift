//
//  LandLevelIntermissionView.swift
//  DinoGames
//
//  Short visual intermission after picking a level (land, air, marine), before level intro audio + game card walk.
//

import SwiftUI
import AVFoundation

struct LandLevelIntermissionView: View {
    let category: GameCategory
    let level: GameLevel
    /// Shorter level-image + crowd sequence for guided auto-play between levels.
    var compact: Bool = false
    let onComplete: () -> Void

    @State private var gameBadgeVisible = false
    @State private var gameBadgeXFraction: CGFloat = 0.5
    @State private var dinoVisible = false
    @State private var dinoScale: CGFloat = 0.22
    @State private var crowdPlayer: AVAudioPlayer?

    private var flashHoldNanoseconds: UInt64 { compact ? 320_000_000 : 640_000_000 }
    private var flashGapNanoseconds: UInt64 { compact ? 110_000_000 : 220_000_000 }
    private var dinoGrowNanoseconds: UInt64 { compact ? 1_200_000_000 : 2_500_000_000 }
    private var fullBleedHoldNanoseconds: UInt64 { compact ? 220_000_000 : 440_000_000 }
    private var pauseBeforeDismissNanoseconds: UInt64 { compact ? 250_000_000 : 600_000_000 }
    private var fadeOutNanoseconds: UInt64 { compact ? 200_000_000 : 400_000_000 }
    private var preGrowNanoseconds: UInt64 { compact ? 120_000_000 : 240_000_000 }
    
    private var levelImageName: String {
        switch category {
        case .land:
            return level.imageName
        case .air:
            return level.pterosaurLevelImageName
        case .marineReptiles:
            let names = [
                "marine-level-one", "marine-level-two", "marine-level-three", "marine-level-four", "marine-level-five",
                "marine-level-six", "marine-level-seven", "marine-level-eight", "marine-level-nine", "marine-level-ten",
            ]
            return names[level.number - 1]
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let centerY = h * 0.42
            let cardSide = min(w, h) * 0.22

            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                if gameBadgeVisible, ImageAssetCache.imageExists(named: level.gameLevelBadgeImageName) {
                    Image(level.gameLevelBadgeImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: cardSide, height: cardSide)
                        .position(x: w * gameBadgeXFraction, y: centerY)
                        .transition(.opacity)
                }

                if dinoVisible, ImageAssetCache.imageExists(named: levelImageName) {
                    Image(levelImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: w * dinoScale, height: h * dinoScale)
                        .position(x: w * 0.5, y: h * 0.5)
                        .transition(.opacity)
                }
            }
        }
        .allowsHitTesting(true)
        .task {
            await runIntermissionSequence()
        }
        .onDisappear {
            stopCrowd()
        }
    }

    @MainActor
    private func runIntermissionSequence() async {
        startCrowd()

        let hasBadge = !compact && ImageAssetCache.imageExists(named: level.gameLevelBadgeImageName)
        if hasBadge {
            for x in [0.22, 0.5, 0.78] as [CGFloat] {
                withAnimation(.easeOut(duration: 0.16)) {
                    gameBadgeXFraction = x
                    gameBadgeVisible = true
                }
                try? await Task.sleep(nanoseconds: flashHoldNanoseconds)
                withAnimation(.easeOut(duration: 0.12)) {
                    gameBadgeVisible = false
                }
                try? await Task.sleep(nanoseconds: flashGapNanoseconds)
            }
        }

        guard ImageAssetCache.imageExists(named: levelImageName) else {
            await waitForCrowdToFinish()
            stopCrowd()
            try? await Task.sleep(nanoseconds: pauseBeforeDismissNanoseconds)
            onComplete()
            return
        }

        dinoScale = compact ? 0.45 : 0.22
        withAnimation(.easeOut(duration: compact ? 0.16 : 0.24)) {
            dinoVisible = true
        }
        try? await Task.sleep(nanoseconds: preGrowNanoseconds)

        withAnimation(.easeInOut(duration: Double(dinoGrowNanoseconds) / 1_000_000_000)) {
            dinoScale = 1.0
        }
        try? await Task.sleep(nanoseconds: dinoGrowNanoseconds)
        try? await Task.sleep(nanoseconds: fullBleedHoldNanoseconds)

        withAnimation(.easeOut(duration: Double(fadeOutNanoseconds) / 1_000_000_000)) {
            dinoVisible = false
            gameBadgeVisible = false
        }
        try? await Task.sleep(nanoseconds: fadeOutNanoseconds)

        if compact {
            stopCrowd()
            try? await Task.sleep(nanoseconds: pauseBeforeDismissNanoseconds)
            onComplete()
            return
        }

        await waitForCrowdToFinish()
        stopCrowd()
        try? await Task.sleep(nanoseconds: pauseBeforeDismissNanoseconds)
        onComplete()
    }

    private func startCrowd() {
        guard let url = SpeechManager().urlForAudio(key: "crowd-cheering") else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            let p = try AVAudioPlayer(contentsOf: url)
            p.volume = 0.9
            p.prepareToPlay()
            p.play()
            crowdPlayer = p
        } catch {
            crowdPlayer = nil
        }
    }

    @MainActor
    private func waitForCrowdToFinish() async {
        guard let player = crowdPlayer else { return }
        while player.isPlaying {
            try? await Task.sleep(nanoseconds: 50_000_000)
            if Task.isCancelled { return }
        }
    }

    private func stopCrowd() {
        crowdPlayer?.stop()
        crowdPlayer = nil
    }
}
