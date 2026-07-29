//
//  SplashScreenView.swift
//  DinoGames
//
//  Created by Cursor on 1/28/26.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var showMainApp = false
    @State private var showCredits = false
    @State private var speechManager = SpeechManager()
    @State private var welcomeAudioFinished = false
    @State private var minimumDisplayElapsed = false
    @State private var advanceTask: Task<Void, Never>?

    /// Minimum time on splash before auto-advance can fire (lets users read on-screen copyright).
    private static let minimumDisplayDuration: Duration = .seconds(5)
    /// Extra pause after welcome audio ends before leaving the splash.
    private static let postWelcomeReadingDelay: Duration = .seconds(3)
    /// Never block launch if welcome audio fails to finish.
    private static let splashSafetyTimeout: Duration = .seconds(20)
    private static let skipIntroDelay: Duration = .milliseconds(800)

    var body: some View {
        Group {
            if showMainApp {
                CategorySelectionView(
                    skipLaunchCoverSequence: CategoryPlaySession.shouldSkipLaunchIntros || UITestConfiguration.skipSplash
                )
            } else {
                NavigationStack {
                    ZStack {
                        // Background color (matches app theme)
                        Color(.systemBackground)
                            .ignoresSafeArea()

                        GeometryReader { geo in
                            // Phone-first art was capped at 300pt; on iPad use most of the
                            // upper canvas while leaving room for copyright copy below.
                            // Clamp: GeometryReader can propose 0 during the first layout pass.
                            let coverSide = max(
                                1,
                                min(geo.size.width - 48, geo.size.height * 0.58)
                            )

                            VStack(spacing: 24) {
                                Spacer(minLength: 12)

                                Image("CoverImage")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: coverSide, height: coverSide)
                                    .padding(.horizontal, 20)

                                Spacer(minLength: 12)

                                VStack(spacing: 12) {
                                    Text("© 2026 Timothy Stilwell. All rights reserved.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)

                                    Text("Character illustrations and environmental assets were created with the assistance of generative AI technologies. All rights to the original game design, story, and software are reserved by Timothy Stilwell.")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)

                                    Link("inquisitivefrog@gmail.com", destination: URL(string: "mailto:inquisitivefrog@gmail.com")!)
                                        .font(.caption)
                                        .foregroundColor(.blue)

                                    Text("Educational app for dinosaur enthusiasts.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)

                                    Text("Designed for non-readers with audio-first learning.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.horizontal, geo.size.width > 700 ? 80 : 40)
                                .padding(.bottom, 60)
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Credits") { showCredits = true }
                        }
                    }
                    .sheet(isPresented: $showCredits) {
                        CreditsView()
                    }
                    .onChange(of: showCredits) { _, isPresented in
                        if isPresented {
                            advanceTask?.cancel()
                            speechManager.stopCurrentAudio()
                            speechManager.onAudioFinished = nil
                            welcomeAudioFinished = true
                        } else {
                            scheduleAdvanceIfReady(after: Self.postWelcomeReadingDelay)
                        }
                    }
                    .onAppear {
                        handleSplashAppear()
                    }
                    .onDisappear {
                        advanceTask?.cancel()
                    }
                }
            }
        }
    }

    private func handleSplashAppear() {
        let skipIntros = CategoryPlaySession.shouldSkipLaunchIntros || UITestConfiguration.skipSplash
        if skipIntros {
            advanceTask = Task { @MainActor in
                try? await Task.sleep(for: Self.skipIntroDelay)
                guard !Task.isCancelled else { return }
                withAnimation { showMainApp = true }
            }
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: Self.minimumDisplayDuration)
            minimumDisplayElapsed = true
            advanceToMainAppIfReady()
        }

        speechManager.onAudioFinished = {
            speechManager.onAudioFinished = nil
            welcomeAudioFinished = true
            scheduleAdvanceIfReady(after: Self.postWelcomeReadingDelay)
        }
        speechManager.speak("cover-welcome-to-dino-games")

        Task { @MainActor in
            try? await Task.sleep(for: Self.splashSafetyTimeout)
            guard !showMainApp else { return }
            welcomeAudioFinished = true
            minimumDisplayElapsed = true
            advanceToMainAppIfReady()
        }
    }

    private func scheduleAdvanceIfReady(after delay: Duration) {
        advanceTask?.cancel()
        advanceTask = Task { @MainActor in
            if delay > .zero {
                try? await Task.sleep(for: delay)
            }
            guard !Task.isCancelled else { return }
            advanceToMainAppIfReady()
        }
    }

    private func advanceToMainAppIfReady() {
        guard !showMainApp else { return }
        guard welcomeAudioFinished, minimumDisplayElapsed, !showCredits else { return }
        speechManager.onAudioFinished = nil
        withAnimation { showMainApp = true }
    }
}

#Preview {
    SplashScreenView()
}
