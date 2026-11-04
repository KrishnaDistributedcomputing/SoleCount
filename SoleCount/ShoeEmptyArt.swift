import SwiftUI

/// An empty-state picture made only of SF Symbols. No downloaded art.
struct ShoeEmptyArt: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(ShoeTheme.today[0].opacity(0.15))
                .frame(width: 160, height: 160)
            Image(systemName: "shoe.2.fill")
                .font(.system(size: 64))
                .foregroundStyle(ShoeTheme.today[0].gradient)
                .offset(y: 8)
            Image(systemName: "figure.walk")
                .font(.title)
                .foregroundStyle(.white)
                .padding(8)
                .background(Circle().fill(ShoeTheme.today[1]))
                .offset(x: 58, y: -48)
            Image(systemName: "heart.fill")
                .font(.caption)
                .foregroundStyle(.pink)
                .offset(x: -62, y: -36)
        }
        .accessibilityHidden(true)
        .padding(.bottom, 8)
    }
}
