import Foundation
import Testing
@testable import SoleCount

struct LoggingConsistencyTests {
    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func oneLocalDayCountsOnceAcrossPairsAndTaps() {
        let today = date(2026, 11, 7, calendar: utc)
        let morning = date(2026, 11, 7, 8, calendar: utc)
        let evening = date(2026, 11, 7, 20, calendar: utc)
        let result = LoggingConsistencyMath.evaluate(
            wearDates: [morning, evening, today],
            now: today,
            calendar: utc
        )
        #expect(result.qualifyingDays.count == 1)
        #expect(result.current == 1)
        #expect(result.best == 1)
        #expect(result.loggedToday)
    }

    @Test func yesterdayKeepsTheRunWhileTodayIsStillOpen() {
        let today = date(2026, 11, 7, calendar: utc)
        let yesterday = utc.date(byAdding: .day, value: -1, to: today)!
        let result = LoggingConsistencyMath.evaluate(wearDates: [yesterday], now: today, calendar: utc)
        #expect(result.current == 1)
        #expect(!result.loggedToday)
        #expect(result.kudos.contains("Today is still open"))
    }

    @Test func aGapEndsTheCurrentRunAndKeepsTheBest() {
        let today = date(2026, 11, 7, calendar: utc)
        let dates = [-10, -9, -8, -1].map { utc.date(byAdding: .day, value: $0, to: today)! }
        let result = LoggingConsistencyMath.evaluate(wearDates: dates, now: today, calendar: utc)
        #expect(result.current == 1)
        #expect(result.best == 3)
    }

    @Test func removingAMiddleDateShortensTheBestRun() {
        let today = date(2026, 11, 7, calendar: utc)
        let full = [-2, -1, 0].map { utc.date(byAdding: .day, value: $0, to: today)! }
        let withoutMiddle = [full[0], full[2]]
        #expect(LoggingConsistencyMath.evaluate(wearDates: full, now: today, calendar: utc).best == 3)
        let edited = LoggingConsistencyMath.evaluate(wearDates: withoutMiddle, now: today, calendar: utc)
        #expect(edited.best == 1)
        #expect(edited.current == 1)
    }

    @Test func aBackdatedDayFillsAGap() {
        let today = date(2026, 11, 7, calendar: utc)
        let yesterday = utc.date(byAdding: .day, value: -1, to: today)!
        let twoAgo = utc.date(byAdding: .day, value: -2, to: today)!
        let before = LoggingConsistencyMath.evaluate(wearDates: [today, twoAgo], now: today, calendar: utc)
        #expect(before.current == 1)
        #expect(before.best == 1)
        let after = LoggingConsistencyMath.evaluate(wearDates: [today, yesterday, twoAgo], now: today, calendar: utc)
        #expect(after.current == 3)
        #expect(after.best == 3)
        #expect(after.reached == .threeDays)
    }

    @Test func futureDatesDoNotCount() {
        let today = date(2026, 11, 7, calendar: utc)
        let tomorrow = utc.date(byAdding: .day, value: 1, to: today)!
        let result = LoggingConsistencyMath.evaluate(wearDates: [tomorrow], now: today, calendar: utc)
        #expect(result.qualifyingDays.isEmpty)
        #expect(result.current == 0)
        #expect(result.best == 0)
        #expect(result.kudos.contains("Nothing logged yet"))
    }

    @Test func noLogsAndAMissedYesterdayStayQuiet() {
        let today = date(2026, 11, 7, calendar: utc)
        let empty = LoggingConsistencyMath.evaluate(wearDates: [], now: today, calendar: utc)
        #expect(empty.current == 0)
        #expect(empty.best == 0)
        let twoAgo = utc.date(byAdding: .day, value: -2, to: today)!
        let missed = LoggingConsistencyMath.evaluate(wearDates: [twoAgo], now: today, calendar: utc)
        #expect(missed.current == 0)
        #expect(missed.best == 1)
        #expect(!missed.kudos.localizedLowercase.contains("shame"))
        #expect(!missed.kudos.localizedLowercase.contains("broken"))
        #expect(!missed.kudos.localizedLowercase.contains("owl"))
    }

    @Test func milestonesAreTheChosenDays() {
        let today = date(2026, 11, 7, calendar: utc)
        func run(_ length: Int) -> LoggingConsistency {
            let dates = (0..<length).map { utc.date(byAdding: .day, value: -$0, to: today)! }
            return LoggingConsistencyMath.evaluate(wearDates: dates, now: today, calendar: utc)
        }
        #expect(run(2).reached == nil)
        #expect(run(2).next == .threeDays)
        #expect(run(3).reached == .threeDays)
        #expect(run(7).reached == .oneWeek)
        #expect(run(14).reached == .twoWeeks)
        #expect(run(30).reached == .oneMonth)
        #expect(run(30).next == nil)
        #expect(run(31).kudos.contains("A month of logging"))
    }

    @Test func springForwardAndFallBackStayConsecutiveDays() {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        let spring = [7, 8, 9].map { date(2026, 3, $0, calendar: newYork) }
        let springNow = date(2026, 3, 9, calendar: newYork)
        let springResult = LoggingConsistencyMath.evaluate(wearDates: spring, now: springNow, calendar: newYork)
        #expect(springResult.current == 3)
        #expect(springResult.best == 3)

        let autumn = [31, 1, 2].enumerated().map { index, day in
            index == 0
                ? date(2026, 10, day, calendar: newYork)
                : date(2026, 11, day, calendar: newYork)
        }
        let autumnNow = date(2026, 11, 2, calendar: newYork)
        let autumnResult = LoggingConsistencyMath.evaluate(wearDates: autumn, now: autumnNow, calendar: newYork)
        #expect(autumnResult.current == 3)
        #expect(autumnResult.best == 3)
    }

    @Test func theCalendarDecidesWhichLocalDayATimestampIs() {
        var losAngeles = Calendar(identifier: .gregorian)
        losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let instant = date(2026, 11, 7, 2, calendar: utc)
        let now = date(2026, 11, 7, 12, calendar: utc)
        let inUTC = LoggingConsistencyMath.evaluate(wearDates: [instant], now: now, calendar: utc)
        let inLA = LoggingConsistencyMath.evaluate(wearDates: [instant], now: now, calendar: losAngeles)
        #expect(inUTC.loggedToday)
        #expect(!inLA.loggedToday)
        #expect(inUTC.current == 1)
        #expect(inLA.current == 1)
    }
}
