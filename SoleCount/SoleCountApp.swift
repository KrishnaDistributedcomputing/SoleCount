import SwiftUI
import SwiftData

// The starting point of the app.
// It creates the Store (for the Pro purchase) and the database (SwiftData),
// then shows the list of sneakers.
@main
struct SoleCountApp: App {
    @State private var store = StoreManager()

    var body: some Scene {
        WindowGroup {
            SneakerListView()
                .environment(store)
        }
        .modelContainer(for: Sneaker.self)
    }
}
