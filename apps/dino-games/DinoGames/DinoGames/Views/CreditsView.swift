//
//  CreditsView.swift
//  DinoGames
//
//  Full licensing and attribution credits. Scrollable for lengthy content.
//

import SwiftUI

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    // Copyright
                    creditsSection(title: "Copyright") {
                        Text("© 2026 Timothy Stilwell. All rights reserved.")
                        Text("DinoGames — Educational app for dinosaur enthusiasts. Designed for non-readers with audio-first learning.")
                    }

                    // Character & assets
                    creditsSection(title: "Character Illustrations & Assets") {
                        Text("Character illustrations and environmental assets were created with the assistance of generative AI technologies. All rights to the original game design, story, and software are reserved by Timothy Stilwell.")
                    }

                    // Audio
                    creditsSection(title: "Audio") {
                        Text("All .m4a, .mp3, and .wav files created or recorded by the author (e.g. via QuickTime Player) are original works owned by Timothy Stilwell unless otherwise noted.")
                    }

                    // Third-party audio
                    creditsSection(title: "Third-Party Audio") {
                        creditItem(
                            asset: "Feedback/starting-whistle",
                            description: "Referee whistle from Pixabay Sound Effects.",
                            url: "https://pixabay.com/sound-effects/search/referee%20whistle/",
                            linkLabel: "Pixabay Sound Effects",
                            license: "Pixabay License (free for commercial use)."
                        )
                        creditItem(
                            asset: "Games/game-dino-eggs-beep",
                            description: "\"tone beep.wav\" by Mossy4, from Freesound.org.",
                            url: "https://freesound.org/s/263133/",
                            linkLabel: "Freesound.org",
                            license: "CC BY 4.0 (Attribution 4.0)."
                        )
                        creditItem(
                            asset: "Feedback/crowd-cheering",
                            description: "\"5 Sec Crowd Cheer\" by Mike Koenig, from SoundBible.com.",
                            url: "https://soundbible.com/1700-5-Sec-Crowd-Cheer.html",
                            linkLabel: "SoundBible.com",
                            license: "Attribution 3.0 license (free to use with attribution)."
                        )
                    }

                    // Contact
                    creditsSection(title: "Contact") {
                        Link("inquisitivefrog@gmail.com", destination: URL(string: "mailto:inquisitivefrog@gmail.com")!)
                            .font(.body)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func creditsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            content()
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func creditItem(asset: String, description: String, url: String, linkLabel: String, license: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(asset)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Text(description)
            Link(linkLabel, destination: URL(string: url)!)
                .font(.caption)
            Text(license)
                .font(.caption)
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    CreditsView()
}
