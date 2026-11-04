import Foundation

/// One badge on the Stats and Today screens.
struct Badge: Equatable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var symbol: String
    var unlocked: Bool
}

/// The numbers the badge rules look at. Built from on-device data.
struct BadgeInput: Equatable {
    var totalMeters: Double
    var bestWeekMeters: Double
    var stepStreak: Int
    var bestDaySteps: Double
    var woreEveryActivePairThisMonth: Bool
    var pairReachedReplaceTarget: Bool
}

/// A real, approximate distance used only as a fun comparison. The UI labels these with ≈.
struct DistanceFact: Equatable {
    var text: String
}

/// Badges, distance comparisons, and the bundled tips.
/// Original lines only. This is encouragement, not medical advice.
enum MotivationEngine {
    static let marathonMeters = 42_195.0
    static let soccerFieldMeters = 105.0

    static func badges(_ input: BadgeInput) -> [Badge] {
        [
            Badge(id: "km-10", title: "First 10 km", detail: "10 kilometres on your pairs", symbol: "shoe.fill", unlocked: input.totalMeters >= 10_000),
            Badge(id: "km-50", title: "50 km club", detail: "50 kilometres in total", symbol: "figure.walk", unlocked: input.totalMeters >= 50_000),
            Badge(id: "km-100", title: "100 km club", detail: "100 kilometres in total", symbol: "flag.fill", unlocked: input.totalMeters >= 100_000),
            Badge(id: "km-500", title: "500 km club", detail: "500 kilometres in total", symbol: "star.fill", unlocked: input.totalMeters >= 500_000),
            Badge(id: "week-marathon", title: "Marathon week", detail: "42.2 km in a single week", symbol: "figure.run", unlocked: input.bestWeekMeters >= marathonMeters),
            Badge(id: "streak-7", title: "7-day streak", detail: "Step goal hit 7 days in a row", symbol: "flame.fill", unlocked: input.stepStreak >= 7),
            Badge(id: "streak-30", title: "30-day streak", detail: "Step goal hit 30 days in a row", symbol: "flame.circle.fill", unlocked: input.stepStreak >= 30),
            Badge(id: "steps-10k", title: "10,000-step day", detail: "One day at 10,000 steps or more", symbol: "bolt.fill", unlocked: input.bestDaySteps >= 10_000),
            Badge(id: "full-rotation", title: "Full rotation", detail: "Every active pair worn this month", symbol: "calendar", unlocked: input.woreEveryActivePairThisMonth),
            Badge(id: "full-life", title: "Full life", detail: "A pair reached its replace-at distance", symbol: "checkmark.seal.fill", unlocked: input.pairReachedReplaceTarget)
        ]
    }

    static func woreEveryActivePair(wearDates: [[Date]], month: Date, calendar: Calendar) -> Bool {
        guard !wearDates.isEmpty else { return false }
        return wearDates.allSatisfy { dates in
            dates.contains { calendar.isDate($0, equalTo: month, toGranularity: .month) }
        }
    }

    static func makeInput(
        totalMeters: Double,
        days: [DayTotal],
        stepGoal: Int,
        activeWearDates: [[Date]],
        replaceReached: Bool,
        now: Date,
        calendar: Calendar
    ) -> BadgeInput {
        let hits = MotionMath.hitDays(from: days, stepGoal: stepGoal, calendar: calendar)
        return BadgeInput(
            totalMeters: totalMeters,
            bestWeekMeters: MotionMath.bestWeekMeters(days: days, calendar: calendar),
            stepStreak: MotionMath.streak(hitDays: hits, now: now, calendar: calendar),
            bestDaySteps: days.map(\.steps).max() ?? 0,
            woreEveryActivePairThisMonth: woreEveryActivePair(wearDates: activeWearDates, month: now, calendar: calendar),
            pairReachedReplaceTarget: replaceReached
        )
    }

    static func facts(meters: Double) -> [DistanceFact] {
        guard meters >= soccerFieldMeters else { return [] }
        var lines: [DistanceFact] = []
        let fields = Int(meters / soccerFieldMeters)
        let noun = fields == 1 ? "soccer field" : "soccer fields"
        lines.append(DistanceFact(text: "You've walked the length of \(fields) \(noun)"))

        let landmarks: [(name: String, meters: Double)] = [
            ("a running track", 400),
            ("Central Park, top to bottom", 4_000),
            ("Manhattan, south to north", 21_000),
            ("the English Channel", 33_000),
            ("a marathon", marathonMeters),
            ("Toronto to Niagara Falls", 125_000)
        ]
        if let best = landmarks.filter({ meters >= $0.meters }).max(by: { $0.meters < $1.meters }) {
            let count = Int(meters / best.meters)
            if count <= 1 {
                lines.append(DistanceFact(text: "≈ \(best.name)"))
            } else {
                lines.append(DistanceFact(text: "≈ \(count) × \(best.name)"))
            }
        }
        return lines
    }

    /// About 60 original short lines. Not quotes from anyone. Not medical advice.
    static let tips: [String] = [
        "A 10-minute walk after meals is a nice reset.",
        "Put the shoes on before you talk yourself out of it.",
        "Short walks still count. They add up.",
        "The pair by the door is the pair you will wear.",
        "A lap around the block is a complete walk.",
        "Walk while a song plays. Stop when it ends, or keep going.",
        "Stairs are a walk too, if your shoes are up for it.",
        "Morning light and a short walk is a calm start.",
        "You do not need a long route. Leave and turn around.",
        "Set the shoes out tonight. Tomorrow is easier.",
        "A slow walk is still a walk.",
        "Invite someone. Or go alone. Both are good.",
        "Notice one thing on the street you usually miss.",
        "If the day was busy, five minutes is enough.",
        "Rotate pairs so each one gets a day out.",
        "The best walk is the one you actually take.",
        "Stand up, step outside, then decide how far.",
        "A walk can be the break between two tasks.",
        "Carry less. Shoes feel better when the bag is light.",
        "Match the pair to the weather, then go.",
        "New shoes like short first outings.",
        "Older shoes still have good days left.",
        "Track the wear. It makes the next walk feel real.",
        "Pick the pair you have not used lately.",
        "A puddle is not a reason to skip the whole walk.",
        "Start at the corner. See if you want the next one.",
        "Walking with a podcast makes the block feel shorter.",
        "Leave the phone in a pocket and look up sometimes.",
        "A loop is easier to finish than an open-ended plan.",
        "The streak can restart tomorrow. Today still counts.",
        "Hit the step goal, or just get closer. Closer is progress.",
        "Shoes that fit make the walk the easy part.",
        "If one foot feels off, try a different pair.",
        "Retire a pair when the soles are done. That is a win.",
        "Clean shoes feel faster. They are not, but you will go.",
        "Walk the long way back from a small errand.",
        "Get off one stop early when you can.",
        "A park path counts the same as a gym.",
        "Rain walks are shorter and still worth logging.",
        "Hot days like shade and an easier pace.",
        "Cold days like a warm-up lap by the door.",
        "The calendar looks better with a few marks on it.",
        "You already own the shoes. That is the hard part.",
        "One pair, one walk, one tap when you get home.",
        "Compare weeks, not perfect days.",
        "A down week is information, not a failure.",
        "Badges are souvenirs. The walk is the point.",
        "Ten thousand steps is a target, not a rule.",
        "Eight thousand is a solid day too.",
        "If you are under the goal, a 20-minute walk moves it.",
        "Log the pair you actually wore, not the one you meant to.",
        "Two short walks beat a plan you skip.",
        "Stretch your calves after a longer day.",
        "Untie the laces fully. Your foot will thank you.",
        "Swap left and right socks if a shoe rubs. Then go.",
        "The Hall of Fame is for shoes that did their job.",
        "A new colourway is a fine reason for a first walk.",
        "Keep a beater pair for wet days so the nice ones stay out.",
        "Walking more is a habit of showing up, not a test.",
        "SoleCount keeps the numbers. You just take the walk."
    ]

    /// The same tip all day, then a different one tomorrow.
    static func tip(on day: Date, calendar: Calendar) -> String {
        guard !tips.isEmpty else { return "" }
        let ordinal = calendar.ordinality(of: .day, in: .year, for: day) ?? 1
        let index = (ordinal - 1) % tips.count
        return tips[index]
    }
}
