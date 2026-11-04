import Foundation

/// Steps and distance for one local day. Saved on the phone so Today opens fast.
struct DayTotal: Codable, Equatable, Identifiable {
    var day: Date
    var steps: Double
    var meters: Double

    var id: Date { day }
}

enum WeekTrend: Equatable {
    case up, down, flat
}

/// Step goals, streaks, and week totals. No HealthKit types, so tests stay simple.
enum MotionMath {
    static let briskStepsPerMinute = 115

    static func streak(hitDays: Set<Date>, now: Date, calendar: Calendar) -> Int {
        let today = calendar.startOfDay(for: now)
        var cursor = today
        if !hitDays.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
                  hitDays.contains(yesterday) else { return 0 }
            cursor = yesterday
        }
        var count = 0
        while hitDays.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    static func hitDays(from days: [DayTotal], stepGoal: Int, calendar: Calendar) -> Set<Date> {
        Set(days.compactMap { day in
            day.steps >= Double(stepGoal) ? calendar.startOfDay(for: day.day) : nil
        })
    }

    /// The last `count` calendar days, oldest first. Missing days count as zero.
    static func lastDays(_ count: Int, from days: [DayTotal], now: Date, calendar: Calendar) -> [DayTotal] {
        let today = calendar.startOfDay(for: now)
        return (0..<count).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -(count - 1 - offset), to: today) else { return nil }
            let match = days.first { calendar.isDate($0.day, inSameDayAs: day) }
            return DayTotal(day: day, steps: match?.steps ?? 0, meters: match?.meters ?? 0)
        }
    }

    static func weekMeters(days: [DayTotal], now: Date, calendar: Calendar) -> (thisWeek: Double, lastWeek: Double) {
        let thisStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        let lastStart = calendar.date(byAdding: .day, value: -7, to: thisStart) ?? thisStart
        var thisWeek = 0.0
        var lastWeek = 0.0
        for day in days {
            let start = calendar.startOfDay(for: day.day)
            if start >= thisStart {
                thisWeek += day.meters
            } else if start >= lastStart && start < thisStart {
                lastWeek += day.meters
            }
        }
        return (thisWeek, lastWeek)
    }

    static func wearCounts(dates: [Date], now: Date, calendar: Calendar) -> (thisWeek: Int, lastWeek: Int) {
        let thisStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        let lastStart = calendar.date(byAdding: .day, value: -7, to: thisStart) ?? thisStart
        var thisWeek = 0
        var lastWeek = 0
        for date in dates {
            if date >= thisStart {
                thisWeek += 1
            } else if date >= lastStart && date < thisStart {
                lastWeek += 1
            }
        }
        return (thisWeek, lastWeek)
    }

    static func bestWeekMeters(days: [DayTotal], calendar: Calendar) -> Double {
        var totals: [Date: Double] = [:]
        for day in days {
            let start = calendar.dateInterval(of: .weekOfYear, for: day.day)?.start ?? calendar.startOfDay(for: day.day)
            totals[start, default: 0] += day.meters
        }
        return totals.values.max() ?? 0
    }

    static func trend(current: Double, previous: Double) -> WeekTrend {
        if abs(current - previous) < 1 { return .flat }
        return current > previous ? .up : .down
    }

    /// What is left today, and how long a brisk walk would take.
    static func stepsRemaining(stepsToday: Int, goal: Int) -> (stepsLeft: Int, minutes: Int)? {
        guard stepsToday < goal else { return nil }
        let left = goal - stepsToday
        let minutes = max(1, Int((Double(left) / Double(briskStepsPerMinute)).rounded()))
        return (left, minutes)
    }

    struct WalkPlan: Equatable {
        var minutes: Int
        var steps: Int
        var alreadyDone: Bool
    }

    /// A short walk to suggest. Capped at 30 minutes so it stays friendly.
    static func walkPlan(stepsToday: Int, goal: Int, healthConnected: Bool) -> WalkPlan {
        if !healthConnected {
            return WalkPlan(minutes: 10, steps: briskStepsPerMinute * 10, alreadyDone: false)
        }
        guard let remaining = stepsRemaining(stepsToday: stepsToday, goal: goal) else {
            return WalkPlan(minutes: 10, steps: briskStepsPerMinute * 10, alreadyDone: true)
        }
        let minutes = min(30, max(5, remaining.minutes))
        return WalkPlan(minutes: minutes, steps: minutes * briskStepsPerMinute, alreadyDone: false)
    }
}
