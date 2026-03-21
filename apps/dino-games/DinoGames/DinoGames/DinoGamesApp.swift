//
//  DinoGamesApp.swift
//  DinoGames
//
//  Created by Timothy Stilwell on 1/23/26.
//

import SwiftUI
import CoreData
import AVFoundation
import UIKit

/// Ensures the audio session stays active after interruptions (phone calls, YouTube, app updates).
/// Observes interruption end, media server reset, and app becoming active.
private final class AudioSessionObserver {
    private var tokens: [NSObjectProtocol] = []

    init() {
        configureAudioSession()

        tokens.append(NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        })

        tokens.append(NotificationCenter.default.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reactivateSession()
        })

        tokens.append(NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reactivateSession()
        })
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .ended:
            reactivateSession()
        case .began:
            break
        @unknown default:
            break
        }
    }

    private func reactivateSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Could not reactivate audio session: \(error)")
        }
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
            try audioSession.setActive(true)
            print("✅ Audio session configured successfully")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
    }
}

@main
struct DinoGamesApp: App {
    let persistenceController = PersistenceController.shared
    private let audioSessionObserver = AudioSessionObserver()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
