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
        let input = MotivationEngine.makeInput(
            totalMeters: sneakers.reduce(0) { $0 + $1.cachedDistanceMeters },
            days: motivation.days,
            stepGoal: motivation.stepGoal,
            activeWearDates: active,
            replaceReached: sneakers.contains(where: \.reachedMileageGoal),
            now: .now,
            calendar: .current
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
}
