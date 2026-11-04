import Foundation
import SwiftData

/// One database for the app and the Siri shortcut, so a wear is saved once.
@MainActor
enum SneakerDatabase {
    private static var disk: ModelContainer?

    static func makeContainer(inMemory: Bool) -> ModelContainer {
        if !inMemory, let disk { return disk }
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        do {
            let container = try ModelContainer(
                for: Sneaker.self,
                SneakerPhotoItem.self,
                WishlistItem.self,
                configurations: config
            )
            #if DEBUG
            if inMemory && LaunchFlags.demoData {
                DemoData.insert(into: container.mainContext)
            }
            #endif
            if !inMemory { disk = container }
            return container
        } catch {
            fatalError("Could not open the SoleCount database: \(error)")
        }
    }
}
