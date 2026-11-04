import Foundation
import Observation

/// Step goal, weekly goal, and the cached day totals. All of it stays on the phone.
@MainActor
@Observable
final class MotivationStore {
    static let stepGoalKey = "stepGoal"
    static let weeklyKmKey = "weeklyKilometers"
    static let daysKey = "motionDays"
    static let morningKey = "morningReminder"
    static let eveningKey = "eveningNudge"
    static let milestoneKey = "milestoneAlerts"
    static let morningHourKey = "morningHour"
    static let morningMinuteKey = "morningMinute"
    static let eveningHourKey = "eveningHour"
    static let eveningMinuteKey = "eveningMinute"
    static let seenBadgesKey = "seenBadges"
    static let seenReadyKey = "seenBadgesReady"
    static let gentleKey = "gentleStreak"
    static let retirementKey = "retirementAlerts"

    private let defaults: UserDefaults

    var stepGoal: Int
    var weeklyKilometers: Double
    var days: [DayTotal]
    var morningReminder: Bool
    var eveningNudge: Bool
    var milestoneAlerts: Bool
    var morningHour: Int
    var morningMinute: Int
    var eveningHour: Int
    var eveningMinute: Int
    /// Bumps when a new badge unlocks, so the screen can celebrate.
    var celebration = 0
    var retirementAlerts: Bool
    private var gentle = GentleState()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        #if DEBUG
        if LaunchFlags.demoData {
            Self.seedDemoDefaults(defaults: defaults)
        }
        #endif
        let storedGoal = defaults.integer(forKey: Self.stepGoalKey)
        stepGoal = storedGoal > 0 ? storedGoal : 8_000
        let storedKm = defaults.double(forKey: Self.weeklyKmKey)
        weeklyKilometers = storedKm > 0 ? storedKm : 20
        if let data = defaults.data(forKey: Self.daysKey),
           let decoded = try? JSONDecoder().decode([DayTotal].self, from: data) {
            days = decoded
        } else {
            days = []
        }
        morningReminder = defaults.bool(forKey: Self.morningKey)
        eveningNudge = defaults.bool(forKey: Self.eveningKey)
        milestoneAlerts = defaults.bool(forKey: Self.milestoneKey)
        morningHour = defaults.object(forKey: Self.morningHourKey) as? Int ?? 8
        morningMinute = defaults.object(forKey: Self.morningMinuteKey) as? Int ?? 0
        eveningHour = defaults.object(forKey: Self.eveningHourKey) as? Int ?? 20
        eveningMinute = defaults.object(forKey: Self.eveningMinuteKey) as? Int ?? 0
        retirementAlerts = defaults.bool(forKey: Self.retirementKey)
        if let data = defaults.data(forKey: Self.gentleKey),
           let decoded = try? JSONDecoder().decode(GentleState.self, from: data) {
            gentle = decoded
        }
        refreshStreak()
    }

    func setRetirementAlerts(_ enabled: Bool) {
        retirementAlerts = enabled
        defaults.set(enabled, forKey: Self.retirementKey)
    }

    func bestStreak() -> Int { gentle.best }
    func bankedRestDays() -> Int { gentle.banked }
    func pause() -> StreakPause { gentle.pause }

    /// A pause freezes the number. Turning it off does not punish the days you were away.
    func setPause(_ pause: StreakPause, now: Date = .now, calendar: Calendar = .current) {
        refreshStreak(now: now, calendar: calendar)
        gentle.pause = pause
        if pause != .none {
            gentle.lastDay = calendar.startOfDay(for: now)
        }
        saveGentle()
        publishWidget(now: now, calendar: calendar)
    }

    private func saveGentle() {
        if let data = try? JSONEncoder().encode(gentle) {
            defaults.set(data, forKey: Self.gentleKey)
        }
    }

    func setStepGoal(_ value: Int) {
        stepGoal = min(100_000, max(1_000, value))
        defaults.set(stepGoal, forKey: Self.stepGoalKey)
        // The saved streak is not rebuilt. A new goal only affects days that have not been counted yet.
        publishWidget()
    }

    func setWeeklyKilometers(_ value: Double) {
        weeklyKilometers = min(500, max(1, value))
        defaults.set(weeklyKilometers, forKey: Self.weeklyKmKey)
    }

    func setMorning(enabled: Bool, hour: Int, minute: Int) {
        morningReminder = enabled
        morningHour = hour
        morningMinute = minute
        defaults.set(enabled, forKey: Self.morningKey)
        defaults.set(hour, forKey: Self.morningHourKey)
        defaults.set(minute, forKey: Self.morningMinuteKey)
    }

    func setEvening(enabled: Bool, hour: Int, minute: Int) {
        eveningNudge = enabled
        eveningHour = hour
        eveningMinute = minute
        defaults.set(enabled, forKey: Self.eveningKey)
        defaults.set(hour, forKey: Self.eveningHourKey)
        defaults.set(minute, forKey: Self.eveningMinuteKey)
    }

    func setMilestoneAlerts(_ enabled: Bool) {
        milestoneAlerts = enabled
        defaults.set(enabled, forKey: Self.milestoneKey)
    }

    /// Folds a Health result into the saved days. Older days outside the result stay put.
    func absorb(_ fresh: [Date: DailyActivity], calendar: Calendar = .current) {
        var map: [Date: DayTotal] = [:]
        for day in days {
            let start = calendar.startOfDay(for: day.day)
            map[start] = DayTotal(day: start, steps: day.steps, meters: day.meters)
        }
        for (day, activity) in fresh {
            let start = calendar.startOfDay(for: day)
            map[start] = DayTotal(day: start, steps: activity.steps, meters: activity.distanceMeters)
        }
        let cutoff = calendar.date(byAdding: .day, value: -120, to: calendar.startOfDay(for: .now)) ?? .distantPast
        days = map.values
            .filter { $0.day >= cutoff }
            .sorted { $0.day > $1.day }
        if let data = try? JSONEncoder().encode(days) {
            defaults.set(data, forKey: Self.daysKey)
        }
        publishWidget()
    }

    func todaySteps(now: Date = .now, calendar: Calendar = .current) -> Double {
        days.first { calendar.isDate($0.day, inSameDayAs: now) }?.steps ?? 0
    }

    func todayMeters(now: Date = .now, calendar: Calendar = .current) -> Double {
        days.first { calendar.isDate($0.day, inSameDayAs: now) }?.meters ?? 0
    }

    func streak() -> Int {
        gentle.current
    }

    /// Counts new days only. It does not replay days that were already saved.
    func refreshStreak(now: Date = .now, calendar: Calendar = .current) {
        let hits = MotionMath.hitDays(from: days, stepGoal: stepGoal, calendar: calendar)
        gentle = GentleStreak.catchUp(state: gentle, hitDays: hits, now: now, calendar: calendar)
        saveGentle()
    }

    func publishWidget(now: Date = .now, calendar: Calendar = .current) {
        refreshStreak(now: now, calendar: calendar)
        let snapshot = WidgetSnapshot(
            todaySteps: Int(todaySteps(now: now, calendar: calendar).rounded()),
            stepGoal: stepGoal,
            streak: gentle.current,
            updatedAt: now
        )
        WidgetStore.save(snapshot)
    }

    /// First launch remembers the badges you already have, without a notification.
    func noteNewBadges(_ badges: [Badge]) -> [Badge] {
        let unlocked = Set(badges.filter(\.unlocked).map(\.id))
        let seen = Set(defaults.stringArray(forKey: Self.seenBadgesKey) ?? [])
        let ready = defaults.bool(forKey: Self.seenReadyKey)
        defaults.set(true, forKey: Self.seenReadyKey)
        defaults.set(Array(unlocked), forKey: Self.seenBadgesKey)
        guard ready else { return [] }
        let freshIDs = unlocked.subtracting(seen)
        return badges.filter { freshIDs.contains($0.id) }
    }

    #if DEBUG
    /// Sample days so App Store screenshots show rings without Apple Health.
    static func seedDemoDefaults(defaults: UserDefaults = .standard, now: Date = .now, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        var seeded: [DayTotal] = []
        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let steps: Double
            let meters: Double
            if offset == 0 {
                steps = 6_400
                meters = 4_800
            } else if offset <= 4 {
                steps = 9_000 + Double(offset * 120)
                meters = 7_200
            } else {
                steps = 4_200
                meters = 3_100
            }
            seeded.append(DayTotal(day: day, steps: steps, meters: meters))
        }
        defaults.set(8_000, forKey: stepGoalKey)
        defaults.set(20.0, forKey: weeklyKmKey)
        defaults.removeObject(forKey: gentleKey)
        if let data = try? JSONEncoder().encode(seeded) {
            defaults.set(data, forKey: daysKey)
        }
        WidgetStore.save(
            WidgetSnapshot(todaySteps: 6_400, stepGoal: 8_000, streak: 4, updatedAt: now)
        )
    }
    #endif
}
