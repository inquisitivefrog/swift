//
//  LandLevelIntermissionView.swift
//  DinoGames
//
//  Land (Dinosaurs) only: short visual intermission after picking a level, before level intro audio + game card walk.
//

import SwiftUI
import AVFoundation

struct LandLevelIntermissionView: View {
    let category: GameCategory
    let level: GameLevel
    let onComplete: () -> Void

    @State private var gameBadgeVisible = false
    @State private var gameBadgeXFraction: CGFloat = 0.5
    @State private var dinoVisible = false
    @State private var dinoScale: CGFloat = 0.22
    @State private var crowdPlayer: AVAudioPlayer?

    /// Horizontal badge: hold each position, gap while hidden (each doubled from original).
    private let flashHoldNanoseconds: UInt64 = 640_000_000
    private let flashGapNanoseconds: UInt64 = 220_000_000
    /// Vertical beat: dino scale-up duration + hold at full size (each doubled).
    private let dinoGrowNanoseconds: UInt64 = 2_500_000_000
    private let fullBleedHoldNanoseconds: UInt64 = 440_000_000
    /// Pause after visuals before returning to the game list so level intro audio is not skipped or colliding with the walk.
    private let pauseBeforeDismissNanoseconds: UInt64 = 600_000_000
    
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

        let hasBadge = ImageAssetCache.imageExists(named: level.gameLevelBadgeImageName)
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
            stopCrowd()
            try? await Task.sleep(nanoseconds: pauseBeforeDismissNanoseconds)
            onComplete()
            return
        }

        dinoScale = 0.22
        withAnimation(.easeOut(duration: 0.24)) {
            dinoVisible = true
        }
        try? await Task.sleep(nanoseconds: 240_000_000)

        withAnimation(.easeInOut(duration: Double(dinoGrowNanoseconds) / 1_000_000_000)) {
            dinoScale = 1.0
        }
        try? await Task.sleep(nanoseconds: dinoGrowNanoseconds)
        try? await Task.sleep(nanoseconds: fullBleedHoldNanoseconds)

        stopCrowd()
        withAnimation(.easeOut(duration: 0.4)) {
            dinoVisible = false
            gameBadgeVisible = false
        }
        try? await Task.sleep(nanoseconds: 400_000_000)
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

    private func stopCrowd() {
        crowdPlayer?.stop()
        crowdPlayer = nil
    }
}
