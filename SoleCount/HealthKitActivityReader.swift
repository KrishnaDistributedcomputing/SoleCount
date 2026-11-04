import Foundation
import HealthKit

/// Reads step count and walking distance. It never writes to Apple Health.
final class HealthKitActivityReader: HealthActivityReading {
    private let store: HKHealthStore?

    init() {
        store = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    }

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestReadAccess() async throws {
        guard let store else { return }
        try await store.requestAuthorization(toShare: [], read: Self.readTypes)
    }

    func dailyTotals(from start: Date, through end: Date, calendar: Calendar) async throws -> [Date: DailyActivity] {
        guard let store else { return [:] }
        let steps = try await dailySum(.stepCount, unit: .count(), store: store, from: start, through: end, calendar: calendar)
        let distance = try await dailySum(.distanceWalkingRunning, unit: .meter(), store: store, from: start, through: end, calendar: calendar)
        var days = Set(steps.keys)
        days.formUnion(distance.keys)
        var result: [Date: DailyActivity] = [:]
        for day in days {
            result[day] = DailyActivity(steps: steps[day] ?? 0, distanceMeters: distance[day] ?? 0)
        }
        return result
    }

    private static var readTypes: Set<HKObjectType> {
        [HKQuantityType(.stepCount), HKQuantityType(.distanceWalkingRunning)]
    }

    private func dailySum(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        store: HKHealthStore,
        from start: Date,
        through end: Date,
        calendar: Calendar
    ) async throws -> [Date: Double] {
        let type = HKQuantityType(identifier)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let anchor = calendar.startOfDay(for: start)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchor,
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, collection, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                var map: [Date: Double] = [:]
                collection?.enumerateStatistics(from: start, to: end) { stats, _ in
                    let day = calendar.startOfDay(for: stats.startDate)
                    let value = stats.sumQuantity()?.doubleValue(for: unit) ?? 0
                    if value > 0 {
                        map[day] = value
                    }
                }
                continuation.resume(returning: map)
            }
            store.execute(query)
        }
    }
}
