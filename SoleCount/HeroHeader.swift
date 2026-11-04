import SwiftUI

/// A bold gradient banner used at the top of Today and a pair's page.
struct HeroHeader: View {
    var title: String
    var subtitle: String
    var symbol: String
    var colors: [Color]

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.largeTitle.bold())
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: symbol)
                    .font(.largeTitle)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
            .padding(22)
        }
        .shadow(color: (colors.first ?? .clear).opacity(0.35), radius: 16, y: 8)
        .accessibilityElement(children: .combine)
    }
}
