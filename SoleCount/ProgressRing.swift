import SwiftUI

/// An Activity-style ring. The arc animates unless Reduce Motion is on.
struct ProgressRing: View {
    var progress: Double
    var tint: Color
    var lineWidth: CGFloat = 12
    var label: String
    var caption: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = 0.0

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(tint.opacity(0.18), lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: shown)
                    .stroke(
                        tint.gradient,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: tint.opacity(0.45), radius: 6)
                Text(label)
                    .font(.title3.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .snappy, value: label)
                    .padding(.horizontal, lineWidth)
            }
            .aspectRatio(1, contentMode: .fit)
            .onAppear { animate(to: clamped) }
            .onChange(of: clamped) { _, newValue in animate(to: newValue) }

            Text(caption)
                .font(.caption)
                .foregroundStyle(ShoeTheme.softText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption), \(label)")
    }

    private func animate(to value: Double) {
        if reduceMotion || LaunchFlags.screenshots {
            shown = value
        } else {
            withAnimation(.easeOut(duration: 0.8)) {
                shown = value
            }
        }
    }
}
