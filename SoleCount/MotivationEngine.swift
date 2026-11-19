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
    var totalWears: Int = 0
    /// Lowest cost per wear among pairs that have been worn. nil if none.
    var lowestCostPerWear: Double? = nil
    var pairCount: Int = 0
    var starterQuestDone: Bool = false
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
            Badge(id: "full-life", title: "Full life", detail: "A pair reached its distance target", symbol: "checkmark.seal.fill", unlocked: input.pairReachedReplaceTarget),
            Badge(id: "first-wear", title: "First wear", detail: "The first time a pair was logged", symbol: "shoe.2", unlocked: input.totalWears >= 1),
            Badge(id: "wears-50", title: "50 wears", detail: "50 wears across the collection", symbol: "figure.walk", unlocked: input.totalWears >= 50),
            Badge(id: "wears-100", title: "100 wears", detail: "100 wears across the collection", symbol: "figure.walk.motion", unlocked: input.totalWears >= 100),
            Badge(id: "cost-under-1", title: "Under 1 a wear", detail: "A pair costs less than 1 per wear", symbol: "dollarsign.circle", unlocked: (input.lowestCostPerWear ?? .greatestFiniteMagnitude) < 1),
            Badge(id: "collection-10", title: "10 pairs", detail: "Ten pairs in the collection", symbol: "square.grid.3x3.fill", unlocked: input.pairCount >= 10),
            Badge(id: "starter-quest", title: "Quest complete", detail: "Finished the starter quest", symbol: "map.fill", unlocked: input.starterQuestDone)
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
        calendar: Calendar,
        totalWears: Int = 0,
        lowestCostPerWear: Double? = nil,
        pairCount: Int = 0,
        stepStreakOverride: Int? = nil
    ) -> BadgeInput {
        let hits = MotionMath.hitDays(from: days, stepGoal: stepGoal, calendar: calendar)
        return BadgeInput(
            totalMeters: totalMeters,
            bestWeekMeters: MotionMath.bestWeekMeters(days: days, calendar: calendar),
            stepStreak: stepStreakOverride ?? MotionMath.streak(hitDays: hits, now: now, calendar: calendar),
            bestDaySteps: days.map(\.steps).max() ?? 0,
            woreEveryActivePairThisMonth: woreEveryActivePair(wearDates: activeWearDates, month: now, calendar: calendar),
            pairReachedReplaceTarget: replaceReached,
            totalWears: totalWears,
            lowestCostPerWear: lowestCostPerWear,
            pairCount: pairCount
        )
    }

    static func facts(meters: Double, locale: Locale = .current) -> [DistanceFact] {
        guard meters >= soccerFieldMeters else { return [] }
        var lines: [DistanceFact] = []
        let fields = Int(meters / soccerFieldMeters)
        let noun = fields == 1 ? "soccer field" : "soccer fields"
        lines.append(DistanceFact(text: "You've walked the length of \(fields.formatted(.number.locale(locale))) \(noun)"))

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
                lines.append(DistanceFact(text: "≈ \(count.formatted(.number.locale(locale))) × \(best.name)"))
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
        "A quieter week is just information.",
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

    /// About 60 original mood lines. Encouragement only, not medical advice.
    static let affirmations: [String] = [
        "Your feet already know the way to a nicer hour.",
        "A few steps outside can soften a busy mind.",
        "You are allowed to walk slowly and still be proud.",
        "Fresh air is a small gift you can give yourself.",
        "The pair you choose today gets to share the day.",
        "Showing up in your shoes is enough of a plan.",
        "A calm pace is a strong pace.",
        "Sunlight on the sidewalk is a fine companion.",
        "You can start small and still feel the lift.",
        "Moving a little is a kind thing to do.",
        "There is room in the day for an easy loop.",
        "Your collection is a shelf of good days.",
        "One block can change the feel of a morning.",
        "You do not have to be fast to be out there.",
        "A walk can be the soft part of a loud day.",
        "The shoes by the door are an invitation.",
        "You have already done the brave bit: you own the habit.",
        "Let the route be simple. The mood can still be bright.",
        "A quiet street and your favorite pair is a full plan.",
        "Today's steps belong to you, however many there are.",
        "Going out for a little while still counts as going out.",
        "You can thank your shoes by taking them somewhere pleasant.",
        "A gentle walk is a good way to meet the day.",
        "The sky looks better when you are under it.",
        "Your body likes the easy rhythm of a walk.",
        "Choose the pair that makes you smile, then step out.",
        "A short outing can leave a long good feeling.",
        "You are building a story, one wear at a time.",
        "There is no wrong pair for a kind walk.",
        "Let today be light. The shoes can do the heavy part.",
        "A lap around the block is a complete kindness.",
        "You can pause, breathe, and still keep the good streak of trying.",
        "Warm light and a familiar route is a lovely mix.",
        "The next corner can be the whole adventure.",
        "Wearing the quiet pair is a fine celebration.",
        "You are someone who makes time to move.",
        "A walk does not need an audience.",
        "Put on the shoes. The rest can be easy.",
        "Your future self will like that you went.",
        "Even a tiny outing is a bright mark on the day.",
        "The world outside is ready whenever you are.",
        "You can walk beside your thoughts without rushing them.",
        "A favorite path is a friend you can visit.",
        "Soft steps still move you forward.",
        "Today can be the day the unused pair gets some sun.",
        "You deserve a few minutes that are only for moving.",
        "The best pace is the one that feels welcome.",
        "A clear bit of sky is reason enough to go.",
        "Your shoes are cheering in their own quiet way.",
        "Step out, look around, and come back pleased.",
        "A walk can be how you say hello to yourself.",
        "You are allowed to enjoy the outing and nothing more.",
        "Nice weather or not, a short walk can feel like care.",
        "The habit is simply this: you go, then you log it.",
        "There is a good hour hiding in an ordinary route.",
        "You can carry a light mood out the door with you.",
        "Every pair in the closet has a day worth having.",
        "A little movement is a warm way to begin again.",
        "You showed up. That is the whole win.",
        "Leave the door, take the walk, keep the smile."
    ]

    /// The same line all day, then a different one tomorrow.
    static func affirmation(on day: Date, calendar: Calendar) -> String {
        line(affirmations, on: day, calendar: calendar)
    }

    /// The same tip all day, then a different one tomorrow.
    static func tip(on day: Date, calendar: Calendar) -> String {
        line(tips, on: day, calendar: calendar)
    }

    private static func line(_ lines: [String], on day: Date, calendar: Calendar) -> String {
        guard !lines.isEmpty else { return "" }
        let ordinal = calendar.ordinality(of: .day, in: .year, for: day) ?? 1
        let index = (ordinal - 1) % lines.count
        return lines[index]
    }
}
