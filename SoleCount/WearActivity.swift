import Foundation

/// What the person did while wearing the pair. Saved as plain text next to the wear date.
enum WearActivity: String, CaseIterable, Identifiable {
    case casual = "Casual"
    case walking = "Walking"
    case running = "Running"
    case gym = "Gym"
    case basketball = "Basketball"
    case hiking = "Hiking"
    case other = "Other"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .casual: "shoe.fill"
        case .walking: "figure.walk"
        case .running: "figure.run"
        case .gym: "dumbbell.fill"
        case .basketball: "basketball.fill"
        case .hiking: "figure.hiking"
        case .other: "ellipsis.circle"
        }
    }
}

struct WearRecord: Equatable {
    var date: Date
    var activity: WearActivity
}

struct ActivityCount: Equatable, Identifiable {
    var activity: WearActivity
    var count: Int

    var id: String { activity.rawValue }
}

/// Turns saved dates and activity names into records. Missing names are Casual,
/// which is how wears from older versions of the app are read.
enum WearActivityMath {
    static func records(dates: [Date], activityRaws: [String]) -> [WearRecord] {
        dates.enumerated().map { index, date in
            let activity: WearActivity
            if activityRaws.indices.contains(index), let known = WearActivity(rawValue: activityRaws[index]) {
                activity = known
            } else if activityRaws.indices.contains(index) {
                activity = .other
            } else {
                activity = .casual
            }
            return WearRecord(date: date, activity: activity)
        }
    }

    static func counts(_ records: [WearRecord]) -> [ActivityCount] {
        WearActivity.allCases.compactMap { activity in
            let count = records.filter { $0.activity == activity }.count
            return count > 0 ? ActivityCount(activity: activity, count: count) : nil
        }
    }
}
