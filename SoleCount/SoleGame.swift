import Foundation

/// One friendly level, worked out from wears, distance, and badges.
struct SoleLevel: Equatable {
    var number: Int
    var name: String
    var xp: Int
    /// XP where this level starts.
    var floor: Int
    /// XP where the next level starts. nil at the top level.
    var nextAt: Int?
    var nextName: String?

    var xpToNext: Int? { nextAt.map { max(0, $0 - xp) } }

    /// 0...1 through the current level. Full at the top level.
    var progress: Double {
        guard let nextAt, nextAt > floor else { return 1 }
        return min(1, max(0, Double(xp - floor) / Double(nextAt - floor)))
    }
}

/// The three first steps for someone new.
struct StarterQuest: Equatable {
    var addedPair: Bool
    var loggedWear: Bool
    var threeWearsThisWeek: Bool

    var doneCount: Int { [addedPair, loggedWear, threeWearsThisWeek].filter { $0 }.count }
    var isComplete: Bool { doneCount == 3 }
}

/// This week's small challenge. The same one all week, a new one next week.
struct WeeklyChallenge: Equatable {
    enum Kind: String, CaseIterable, Equatable {
        case differentPairs
        case distance
        case wearDays
        case wears
    }

    var kind: Kind
    var title: String
    var symbol: String
    var target: Double
}

struct ChallengeProgress: Equatable {
    var value: Double
    var target: Double

    var fraction: Double { target > 0 ? min(1, max(0, value / target)) : 0 }
    var isDone: Bool { value >= target }
}

/// Sole Level, the starter quest, and the weekly challenge.
/// Everything is worked out from data already on the phone. Nothing new is sent anywhere.
enum SoleGame {
    static let xpPerWear = 10
    static let xpPerKilometer = 1
    static let xpPerBadge = 25

    /// Level names and the XP each one starts at.
    static let levels: [(name: String, at: Int)] = [
        ("First Steps", 0),
        ("Sidewalk Starter", 50),
        ("Block Explorer", 150),
        ("Trail Seeker", 350),
        ("City Strider", 700),
        ("Mile Collector", 1_200),
        ("Sole Legend", 2_000)
    ]

    static func xp(wears: Int, meters: Double, badges: Int) -> Int {
        let kilometers = Int((max(0, meters) / 1_000).rounded(.down))
        return max(0, wears) * xpPerWear + kilometers * xpPerKilometer + max(0, badges) * xpPerBadge
    }

    static func level(xp: Int) -> SoleLevel {
        let xp = max(0, xp)
        var index = 0
        for (offset, level) in levels.enumerated() where xp >= level.at {
            index = offset
        }
        let next = index + 1 < levels.count ? levels[index + 1] : nil
        return SoleLevel(
            number: index + 1,
            name: levels[index].name,
            xp: xp,
            floor: levels[index].at,
            nextAt: next?.at,
            nextName: next?.name
        )
    }

    /// The level to celebrate now, or nil. The first time ever, nothing is celebrated,
    /// so opening the app with old data stays quiet. Each level is celebrated once.
    static func levelToCelebrate(current: Int, lastCelebrated: Int?) -> Int? {
        guard let lastCelebrated else { return nil }
        return current > lastCelebrated ? current : nil
    }

    static func starterQuest(pairCount: Int, loggedWears: Int, wearsThisWeek: Int) -> StarterQuest {
        StarterQuest(
            addedPair: pairCount >= 1,
            loggedWear: loggedWears >= 1,
            threeWearsThisWeek: wearsThisWeek >= 3
        )
    }

    /// Challenges that make sense for this person. Distance needs Apple Health numbers.
    /// "Different pairs" needs at least two pairs in rotation.
    static func challenges(activePairs: Int, hasDistance: Bool, usesMiles: Bool) -> [WeeklyChallenge] {
        var list: [WeeklyChallenge] = []
        if activePairs >= 2 {
            let pairs = min(3, activePairs)
            list.append(WeeklyChallenge(kind: .differentPairs, title: "Wear \(pairs) different pairs this week", symbol: "shoe.2.fill", target: Double(pairs)))
        }
        list.append(WeeklyChallenge(kind: .wearDays, title: "Log wears on 4 days this week", symbol: "calendar.badge.checkmark", target: 4))
        if hasDistance {
            let meters = usesMiles ? 10 * 1_609.344 : 15_000
            let label = usesMiles ? "10 mi" : "15 km"
            list.append(WeeklyChallenge(kind: .distance, title: "Walk \(label) this week", symbol: "figure.walk", target: meters))
        }
        list.append(WeeklyChallenge(kind: .wears, title: "Log 5 wears this week", symbol: "sparkles", target: 5))
        return list
    }

    /// Same challenge all week, a different one the next week. No randomness.
    static func challenge(for date: Date, calendar: Calendar, activePairs: Int, hasDistance: Bool, usesMiles: Bool) -> WeeklyChallenge {
        let list = challenges(activePairs: activePairs, hasDistance: hasDistance, usesMiles: usesMiles)
        let week = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let index = abs(year * 53 + week) % list.count
        return list[index]
    }

    static func weekStart(for date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    /// `pairWearDates` holds each active pair's logged wear dates.
    static func progress(
        of challenge: WeeklyChallenge,
        pairWearDates: [[Date]],
        weekMeters: Double,
        now: Date,
        calendar: Calendar
    ) -> ChallengeProgress {
        let start = weekStart(for: now, calendar: calendar)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? now
        let inWeek: (Date) -> Bool = { $0 >= start && $0 < end }
        let value: Double
        switch challenge.kind {
        case .differentPairs:
            value = Double(pairWearDates.filter { $0.contains(where: inWeek) }.count)
        case .wearDays:
            let days = Set(pairWearDates.flatMap { $0 }.filter(inWeek).map { calendar.startOfDay(for: $0) })
            value = Double(days.count)
        case .wears:
            value = Double(pairWearDates.flatMap { $0 }.filter(inWeek).count)
        case .distance:
            value = weekMeters
        }
        return ChallengeProgress(value: value, target: challenge.target)
    }

    /// Kind words for the challenge card.
    static func challengeLine(_ challenge: WeeklyChallenge, progress: ChallengeProgress, usesMiles: Bool) -> String {
        if progress.isDone { return "Challenge done. What a lovely week." }
        switch challenge.kind {
        case .distance:
            let unit = usesMiles ? 1_609.344 : 1_000
            let done = (progress.value / unit).formatted(.number.precision(.fractionLength(0...1)))
            let goal = (progress.target / unit).formatted(.number.precision(.fractionLength(0)))
            return "\(done) of \(goal) \(usesMiles ? "mi" : "km") so far. Every step counts."
        default:
            return "\(Int(progress.value)) of \(Int(progress.target)) so far. A fresh challenge comes every week."
        }
    }
}
