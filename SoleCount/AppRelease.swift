import Foundation

/// What About shows for this installed build.
/// `released` is an App Store release instant for that marketing version.
/// It is not the compile time, the approval time, or the day the phone installed the app.
/// `notYetReleased` is only for a version the manifest explicitly marks unreleased.
/// `unavailable` means no verified instant is on record. That is not a claim that the version is unreleased.
enum ReleaseStatus: Equatable {
    case released(Date)
    case notYetReleased
    case unavailable
}

struct AppIdentity: Equatable {
    var name: String
    var version: String
    var build: String
}

enum AppAboutCopy {
    static let lastUpdate = "Last update"
    static let version = "Version"
    static let build = "Build"
    static let notYetReleased = "Not yet released"
    static let releaseUnavailable = "Release date unavailable"
    static let meaning = "Last update is the App Store release of this version, when that time is on record. It is not when this iPhone installed or opened SoleCount."
}

enum AppRelease {
    static func identity(from info: [String: Any]) -> AppIdentity {
        let name = nonEmpty(info["CFBundleDisplayName"])
            ?? nonEmpty(info["CFBundleName"])
            ?? "SoleCount"
        return AppIdentity(
            name: name,
            version: nonEmpty(info["CFBundleShortVersionString"]) ?? "Unavailable",
            build: nonEmpty(info["CFBundleVersion"]) ?? "Unavailable"
        )
    }

    /// A valid `releasedAt` instant wins.
    /// `unreleased: true` with no instant means the version is explicitly unreleased.
    /// Null, a missing instant, a missing version, or a date that is not an instant means unknown.
    static func status(for version: String, json: Data) -> ReleaseStatus {
        guard let root = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              let versions = root["versions"] as? [String: Any],
              let record = versions[version] as? [String: Any] else {
            return .unavailable
        }
        if let text = record["releasedAt"] as? String {
            guard let date = parseReleaseInstant(text) else { return .unavailable }
            return .released(date)
        }
        if let raw = record["releasedAt"], !(raw is NSNull) {
            return .unavailable
        }
        if record["unreleased"] as? Bool == true {
            return .notYetReleased
        }
        return .unavailable
    }

    static func status(for version: String, bundle: Bundle) -> ReleaseStatus {
        guard let url = bundle.url(forResource: "ReleaseManifest", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return .unavailable
        }
        return status(for: version, json: data)
    }

    /// An unambiguous instant. A date with no timezone is rejected.
    static func parseReleaseInstant(_ text: String) -> Date? {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime]
        return parser.date(from: text)
    }

    static func lastUpdateValue(_ status: ReleaseStatus, locale: Locale, timeZone: TimeZone) -> String {
        switch status {
        case .notYetReleased:
            return AppAboutCopy.notYetReleased
        case .unavailable:
            return AppAboutCopy.releaseUnavailable
        case .released(let date):
            return formattedRelease(date, locale: locale, timeZone: timeZone)
        }
    }

    /// Date, time, and timezone name in the given locale and zone. Not a fixed city.
    static func formattedRelease(_ date: Date, locale: Locale, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        let when = formatter.string(from: date)
        let style: NSTimeZone.NameStyle = timeZone.isDaylightSavingTime(for: date) ? .shortDaylightSaving : .shortStandard
        let zone = timeZone.localizedName(for: style, locale: locale)
            ?? timeZone.abbreviation(for: date)
            ?? timeZone.identifier
        return "\(when) \(zone)"
    }

    private static func nonEmpty(_ value: Any?) -> String? {
        guard let text = value as? String else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
