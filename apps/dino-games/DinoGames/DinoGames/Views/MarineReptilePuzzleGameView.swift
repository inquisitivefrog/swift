//
//  MarineReptilePuzzleGameView.swift
//  DinoGames
//
//  Marine Reptile Puzzle: portrait jigsaw using marine image groups (`marine-<group>-*`) and `SeaMarineReptileData`.
//

import SwiftUI

struct MarineReptilePuzzleGameConfig: Equatable {
    let id: String
    let title: String
    let introAudio: String
}

enum MarineReptilePuzzleGameConfigs {
    static let marinePuzzle = MarineReptilePuzzleGameConfig(
        id: "marine-reptile-puzzle",
        title: "Marine Reptile Puzzle",
        introAudio: "game-marine-reptile-puzzle"
    )
}

struct MarineReptilePuzzleGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: MarineReptilePuzzleGameConfig

    var body: some View {
        PortraitJigsawPuzzleGameView(isPresented: $isPresented, line: .marineReptile(gameConfig))
    }
}
