import Foundation

/// The only Health calls the rest of the app needs.
/// Tests pass a fake reader. The real one talks to Apple Health.
protocol HealthActivityReading {
    func requestReadAccess() async throws
    func dailyTotals(from start: Date, through end: Date, calendar: Calendar) async throws -> [Date: DailyActivity]
}
