import SwiftUI

/// A rounded progress bar in a sunrise tint. The track is a pale version of the same colour.
struct SunriseBar: View {
    var fraction: Double
    var tint: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(tint.opacity(0.2))
                Capsule()
                    .fill(tint.gradient)
                    .frame(width: max(clamped > 0 ? 10 : 0, geo.size.width * clamped))
            }
        }
        .frame(height: 10)
        .animation(reduceMotion || LaunchFlags.screenshots ? nil : .easeOut(duration: 0.6), value: clamped)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int((clamped * 100).rounded())) percent")
    }
}
