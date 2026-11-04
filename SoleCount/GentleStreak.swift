import Foundation

/// A chosen pause. The streak stays where it is until you turn this off.
enum StreakPause: String, Codable, CaseIterable, Identifiable {
    case none
    case sick
    case travel
    case rest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "Not paused"
        case .sick: "Sick"
        case .travel: "Travel"
        case .rest: "Rest"
        }
    }
}

/// Saved streak. Changing the step goal does not rebuild this from old days.
struct GentleState: Equatable, Codable {
    var current: Int = 0
    var best: Int = 0
    var banked: Int = 0
    var towardRest: Int = 0
    var pause: StreakPause = .none
    var lastDay: Date? = nil
}

/// One rest day after every 6 goal days, up to 2 banked. A pause freezes the number.
enum GentleStreak {
    static let daysPerRest = 6
    static let maxBank = 2

    /// Apply one closed day. A pause records the day and leaves the streak alone.
    static func apply(state: GentleState, day: Date, hit: Bool, calendar: Calendar) -> GentleState {
        var next = state
        let day = calendar.startOfDay(for: day)
        if next.pause != .none {
            next.lastDay = day
            return next
        }
        if hit {
            next.current += 1
            next.towardRest += 1
            if next.towardRest >= daysPerRest {
                next.banked = min(maxBank, next.banked + 1)
                next.towardRest = 0
            }
        } else if next.banked > 0 {
            next.banked -= 1
            next.towardRest = 0
        } else {
            next.current = 0
            next.towardRest = 0
        }
        next.best = max(next.best, next.current)
        next.lastDay = day
        return next
    }

    /// Walk forward from the day after `lastDay`. Today counts only when the goal was hit.
    /// Days already saved are not replayed, so a new step goal cannot wipe the record.
    static func catchUp(state: GentleState, hitDays: Set<Date>, now: Date, calendar: Calendar) -> GentleState {
        var state = state
        let today = calendar.startOfDay(for: now)
        let start: Date
        if let last = state.lastDay {
            let lastStart = calendar.startOfDay(for: last)
            if lastStart >= today { return state }
            guard let next = calendar.date(byAdding: .day, value: 1, to: lastStart) else { return state }
            start = next
        } else if let earliest = hitDays.map({ calendar.startOfDay(for: $0) }).min() {
            start = earliest
        } else {
            return state
        }

        var day = start
        var steps = 0
        while day < today, steps < 500 {
            state = apply(state: state, day: day, hit: hitDays.contains(day), calendar: calendar)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
            steps += 1
        }
        if hitDays.contains(today) {
            state = apply(state: state, day: today, hit: true, calendar: calendar)
        }
        return state
    }
}
