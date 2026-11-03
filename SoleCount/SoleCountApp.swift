import SwiftUI
import SwiftData

// The starting point of the app.
// It creates the Store (for the Pro purchase) and the database (SwiftData),
// then shows the list of sneakers.
@main
struct SoleCountApp: App {
    @State private var store = StoreManager(demoPro: LaunchFlags.demoPro)
    private let container: ModelContainer

    init() {
        container = Self.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            SneakerListView()
                .environment(store)
        }
        .modelContainer(container)
    }

    /// Normal runs save to the phone. Automated tests use a throw-away
    /// in-memory database so every test starts empty.
    @MainActor
    private static func makeContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: LaunchFlags.uiTesting || LaunchFlags.demoData)
        do {
            let container = try ModelContainer(for: Sneaker.self, configurations: config)
            #if DEBUG
            if LaunchFlags.demoData {
                DemoData.insert(into: container.mainContext)
            }
            #endif
            return container
        } catch {
            fatalError("Could not open the SoleCount database: \(error)")
        }
    }
}
