import Foundation

/// US, UK, or EU. The short word is what the screen and the database store.
enum SizeSystem: String, CaseIterable, Identifiable {
    case us = "US"
    case uk = "UK"
    case eu = "EU"

    var id: String { rawValue }
}

/// Men's, women's, or unisex. This is the pair's fit, and it also picks the size chart.
/// Unisex uses the men's column, which is how Nike sizes unisex shoes.
enum ShoeFit: String, CaseIterable, Identifiable {
    case mens = "Men's"
    case womens = "Women's"
    case unisex = "Unisex"

    var id: String { rawValue }

    /// The words on the shoe page: Men's, Women's, or Unisex.
    var label: String { rawValue }

    var usesWomensColumn: Bool { self == .womens }
}

/// The size system a new pair starts in. It lives in UserDefaults on this iPhone.
enum ShoeSizeDefaults {
    static let systemKey = "defaultSizeSystem"

    static func system(defaults: UserDefaults = .standard) -> SizeSystem {
        SizeSystem(rawValue: defaults.string(forKey: systemKey) ?? "") ?? .us
    }

    static func setSystem(_ system: SizeSystem, defaults: UserDefaults = .standard) {
        defaults.set(system.rawValue, forKey: systemKey)
    }
}

/// Converts a saved size between US, UK, and EU.
///
/// The rows are Nike's published men's footwear chart (the same chart lists a women's
/// US size 1.5 above the men's size). UK 6 appears on two rows. When the saved size
/// is UK 6, the row used is the one where UK is one full size below the men's US size.
enum ShoeSizeChart {
    struct Converted: Equatable {
        var us: String
        var uk: String
        var eu: String

        func text(for system: SizeSystem) -> String {
            switch system {
            case .us: "US \(us)"
            case .uk: "UK \(uk)"
            case .eu: "EU \(eu)"
            }
        }
    }

    struct Row: Equatable {
        /// Tenths of a size, so 10.5 is 105. Whole numbers avoid fuzzy compares.
        var usMen: Int
        var usWomen: Int
        var uk: Int
        var eu: Int
    }

    /// Men's UK sizes, in tenths, lined up with men's US 3.5 through 22.
    private static let ukTenths: [Int] = [
        30, 35, 40, 45, 50, 55, 60, 60, 65, 70,
        75, 80, 85, 90, 95, 100, 105, 110, 115, 120,
        125, 130, 135, 140, 145, 150, 155, 160, 165, 170,
        175, 180, 185, 190, 195, 200, 205, 210
    ]

    /// Men's EU sizes, in tenths, on those same rows.
    private static let euTenths: [Int] = [
        355, 360, 365, 375, 380, 385, 390, 400, 405, 410,
        420, 425, 430, 440, 445, 450, 455, 460, 470, 475,
        480, 485, 490, 495, 500, 505, 510, 515, 520, 525,
        530, 535, 540, 545, 550, 555, 560, 565
    ]

    static let rows: [Row] = {
        let usMen = Array(stride(from: 35, through: 220, by: 5))
        guard usMen.count == ukTenths.count, usMen.count == euTenths.count else { return [] }
        return usMen.indices.map { index in
            Row(
                usMen: usMen[index],
                usWomen: usMen[index] + 15,
                uk: ukTenths[index],
                eu: euTenths[index]
            )
        }
    }()

    /// "US 10". Empty when the person has not typed a size.
    static func label(size: String, system: SizeSystem) -> String {
        let trimmed = size.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return "\(system.rawValue) \(trimmed)"
    }

    /// "Also UK 9 and EU 44", or nil when the typed size is not on the chart.
    static func equivalentLine(size: String, system: SizeSystem, fit: ShoeFit) -> String? {
        guard let converted = convert(size: size, system: system, fit: fit) else { return nil }
        let others = SizeSystem.allCases.filter { $0 != system }.map { converted.text(for: $0) }
        guard others.count == 2 else { return nil }
        return "Also \(others[0]) and \(others[1])"
    }

    static func convert(size: String, system: SizeSystem, fit: ShoeFit) -> Converted? {
        guard let tenths = tenths(from: size), let row = row(tenths: tenths, system: system, fit: fit) else {
            return nil
        }
        return Converted(
            us: format(tenths: fit.usesWomensColumn ? row.usWomen : row.usMen),
            uk: format(tenths: row.uk),
            eu: format(tenths: row.eu)
        )
    }

    static func row(tenths: Int, system: SizeSystem, fit: ShoeFit) -> Row? {
        let matches = rows.filter { row in
            switch system {
            case .us:
                return tenths == (fit.usesWomensColumn ? row.usWomen : row.usMen)
            case .uk:
                return tenths == row.uk
            case .eu:
                return tenths == row.eu
            }
        }
        if matches.count <= 1 { return matches.first }
        return matches.first { $0.uk == $0.usMen - 10 } ?? matches[0]
    }

    static func tenths(from text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= 0, value < 100 else { return nil }
        let scaled = value * 10
        let rounded = scaled.rounded()
        guard abs(scaled - rounded) < 0.001 else { return nil }
        return Int(rounded)
    }

    static func format(tenths: Int) -> String {
        let whole = tenths / 10
        let fraction = abs(tenths % 10)
        if fraction == 0 { return String(whole) }
        return "\(whole).\(fraction)"
    }
}
