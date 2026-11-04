import Foundation
import Testing
@testable import SoleCount

struct RetirementMathTests {
    @Test func bandsFollowEightyAndOneHundred() {
        #expect(RetirementMath.fraction(meters: 100, goalKilometers: 0) == nil)
        #expect(RetirementMath.band(for: nil) == .none)
        let half = RetirementMath.fraction(meters: 325_000, goalKilometers: 650)
        #expect(half == 0.5)
        #expect(RetirementMath.band(for: half) == .green)
        #expect(RetirementMath.band(for: 0.8) == .yellow)
        #expect(RetirementMath.band(for: 0.99) == .yellow)
        #expect(RetirementMath.band(for: 1) == .red)
        #expect(RetirementMath.band(for: 1.4) == .red)
    }

    @Test func crossingEightyAndFullSendsThoseMarks() {
        let goal = 650.0
        #expect(RetirementMath.marks(previousMeters: 400_000, meters: 520_000, goalKilometers: goal) == [.eighty])
        #expect(RetirementMath.marks(previousMeters: 600_000, meters: 650_000, goalKilometers: goal) == [.full])
        #expect(RetirementMath.marks(previousMeters: 100_000, meters: 700_000, goalKilometers: goal) == [.eighty, .full])
        #expect(RetirementMath.marks(previousMeters: 700_000, meters: 800_000, goalKilometers: goal).isEmpty)
        #expect(RetirementMath.highWater(for: 0.5) == 0)
        #expect(RetirementMath.highWater(for: 0.8) == 80)
        #expect(RetirementMath.highWater(for: 1) == 100)
    }
}

struct StartingTotalsTests {
    @Test func startingWearsAndKilometresJoinTheTotals() {
        #expect(PairTotals.wears(logged: 2, starting: 3) == 5)
        #expect(PairTotals.meters(tracked: 1_000, startingKilometers: 2) == 3_000)
        #expect(PairTotals.costPerWear(price: 100, wears: 5) == 20)
        #expect(PairTotals.costPerWear(price: 100, wears: 0) == nil)
        #expect(PairTotals.wears(logged: 4, starting: -2) == 4)
    }
}

struct ForgottenAndSortTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test func forgottenSkipsRetiredAndRecentPairs() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 4))!
        let recent = calendar.date(byAdding: .day, value: -29, to: now)!
        let idle = calendar.date(byAdding: .day, value: -30, to: now)!
        let hints = CollectionMath.forgotten(
            pairs: [
                ("Recent", recent, false),
                ("Idle", idle, false),
                ("Old retired", idle, true),
                ("Never", nil, false)
            ],
            now: now,
            calendar: calendar
        )
        #expect(hints.map(\.name) == ["Never", "Idle"])
    }
}

struct GentleStreakTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private func day(_ offset: Int, from start: Date) -> Date {
        calendar.date(byAdding: .day, value: offset, to: start)!
    }

    @Test func sixDaysEarnOneRestDayAndAMissSpendsIt() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        var state = GentleState()
        for offset in 0..<6 {
            state = GentleStreak.apply(state: state, day: day(offset, from: start), hit: true, calendar: calendar)
        }
        #expect(state.current == 6)
        #expect(state.banked == 1)
        #expect(state.best == 6)
        state = GentleStreak.apply(state: state, day: day(6, from: start), hit: false, calendar: calendar)
        #expect(state.current == 6)
        #expect(state.banked == 0)
        state = GentleStreak.apply(state: state, day: day(7, from: start), hit: false, calendar: calendar)
        #expect(state.current == 0)
        #expect(state.best == 6)
    }

    @Test func bankStopsAtTwo() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        var state = GentleState()
        for offset in 0..<18 {
            state = GentleStreak.apply(state: state, day: day(offset, from: start), hit: true, calendar: calendar)
        }
        #expect(state.banked == 2)
        #expect(state.current == 18)
    }

    @Test func pauseFreezesTheStreak() {
        var state = GentleState(current: 4, best: 4, banked: 1, towardRest: 2, pause: .sick)
        let day = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        state = GentleStreak.apply(state: state, day: day, hit: false, calendar: calendar)
        #expect(state.current == 4)
        #expect(state.best == 4)
        #expect(state.banked == 1)
    }

    @Test func aNewGoalDoesNotReplayOldDays() {
        let yesterday = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let today = calendar.date(byAdding: .day, value: 1, to: yesterday)!
        let saved = GentleState(current: 10, best: 12, lastDay: yesterday)
        let updated = GentleStreak.catchUp(state: saved, hitDays: [], now: today, calendar: calendar)
        #expect(updated.current == 10)
        #expect(updated.best == 12)
    }
}

struct BadgeAndWishlistTests {
    @Test func newBadgesUnlockAtTheAskedMarks() {
        let quiet = MotivationEngine.badges(BadgeInput(
            totalMeters: 0,
            bestWeekMeters: 0,
            stepStreak: 0,
            bestDaySteps: 0,
            woreEveryActivePairThisMonth: false,
            pairReachedReplaceTarget: false
        ))
        #expect(quiet.first { $0.id == "first-wear" }?.unlocked == false)
        #expect(quiet.first { $0.id == "collection-10" }?.unlocked == false)

        let loud = MotivationEngine.badges(BadgeInput(
            totalMeters: 500_000,
            bestWeekMeters: 0,
            stepStreak: 30,
            bestDaySteps: 0,
            woreEveryActivePairThisMonth: false,
            pairReachedReplaceTarget: true,
            totalWears: 100,
            lowestCostPerWear: 0.4,
            pairCount: 10
        ))
        for id in ["first-wear", "km-100", "km-500", "wears-50", "wears-100", "cost-under-1", "full-life", "streak-7", "streak-30", "collection-10"] {
            #expect(loud.first { $0.id == id }?.unlocked == true)
        }
    }

    @Test func buyingAWishFillsTheCollectionPair() {
        let bought = WishlistMath.bought(WishlistDraft(brand: "Nike", modelName: "Air Max 90", targetPrice: 120, notes: "Grey"))
        #expect(bought.name == "Air Max 90")
        #expect(bought.brand == "Nike")
        #expect(bought.price == 120)
        #expect(bought.notes == "Grey")
        let brandOnly = WishlistMath.bought(WishlistDraft(brand: "Veja", modelName: "  ", targetPrice: -5, notes: ""))
        #expect(brandOnly.name == "Veja")
        #expect(brandOnly.price == 0)
    }
}
