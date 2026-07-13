//
//  GameAudioInputLock.swift
//  DinoGames
//
//  Shared helpers: block sheet swipe-dismiss while game audio is playing.
//

import SwiftUI

extension View {
    /// Prevents swipe-to-dismiss on game sheets while intro or gameplay audio is active.
    func gameSheetDismissDisabledWhileAudioPlaying(_ isPlaying: Bool) -> some View {
        interactiveDismissDisabled(isPlaying)
    }
}
