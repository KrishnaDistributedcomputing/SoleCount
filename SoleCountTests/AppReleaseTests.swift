import Foundation
import Testing
@testable import SoleCount

struct AppReleaseTests {
    private let toronto = TimeZone(identifier: "America/Toronto")!

    @Test func identityUsesDisplayNameVersionAndBuild() {
        let info = AppRelease.identity(from: [
            "CFBundleDisplayName": "SoleCount",
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "2"
        ])
        #expect(info.name == "SoleCount")
        #expect(info.version == "1.0")
        #expect(info.build == "2")
    }

    @Test func blankVersionAndBuildStayUnavailable() {
        let info = AppRelease.identity(from: [
            "CFBundleName": "   ",
            "CFBundleShortVersionString": "",
            "CFBundleVersion": " "
        ])
        #expect(info.name == "SoleCount")
        #expect(info.version == "Unavailable")
        #expect(info.build == "Unavailable")
    }

    @Test func aMissingInstantIsUnknownNotUnreleased() throws {
        let nullDate = Data(#"{"versions":{"1.0":{"releasedAt":null}}}"#.utf8)
        let omitted = Data(#"{"versions":{"1.0":{}}}"#.utf8)
        #expect(AppRelease.status(for: "1.0", json: nullDate) == .unavailable)
        #expect(AppRelease.status(for: "1.0", json: omitted) == .unavailable)
        #expect(AppRelease.lastUpdateValue(.unavailable, locale: Locale(identifier: "en_US"), timeZone: toronto) == "Release date unavailable")
        #expect(AppRelease.lastUpdateValue(.unavailable, locale: Locale(identifier: "en_US"), timeZone: toronto) != "Not yet released")
    }

    @Test func anExplicitUnreleasedFlagIsNotTheUnknownState() {
        let flagged = Data(#"{"versions":{"9.9":{"unreleased":true}}}"#.utf8)
        let flaggedNull = Data(#"{"versions":{"9.9":{"releasedAt":null,"unreleased":true}}}"#.utf8)
        #expect(AppRelease.status(for: "9.9", json: flagged) == .notYetReleased)
        #expect(AppRelease.status(for: "9.9", json: flaggedNull) == .notYetReleased)
        #expect(AppRelease.lastUpdateValue(.notYetReleased, locale: Locale(identifier: "en_US"), timeZone: toronto) == "Not yet released")
        let contradicted = Data(#"{"versions":{"9.9":{"releasedAt":"2026-03-15T15:00:00Z","unreleased":true}}}"#.utf8)
        #expect(AppRelease.status(for: "9.9", json: contradicted) != .notYetReleased)
        if case .released = AppRelease.status(for: "9.9", json: contradicted) {
        } else {
            Issue.record("A timezone instant stays a release even if unreleased is also set")
        }
    }

    @Test func aMissingVersionOrBrokenFileIsUnavailable() {
        let other = Data(#"{"versions":{"2.0":{"releasedAt":null}}}"#.utf8)
        #expect(AppRelease.status(for: "1.0", json: other) == .unavailable)
        #expect(AppRelease.status(for: "1.0", json: Data("nope".utf8)) == .unavailable)
        #expect(AppRelease.status(for: "1.0", json: Data(#"{"versions":{"1.0":{"releasedAt":"6 November 2026"}}}"#.utf8)) == .unavailable)
        #expect(AppRelease.status(for: "1.0", json: Data(#"{"versions":{"1.0":{"releasedAt":"2026-11-06"}}}"#.utf8)) == .unavailable)
        #expect(AppRelease.status(for: "1.0", json: Data(#"{"versions":{"1.0":{"releasedAt":"2026-11-06","unreleased":true}}}"#.utf8)) == .unavailable)
        #expect(AppRelease.lastUpdateValue(.unavailable, locale: Locale(identifier: "en_US"), timeZone: toronto) == "Release date unavailable")
    }

    @Test func aTimezoneInstantFormatsInTheDeviceZone() throws {
        let json = Data(#"{"versions":{"1.0":{"releasedAt":"2026-03-15T15:00:00Z"}}}"#.utf8)
        guard case .released(let date) = AppRelease.status(for: "1.0", json: json) else {
            Issue.record("The sample instant should parse")
            return
        }
        let english = AppRelease.formattedRelease(date, locale: Locale(identifier: "en_US"), timeZone: toronto)
        #expect(english.contains("March"))
        #expect(english.contains("15"))
        #expect(english.contains("2026"))
        #expect(english.contains("11:00"))
        #expect(english.contains("EDT") || english.contains("Eastern") || english.contains("GMT-4"))
        let french = AppRelease.formattedRelease(date, locale: Locale(identifier: "fr_FR"), timeZone: toronto)
        #expect(french.contains("mars"))
        #expect(french.contains("15"))
        #expect(!french.contains("March"))
    }

    @Test func theBundledManifestDoesNotClaimARelease() throws {
        let url = try #require(
            Bundle(for: ReleaseManifestAnchor.self).url(forResource: "ReleaseManifest", withExtension: "json")
                ?? Bundle.main.url(forResource: "ReleaseManifest", withExtension: "json")
        )
        let data = try Data(contentsOf: url)
        #expect(AppRelease.status(for: "1.0", json: data) == .unavailable)
        #expect(AppRelease.lastUpdateValue(.unavailable, locale: Locale(identifier: "en_US"), timeZone: toronto) == "Release date unavailable")
        let text = String(decoding: data, as: UTF8.self)
        #expect(!text.contains("2026-11-06"))
        #expect(!text.contains("November"))
    }
}

private final class ReleaseManifestAnchor {}
