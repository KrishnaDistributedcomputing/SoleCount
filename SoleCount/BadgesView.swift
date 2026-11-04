import SwiftUI

/// Every badge, locked and unlocked. Nothing here is sent off the phone.
struct BadgesView: View {
    var badges: [Badge]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Unlocked badges stay on this iPhone. Locked ones are just next steps.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                AchievementGrid(badges: badges)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Badges")
        .navigationBarTitleDisplayMode(.inline)
    }
}
