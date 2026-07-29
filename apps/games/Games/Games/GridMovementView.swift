//
//  GridMovementView.swift
//  Games
//

import SwiftUI

struct GridMovementView: View {
    @State private var game = GridMovementGame()
    @State private var showBirdseye = false

    private let wallColor = Color(red: 0.35, green: 0.28, blue: 0.22)
    private let pathA = Color(red: 0.72, green: 0.82, blue: 0.62)
    private let pathB = Color(red: 0.62, green: 0.74, blue: 0.52)

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(game.playerLabel)
                    .font(.headline.monospacedDigit())
                Text(game.cameraLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            viewport
                .frame(maxHeight: 320)

            controls

            Button {
                showBirdseye = true
            } label: {
                Label("Bird’s-eye map (16×16)", systemImage: "map")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)

            Button("Reset to center", action: game.reset)
                .buttonStyle(.bordered)
        }
        .padding()
        .navigationTitle("Grid Movement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showBirdseye = true
                } label: {
                    Image(systemName: "map")
                }
                .accessibilityLabel("Bird’s-eye map")
            }
        }
        .sheet(isPresented: $showBirdseye) {
            NavigationStack {
                birdseye
                    .padding()
                    .navigationTitle("Bird’s-eye")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showBirdseye = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var viewport: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("4×4 view")
                .font(.subheadline.weight(.semibold))

            GeometryReader { proxy in
                let cell = min(proxy.size.width, proxy.size.height) / CGFloat(GridMovementGame.viewSize)
                VStack(spacing: 0) {
                    ForEach(0..<GridMovementGame.viewSize, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<GridMovementGame.viewSize, id: \.self) { column in
                                let mapPoint = GridPoint(
                                    row: game.camera.row + row,
                                    column: game.camera.column + column
                                )
                                tileView(
                                    kind: game.tile(at: mapPoint) ?? .wall,
                                    mapPoint: mapPoint,
                                    size: cell,
                                    showDog: game.player == mapPoint
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.primary.opacity(0.2), lineWidth: 1)
            }
        }
    }

    private var birdseye: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Full 16×16 map")
                .font(.subheadline.weight(.semibold))
            Text("Yellow frame = what the 4×4 view shows · 🐶 = you")
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { proxy in
                let cell = proxy.size.width / CGFloat(GridMovementGame.mapSize)
                ZStack(alignment: .topLeading) {
                    VStack(spacing: 0) {
                        ForEach(0..<GridMovementGame.mapSize, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<GridMovementGame.mapSize, id: \.self) { column in
                                    let point = GridPoint(row: row, column: column)
                                    Rectangle()
                                        .fill(fill(for: game.tile(at: point) ?? .wall, at: point))
                                        .frame(width: cell, height: cell)
                                        .overlay {
                                            if game.player == point {
                                                Text("🐶")
                                                    .font(.system(size: max(8, cell * 0.85)))
                                            }
                                        }
                                }
                            }
                        }
                    }

                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(Color.yellow, lineWidth: 2)
                        .frame(
                            width: cell * CGFloat(GridMovementGame.viewSize),
                            height: cell * CGFloat(GridMovementGame.viewSize)
                        )
                        .offset(
                            x: cell * CGFloat(game.camera.column),
                            y: cell * CGFloat(game.camera.row)
                        )
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.primary.opacity(0.2), lineWidth: 1)
            }

            Text(game.playerLabel)
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            moveButton(.up, systemImage: "chevron.up")
            HStack(spacing: 10) {
                moveButton(.left, systemImage: "chevron.left")
                moveButton(.down, systemImage: "chevron.down")
                moveButton(.right, systemImage: "chevron.right")
            }
        }
    }

    private func moveButton(_ direction: GridMoveDirection, systemImage: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.12)) {
                game.move(direction)
            }
        } label: {
            Image(systemName: systemImage)
                .font(.title2.weight(.bold))
                .frame(width: 64, height: 48)
        }
        .buttonStyle(.borderedProminent)
    }

    private func tileView(kind: GridTileKind, mapPoint: GridPoint, size: CGFloat, showDog: Bool) -> some View {
        ZStack {
            Rectangle()
                .fill(fill(for: kind, at: mapPoint))

            if kind == .wall {
                Image(systemName: "rectangle.split.3x3.fill")
                    .font(.system(size: size * 0.35))
                    .foregroundStyle(.white.opacity(0.55))
            } else {
                Image(systemName: "leaf.fill")
                    .font(.system(size: size * 0.22))
                    .foregroundStyle(.green.opacity(0.45))
            }

            if showDog {
                Text("🐶")
                    .font(.system(size: size * 0.55))
            }

            Text("\(mapPoint.row),\(mapPoint.column)")
                .font(.system(size: max(8, size * 0.14), weight: .medium).monospacedDigit())
                .foregroundStyle(.black.opacity(0.35))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(3)
        }
        .frame(width: size, height: size)
        .overlay {
            Rectangle()
                .strokeBorder(.black.opacity(0.08), lineWidth: 0.5)
        }
    }

    private func fill(for kind: GridTileKind, at point: GridPoint) -> Color {
        switch kind {
        case .wall:
            return wallColor
        case .path:
            return (point.row + point.column).isMultiple(of: 2) ? pathA : pathB
        }
    }
}

#Preview {
    NavigationStack {
        GridMovementView()
    }
}
