import SwiftUI

/// How close a pair is to the distance you chose to replace it.
struct MileageGoalCard: View {
    var meters: Double
    var goalKilometers: Double
    var tint: Color

    private var progress: Double {
        guard goalKilometers > 0 else { return 0 }
        return meters / (goalKilometers * 1_000)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                ProgressRing(
                    progress: progress,
                    tint: tint,
                    lineWidth: 10,
                    label: DistanceFormat.string(meters: meters),
                    caption: "of \(DistanceFormat.string(meters: goalKilometers * 1_000))"
                )
                .frame(width: 120)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Replace at")
                        .font(.headline)
                    Text("A gentle target for when this pair has done its job. SoleCount does not retire it for you.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            if progress >= 1 {
                Label("Time to retire these?", systemImage: "shoe.fill")
                    .font(.headline)
                    .foregroundStyle(tint)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
