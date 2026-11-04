import SwiftUI

/// Shown once when a pair is retired. The history stays in the Hall of Fame.
struct SendOffView: View {
    var name: String
    var meters: Double
    var wears: Int
    var cost: Double?
    var daysOwned: Int

    @Environment(\.dismiss) private var dismiss
    @State private var burst = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("Send-off")
                    .font(.largeTitle.bold())
                    .accessibilityIdentifier("sendOffTitle")
                Text(name)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 8) {
                    Text(DistanceFormat.string(meters: meters))
                    Text("\(wears) wears")
                    Text(cost.map { "\($0.asCurrency) per wear" } ?? "No cost per wear yet")
                    Text("\(daysOwned) days owned")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .warmCard()
                Text("This pair has a story worth keeping. Retired pairs keep their stats, and you can bring this pair back any time.")
                    .font(.footnote)
                    .foregroundStyle(ShoeTheme.softText)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Keep in the Hall of Fame") { dismiss() }
                    .buttonStyle(SunriseButtonStyle())
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ShoeTheme.canvas)
            .overlay(alignment: .top) { ConfettiBurst(trigger: burst) }
            .onAppear { burst = 1 }
            .navigationTitle("Send-off")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
