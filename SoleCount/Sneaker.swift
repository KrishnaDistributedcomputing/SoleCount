import Foundation
import SwiftData

// One pair of sneakers, saved on the phone with SwiftData.
// New fields all have defaults so pairs from older versions of the app still open.
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

    var shoeTypeRaw: String = ShoeType.other.rawValue
    var notes: String = ""
    var size: String = ""
    var colorway: String = ""
    var conditionRaw: String = ShoeCondition.good.rawValue

    /// Cached Health totals so the list opens without waiting on Apple Health.
    var cachedSteps: Double = 0
    var cachedDistanceMeters: Double = 0
    /// Six monthly distances in metres, oldest first, separated by commas.
    var cachedMonthlyMetersCSV: String = ""
    var cachedSharedDays: Int = 0
    /// 0 = not shared, -1 = shared with a different count on some days, otherwise the other-pair count.
    var cachedShareOthers: Int = 0
    var healthUpdatedAt: Date?
    /// 0 means there is no replacement target.
    var replaceAtKilometers: Double = 0

    @Relationship(deleteRule: .cascade, inverse: \SneakerPhotoItem.sneaker)
    var photos: [SneakerPhotoItem] = []

    init(name: String,
         brand: String,
         price: Double,
         purchaseDate: Date = .now,
         photoData: Data? = nil,
         wearLimit: Int? = nil,
         shoeType: ShoeType = .other,
         size: String = "",
         colorway: String = "",
         condition: ShoeCondition = .good,
         notes: String = "",
         replaceAtKilometers: Double = 0) {
        self.name = name
        self.brand = brand
        self.price = price
        self.purchaseDate = purchaseDate
        self.createdAt = .now
        self.photoData = photoData
        self.wearDates = []
        self.isRetired = false
        self.wearLimit = wearLimit
        self.shoeTypeRaw = shoeType.rawValue
        self.size = size
        self.colorway = colorway
        self.conditionRaw = condition.rawValue
        self.notes = notes
        self.replaceAtKilometers = replaceAtKilometers
    }

    var shoeType: ShoeType {
        get { ShoeType(rawValue: shoeTypeRaw) ?? .other }
        set { shoeTypeRaw = newValue.rawValue }
    }

    var condition: ShoeCondition {
        get { ShoeCondition(rawValue: conditionRaw) ?? .good }
        set { conditionRaw = newValue.rawValue }
    }

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

    var lastWorn: Date? { wearDates.max() }

    var monthlyMeters: [Double] {
        let values = cachedMonthlyMetersCSV.split(separator: ",").compactMap { Double($0) }
        if values.count >= 6 { return Array(values.prefix(6)) }
        return values + Array(repeating: 0, count: 6 - values.count)
    }

    var shareNote: String? {
        let others: Int? = cachedShareOthers > 0 ? cachedShareOthers : nil
        return HealthAttribution.shareNote(sharedDayCount: cachedSharedDays, otherPairs: others)
    }

    var averageMetersPerWear: Double? {
        guard wearCount > 0 else { return nil }
        return cachedDistanceMeters / Double(wearCount)
    }

    var reachedMileageGoal: Bool {
        replaceAtKilometers > 0 && cachedDistanceMeters + 0.5 >= replaceAtKilometers * 1_000
    }

    /// Extra photos first. If there are none, the original single photo is used.
    var gallery: [Data] {
        let extra = photos.sorted { $0.createdAt < $1.createdAt }.compactMap(\.photoData)
        if !extra.isEmpty { return extra }
        if let photoData { return [photoData] }
        return []
    }

    func logWear(on date: Date = .now) {
        wearDates.append(date)
    }

    func undoTodayWear() {
        if let index = wearDates.lastIndex(where: { Calendar.current.isDateInToday($0) }) {
            wearDates.remove(at: index)
        }
    }

    func applyHealth(_ result: AttributedShoe) {
        cachedSteps = result.steps
        cachedDistanceMeters = result.distanceMeters
        cachedMonthlyMetersCSV = result.monthlyMeters.map { meters in
            String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"), meters)
        }.joined(separator: ",")
        cachedSharedDays = result.sharedDayCount
        if result.sharedDayCount == 0 {
            cachedShareOthers = 0
        } else if let others = result.otherPairs {
            cachedShareOthers = others
        } else {
            cachedShareOthers = -1
        }
        healthUpdatedAt = .now
    }

    func asRow() -> CollectionRow {
        CollectionRow(
            name: name,
            brand: brand,
            type: shoeType.rawValue,
            wears: wearCount,
            meters: cachedDistanceMeters,
            costPerWear: costPerWear,
            createdAt: createdAt,
            isRetired: isRetired
        )
    }

    func asPairStats() -> PairStats {
        PairStats(
            name: name,
            wears: wearCount,
            price: price,
            meters: cachedDistanceMeters,
            steps: cachedSteps,
            isRetired: isRetired,
            lastWorn: lastWorn
        )
    }

    func asExportRow() -> ExportRow {
        ExportRow(
            name: name,
            brand: brand,
            type: shoeType.rawValue,
            size: size,
            colorway: colorway,
            condition: condition.rawValue,
            price: price,
            purchaseDate: purchaseDate,
            wears: wearCount,
            meters: cachedDistanceMeters,
            steps: cachedSteps,
            retired: isRetired,
            notes: notes
        )
    }

    func replacePhotos(_ datas: [Data], in context: ModelContext) {
        for photo in photos {
            context.delete(photo)
        }
        let items = datas.map { data in
            let item = SneakerPhotoItem(photoData: data)
            context.insert(item)
            return item
        }
        photos = items
        photoData = datas.first
    }
}
