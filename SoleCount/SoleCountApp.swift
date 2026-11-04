import SwiftUI
import SwiftData

// The starting point of the app.
// It creates the database and shows Today, the collection, stats, and the calendar.
@main
struct SoleCountApp: App {
    @State private var store = StoreManager(demoPro: LaunchFlags.demoPro)
    @State private var health = HealthSync()
    @State private var motivation = MotivationStore()
    private let container: ModelContainer

    init() {
        container = SneakerDatabase.makeContainer(inMemory: LaunchFlags.uiTesting || LaunchFlags.demoData)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
                .environment(health)
                .environment(motivation)
        }
        .modelContainer(container)
    }
}
