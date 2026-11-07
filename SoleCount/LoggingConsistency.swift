import Foundation

/// A day you logged a wear. This is not the step-goal streak.
///
/// Product choices, written down so the screen and the tests share them:
/// one local calendar day counts once; milestones are 3, 7, 14, and 30 days;
/// the best run is recomputed from the dates still saved.
struct LoggingConsistency: Equatable {
    var qualifyingDays: Set<Date>
    var current: Int
    var best: Int
    var loggedToday: Bool
    var reached: LoggingMilestone?
    var next: LoggingMilestone?
    var kudos: String
    var howItCounts: String

    var accessibilityLabel: String {
        "Logging streak. \(kudos) Current \(current) days. Best \(best) days. \(howItCounts)"
    }
}

/// Modest kudos for a logging run. Not a prize, and not a step goal.
enum LoggingMilestone: Int, CaseIterable, Equatable {
    case threeDays = 3
    case oneWeek = 7
    case twoWeeks = 14
    case oneMonth = 30

    var kudos: String {
        switch self {
        case .threeDays: "Three days in a row."
        case .oneWeek: "A week of logging."
        case .twoWeeks: "Two steady weeks."
        case .oneMonth: "A month of logging."
        }
    }

    static func reached(by days: Int) -> LoggingMilestone? {
        allCases.last { days >= $0.rawValue }
    }

    static func next(after days: Int) -> LoggingMilestone? {
        allCases.first { days < $0.rawValue }
    }
}

enum LoggingConsistencyMath {
    static let howItCounts = "This counts days you logged a wear, not your step goal. One local day counts once, even if you log several pairs. Starting wears with no date do not count. A future date does not."

    /// Days at or before `now`, one entry per local calendar day.
    /// Future calendar days are left out. Duplicate timestamps collapse.
    static func qualifyingDays(from wearDates: [Date], now: Date, calendar: Calendar) -> Set<Date> {
        let today = calendar.startOfDay(for: now)
        var days: Set<Date> = []
        for date in wearDates {
            let start = calendar.startOfDay(for: date)
            if start <= today {
                days.insert(start)
            }
        }
        return days
    }

    /// Longest run of consecutive local days still present. A removed date can shorten it.
    static func bestRun(days: Set<Date>, calendar: Calendar) -> Int {
        let sorted = days.sorted()
        guard var cursor = sorted.first else { return 0 }
        var best = 1
        var run = 1
        for day in sorted.dropFirst() {
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            if calendar.startOfDay(for: next) == day {
                run += 1
                best = max(best, run)
            } else if day != cursor {
                run = 1
            }
            cursor = day
        }
        return best
    }

    static func evaluate(wearDates: [Date], now: Date, calendar: Calendar) -> LoggingConsistency {
        let days = qualifyingDays(from: wearDates, now: now, calendar: calendar)
        let today = calendar.startOfDay(for: now)
        let current = MotionMath.streak(hitDays: days, now: now, calendar: calendar)
        let best = bestRun(days: days, calendar: calendar)
        let loggedToday = days.contains(today)
        let reached = LoggingMilestone.reached(by: current)
        let next = LoggingMilestone.next(after: current)
        return LoggingConsistency(
            qualifyingDays: days,
            current: current,
            best: best,
            loggedToday: loggedToday,
            reached: reached,
            next: next,
            kudos: message(current: current, best: best, loggedToday: loggedToday, reached: reached, next: next),
            howItCounts: howItCounts
        )
    }

    static func message(
        current: Int,
        best: Int,
        loggedToday: Bool,
        reached: LoggingMilestone?,
        next: LoggingMilestone?
    ) -> String {
        if current == 0 && best == 0 {
            return "Nothing logged yet. The first day you log a wear is day one."
        }
        if current == 0 {
            let days = best == 1 ? "1 day" : "\(best) days"
            let praise = LoggingMilestone.reached(by: best).map { " That run reached: \($0.kudos)" } ?? ""
            return "Your best logging run is \(days).\(praise) A new run starts the next day you log a wear."
        }
        let open = loggedToday ? "" : " Today is still open."
        let kudo = reached.map { " \($0.kudos)" } ?? ""
        let upcoming = next.map { " Next kudos at \($0.rawValue) days." } ?? ""
        return "\(current)-day logging streak.\(open)\(kudo)\(upcoming)"
    }
}
