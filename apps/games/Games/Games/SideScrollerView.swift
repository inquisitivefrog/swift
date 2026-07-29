//
//  SideScrollerView.swift
//  Games
//

import SpriteKit
import SwiftUI

struct SideScrollerView: View {
    @State private var session: SideScrollerSession
    @State private var scene: SideScrollerScene

    init() {
        let session = SideScrollerSession()
        let scene = SideScrollerScene(size: CGSize(width: 750, height: 420))
        scene.scaleMode = .resizeFill
        scene.attach(session: session)
        _session = State(initialValue: session)
        _scene = State(initialValue: scene)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(statusText)
                .font(.headline)
                .foregroundStyle(statusColor)

            SideScrollerSpriteContainer(scene: scene)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.primary.opacity(0.12), lineWidth: 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            controls
        }
        .padding()
        .navigationTitle("Side Scroller")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scene.isPaused = false
            scene.view?.isPaused = false
        }
    }

    private var statusText: String {
        switch session.status {
        case .playing:
            return "Auto-runs right — tap Jump over gaps"
        case .won:
            return "You made it!"
        case .lost:
            return "Fell into the canyon — try again"
        }
    }

    private var statusColor: Color {
        switch session.status {
        case .playing: .secondary
        case .won: .green
        case .lost: .orange
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if session.status == .playing {
                Button {
                    scene.jump()
                } label: {
                    Label("Jump", systemImage: "arrow.up.circle.fill")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 64)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .opacity(session.canJump ? 1 : 0.55)
                .animation(.easeInOut(duration: 0.12), value: session.canJump)
                .accessibilityHint(session.canJump ? "Jump" : "Jump available when on the ground")

                Text(session.canJump ? "Tap Jump before each gap" : "In the air…")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HoldButton(systemImage: "chevron.left", accessibilityLabel: "Move left") {
                    scene.setMovingLeft(true)
                } onRelease: {
                    scene.setMovingLeft(false)
                }
            } else {
                Button("Play Again") {
                    scene.restart()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}

/// UIKit-backed SKView so the scene stays running inside NavigationStack.
private struct SideScrollerSpriteContainer: UIViewRepresentable {
    let scene: SideScrollerScene

    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: .zero)
        view.preferredFramesPerSecond = 60
        view.ignoresSiblingOrder = true
        view.presentScene(scene)
        view.isPaused = false
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        uiView.isPaused = false
        scene.isPaused = false
        if uiView.scene !== scene {
            uiView.presentScene(scene)
        }
    }
}

private struct HoldButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var isPressed = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.title2.weight(.bold))
            .frame(width: 72, height: 44)
            .foregroundStyle(isPressed ? Color.white : Color.primary)
            .background(isPressed ? Color.accentColor : Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            onPress()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        onRelease()
                    }
            )
            .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    NavigationStack {
        SideScrollerView()
    }
}
