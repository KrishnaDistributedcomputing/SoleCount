#if DEBUG
import SwiftUI
import SwiftData
import UIKit

/// Sample pairs used only for automated App Store screenshots (DEBUG builds only).
/// Names are generic on purpose: no real brand names or logos in screenshots.
enum DemoData {
    @MainActor
    static func insert(into context: ModelContext) {
        let calendar = Calendar.current
        let now = Date.now
        let samples: [(name: String, brand: String, type: ShoeType, price: Double, wears: Int, color: UIColor, km: Double, steps: Double, recent: Int, goal: Double)] = [
            ("Daily Runners", "Running", .running, 140, 48, .systemOrange, 180, 230_000, 0, 600),
            ("White Court Lows", "Everyday", .lifestyle, 95, 31, .systemTeal, 42, 60_000, 1, 0),
            ("Trail Hikers", "Outdoor", .hiking, 180, 12, .systemGreen, 30, 40_000, 40, 0),
        ]

        for (index, sample) in samples.enumerated() {
            let bought = calendar.date(byAdding: .month, value: -(6 + index), to: now) ?? now
            let sneaker = Sneaker(name: sample.name,
                                  brand: sample.brand,
                                  price: sample.price,
                                  purchaseDate: bought,
                                  photoData: photo(color: sample.color),
                                  wearLimit: index == 0 ? 500 : nil,
                                  shoeType: sample.type,
                                  size: index == 0 ? "10" : "",
                                  colorway: index == 0 ? "Grey" : "",
                                  replaceAtKilometers: sample.goal)
            // Spread the wears over the last ~6 months. Trail Hikers sit unused so rotation has something to say.
            for wear in 0..<sample.wears {
                let daysAgo = wear * 140 / max(sample.wears, 1) + sample.recent
                if let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) {
                    sneaker.logWear(on: date)
                }
            }
            sneaker.cachedDistanceMeters = sample.km * 1_000
            sneaker.cachedSteps = sample.steps
            sneaker.cachedMonthlyMetersCSV = (0..<6).map { _ in
                String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"), sample.km * 1_000 / 6)
            }.joined(separator: ",")
            sneaker.healthUpdatedAt = now
            sneaker.createdAt = calendar.date(byAdding: .minute, value: -index, to: now) ?? now
            context.insert(sneaker)
        }
        try? context.save()
    }

    /// A simple colored square with a shoe symbol, so screenshots have "photos".
    private static func photo(color: UIColor) -> Data? {
        let size = CGSize(width: 600, height: 600)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let config = UIImage.SymbolConfiguration(pointSize: 300, weight: .regular)
            if let shoe = UIImage(systemName: "shoe.fill", withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                let rect = CGRect(x: (size.width - shoe.size.width) / 2,
                                  y: (size.height - shoe.size.height) / 2,
                                  width: shoe.size.width,
                                  height: shoe.size.height)
                shoe.draw(in: rect)
            }
        }
        return image.jpegData(compressionQuality: 0.8)
    }
}
#endif
