import Foundation
import Testing
@testable import SoleCount

struct SoleLevelTests {
    @Test func xpAddsWearsKilometresAndBadges() {
        #expect(SoleGame.xp(wears: 0, meters: 0, badges: 0) == 0)
        #expect(SoleGame.xp(wears: 3, meters: 12_900, badges: 2) == 30 + 12 + 50)
        #expect(SoleGame.xp(wears: -2, meters: -100, badges: -1) == 0)
    }

    @Test func levelsStartAtTheRightXP() {
        let start = SoleGame.level(xp: 0)
        #expect(start.number == 1)
        #expect(start.name == "First Steps")
        #expect(start.xpToNext == 50)
        #expect(start.nextName == "Sidewalk Starter")
        #expect(start.progress == 0)

        let mid = SoleGame.level(xp: 250)
        #expect(mid.number == 3)
        #expect(mid.name == "Block Explorer")
        #expect(mid.xpToNext == 100)
        #expect(mid.progress == 0.5)

        #expect(SoleGame.level(xp: 49).number == 1)
        #expect(SoleGame.level(xp: 50).number == 2)
        #expect(SoleGame.level(xp: 1_999).name == "Mile Collector")

        let top = SoleGame.level(xp: 9_000)
        #expect(top.number == SoleGame.levels.count)
        #expect(top.name == "Sole Legend")
        #expect(top.nextAt == nil)
        #expect(top.xpToNext == nil)
        #expect(top.progress == 1)
    }

    @Test func eachLevelUpIsCelebratedOnceAndFirstLaunchStaysQuiet() {
        #expect(SoleGame.levelToCelebrate(current: 4, lastCelebrated: nil) == nil)
        #expect(SoleGame.levelToCelebrate(current: 4, lastCelebrated: 4) == nil)
        #expect(SoleGame.levelToCelebrate(current: 3, lastCelebrated: 4) == nil)
        #expect(SoleGame.levelToCelebrate(current: 5, lastCelebrated: 4) == 5)
    }
}

struct StarterQuestTests {
    @Test func stepsTickOffInOrder() {
        let empty = SoleGame.starterQuest(pairCount: 0, loggedWears: 0, wearsThisWeek: 0)
        #expect(empty.doneCount == 0)
        #expect(!empty.isComplete)

        let added = SoleGame.starterQuest(pairCount: 1, loggedWears: 0, wearsThisWeek: 0)
        #expect(added.addedPair && !added.loggedWear)
        #expect(added.doneCount == 1)

        let worn = SoleGame.starterQuest(pairCount: 1, loggedWears: 2, wearsThisWeek: 2)
        #expect(worn.doneCount == 2)
        #expect(!worn.isComplete)

        let done = SoleGame.starterQuest(pairCount: 2, loggedWears: 5, wearsThisWeek: 3)
        #expect(done.isComplete)
    }

    @Test func questBadgeUnlocksOnlyWhenDone() {
        var input = BadgeInput(totalMeters: 0, bestWeekMeters: 0, stepStreak: 0, bestDaySteps: 0, woreEveryActivePairThisMonth: false, pairReachedReplaceTarget: false)
        #expect(MotivationEngine.badges(input).first { $0.id == "starter-quest" }?.unlocked == false)
        input.starterQuestDone = true
        #expect(MotivationEngine.badges(input).first { $0.id == "starter-quest" }?.unlocked == true)
    }
}

struct WeeklyChallengeTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Toronto")!
        calendar.firstWeekday = 2
        return calendar
    }

    private func day(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    @Test func sameChallengeAllWeekAndItRotates() {
        let monday = day(2026, 11, 2)
        let sunday = day(2026, 11, 8)
        let a = SoleGame.challenge(for: monday, calendar: calendar, activePairs: 3, hasDistance: true, usesMiles: false)
        let b = SoleGame.challenge(for: sunday, calendar: calendar, activePairs: 3, hasDistance: true, usesMiles: false)
        #expect(a == b)
        var kinds = Set<WeeklyChallenge.Kind>()
        for week in 0..<8 {
            let date = calendar.date(byAdding: .day, value: week * 7, to: monday)!
            kinds.insert(SoleGame.challenge(for: date, calendar: calendar, activePairs: 3, hasDistance: true, usesMiles: false).kind)
        }
        #expect(kinds.count == 4)
    }

    @Test func onlyFairChallengesAreOffered() {
        let solo = SoleGame.challenges(activePairs: 1, hasDistance: false, usesMiles: false)
        #expect(!solo.contains { $0.kind == .differentPairs })
        #expect(!solo.contains { $0.kind == .distance })
        #expect(!solo.isEmpty)
        let two = SoleGame.challenges(activePairs: 2, hasDistance: true, usesMiles: true)
        #expect(two.first { $0.kind == .differentPairs }?.target == 2)
        #expect(two.first { $0.kind == .distance }?.title == "Walk 10 mi this week")
    }

    @Test func progressCountsOnlyThisWeek() {
        let now = day(2026, 11, 4)
        let lastWeek = day(2026, 10, 30)
        let pairs: [[Date]] = [
            [day(2026, 11, 2), day(2026, 11, 4), lastWeek],
            [day(2026, 11, 3)],
            [lastWeek]
        ]
        let differ = WeeklyChallenge(kind: .differentPairs, title: "", symbol: "", target: 3)
        #expect(SoleGame.progress(of: differ, pairWearDates: pairs, weekMeters: 0, now: now, calendar: calendar).value == 2)
        let days = WeeklyChallenge(kind: .wearDays, title: "", symbol: "", target: 4)
        #expect(SoleGame.progress(of: days, pairWearDates: pairs, weekMeters: 0, now: now, calendar: calendar).value == 3)
        let wears = WeeklyChallenge(kind: .wears, title: "", symbol: "", target: 3)
        let wearProgress = SoleGame.progress(of: wears, pairWearDates: pairs, weekMeters: 0, now: now, calendar: calendar)
        #expect(wearProgress.value == 3)
        #expect(wearProgress.isDone)
        let walk = WeeklyChallenge(kind: .distance, title: "", symbol: "", target: 15_000)
        let walkProgress = SoleGame.progress(of: walk, pairWearDates: pairs, weekMeters: 7_500, now: now, calendar: calendar)
        #expect(walkProgress.fraction == 0.5)
        #expect(!walkProgress.isDone)
    }
}

struct BigNumberFormatTests {
    @Test func soccerFieldsUseThousandsSeparators() {
        let facts = MotivationEngine.facts(meters: 600_000, locale: Locale(identifier: "en_US"))
        #expect(facts[0].text == "You've walked the length of 5,714 soccer fields")
    }
}
