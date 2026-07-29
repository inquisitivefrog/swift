//
//  ContentView.swift
//  Games
//
//  Created by Timothy Stilwell on 7/13/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(GameCatalog.sections, id: \.genre) { section in
                    Section {
                        ForEach(section.games) { game in
                            NavigationLink(value: game.id) {
                                GameRow(game: game)
                            }
                        }
                    } header: {
                        Label(section.genre.title, systemImage: section.genre.systemImage)
                    }
                }
            }
            .navigationTitle("Games")
            .navigationDestination(for: GameID.self) { gameID in
                gameDestination(for: gameID)
            }
        }
    }

    @ViewBuilder
    private func gameDestination(for id: GameID) -> some View {
        switch id {
        case .ticTacToe:
            TicTacToeView()
        case .sudoku:
            SudokuView()
        case .easyFrench:
            EasyFrenchView()
        case .undergroundMaze:
            UndergroundMazeView()
        case .sideScroller:
            SideScrollerView()
        case .gridMovement:
            GridMovementView()
        }
    }
}

private struct GameRow: View {
    let game: GameEntry

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.headline)
                Text(game.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(game.difficulty.title)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        } icon: {
            Image(systemName: game.systemImage)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
