//
//  SudokuView.swift
//  Games
//

import SwiftUI

struct SudokuView: View {
    @State private var game = SudokuGame()

    var body: some View {
        VStack(spacing: 20) {
            Text(statusText)
                .font(.title3)
                .foregroundStyle(statusColor)
                .animation(.default, value: statusText)

            SudokuBoardView(game: game)

            numberPad

            HStack(spacing: 12) {
                Button("Restart", action: game.restart)
                    .buttonStyle(.bordered)
                Button("New Puzzle", action: game.newGame)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Sudoku")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusText: String {
        switch game.status {
        case .solved:
            return "Solved!"
        case .playing:
            if game.selectedIndex == nil {
                return "Select a cell"
            }
            if let index = game.selectedIndex, game.isGiven[index] {
                return "Clue cell"
            }
            return "Enter a number"
        }
    }

    private var statusColor: Color {
        game.status == .solved ? .green : .secondary
    }

    private var numberPad: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { digit in
                    numberButton(digit)
                }
            }
            HStack(spacing: 8) {
                ForEach(6...9, id: \.self) { digit in
                    numberButton(digit)
                }
                Button {
                    game.erase()
                } label: {
                    Image(systemName: "delete.left")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .disabled(eraseDisabled)
            }
        }
    }

    private var eraseDisabled: Bool {
        guard let index = game.selectedIndex else { return true }
        return game.isGiven[index] || game.status == .solved || game.values[index] == 0
    }

    private func numberButton(_ digit: Int) -> some View {
        Button {
            game.enter(digit)
        } label: {
            Text("\(digit)")
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .disabled(game.status == .solved || game.selectedIndex == nil || selectedIsGiven)
    }

    private var selectedIsGiven: Bool {
        guard let index = game.selectedIndex else { return true }
        return game.isGiven[index]
    }
}

private struct SudokuBoardView: View {
    @Bindable var game: SudokuGame

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let cell = size / 9

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.primary.opacity(0.35), lineWidth: 2)

                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { column in
                                let index = row * 9 + column
                                cellView(index: index, row: row, column: column, cellSize: cell)
                            }
                        }
                    }
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxHeight: 420)
    }

    private func cellView(index: Int, row: Int, column: Int, cellSize: CGFloat) -> some View {
        let value = game.values[index]
        let isSelected = game.selectedIndex == index
        let isConflict = game.conflictIndices.contains(index)
        let isPeer = isPeerOfSelection(row: row, column: column)
        let selectedValue = game.selectedIndex.map { game.values[$0] } ?? 0
        let matchesSelected = value != 0 && value == selectedValue

        return Button {
            game.select(index)
        } label: {
            ZStack {
                Rectangle()
                    .fill(backgroundColor(
                        isSelected: isSelected,
                        isPeer: isPeer,
                        matchesSelected: matchesSelected,
                        isConflict: isConflict
                    ))

                if value != 0 {
                    Text("\(value)")
                        .font(.system(size: cellSize * 0.48, weight: game.isGiven[index] ? .bold : .medium))
                        .monospacedDigit()
                        .foregroundStyle(numberColor(index: index, isConflict: isConflict))
                }
            }
            .frame(width: cellSize, height: cellSize)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(column % 3 == 2 ? Color.primary.opacity(0.55) : Color.primary.opacity(0.18))
                    .frame(width: column % 3 == 2 ? 2 : 0.5)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(row % 3 == 2 ? Color.primary.opacity(0.55) : Color.primary.opacity(0.18))
                    .frame(height: row % 3 == 2 ? 2 : 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(row: row, column: column, value: value))
    }

    private func isPeerOfSelection(row: Int, column: Int) -> Bool {
        guard let selected = game.selectedIndex else { return false }
        let selectedRow = selected / 9
        let selectedColumn = selected % 9
        let sameBox = selectedRow / 3 == row / 3 && selectedColumn / 3 == column / 3
        return selectedRow == row || selectedColumn == column || sameBox
    }

    private func backgroundColor(
        isSelected: Bool,
        isPeer: Bool,
        matchesSelected: Bool,
        isConflict: Bool
    ) -> Color {
        if isSelected {
            return Color.accentColor.opacity(0.28)
        }
        if isConflict {
            return Color.red.opacity(0.12)
        }
        if matchesSelected {
            return Color.accentColor.opacity(0.14)
        }
        if isPeer {
            return Color.primary.opacity(0.05)
        }
        return Color.clear
    }

    private func numberColor(index: Int, isConflict: Bool) -> Color {
        if isConflict {
            return .red
        }
        return game.isGiven[index] ? .primary : .blue
    }

    private func accessibilityLabel(row: Int, column: Int, value: Int) -> String {
        let position = "Row \(row + 1), column \(column + 1)"
        if value == 0 {
            return "\(position), empty"
        }
        return "\(position), \(value)"
    }
}

#Preview {
    NavigationStack {
        SudokuView()
    }
}
