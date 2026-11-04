import Foundation
import SwiftData

/// One extra photo on a pair. The original photoData field is still kept
/// so pairs saved by older versions of the app open normally.
@Model
final class SneakerPhotoItem {
    var createdAt: Date = Date.now
    @Attribute(.externalStorage) var photoData: Data?
    var sneaker: Sneaker?

    init(photoData: Data?) {
        self.photoData = photoData
        self.createdAt = .now
    }
}
