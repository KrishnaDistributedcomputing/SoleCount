import SwiftUI
import UIKit

// MARK: - Money formatting

extension Double {
    /// Shows a number as money in the phone's currency, e.g. "$12.50".
    var asCurrency: String {
        formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

// MARK: - Photo shrinking

enum ImageHelper {
    /// Shrinks a photo to at most 1024 pixels wide/tall and saves it as JPEG,
    /// so the app stays small and fast.
    static func downsized(_ data: Data, maxDimension: CGFloat = 1024) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > 0 else { return nil }
        let scale = min(1, maxDimension / longestSide)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Reusable little views

/// A square photo of the sneaker, or a shoe icon if there is no photo.
struct SneakerPhoto: View {
    let data: Data?
    var size: CGFloat = 56

    var body: some View {
        Group {
            if let data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.2),
                            Color.accentColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "shoe.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .accessibilityHidden(true)
    }
}
