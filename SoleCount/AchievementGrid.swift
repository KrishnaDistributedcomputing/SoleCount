import SwiftUI

/// Badges in a grid. Locked ones stay visible so the next walk has a target.
struct AchievementGrid: View {
    var badges: [Badge]

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
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                .foregroundStyle(badge.unlocked ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(badge.unlocked ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(Color.secondary.opacity(0.08)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(badge.unlocked ? Color.orange.opacity(0.45) : Color.clear, lineWidth: 1)
                )
                .opacity(badge.unlocked ? 1 : 0.72)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(badge.unlocked ? "\(badge.title), unlocked" : "\(badge.title), locked")
            }
        }
    }
}
