import AppIntents
import Foundation
import SwiftData

/// "Log today's sneakers" for Shortcuts and Siri. It only updates the on-device log.
struct LogTodayWearIntent: AppIntent {
    static var title: LocalizedStringResource = "Log today's sneakers"
    static var description = IntentDescription("Add a wear for a pair in SoleCount.")
    static var openAppWhenRun = true

    @Parameter(title: "Pair name", requestValueDialog: IntentDialog("Which pair did you wear?"))
    var pairName: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = await MainActor.run { WearLogAction.log(named: pairName) }
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

/// Finds the pair and adds today's wear. Kept separate so the intent stays short.
enum WearLogAction {
    @MainActor
    static func log(named rawName: String) -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return "Say the name of the pair you wore." }
        let container = SneakerDatabase.makeContainer(inMemory: false)
        let context = container.mainContext
        let all = (try? context.fetch(FetchDescriptor<Sneaker>())) ?? []
        let active = all.filter { !$0.isRetired }
        let match = active.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
            ?? active.first { $0.name.localizedCaseInsensitiveContains(name) }
        guard let match else { return "No pair named \(name) in SoleCount." }
        match.logWear()
        try? context.save()
        return "Logged a wear for \(match.name)."
    }
}

struct SoleCountShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogTodayWearIntent(),
            phrases: ["Log today's sneakers in \(.applicationName)"],
            shortTitle: "Log today's sneakers",
            systemImageName: "shoe.2"
        )
    }
}
