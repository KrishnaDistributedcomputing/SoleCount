import Foundation
import Testing
@testable import SoleCount

struct HealthAttributionTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test func onePairKeepsTheWholeDay() {
        let id = UUID()
        let worn = day(2026, 11, 2)
        let result = HealthAttribution.attribute(
            logs: [WearDayLog(id: id, days: [worn])],
            daily: [worn: DailyActivity(steps: 1_000, distanceMeters: 800)],
            calendar: calendar,
            now: day(2026, 11, 4)
        )
        let shoe = result[0]
        #expect(shoe.steps == 1_000)
        #expect(shoe.distanceMeters == 800)
        #expect(shoe.sharedDayCount == 0)
        #expect(HealthAttribution.shareNote(sharedDayCount: 0, otherPairs: nil) == nil)
    }

    @Test func twoPairsSplitTheDayEvenly() {
        let first = UUID()
        let second = UUID()
        let shared = day(2026, 11, 2)
        let solo = day(2026, 11, 3)
        let result = HealthAttribution.attribute(
            logs: [
                WearDayLog(id: first, days: [shared, solo]),
                WearDayLog(id: second, days: [shared])
            ],
            daily: [
                shared: DailyActivity(steps: 1_000, distanceMeters: 800),
                solo: DailyActivity(steps: 200, distanceMeters: 100)
            ],
            calendar: calendar,
            now: day(2026, 11, 4)
        )
        let left = result.first { $0.id == first }!
        let right = result.first { $0.id == second }!
        #expect(left.steps == 700)
        #expect(left.distanceMeters == 500)
        #expect(right.steps == 500)
        #expect(right.distanceMeters == 400)
        #expect(HealthAttribution.shareNote(sharedDayCount: right.sharedDayCount, otherPairs: right.otherPairs) == "shared with 1 other pair")
    }

    @Test func threePairsAndMixedDaysUseTheRightNote() {
        let a = UUID()
        let b = UUID()
        let c = UUID()
        let trio = day(2026, 11, 1)
        let pair = day(2026, 11, 2)
        let result = HealthAttribution.attribute(
            logs: [
                WearDayLog(id: a, days: [trio, pair]),
                WearDayLog(id: b, days: [trio, pair]),
                WearDayLog(id: c, days: [trio])
            ],
            daily: [
                trio: DailyActivity(steps: 900, distanceMeters: 900),
                pair: DailyActivity(steps: 200, distanceMeters: 200)
            ],
            calendar: calendar,
            now: day(2026, 11, 4)
        )
        let first = result.first { $0.id == a }!
        #expect(first.otherPairs == nil)
        #expect(first.sharedDayCount == 2)
        #expect(HealthAttribution.shareNote(sharedDayCount: first.sharedDayCount, otherPairs: first.otherPairs) == "shared with other pairs on some days")
        let third = result.first { $0.id == c }!
        #expect(third.steps == 300)
        #expect(HealthAttribution.shareNote(sharedDayCount: third.sharedDayCount, otherPairs: third.otherPairs) == "shared with 2 other pairs")
    }

    @Test func olderThanSixMonthsStaysInTheTotalOnly() {
        let id = UUID()
        let old = day(2026, 5, 2)
        let recent = day(2026, 11, 2)
        let result = HealthAttribution.attribute(
            logs: [WearDayLog(id: id, days: [old, recent])],
            daily: [
                old: DailyActivity(steps: 10, distanceMeters: 100),
                recent: DailyActivity(steps: 10, distanceMeters: 50)
            ],
            calendar: calendar,
            now: day(2026, 11, 15)
        )
        let shoe = result[0]
        #expect(shoe.distanceMeters == 150)
        #expect(shoe.monthlyMeters.reduce(0, +) == 50)
        #expect(shoe.monthlyMeters.count == 6)
    }
}
