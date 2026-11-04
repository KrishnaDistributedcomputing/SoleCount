import Foundation

/// One place that refreshes Health, updates the Today cache, and the reminders.
@MainActor
enum HealthCoordinator {
    static func refresh(health: HealthSync, motivation: MotivationStore, sneakers: [Sneaker]) async {
        await health.refresh(sneakers: sneakers)
        if let daily = health.lastDaily {
            motivation.absorb(daily)
        }
        await followUp(motivation: motivation, sneakers: sneakers)
    }

    static func connect(health: HealthSync, motivation: MotivationStore, sneakers: [Sneaker]) async {
        await health.connectAndRefresh(sneakers: sneakers)
        if let daily = health.lastDaily {
            motivation.absorb(daily)
        }
        await followUp(motivation: motivation, sneakers: sneakers)
    }

    /// Remember badges that are already unlocked so the first launch stays quiet.
    static func rememberCurrentBadges(motivation: MotivationStore, sneakers: [Sneaker]) {
        _ = motivation.noteNewBadges(badges(motivation: motivation, sneakers: sneakers))
    }

    static func badges(motivation: MotivationStore, sneakers: [Sneaker]) -> [Badge] {
        let active = sneakers.filter { !$0.isRetired }.map(\.wearDates)
        let costs = sneakers.compactMap(\.costPerWear)
        let input = MotivationEngine.makeInput(
            totalMeters: sneakers.reduce(0) { $0 + $1.totalMeters },
            days: motivation.days,
            stepGoal: motivation.stepGoal,
            activeWearDates: active,
            replaceReached: sneakers.contains(where: \.reachedMileageGoal),
            now: .now,
            calendar: .current,
            totalWears: sneakers.reduce(0) { $0 + $1.wearCount },
            lowestCostPerWear: costs.min(),
            pairCount: sneakers.count,
            stepStreakOverride: motivation.streak()
        )
        return MotivationEngine.badges(input)
    }

    private static func followUp(motivation: MotivationStore, sneakers: [Sneaker]) async {
        let fresh = motivation.noteNewBadges(badges(motivation: motivation, sneakers: sneakers))
        if !fresh.isEmpty {
            motivation.celebration += 1
        }
        if motivation.milestoneAlerts {
            for badge in fresh {
                await WearReminder.celebrate(title: badge.title)
            }
        }
        await retirementAlerts(motivation: motivation, sneakers: sneakers)
        let steps = Int(motivation.todaySteps().rounded())
        let evening = motivation.eveningNudge
            ? WearReminder.eveningCopy(stepsToday: steps, goal: motivation.stepGoal)
            : nil
        await WearReminder.reschedule(
            morning: motivation.morningReminder,
            morningHour: motivation.morningHour,
            morningMinute: motivation.morningMinute,
            evening: motivation.eveningNudge && evening != nil,
            eveningHour: motivation.eveningHour,
            eveningMinute: motivation.eveningMinute,
            eveningBody: evening
        )
    }

    /// Baselines the current distance first, so opening the app does not notify.
    /// Later crossings notify only when the retirement reminder is on.
    private static func retirementAlerts(motivation: MotivationStore, sneakers: [Sneaker]) async {
        let allowed = motivation.retirementAlerts && await WearReminder.isAuthorized()
        for sneaker in sneakers where !sneaker.isRetired {
            let water = RetirementMath.highWater(for: sneaker.lifeFraction)
            if !sneaker.retirementAlertBaselined {
                sneaker.retirementAlertBaselined = true
                sneaker.retirementAlertMark = water
                continue
            }
            guard allowed, water > sneaker.retirementAlertMark else { continue }
            if sneaker.retirementAlertMark < 80, water >= 80 {
                await WearReminder.retirement(name: sneaker.name, mark: .eighty)
            }
            if sneaker.retirementAlertMark < 100, water >= 100 {
                await WearReminder.retirement(name: sneaker.name, mark: .full)
            }
            sneaker.retirementAlertMark = water
        }
    }
}
