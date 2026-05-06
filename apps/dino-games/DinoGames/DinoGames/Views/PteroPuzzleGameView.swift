//
//  PteroPuzzleGameView.swift
//  DinoGames
//
//  Ptero Puzzle: same portrait jigsaw as Dino Puzzle, using pterosaur guess groups and `AirPterosaurData`.
//

import SwiftUI

struct PteroPuzzleGameConfig: Equatable {
    let id: String
    let title: String
    let introAudio: String
}

enum PteroPuzzleGameConfigs {
    static let pteroPuzzle = PteroPuzzleGameConfig(
        id: "ptero-puzzle",
        title: "Ptero Puzzle",
        introAudio: "game-ptero-puzzle"
    )
}

struct PteroPuzzleGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: PteroPuzzleGameConfig

    var body: some View {
        PortraitJigsawPuzzleGameView(isPresented: $isPresented, line: .pterosaur(gameConfig))
    }
}
