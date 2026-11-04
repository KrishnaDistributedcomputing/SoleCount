import Foundation

/// The small snapshot the Home Screen widget reads.
/// The app writes it. The widget never talks to Apple Health itself.
struct WidgetSnapshot: Codable, Equatable {
    var todaySteps: Int
    var stepGoal: Int
    var streak: Int
    var updatedAt: Date

    static let empty = WidgetSnapshot(todaySteps: 0, stepGoal: 8_000, streak: 0, updatedAt: .distantPast)
}

enum WidgetStore {
    static let suiteName = "group.com.krishnav.SoleCount"
    static let key = "widgetSnapshot"

    static func save(_ snapshot: WidgetSnapshot, defaults: UserDefaults? = UserDefaults(suiteName: suiteName)) {
        guard let defaults, let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    static func load(defaults: UserDefaults? = UserDefaults(suiteName: suiteName)) -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
