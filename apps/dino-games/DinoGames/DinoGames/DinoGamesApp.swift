//
//  DinoGamesApp.swift
//  DinoGames
//
//  Created by Timothy Stilwell on 1/23/26.
//

import SwiftUI
import CoreData
import AVFoundation

@main
struct DinoGamesApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Configure audio session for speech synthesis
        configureAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
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
