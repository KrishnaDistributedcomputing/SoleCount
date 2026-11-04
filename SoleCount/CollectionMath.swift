import Foundation

/// One pair, reduced to the numbers the stats screen needs.
struct PairStats: Equatable {
    var name: String
    var wears: Int
    var price: Double
    var meters: Double
    var steps: Double
    var isRetired: Bool
    var lastWorn: Date?
}

struct CollectionSummary: Equatable {
    var pairCount: Int
    var activeCount: Int
    var retiredCount: Int
    var totalWears: Int
    var totalMeters: Double
    var totalSteps: Double
    var collectionValue: Double
    /// Money spent on pairs you have worn, divided by all wears.
    var averageCostPerWear: Double?
    var mostWorn: String?
    var leastWorn: String?
    var wearStreak: Int
}

struct RotationHint: Equatable {
    var name: String
    /// nil means the pair has never been worn.
    var idleDays: Int?
}

enum CollectionSort: String, CaseIterable, Identifiable {
    case newest
    case brand
    case type
    case distance
    case wears
    case leastWorn
    case lastWorn
    case cost

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newest: "Newest"
        case .brand: "Brand"
        case .type: "Type"
        case .distance: "Distance"
        case .wears: "Most worn"
        case .leastWorn: "Least worn"
        case .lastWorn: "Last worn"
        case .cost: "Cost per wear"
        }
    }
}

struct CollectionRow: Equatable {
    var name: String
    var brand: String
    var type: String
    var wears: Int
    var meters: Double
    var costPerWear: Double?
    var createdAt: Date
    var isRetired: Bool
    var lastWorn: Date? = nil
}

enum CollectionMath {
    static func summarize(pairs: [PairStats], wearDays: Set<Date>, now: Date, calendar: Calendar) -> CollectionSummary {
        let active = pairs.filter { !$0.isRetired }
        let wornPrices = pairs.filter { $0.wears > 0 }.map(\.price).reduce(0, +)
        let totalWears = pairs.reduce(0) { $0 + $1.wears }
        let most = active.max { left, right in
            if left.wears == right.wears {
                return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedDescending
            }
            return left.wears < right.wears
        }
        let least = active.min { left, right in
            if left.wears == right.wears {
                return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedDescending
            }
            return left.wears < right.wears
        }
        let average: Double? = totalWears > 0 ? wornPrices / Double(totalWears) : nil
        return CollectionSummary(
            pairCount: pairs.count,
            activeCount: active.count,
            retiredCount: pairs.filter(\.isRetired).count,
            totalWears: totalWears,
            totalMeters: pairs.reduce(0) { $0 + $1.meters },
            totalSteps: pairs.reduce(0) { $0 + $1.steps },
            collectionValue: pairs.reduce(0) { $0 + $1.price },
            averageCostPerWear: average,
            mostWorn: most?.name,
            leastWorn: least?.name,
            wearStreak: MotionMath.streak(hitDays: wearDays, now: now, calendar: calendar)
        )
    }

    /// Active pairs that have sat for `idleDays` or have never been worn.
    static func forgotten(
        pairs: [(name: String, lastWorn: Date?, isRetired: Bool)],
        now: Date,
        idleDays: Int = 30,
        calendar: Calendar
    ) -> [RotationHint] {
        let today = calendar.startOfDay(for: now)
        var hints: [RotationHint] = []
        for pair in pairs where !pair.isRetired {
            guard let lastWorn = pair.lastWorn else {
                hints.append(RotationHint(name: pair.name, idleDays: nil))
                continue
            }
            let start = calendar.startOfDay(for: lastWorn)
            let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
            if days >= idleDays {
                hints.append(RotationHint(name: pair.name, idleDays: days))
            }
        }
        return hints.sorted { left, right in
            switch (left.idleDays, right.idleDays) {
            case (nil, nil):
                return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
            case (nil, .some):
                return true
            case (.some, nil):
                return false
            case let (lhs?, rhs?):
                if lhs == rhs { return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending }
                return lhs > rhs
            }
        }
    }

    static func hintLine(_ hint: RotationHint) -> String {
        if let days = hint.idleDays {
            return "You haven't worn \(hint.name) in \(days) days"
        }
        return "You haven't worn \(hint.name) yet"
    }

    static func indices(
        rows: [CollectionRow],
        brand: String?,
        type: String?,
        sort: CollectionSort,
        retired: Bool
    ) -> [Int] {
        let filtered = rows.enumerated().filter { item in
            let row = item.element
            guard row.isRetired == retired else { return false }
            if let brand, !brand.isEmpty, row.brand.caseInsensitiveCompare(brand) != .orderedSame {
                return false
            }
            if let type, row.type != type { return false }
            return true
        }
        let sorted = filtered.sorted { left, right in
            switch sort {
            case .newest:
                if left.element.createdAt != right.element.createdAt {
                    return left.element.createdAt > right.element.createdAt
                }
            case .brand:
                let order = left.element.brand.localizedCaseInsensitiveCompare(right.element.brand)
                if order != .orderedSame { return order == .orderedAscending }
            case .type:
                let order = left.element.type.localizedCaseInsensitiveCompare(right.element.type)
                if order != .orderedSame { return order == .orderedAscending }
            case .distance:
                if left.element.meters != right.element.meters { return left.element.meters > right.element.meters }
            case .wears:
                if left.element.wears != right.element.wears { return left.element.wears > right.element.wears }
            case .leastWorn:
                if left.element.wears != right.element.wears { return left.element.wears < right.element.wears }
            case .lastWorn:
                switch (left.element.lastWorn, right.element.lastWorn) {
                case let (lhs?, rhs?) where lhs != rhs:
                    return lhs > rhs
                case (.some, nil):
                    return true
                case (nil, .some):
                    return false
                default:
                    break
                }
            case .cost:
                let leftCost = left.element.costPerWear ?? .greatestFiniteMagnitude
                let rightCost = right.element.costPerWear ?? .greatestFiniteMagnitude
                if leftCost != rightCost { return leftCost < rightCost }
            }
            return left.element.name.localizedCaseInsensitiveCompare(right.element.name) == .orderedAscending
        }
        return sorted.map(\.offset)
    }
}
