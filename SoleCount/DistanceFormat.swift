import Foundation

/// Turns metres into kilometres or miles for the phone's region.
/// Screenshots always use kilometres so the pictures match the guide.
enum DistanceFormat {
    static let metersPerKilometer = 1_000.0
    static let metersPerMile = 1_609.344

    static func usesMiles(locale: Locale = .current, forceMetric: Bool = false) -> Bool {
        if forceMetric { return false }
        return locale.measurementSystem != .metric
    }

    static func string(meters: Double, locale: Locale = .current, forceMetric: Bool = LaunchFlags.screenshots) -> String {
        let miles = usesMiles(locale: locale, forceMetric: forceMetric)
        let value = miles ? meters / metersPerMile : meters / metersPerKilometer
        let number = value.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
        return miles ? "\(number) mi" : "\(number) km"
    }

    static func unitWord(locale: Locale = .current, forceMetric: Bool = LaunchFlags.screenshots) -> String {
        usesMiles(locale: locale, forceMetric: forceMetric) ? "mi" : "km"
    }

    /// A stored kilometre goal, shown in the unit the phone uses.
    static func displayValue(kilometers: Double, locale: Locale = .current, forceMetric: Bool = LaunchFlags.screenshots) -> Double {
        if usesMiles(locale: locale, forceMetric: forceMetric) {
            return kilometers * metersPerKilometer / metersPerMile
        }
        return kilometers
    }

    static func kilometers(fromDisplay value: Double, locale: Locale = .current, forceMetric: Bool = LaunchFlags.screenshots) -> Double {
        if usesMiles(locale: locale, forceMetric: forceMetric) {
            return value * metersPerMile / metersPerKilometer
        }
        return value
    }

    static func steps(_ steps: Double, locale: Locale = .current) -> String {
        Int(steps.rounded()).formatted(.number.locale(locale))
    }
}
