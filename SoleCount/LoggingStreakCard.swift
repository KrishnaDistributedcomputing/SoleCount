import SwiftUI

/// Current and best logging runs, plus a short explanation.
/// The card does not animate, so Reduce Motion has nothing to turn off.
/// Text styles grow with Dynamic Type, and VoiceOver reads one label.
struct LoggingStreakCard: View {
    var consistency: LoggingConsistency

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Logging streak", systemImage: "shoe.2.fill")
                .font(.headline)
                .labelStyle(.titleAndIcon)
            Text(consistency.kudos)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Text("Current \(consistency.current) · Best \(consistency.best)")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Text(consistency.howItCounts)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(consistency.accessibilityLabel)
        .accessibilityIdentifier("loggingStreakCard")
    }
}
