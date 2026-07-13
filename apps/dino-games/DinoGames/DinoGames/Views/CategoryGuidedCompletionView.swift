//
//  CategoryGuidedCompletionView.swift
//  DinoGames
//
//  Full-screen acknowledgement when guided play finishes every game in a category (land, air, sea).
//

import SwiftUI

struct CategoryGuidedCompletionView: View {
    let category: GameCategory
    let onComplete: () -> Void

    @StateObject private var speechManager = SpeechManager()
    @State private var artVisible = false
    @State private var artScale: CGFloat = 0.22
    @State private var emojisVisible = false

    private var imageName: String { CategoryGuidedCompletion.imageName(for: category) }
    private var celebrationEmojis: [String] { CategoryGuidedCompletion.celebrationEmojis(for: category) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                if emojisVisible {
                    ForEach(Array(celebrationEmojis.enumerated()), id: \.offset) { index, emoji in
                        Text(emoji)
                            .font(.system(size: emojiFontSize(for: index)))
                            .position(emojiPosition(index: index, width: w, height: h))
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                if artVisible, ImageAssetCache.imageExists(named: imageName) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: w * artScale, height: h * artScale)
                        .position(x: w * 0.5, y: h * 0.5)
                        .transition(.opacity)
                        .accessibilityIdentifier("category-guided-completion-art")
                }
            }
        }
        .allowsHitTesting(true)
        .accessibilityIdentifier("category-guided-completion")
        .task {
            if UITestConfiguration.skipGameSelectionIntros {
                onComplete()
                return
            }
            await runCelebrationSequence()
        }
    }

    @MainActor
    private func runCelebrationSequence() async {
        async let audio: Void = playCelebrationAudioSequence()
        async let visuals: Void = runVisualCelebrationSequence()
        _ = await (audio, visuals)
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard !Task.isCancelled else { return }
        onComplete()
    }

    @MainActor
    private func runVisualCelebrationSequence() async {
        guard ImageAssetCache.imageExists(named: imageName) else {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            return
        }

        artScale = 0.22
        withAnimation(.easeOut(duration: 0.24)) {
            artVisible = true
        }
        try? await Task.sleep(nanoseconds: 240_000_000)
        guard !Task.isCancelled else { return }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            emojisVisible = true
        }
        withAnimation(.easeInOut(duration: 2.5)) {
            artScale = 1.0
        }
        try? await Task.sleep(nanoseconds: 2_940_000_000)
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.4)) {
            artVisible = false
            emojisVisible = false
        }
        try? await Task.sleep(nanoseconds: 400_000_000)
    }

    @MainActor
    private func playCelebrationAudioSequence() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            CategoryGuidedCompletionAudio.playCelebrationSequence(speechManager: speechManager) {
                continuation.resume()
            }
        }
    }

    private func emojiFontSize(for index: Int) -> CGFloat {
        switch index % 3 {
        case 0: return 44
        case 1: return 36
        default: return 40
        }
    }

    private func emojiPosition(index: Int, width: CGFloat, height: CGFloat) -> CGPoint {
        let positions: [CGPoint] = [
            CGPoint(x: width * 0.14, y: height * 0.16),
            CGPoint(x: width * 0.86, y: height * 0.14),
            CGPoint(x: width * 0.12, y: height * 0.78),
            CGPoint(x: width * 0.88, y: height * 0.76),
            CGPoint(x: width * 0.22, y: height * 0.48),
            CGPoint(x: width * 0.78, y: height * 0.50),
        ]
        return positions[index % positions.count]
    }
}
