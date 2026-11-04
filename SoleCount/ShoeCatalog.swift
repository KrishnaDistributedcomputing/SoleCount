import Foundation

/// A shoe style. Saved on each pair as plain text so old data still opens.
enum ShoeType: String, CaseIterable, Identifiable {
    case running = "Running"
    case walking = "Walking"
    case trail = "Trail"
    case basketball = "Basketball"
    case lifestyle = "Lifestyle/Casual"
    case training = "Training/Gym"
    case tennis = "Tennis"
    case skate = "Skate"
    case hiking = "Hiking"
    case soccer = "Soccer/Cleats"
    case golf = "Golf"
    case boots = "Boots"
    case sandals = "Sandals/Slides"
    case dress = "Dress"
    case other = "Other"

    var id: String { rawValue }

    /// SF Symbol name. These exist on iOS 18. No brand logos.
    var symbolName: String {
        switch self {
        case .running: "figure.run"
        case .walking: "figure.walk"
        case .trail: "mountain.2.fill"
        case .basketball: "basketball.fill"
        case .lifestyle: "shoe.fill"
        case .training: "dumbbell.fill"
        case .tennis: "tennisball.fill"
        case .skate: "shoe.2.fill"
        case .hiking: "figure.hiking"
        case .soccer: "soccerball"
        case .golf: "figure.golf"
        case .boots: "shoe.fill"
        case .sandals: "sun.max.fill"
        case .dress: "shoeprints.fill"
        case .other: "square.grid.2x2"
        }
    }

    /// Default "replace at" distance in kilometres. nil means the target starts off.
    var defaultReplaceKilometers: Double? {
        switch self {
        case .running, .training: 650
        case .trail: 650
        case .walking: 800
        case .basketball: 500
        default: nil
        }
    }
}

/// How worn the pair looks. Saved as plain text.
enum ShoeCondition: String, CaseIterable, Identifiable {
    case new = "New"
    case good = "Good"
    case worn = "Worn"
    case beat = "Beat"

    var id: String { rawValue }
}

/// Offline list of well-known brands, types, and a few real models.
/// Names are text only. The app does not ship logos.
enum ShoeCatalog {
    static let recentKey = "recentShoeBrands"

    static let brands: [String] = [
        "Nike", "Jordan", "Adidas", "New Balance", "ASICS", "Puma", "Reebok",
        "Converse", "Vans", "Hoka", "On", "Brooks", "Saucony", "Salomon",
        "Mizuno", "Under Armour", "Skechers", "Fila", "Allbirds", "Timberland",
        "Dr. Martens", "Yeezy", "Merrell", "Altra", "Veja", "Onitsuka Tiger",
        "Birkenstock", "Crocs", "Clarks", "Lululemon"
    ]

    /// A handful of real models for each brand. The name field stays free to type.
    static let modelsByBrand: [String: [String]] = [
        "Nike": ["Air Force 1", "Air Max 90", "Air Max 1", "Pegasus", "Dunk Low", "Cortez"],
        "Jordan": ["Air Jordan 1", "Air Jordan 3", "Air Jordan 4", "Air Jordan 11"],
        "Adidas": ["Samba", "Stan Smith", "Ultraboost", "Gazelle", "Superstar"],
        "New Balance": ["550", "990", "1080", "9060", "574"],
        "ASICS": ["Gel-Kayano", "Gel-Nimbus", "Gel-1130", "Gel-Lyte III"],
        "Puma": ["Suede", "Clyde", "RS-X"],
        "Reebok": ["Club C", "Classic Leather"],
        "Converse": ["Chuck Taylor", "Chuck 70"],
        "Vans": ["Old Skool", "Sk8-Hi", "Authentic"],
        "Hoka": ["Clifton", "Bondi", "Speedgoat"],
        "On": ["Cloud", "Cloudmonster", "Cloudnova"],
        "Brooks": ["Ghost", "Glycerin", "Adrenaline GTS"],
        "Saucony": ["Ride", "Triumph", "Jazz"],
        "Salomon": ["XT-6", "Speedcross"],
        "Mizuno": ["Wave Rider"],
        "Under Armour": ["HOVR Phantom", "Curry"],
        "Skechers": ["Go Walk"],
        "Fila": ["Disruptor"],
        "Allbirds": ["Tree Runner", "Wool Runner"],
        "Timberland": ["6-Inch Premium Boot"],
        "Dr. Martens": ["1460", "1461"],
        "Yeezy": ["Boost 350", "Slide"],
        "Merrell": ["Moab"],
        "Altra": ["Torin", "Lone Peak"],
        "Veja": ["V-10", "Campo"],
        "Onitsuka Tiger": ["Mexico 66"],
        "Birkenstock": ["Arizona", "Boston"],
        "Crocs": ["Classic Clog"],
        "Clarks": ["Desert Boot", "Wallabee"],
        "Lululemon": ["Strongfeel", "Chargefeel"]
    ]

    static func recentBrands(defaults: UserDefaults = .standard) -> [String] {
        defaults.stringArray(forKey: recentKey) ?? []
    }

    static func rememberBrand(_ brand: String, defaults: UserDefaults = .standard) {
        let trimmed = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var list = recentBrands(defaults: defaults).filter {
            $0.caseInsensitiveCompare(trimmed) != .orderedSame
        }
        list.insert(trimmed, at: 0)
        defaults.set(Array(list.prefix(8)), forKey: recentKey)
    }

    /// Recent names first, then the built-in list. A typed search filters both.
    static func brandChoices(query: String, recent: [String]) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var pool = brands
        for name in recent where !pool.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
            pool.append(name)
        }
        if !trimmed.isEmpty {
            pool = pool.filter { $0.localizedCaseInsensitiveContains(trimmed) }
        }
        let rank = Dictionary(uniqueKeysWithValues: recent.enumerated().map { ($1.lowercased(), $0) })
        return pool.sorted { left, right in
            let leftRank = rank[left.lowercased()]
            let rightRank = rank[right.lowercased()]
            switch (leftRank, rightRank) {
            case let (lhs?, rhs?):
                return lhs < rhs
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return (brands.firstIndex(of: left) ?? 999) < (brands.firstIndex(of: right) ?? 999)
            }
        }
    }

    static func models(forBrand brand: String, query: String) -> [String] {
        let match = modelsByBrand.keys.first { $0.caseInsensitiveCompare(brand) == .orderedSame }
        let models = match.flatMap { modelsByBrand[$0] } ?? []
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return models }
        return models.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }
}
