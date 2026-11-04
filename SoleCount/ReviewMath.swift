import Foundation

/// Numbers for a share card. The picture is drawn on the phone.
struct ReviewSummary: Equatable {
    var title: String
    var topPair: String?
    var totalMeters: Double
    var wears: Int
    var bestStreak: Int
}

enum ReviewMath {
    static func summarize(
        title: String,
        pairs: [(name: String, wears: Int, meters: Double)],
        bestStreak: Int
    ) -> ReviewSummary {
        let top = pairs.max { left, right in
            if left.wears == right.wears {
                return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedDescending
            }
            return left.wears < right.wears
        }
        let topName: String? = {
            guard let top, top.wears > 0 else { return nil }
            return top.name
        }()
        return ReviewSummary(
            title: title,
            topPair: topName,
            totalMeters: pairs.reduce(0) { $0 + max(0, $1.meters) },
            wears: pairs.reduce(0) { $0 + max(0, $1.wears) },
            bestStreak: max(0, bestStreak)
        )
    }
}
