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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SoleCount")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))
            Text(summary.title)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            if let top = summary.topPair {
                Text("Top pair: \(top)")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            Text(DistanceFormat.string(meters: summary.totalMeters, forceMetric: true))
                .font(.title.bold())
                .foregroundStyle(.white)
            Text("\(summary.wears) wears")
                .font(.title3)
                .foregroundStyle(.white)
            Text("Best streak: \(summary.bestStreak) days")
                .font(.title3)
                .foregroundStyle(.white)
            Spacer(minLength: 0)
            Text("On this iPhone. Not a medical app.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.35, blue: 0.85), Color(red: 0.45, green: 0.20, blue: 0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
