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
        let samples: [(name: String, brand: String, price: Double, wears: Int, color: UIColor)] = [
            ("Daily Runners", "Running", 140, 48, .systemOrange),
            ("White Court Lows", "Everyday", 95, 31, .systemTeal),
            ("Trail Hikers", "Outdoor", 180, 12, .systemGreen),
        ]

        for (index, sample) in samples.enumerated() {
            let bought = calendar.date(byAdding: .month, value: -(6 + index), to: now) ?? now
            let sneaker = Sneaker(name: sample.name,
                                  brand: sample.brand,
                                  price: sample.price,
                                  purchaseDate: bought,
                                  photoData: photo(color: sample.color),
                                  wearLimit: index == 0 ? 500 : nil)
            // Spread the wears over the last ~6 months.
            for wear in 0..<sample.wears {
                let daysAgo = wear * 170 / max(sample.wears, 1) + index
                if let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) {
                    sneaker.logWear(on: date)
                }
            }
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
