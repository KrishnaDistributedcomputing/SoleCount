import Foundation

/// Logged wears plus anything the pair already had when you added it.
enum PairTotals {
    static func wears(logged: Int, starting: Int) -> Int {
        max(0, logged) + max(0, starting)
    }

    static func meters(tracked: Double, startingKilometers: Double) -> Double {
        max(0, tracked) + max(0, startingKilometers) * 1_000
    }

    static func costPerWear(price: Double, wears: Int) -> Double? {
        guard wears > 0 else { return nil }
        return price / Double(wears)
    }

    /// Whole days from the purchase date through today. Same day is 0.
    static func daysOwned(from purchase: Date, to now: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: purchase)
        let end = calendar.startOfDay(for: now)
        return max(0, calendar.dateComponents([.day], from: start, to: end).day ?? 0)
    }
}
