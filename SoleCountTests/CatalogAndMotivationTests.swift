import Foundation
import Testing
@testable import SoleCount

struct ShoeCatalogTests {
    @Test func catalogHasTheBuiltInBrandsAndTypes() {
        #expect(ShoeCatalog.brands.count == 30)
        #expect(ShoeCatalog.brands.contains("Nike"))
        #expect(ShoeCatalog.brands.contains("Onitsuka Tiger"))
        #expect(ShoeCatalog.brands.contains("Lululemon"))
        #expect(ShoeType.allCases.count == 15)
        #expect(ShoeType.running.defaultReplaceKilometers == 650)
        #expect(ShoeType.trail.defaultReplaceKilometers == 650)
        #expect(ShoeType.walking.defaultReplaceKilometers == 800)
        #expect(ShoeType.basketball.defaultReplaceKilometers == 500)
        #expect(ShoeType.training.defaultReplaceKilometers == 650)
        #expect(ShoeType.lifestyle.defaultReplaceKilometers == nil)
    }

    @Test func searchPutsRecentBrandsFirstAndFiltersModels() {
        let choices = ShoeCatalog.brandChoices(query: "", recent: ["On", "Nike"])
        #expect(choices.first == "On")
        #expect(choices.dropFirst().first == "Nike")
        let filtered = ShoeCatalog.brandChoices(query: "nik", recent: [])
        #expect(filtered == ["Nike"])
        let models = ShoeCatalog.models(forBrand: "nike", query: "90")
        #expect(models.contains("Air Max 90"))
        #expect(ShoeCatalog.models(forBrand: "Not A Brand", query: "").isEmpty)
    }

    @Test func recentBrandsAreRemembered() {
        let defaults = UserDefaults(suiteName: "catalog-tests")!
        defaults.removePersistentDomain(forName: "catalog-tests")
        ShoeCatalog.rememberBrand("  Veja ", defaults: defaults)
        ShoeCatalog.rememberBrand("Nike", defaults: defaults)
        #expect(ShoeCatalog.recentBrands(defaults: defaults) == ["Nike", "Veja"])
    }
}

struct MotivationTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 1
        return calendar
    }()

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test func streakCountsThroughYesterdayWhenTodayIsShort() {
        let today = day(2026, 11, 4)
        var hits: Set<Date> = []
        for offset in 1...4 {
            hits.insert(calendar.date(byAdding: .day, value: -offset, to: today)!)
        }
        #expect(MotionMath.streak(hitDays: hits, now: today, calendar: calendar) == 4)
        #expect(MotionMath.streak(hitDays: [], now: today, calendar: calendar) == 0)
    }

    @Test func badgesUnlockAtTheStatedMarks() {
        let locked = MotivationEngine.badges(BadgeInput(
            totalMeters: 9_000,
            bestWeekMeters: 10_000,
            stepStreak: 3,
            bestDaySteps: 8_000,
            woreEveryActivePairThisMonth: false,
            pairReachedReplaceTarget: false
        ))
        #expect(locked.filter(\.unlocked).isEmpty)

        let unlocked = MotivationEngine.badges(BadgeInput(
            totalMeters: 500_000,
            bestWeekMeters: 42_195,
            stepStreak: 30,
            bestDaySteps: 10_000,
            woreEveryActivePairThisMonth: true,
            pairReachedReplaceTarget: true,
            totalWears: 100,
            lowestCostPerWear: 0.5,
            pairCount: 10,
            starterQuestDone: true
        ))
        #expect(unlocked.filter(\.unlocked).count == unlocked.count)
        #expect(unlocked.map(\.id).contains("km-10"))
    }

    @Test func comparisonsUseRealApproximateDistances() {
        let fields = MotivationEngine.facts(meters: 105 * 120)
        #expect(fields[0].text == "You've walked the length of 120 soccer fields")
        let far = MotivationEngine.facts(meters: 125_000)
        #expect(far.map(\.text).contains("≈ Toronto to Niagara Falls"))
        #expect(MotivationEngine.facts(meters: 50).isEmpty)
    }

    @Test func walkPlanAndWeekTrendStaySimple() {
        let plan = MotionMath.walkPlan(stepsToday: 5_700, goal: 8_000, healthConnected: true)
        #expect(plan.minutes == 20)
        #expect(plan.steps == 20 * 115)
        let remaining = MotionMath.stepsRemaining(stepsToday: 5_700, goal: 8_000)
        #expect(remaining?.stepsLeft == 2_300)
        #expect(remaining?.minutes == 20)
        #expect(MotionMath.trend(current: 10, previous: 4) == .up)
        #expect(MotionMath.trend(current: 4, previous: 10) == .down)
        #expect(MotionMath.trend(current: 4, previous: 4) == .flat)
        let offline = MotionMath.walkPlan(stepsToday: 0, goal: 8_000, healthConnected: false)
        #expect(offline.minutes == 10)
    }

    @Test func tipsAreOriginalAndPlenty() {
        #expect(MotivationEngine.tips.count == 60)
        #expect(Set(MotivationEngine.tips).count == 60)
        let tip = MotivationEngine.tip(on: day(2026, 1, 1), calendar: calendar)
        #expect(MotivationEngine.tips.contains(tip))
    }

    @Test func affirmationsArePlentyAndRotateByDay() {
        #expect(!MotivationEngine.affirmations.isEmpty)
        #expect(MotivationEngine.affirmations.count >= 60)
        #expect(Set(MotivationEngine.affirmations).count == MotivationEngine.affirmations.count)
        let first = MotivationEngine.affirmation(on: day(2026, 1, 1), calendar: calendar)
        let next = MotivationEngine.affirmation(on: day(2026, 1, 2), calendar: calendar)
        #expect(first == MotivationEngine.affirmation(on: day(2026, 1, 1), calendar: calendar))
        #expect(first != next)
        #expect(MotivationEngine.affirmations.contains(first))
    }

    @Test func fullRotationNeedsEveryActivePairThisMonth() {
        let now = day(2026, 11, 4)
        #expect(!MotivationEngine.woreEveryActivePair(wearDates: [], month: now, calendar: calendar))
        #expect(MotivationEngine.woreEveryActivePair(
            wearDates: [[day(2026, 11, 1)], [day(2026, 11, 3)]],
            month: now,
            calendar: calendar
        ))
        #expect(!MotivationEngine.woreEveryActivePair(
            wearDates: [[day(2026, 11, 1)], [day(2026, 10, 3)]],
            month: now,
            calendar: calendar
        ))
    }
}

struct CollectionMathTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test func summaryAndForgottenPairs() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 4))!
        let old = calendar.date(byAdding: .day, value: -40, to: now)!
        let pairs = [
            PairStats(name: "Daily", wears: 4, price: 100, meters: 8_000, steps: 10_000, isRetired: false, lastWorn: now),
            PairStats(name: "Trail", wears: 1, price: 80, meters: 2_000, steps: 3_000, isRetired: false, lastWorn: old),
            PairStats(name: "Shelf", wears: 0, price: 50, meters: 0, steps: 0, isRetired: false, lastWorn: nil)
        ]
        let summary = CollectionMath.summarize(pairs: pairs, wearDays: [now, old], now: now, calendar: calendar)
        #expect(summary.totalWears == 5)
        #expect(summary.collectionValue == 230)
        #expect(summary.averageCostPerWear == 36)
        #expect(summary.mostWorn == "Daily")
        #expect(summary.leastWorn == "Shelf")
        let hints = CollectionMath.forgotten(
            pairs: pairs.map { ($0.name, $0.lastWorn, $0.isRetired) },
            now: now,
            calendar: calendar
        )
        #expect(hints.map(\.name) == ["Shelf", "Trail"])
        #expect(CollectionMath.hintLine(hints[0]) == "You haven't worn Shelf yet")
        #expect(CollectionMath.hintLine(hints[1]) == "You haven't worn Trail in 40 days")
    }

    @Test func sortAndFilterKeepTheRightPairs() {
        let older = Date(timeIntervalSince1970: 10)
        let newer = Date(timeIntervalSince1970: 20)
        let rows = [
            CollectionRow(name: "B", brand: "Nike", type: "Running", wears: 2, meters: 100, costPerWear: 10, createdAt: older, isRetired: false),
            CollectionRow(name: "A", brand: "Adidas", type: "Trail", wears: 9, meters: 50, costPerWear: 4, createdAt: newer, isRetired: false),
            CollectionRow(name: "Old", brand: "Nike", type: "Running", wears: 1, meters: 10, costPerWear: 20, createdAt: newer, isRetired: true)
        ]
        let byWears = CollectionMath.indices(rows: rows, brand: nil, type: nil, sort: .wears, retired: false)
        let wornNames = byWears.map { rows[$0].name }
        #expect(wornNames == ["A", "B"])
        let nike = CollectionMath.indices(rows: rows, brand: "nike", type: "Running", sort: .newest, retired: false)
        let nikeNames = nike.map { rows[$0].name }
        #expect(nikeNames == ["B"])
        let fame = CollectionMath.indices(rows: rows, brand: nil, type: nil, sort: .newest, retired: true)
        let fameNames = fame.map { rows[$0].name }
        #expect(fameNames == ["Old"])
    }

    @Test func csvEscapesCommas() {
        let row = ExportRow(
            name: "Air, Max",
            brand: "Nike",
            type: "Running",
            size: "10",
            colorway: "White",
            condition: "Good",
            price: 10,
            purchaseDate: Date(timeIntervalSince1970: 0),
            wears: 2,
            meters: 1_500,
            steps: 100,
            retired: false,
            notes: "line"
        )
        let csv = CollectionExport.csv(rows: [row], calendar: calendar)
        #expect(csv.contains("\"Air, Max\""))
        #expect(csv.contains("1.50"))
    }

    @Test func milesFollowTheLocale() {
        let meters = 1_609.344
        let miles = DistanceFormat.string(meters: meters, locale: Locale(identifier: "en_US"), forceMetric: false)
        let km = DistanceFormat.string(meters: meters, locale: Locale(identifier: "fr_FR"), forceMetric: false)
        #expect(miles.contains("mi"))
        #expect(km.contains("km"))
        #expect(DistanceFormat.string(meters: 1_000, locale: Locale(identifier: "en_US"), forceMetric: true).contains("km"))
    }
}
