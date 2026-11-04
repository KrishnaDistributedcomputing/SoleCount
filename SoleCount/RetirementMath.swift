import Foundation

/// How far a pair is through its distance target.
enum LifeBand: Equatable {
    case none
    case green
    case yellow
    case red
}

/// A distance alert the phone may show. 80% and 100% only.
enum RetirementMark: Equatable {
    case eighty
    case full
}

/// Pure rules for the green / yellow / red bar. No HealthKit and no notifications here.
enum RetirementMath {
    static func fraction(meters: Double, goalKilometers: Double) -> Double? {
        guard goalKilometers > 0 else { return nil }
        return max(0, meters) / (goalKilometers * 1_000)
    }

    /// Green under 80%, yellow from 80% up to the target, red at the target.
    static func band(for fraction: Double?) -> LifeBand {
        guard let fraction else { return .none }
        if fraction >= 1 { return .red }
        if fraction >= 0.8 { return .yellow }
        return .green
    }

    /// Marks crossed between two distances. Empty when the target is off.
    static func marks(previousMeters: Double, meters: Double, goalKilometers: Double) -> [RetirementMark] {
        guard let before = fraction(meters: previousMeters, goalKilometers: goalKilometers),
              let after = fraction(meters: meters, goalKilometers: goalKilometers) else { return [] }
        var result: [RetirementMark] = []
        if before < 0.8, after >= 0.8 { result.append(.eighty) }
        if before < 1, after >= 1 { result.append(.full) }
        return result
    }

    /// 0, 80, or 100. Used so the same alert is not sent twice.
    static func highWater(for fraction: Double?) -> Int {
        switch band(for: fraction) {
        case .none, .green: 0
        case .yellow: 80
        case .red: 100
        }
    }
}
