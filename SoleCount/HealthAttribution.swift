import Foundation

/// One day's steps and walking distance from Apple Health.
struct DailyActivity: Equatable, Codable {
    var steps: Double
    var distanceMeters: Double

    static let zero = DailyActivity(steps: 0, distanceMeters: 0)
}

/// The days one pair was worn. Dates should already be the start of the local day.
struct WearDayLog: Equatable {
    var id: UUID
    var days: Set<Date>
}

/// How the day's steps and distance were split onto one pair.
struct AttributedShoe: Equatable {
    var id: UUID
    var steps: Double
    var distanceMeters: Double
    var wearDayCount: Int
    var sharedDayCount: Int
    /// Set when every shared day was split with the same number of other pairs.
    var otherPairs: Int?
    /// Six month buckets, oldest first. Days outside that window stay in the totals only.
    var monthlyMeters: [Double]

    static func empty(id: UUID) -> AttributedShoe {
        AttributedShoe(
            id: id,
            steps: 0,
            distanceMeters: 0,
            wearDayCount: 0,
            sharedDayCount: 0,
            otherPairs: nil,
            monthlyMeters: Array(repeating: 0, count: 6)
        )
    }
}

/// Splits daily Health totals across the pairs that were worn that day.
/// No HealthKit calls live here, so unit tests can feed plain numbers.
enum HealthAttribution {
    static func monthWindow(calendar: Calendar, now: Date) -> [Date] {
        let thisMonth = calendar.dateInterval(of: .month, for: now)?.start ?? calendar.startOfDay(for: now)
        return (0..<6).compactMap { index in
            calendar.date(byAdding: .month, value: -(5 - index), to: thisMonth)
        }
    }

    static func attribute(
        logs: [WearDayLog],
        daily: [Date: DailyActivity],
        calendar: Calendar,
        now: Date
    ) -> [AttributedShoe] {
        let normalized = logs.map { log in
            WearDayLog(id: log.id, days: Set(log.days.map { calendar.startOfDay(for: $0) }))
        }
        var owners: [Date: [UUID]] = [:]
        for log in normalized {
            for day in log.days {
                var ids = owners[day] ?? []
                if !ids.contains(log.id) {
                    ids.append(log.id)
                }
                owners[day] = ids
            }
        }

        struct Bucket {
            var steps = 0.0
            var meters = 0.0
            var days = 0
            var sharedDays = 0
            var others: [Int] = []
            var monthly = Array(repeating: 0.0, count: 6)
        }
        var buckets: [UUID: Bucket] = [:]
        for log in normalized {
            buckets[log.id] = Bucket()
        }
        let months = monthWindow(calendar: calendar, now: now)

        for (day, ids) in owners {
            let share = max(ids.count, 1)
            let activity = daily[day] ?? .zero
            let stepsEach = activity.steps / Double(share)
            let metersEach = activity.distanceMeters / Double(share)
            let monthIndex = months.firstIndex { calendar.isDate(day, equalTo: $0, toGranularity: .month) }
            for id in ids {
                var bucket = buckets[id] ?? Bucket()
                bucket.steps += stepsEach
                bucket.meters += metersEach
                bucket.days += 1
                if share > 1 {
                    bucket.sharedDays += 1
                    bucket.others.append(share - 1)
                }
                if let monthIndex {
                    bucket.monthly[monthIndex] += metersEach
                }
                buckets[id] = bucket
            }
        }

        return normalized.map { log in
            let bucket = buckets[log.id] ?? Bucket()
            let uniqueOthers = Set(bucket.others)
            let otherPairs: Int?
            if bucket.sharedDays == 0 {
                otherPairs = nil
            } else if uniqueOthers.count == 1 {
                otherPairs = uniqueOthers.first
            } else {
                otherPairs = nil
            }
            return AttributedShoe(
                id: log.id,
                steps: bucket.steps,
                distanceMeters: bucket.meters,
                wearDayCount: bucket.days,
                sharedDayCount: bucket.sharedDays,
                otherPairs: otherPairs,
                monthlyMeters: bucket.monthly
            )
        }
    }

    /// Short line for the detail screen. nil when the pair had the day to itself.
    static func shareNote(sharedDayCount: Int, otherPairs: Int?) -> String? {
        guard sharedDayCount > 0 else { return nil }
        guard let otherPairs else { return "shared with other pairs on some days" }
        if otherPairs == 1 { return "shared with 1 other pair" }
        return "shared with \(otherPairs) other pairs"
    }
}
