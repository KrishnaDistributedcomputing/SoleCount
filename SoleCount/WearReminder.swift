import Foundation
import UserNotifications

/// Local reminders only. Permission is asked when a switch is turned on, not at launch.
enum WearReminder {
    static func requestAccess() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    /// Rebuilds the daily reminders from the switches. Does not ask for permission.
    static func reschedule(
        morning: Bool,
        morningHour: Int,
        morningMinute: Int,
        evening: Bool,
        eveningHour: Int,
        eveningMinute: Int,
        eveningBody: String?
    ) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["solecount.morning", "solecount.evening"])
        guard await isAuthorized() else { return }
        if morning {
            await add(
                id: "solecount.morning",
                title: "Good morning. Which pair is coming with you?",
                body: "Log it in SoleCount whenever you head out.",
                hour: morningHour,
                minute: morningMinute
            )
        }
        if evening, let eveningBody {
            await add(
                id: "solecount.evening",
                title: "A short walk is still on the table",
                body: eveningBody,
                hour: eveningHour,
                minute: eveningMinute
            )
        }
    }

    /// 80% or 100% of a pair's distance. Only call this after the person turned reminders on.
    static func retirement(name: String, mark: RetirementMark) async {
        guard await isAuthorized() else { return }
        let content = UNMutableNotificationContent()
        content.title = name
        switch mark {
        case .eighty:
            content.body = "This pair is about 80% of the way to its distance target. It still has good days."
        case .full:
            content.body = "This pair reached its distance target. Thank it, or keep wearing it. Both are fine."
        }
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "solecount.retire.\(name).\(mark == .eighty ? "80" : "100")",
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func celebrate(title: String) async {
        guard await isAuthorized() else { return }
        let content = UNMutableNotificationContent()
        content.title = "New badge"
        content.body = "\(title). A small celebration for showing up."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "solecount.badge.\(title)",
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func eveningCopy(stepsToday: Int, goal: Int) -> String? {
        guard let remaining = MotionMath.stepsRemaining(stepsToday: stepsToday, goal: goal) else { return nil }
        let steps = remaining.stepsLeft.formatted()
        return "About \(steps) steps left. A \(remaining.minutes)-minute walk would feel great."
    }

    private static func add(id: String, title: String, body: String, hour: Int, minute: Int) async {
        var parts = DateComponents()
        parts.hour = hour
        parts.minute = minute
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
