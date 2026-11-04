import SwiftUI

/// Badges in a grid. Locked ones stay visible so the next walk has a target.
struct AchievementGrid: View {
    var badges: [Badge]
    var celebrate: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var popped = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(badges) { badge in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: badge.symbol)
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                        Spacer()
                        if !badge.unlocked {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .accessibilityLabel("Locked")
                        }
                    }
                    Text(badge.title)
                        .font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(badge.detail)
                        .font(.caption)
                        .foregroundStyle(ShoeTheme.softText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                .foregroundStyle(badge.unlocked ? AnyShapeStyle(.primary) : AnyShapeStyle(ShoeTheme.softText))
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(badge.unlocked ? AnyShapeStyle(ShoeTheme.cardFill) : AnyShapeStyle(ShoeTheme.canvas))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(badge.unlocked ? ShoeTheme.glow.opacity(0.7) : Color.clear, lineWidth: 1.5)
                )
                .shadow(color: badge.unlocked ? ShoeTheme.glow.opacity(popped ? 0.55 : 0.2) : .clear, radius: popped ? 14 : 6)
                .scaleEffect(popped && badge.unlocked ? 1.04 : 1)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(badge.unlocked ? "\(badge.title), unlocked" : "\(badge.title), locked")
            }
        }
        .onChange(of: celebrate) { _, newValue in
            guard newValue > 0, !reduceMotion, !LaunchFlags.screenshots else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { popped = true }
            Task {
                try? await Task.sleep(for: .milliseconds(700))
                withAnimation(.easeOut(duration: 0.35)) { popped = false }
            }
        }
    }
}
