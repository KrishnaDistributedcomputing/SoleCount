import Foundation
import SwiftData

/// A pair you might buy next. It stays on the phone until you move it into the collection.
@Model
final class WishlistItem {
    var brand: String = ""
    var modelName: String = ""
    var targetPrice: Double = 0
    var notes: String = ""
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date = Date.now

    init(brand: String, modelName: String, targetPrice: Double, notes: String = "", photoData: Data? = nil) {
        self.brand = brand
        self.modelName = modelName
        self.targetPrice = targetPrice
        self.notes = notes
        self.photoData = photoData
        self.createdAt = .now
    }
}
