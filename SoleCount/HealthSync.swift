import Foundation
import Observation

/// Asks Apple Health for steps, then caches the split on each pair.
/// If Health is missing or the person says no, the rest of the app still works.
@MainActor
@Observable
final class HealthSync {
    enum Access: Equatable {
        case unavailable
        case notAsked
        case ready
        case failed(String)
    }

    static let askedKey = "healthAccessAsked"

    private(set) var access: Access
    private(set) var isRefreshing = false
    /// Set after a real query. nil when we skipped the query on purpose.
    private(set) var lastDaily: [Date: DailyActivity]?

    private let reader: any HealthActivityReading
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let healthDataAvailable: Bool

    init(
        reader: (any HealthActivityReading)? = nil,
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        healthDataAvailable: Bool? = nil
    ) {
        let available = LaunchFlags.healthUnavailable ? false : (healthDataAvailable ?? HealthKitActivityReader.isAvailable)
        self.healthDataAvailable = available
        if let reader {
            self.reader = reader
        } else if available {
            self.reader = HealthKitActivityReader()
        } else {
            self.reader = UnavailableHealthReader()
        }
        self.defaults = defaults
        self.calendar = calendar
        if !available {
            access = .unavailable
        } else if defaults.bool(forKey: Self.askedKey) {
            access = .ready
        } else {
            access = .notAsked
        }
    }

    var showsConnectPrompt: Bool {
        if LaunchFlags.screenshots || LaunchFlags.demoData { return false }
        switch access {
        case .notAsked, .failed:
            return true
        case .unavailable, .ready:
            return false
        }
    }

    func connectAndRefresh(sneakers: [Sneaker]) async {
        guard healthDataAvailable else {
            access = .unavailable
            return
        }
        do {
            try await reader.requestReadAccess()
            defaults.set(true, forKey: Self.askedKey)
            access = .ready
            await refresh(sneakers: sneakers, force: true)
        } catch {
            access = .failed("Apple Health did not open this time. Your wears and cost per wear are still right here.")
        }
    }

    /// Pulls steps when the person has already been asked. Never shows the system prompt by itself.
    func refresh(sneakers: [Sneaker], force: Bool = false) async {
        if LaunchFlags.screenshots || LaunchFlags.demoData { return }
        guard healthDataAvailable else {
            access = .unavailable
            return
        }
        guard force || defaults.bool(forKey: Self.askedKey) else {
            access = .notAsked
            return
        }
        let today = calendar.startOfDay(for: .now)
        let recent = calendar.date(byAdding: .day, value: -60, to: today) ?? today
        let wearStarts = sneakers.flatMap { sneaker in
            sneaker.wearDates.map { calendar.startOfDay(for: $0) }
        }
        var start = recent
        if let earliest = wearStarts.min(), earliest < start {
            start = earliest
        }
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86_400)

        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let totals = try await reader.dailyTotals(from: start, through: end, calendar: calendar)
            apply(totals, to: sneakers, now: .now)
            lastDaily = totals
            access = .ready
        } catch {
            access = .failed("Apple Health is quiet right now. Your wear log is safe on this iPhone.")
        }
    }

    private func apply(_ totals: [Date: DailyActivity], to sneakers: [Sneaker], now: Date) {
        let tagged = sneakers.map { sneaker -> (Sneaker, WearDayLog) in
            let days = Set(sneaker.wearDates.map { calendar.startOfDay(for: $0) })
            return (sneaker, WearDayLog(id: UUID(), days: days))
        }
        let results = HealthAttribution.attribute(
            logs: tagged.map(\.1),
            daily: totals,
            calendar: calendar,
            now: now
        )
        let byID = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0) })
        for item in tagged {
            item.0.applyHealth(byID[item.1.id] ?? AttributedShoe.empty(id: item.1.id))
        }
    }
}
