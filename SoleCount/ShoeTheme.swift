import SwiftUI

/// Colours for each shoe type. Drawn in code so the app stays small.
enum ShoeTheme {
    static var today: [Color] {
        [Color(red: 0.12, green: 0.40, blue: 0.92), Color(red: 0.36, green: 0.22, blue: 0.82)]
    }

    static func colors(for type: ShoeType) -> [Color] {
        switch type {
        case .running:
            [Color(red: 0.95, green: 0.35, blue: 0.16), Color(red: 0.78, green: 0.12, blue: 0.28)]
        case .walking:
            [Color(red: 0.12, green: 0.62, blue: 0.42), Color(red: 0.08, green: 0.42, blue: 0.48)]
        case .trail:
            [Color(red: 0.45, green: 0.34, blue: 0.18), Color(red: 0.22, green: 0.42, blue: 0.24)]
        case .basketball:
            [Color(red: 0.92, green: 0.42, blue: 0.08), Color(red: 0.72, green: 0.16, blue: 0.08)]
        case .lifestyle:
            [Color(red: 0.36, green: 0.28, blue: 0.82), Color(red: 0.22, green: 0.22, blue: 0.55)]
        case .training:
            [Color(red: 0.86, green: 0.22, blue: 0.48), Color(red: 0.55, green: 0.16, blue: 0.48)]
        case .tennis:
            [Color(red: 0.55, green: 0.72, blue: 0.12), Color(red: 0.16, green: 0.52, blue: 0.28)]
        case .skate:
            [Color(red: 0.15, green: 0.45, blue: 0.72), Color(red: 0.10, green: 0.22, blue: 0.42)]
        case .hiking:
            [Color(red: 0.18, green: 0.48, blue: 0.28), Color(red: 0.12, green: 0.28, blue: 0.22)]
        case .soccer:
            [Color(red: 0.10, green: 0.55, blue: 0.28), Color(red: 0.06, green: 0.32, blue: 0.22)]
        case .golf:
            [Color(red: 0.20, green: 0.62, blue: 0.48), Color(red: 0.12, green: 0.36, blue: 0.32)]
        case .boots:
            [Color(red: 0.48, green: 0.30, blue: 0.16), Color(red: 0.28, green: 0.16, blue: 0.10)]
        case .sandals:
            [Color(red: 0.15, green: 0.62, blue: 0.72), Color(red: 0.10, green: 0.36, blue: 0.62)]
        case .dress:
            [Color(red: 0.42, green: 0.22, blue: 0.58), Color(red: 0.22, green: 0.12, blue: 0.32)]
        case .other:
            [Color(red: 0.35, green: 0.38, blue: 0.45), Color(red: 0.18, green: 0.20, blue: 0.26)]
        }
    }

    static func accent(for type: ShoeType) -> Color {
        colors(for: type).first ?? .accentColor
    }
}
