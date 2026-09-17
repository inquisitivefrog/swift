//
//  WalkthroughEarlyExit.swift
//  DinoGames
//
//  Overlay Exit on game fullScreenCovers so a walkthrough build can leave mid-game.
//  Lives on the cover (outside each game's `allowsHitTesting(false)` during audio).
//

import SwiftUI

struct WalkthroughEarlyExitModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content.overlay(alignment: .topTrailing) {
            if DeveloperSessionFlags.showEarlyExitDone {
                Button {
                    isPresented = false
                } label: {
                    Text("Exit")
                        .font(.headline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .accessibilityIdentifier("walkthrough-exit")
                .padding(.top, 12)
                .padding(.trailing, 16)
            }
        }
    }
}

extension View {
    func walkthroughEarlyExit(isPresented: Binding<Bool>) -> some View {
        modifier(WalkthroughEarlyExitModifier(isPresented: isPresented))
    }
}
