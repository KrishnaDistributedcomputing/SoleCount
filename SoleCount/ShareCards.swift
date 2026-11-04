import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// A PNG the share sheet can hand to another app. The picture is made on this iPhone.
struct PNGShare: Transferable {
    var data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { share in
            share.data
        }
    }
}

enum CardRenderer {
    @MainActor
    static func png<V: View>(@ViewBuilder content: () -> V) -> Data? {
        let renderer = ImageRenderer(content: content().frame(width: 360, height: 480))
        renderer.scale = 2
        return renderer.uiImage?.pngData()
    }
}

/// The picture shared from Stats. Kilometres are forced so the card matches the guide.
struct ShareCardBody: View {
    var summary: ReviewSummary

    /// Fixed sunrise ink so the shared picture stays bright and readable.
    private static let ink = Color(red: 0.24, green: 0.12, blue: 0.08)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SoleCount")
                .font(.headline)
                .foregroundStyle(Self.ink.opacity(0.8))
            Text(summary.title)
                .font(.largeTitle.bold())
                .foregroundStyle(Self.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let top = summary.topPair {
                Text("Top pair: \(top)")
                    .font(.title3)
                    .foregroundStyle(Self.ink)
            }
            Text(DistanceFormat.string(meters: summary.totalMeters, forceMetric: true))
                .font(.title.bold())
                .foregroundStyle(Self.ink)
            Text("\(summary.wears) wears")
                .font(.title3)
                .foregroundStyle(Self.ink)
            Text("Best streak: \(summary.bestStreak) days")
                .font(.title3)
                .foregroundStyle(Self.ink)
            Spacer(minLength: 0)
            Text("On this iPhone. Not a medical app.")
                .font(.caption)
                .foregroundStyle(Self.ink.opacity(0.8))
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.55, blue: 0.42),
                    Color(red: 0.98, green: 0.75, blue: 0.45),
                    Color(red: 0.62, green: 0.82, blue: 0.70)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
