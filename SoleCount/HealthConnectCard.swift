import SwiftUI

/// Explains the Apple Health read, and stays out of the way once it is connected.
struct HealthConnectCard: View {
    @Environment(HealthSync.self) private var health
    var onConnect: () -> Void
    var onRefresh: () -> Void

    var body: some View {
        if LaunchFlags.screenshots || LaunchFlags.demoData {
            EmptyView()
        } else {
            card
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Apple Health", systemImage: "heart.fill")
                .font(.headline)
                .foregroundStyle(.pink)
            switch health.access {
            case .unavailable:
                Text("Apple Health is not on this device, and that is okay. Wears, cost per wear, and the rest of SoleCount still work.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .notAsked:
                Text("SoleCount reads your steps and walking distance for the days you wore each pair. The numbers stay on this iPhone. Nothing is written to Health, and nothing is sent anywhere.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Connect Apple Health", action: onConnect)
                    .buttonStyle(.borderedProminent)
            case .ready:
                Text("Connected. Steps and distance stay on this iPhone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button(action: onRefresh) {
                    if health.isRefreshing {
                        ProgressView()
                    } else {
                        Text("Refresh")
                    }
                }
                .buttonStyle(.bordered)
            case .failed(let message):
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Try Again", action: onConnect)
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .warmCard()
    }
}
