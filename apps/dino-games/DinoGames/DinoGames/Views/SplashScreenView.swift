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

    var body: some View {
        Group {
            if showMainApp {
                CategorySelectionView()
            } else {
                NavigationStack {
                    ZStack {
                        // Background color (matches app theme)
                        Color(.systemBackground)
                            .ignoresSafeArea()

                        VStack(spacing: 24) {
                            Spacer()

                            // Cover image (replaces text title)
                            Image("CoverImage")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .padding(.horizontal, 20)

                            Spacer()

                            // Copyright and credits
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
                            .padding(.horizontal, 40)
                            .padding(.bottom, 60)
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
                    .onAppear {
                        let skipIntros = CategoryPlaySession.shouldSkipLaunchIntros || UITestConfiguration.skipSplash
                        if !skipIntros {
                            speechManager.speak("cover-welcome-to-dino-games")
                        }
                        let delay = skipIntros ? 0.8 : 3.5
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            withAnimation {
                                showMainApp = true
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
