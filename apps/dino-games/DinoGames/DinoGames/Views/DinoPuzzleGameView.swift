//
//  DinoPuzzleGameView.swift
//  DinoGames
//
//  Dino Puzzle: three rounds. Each round picks a dinosaur from a distinct clade, splits its portrait
//  into one of ten grid “jigsaw” patterns, and the player drags pieces onto matching slots.
//  Implementation is shared with Ptero Puzzle in `PortraitJigsawPuzzleGameView`.
//  Victory / completion UI lives in that shared view, not `StandardVictorySequenceViews`.
//

import SwiftUI

// MARK: - Config

struct DinoPuzzleGameConfig: Equatable {
    let id: String
    let title: String
    let introAudio: String
}

enum DinoPuzzleGameConfigs {
    static let dinoPuzzle = DinoPuzzleGameConfig(
        id: "dino-puzzle",
        title: "Dino Puzzle",
        introAudio: "game-dino-puzzle"
    )
}

struct DinoPuzzleGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: DinoPuzzleGameConfig

    var body: some View {
        PortraitJigsawPuzzleGameView(isPresented: $isPresented, line: .dinosaur(gameConfig))
    }
}
