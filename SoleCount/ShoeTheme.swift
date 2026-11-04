import SwiftUI
import UIKit

/// Warm sunrise colours. Light mode stays peach and gold. Dark mode stays deep and warm.
/// Words on a sunrise fill use `ink`, which stays readable in both modes.
enum ShoeTheme {
    static func adaptive(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        Color(uiColor: UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        })
    }

    /// Coral, gold, and mint. Dark mode uses the deeper versions of the same hues.
    static var today: [Color] {
        [
            fill(0.93, 0.45, 0.38, 0.55, 0.24, 0.20),
            fill(0.95, 0.72, 0.40, 0.62, 0.38, 0.16),
            fill(0.55, 0.78, 0.66, 0.16, 0.40, 0.36)
        ]
    }

    /// Dark brown on a light sunrise, cream on a dark one.
    static var ink: Color {
        adaptive(light: (0.24, 0.12, 0.08), dark: (1.0, 0.96, 0.91))
    }

    static var canvas: Color {
        adaptive(light: (0.99, 0.96, 0.93), dark: (0.11, 0.09, 0.08))
    }

    static var cardFill: Color {
        adaptive(light: (1.0, 0.97, 0.94), dark: (0.20, 0.15, 0.13))
    }

    static var shadow: Color {
        adaptive(light: (0.72, 0.36, 0.24), dark: (0.0, 0.0, 0.0))
    }

    static var glow: Color {
        adaptive(light: (0.95, 0.62, 0.32), dark: (0.95, 0.72, 0.45))
    }

    /// Quiet text on cards. Warm brown by day, soft cream at night. At least 4.5:1 on every card and canvas.
    static var softText: Color {
        adaptive(light: (0.45, 0.33, 0.27), dark: (0.86, 0.78, 0.72))
    }

    /// The main button colour. Deep coral by day so white words read clearly, bright coral at night with dark words.
    static var coral: Color {
        adaptive(light: (0.74, 0.30, 0.23), dark: (0.96, 0.58, 0.48))
    }

    /// Words on a `coral` button.
    static var onCoral: Color {
        adaptive(light: (1.0, 1.0, 1.0), dark: (0.24, 0.12, 0.08))
    }

    /// Ring, bar, and icon tints. Each one is at least 3:1 on a card in both modes.
    static var coralTint: Color {
        adaptive(light: (0.80, 0.33, 0.26), dark: (0.96, 0.52, 0.42))
    }

    static var goldTint: Color {
        adaptive(light: (0.74, 0.46, 0.08), dark: (0.97, 0.74, 0.38))
    }

    static var mintTint: Color {
        adaptive(light: (0.16, 0.55, 0.42), dark: (0.45, 0.80, 0.64))
    }

    /// Flame and star icons, in place of the system orange that faded on peach.
    static var flame: Color {
        adaptive(light: (0.80, 0.38, 0.10), dark: (0.98, 0.64, 0.36))
    }

    /// Backgrounds for a pair. Bright enough for `ink` in the day, deep enough for cream at night.
    static func colors(for type: ShoeType) -> [Color] {
        switch type {
        case .running:
            [fill(0.93, 0.45, 0.38, 0.55, 0.24, 0.20), fill(0.96, 0.62, 0.40, 0.62, 0.32, 0.16)]
        case .walking:
            [fill(0.55, 0.78, 0.66, 0.16, 0.40, 0.36), fill(0.78, 0.88, 0.70, 0.22, 0.46, 0.32)]
        case .trail:
            [fill(0.86, 0.68, 0.40, 0.42, 0.30, 0.14), fill(0.62, 0.72, 0.42, 0.24, 0.38, 0.18)]
        case .basketball:
            [fill(0.94, 0.58, 0.32, 0.58, 0.30, 0.12), fill(0.96, 0.74, 0.42, 0.62, 0.38, 0.16)]
        case .lifestyle:
            [fill(0.92, 0.62, 0.58, 0.48, 0.24, 0.26), fill(0.96, 0.74, 0.62, 0.55, 0.32, 0.28)]
        case .training:
            [fill(0.94, 0.52, 0.42, 0.55, 0.26, 0.20), fill(0.96, 0.70, 0.48, 0.60, 0.36, 0.18)]
        case .tennis:
            [fill(0.72, 0.82, 0.42, 0.32, 0.42, 0.16), fill(0.86, 0.88, 0.55, 0.40, 0.46, 0.18)]
        case .skate:
            [fill(0.55, 0.70, 0.78, 0.16, 0.32, 0.40), fill(0.78, 0.84, 0.88, 0.22, 0.38, 0.46)]
        case .hiking:
            [fill(0.55, 0.70, 0.48, 0.18, 0.36, 0.22), fill(0.78, 0.72, 0.42, 0.36, 0.32, 0.16)]
        case .soccer:
            [fill(0.48, 0.74, 0.50, 0.14, 0.38, 0.22), fill(0.74, 0.86, 0.55, 0.28, 0.44, 0.20)]
        case .golf:
            [fill(0.55, 0.78, 0.66, 0.16, 0.40, 0.34), fill(0.78, 0.86, 0.62, 0.30, 0.46, 0.28)]
        case .boots:
            [fill(0.78, 0.58, 0.40, 0.40, 0.26, 0.14), fill(0.90, 0.72, 0.50, 0.52, 0.34, 0.18)]
        case .sandals:
            [fill(0.96, 0.74, 0.48, 0.55, 0.36, 0.16), fill(0.55, 0.78, 0.74, 0.16, 0.40, 0.38)]
        case .dress:
            [fill(0.78, 0.55, 0.62, 0.40, 0.22, 0.30), fill(0.92, 0.70, 0.62, 0.50, 0.30, 0.32)]
        case .other:
            [fill(0.82, 0.70, 0.62, 0.36, 0.28, 0.24), fill(0.92, 0.80, 0.68, 0.46, 0.36, 0.28)]
        }
    }

    /// Icon colour on a card. Darker by day, lighter at night, so it stays easy to see.
    static func accent(for type: ShoeType) -> Color {
        switch type {
        case .running, .training:
            adaptive(light: (0.62, 0.24, 0.18), dark: (0.96, 0.62, 0.48))
        case .walking, .golf, .sandals:
            adaptive(light: (0.12, 0.42, 0.32), dark: (0.55, 0.82, 0.70))
        case .trail, .hiking, .boots:
            adaptive(light: (0.40, 0.28, 0.12), dark: (0.86, 0.70, 0.42))
        case .basketball, .tennis:
            adaptive(light: (0.62, 0.32, 0.10), dark: (0.96, 0.70, 0.40))
        case .lifestyle, .dress:
            adaptive(light: (0.55, 0.28, 0.32), dark: (0.94, 0.68, 0.70))
        case .skate:
            adaptive(light: (0.16, 0.32, 0.42), dark: (0.62, 0.78, 0.86))
        case .soccer:
            adaptive(light: (0.14, 0.40, 0.22), dark: (0.55, 0.82, 0.58))
        case .other:
            adaptive(light: (0.42, 0.30, 0.24), dark: (0.92, 0.78, 0.66))
        }
    }

    private static func fill(
        _ lightRed: Double, _ lightGreen: Double, _ lightBlue: Double,
        _ darkRed: Double, _ darkGreen: Double, _ darkBlue: Double
    ) -> Color {
        adaptive(
            light: (lightRed, lightGreen, lightBlue),
            dark: (darkRed, darkGreen, darkBlue)
        )
    }
}

/// The big coral call-to-action button used on empty screens.
struct SunriseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(ShoeTheme.onCoral)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .frame(minHeight: 50)
            .background(ShoeTheme.coral, in: Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .shadow(color: ShoeTheme.shadow.opacity(0.25), radius: 8, y: 4)
    }
}

extension View {
    /// A rounded card with a warm fill and a soft shadow.
    func warmCard() -> some View {
        background(ShoeTheme.cardFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: ShoeTheme.shadow.opacity(0.22), radius: 12, y: 6)
    }
}
