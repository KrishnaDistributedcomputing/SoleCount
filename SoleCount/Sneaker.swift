import Foundation
import SwiftData

// One pair of sneakers, saved on the phone with SwiftData.
@Model
final class Sneaker {
    var name: String = ""
    var brand: String = ""
    var price: Double = 0
    var purchaseDate: Date = Date.now
    var createdAt: Date = Date.now

    // The photo is stored outside the main database file to keep it fast.
    @Attribute(.externalStorage) var photoData: Data?

    // Every time you tap "Wore today", the date is added here.
    var wearDates: [Date] = []

    var isRetired: Bool = false

    // Optional: retire the pair after this many wears (nil = no limit).
    var wearLimit: Int?

    init(name: String,
         brand: String,
         price: Double,
         purchaseDate: Date = .now,
         photoData: Data? = nil,
         wearLimit: Int? = nil) {
        self.name = name
        self.brand = brand
        self.price = price
        self.purchaseDate = purchaseDate
        self.createdAt = .now
        self.photoData = photoData
        self.wearDates = []
        self.isRetired = false
        self.wearLimit = wearLimit
    }

    // MARK: - Handy calculations (not saved, worked out on the fly)

    var wearCount: Int { wearDates.count }

    /// Price divided by number of wears. nil until the first wear.
    var costPerWear: Double? {
        wearCount > 0 ? price / Double(wearCount) : nil
    }

    var woreToday: Bool {
        wearDates.contains { Calendar.current.isDateInToday($0) }
    }

    var hasReachedLimit: Bool {
        guard let limit = wearLimit, limit > 0 else { return false }
        return wearCount >= limit
    }

    func logWear(on date: Date = .now) {
        wearDates.append(date)
    }

    func undoTodayWear() {
        if let index = wearDates.lastIndex(where: { Calendar.current.isDateInToday($0) }) {
            wearDates.remove(at: index)
        }
    }
}
