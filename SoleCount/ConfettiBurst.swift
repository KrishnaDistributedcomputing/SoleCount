import SwiftUI

/// A short burst of dots. Reduce Motion skips it.
struct ConfettiBurst: View {
    var trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pieces: [Piece] = []

    private struct Piece: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var color: Color
        var opacity: Double
    }

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                Circle()
                    .fill(piece.color)
                    .frame(width: 8, height: 8)
                    .offset(x: piece.x, y: piece.y)
                    .opacity(piece.opacity)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0, !reduceMotion, !LaunchFlags.screenshots else { return }
            burst()
        }
    }

    private func burst() {
        let colors: [Color] = [
            Color(red: 0.93, green: 0.45, blue: 0.38),
            Color(red: 0.96, green: 0.72, blue: 0.55),
            Color(red: 0.95, green: 0.78, blue: 0.42),
            Color(red: 0.55, green: 0.78, blue: 0.66)
        ]
        pieces = (0..<16).map { _ in
            Piece(x: 0, y: 0, color: colors.randomElement() ?? .orange, opacity: 1)
        }
        withAnimation(.easeOut(duration: 0.9)) {
            pieces = pieces.map { piece in
                var moved = piece
                moved.x = CGFloat.random(in: -140...140)
                moved.y = CGFloat.random(in: -220...40)
                moved.opacity = 0
                return moved
            }
        }
    }
}
