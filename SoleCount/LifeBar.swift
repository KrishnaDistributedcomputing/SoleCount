import SwiftUI

/// Green, yellow, or red bar for a pair's distance target.
struct LifeBar: View {
    var fraction: Double

    private var band: LifeBand { RetirementMath.band(for: fraction) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.18))
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geo.size.width * min(fraction, 1)))
            }
        }
        .frame(height: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }

    private var color: Color {
        switch band {
        case .none, .green: Color.green
        case .yellow: Color(red: 0.72, green: 0.52, blue: 0.0)
        case .red: Color.red
        }
    }

    private var label: String {
        let percent = Int((min(fraction, 9) * 100).rounded())
        switch band {
        case .none: return "No distance target"
        case .green: return "\(percent) percent of the distance target"
        case .yellow: return "\(percent) percent of the distance target, getting close"
        case .red: return "Distance target reached"
        }
    }
}
