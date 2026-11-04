import Foundation

/// What you typed for a pair you have not bought yet.
struct WishlistDraft: Equatable {
    var brand: String
    var modelName: String
    var targetPrice: Double
    var notes: String
}

/// The collection pair created when you tap "I bought it".
struct BoughtPairDraft: Equatable {
    var name: String
    var brand: String
    var price: Double
    var notes: String
}

enum WishlistMath {
    static func bought(_ item: WishlistDraft) -> BoughtPairDraft {
        let model = item.modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        let brand = item.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = model.isEmpty ? (brand.isEmpty ? "New pair" : brand) : model
        return BoughtPairDraft(
            name: name,
            brand: brand,
            price: max(0, item.targetPrice),
            notes: item.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
