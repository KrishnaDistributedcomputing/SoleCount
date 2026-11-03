import Foundation

/// Switches used only by automated tests and screenshots.
/// They are passed as launch arguments by the UI tests (for example "-UITesting").
/// In Release builds (the App Store version) every flag is always false.
enum LaunchFlags {
    private static func has(_ flag: String) -> Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains(flag)
        #else
        return false
        #endif
    }

    /// Use an empty in-memory database.
    static var uiTesting: Bool { has("-UITesting") }
    /// Fill the database with sample pairs (for screenshots).
    static var demoData: Bool { has("-DemoData") }
    /// Pretend Pro is unlocked (for the chart screenshot).
    static var demoPro: Bool { has("-DemoPro") }
    /// We are taking App Store screenshots.
    static var screenshots: Bool { has("-Screenshots") }
}
