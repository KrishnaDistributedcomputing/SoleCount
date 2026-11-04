import Foundation
import SwiftData

/// One photo of a pair's sole, with the date and the pair's distance when it was taken.
/// Added in version 1.0 (build 2). It is a new model, so older databases open as before.
@Model
final class SolePhoto {
    var takenAt: Date = Date.now
    /// The pair's total kilometres when the photo was taken.
    var kilometers: Double = 0
    @Attribute(.externalStorage) var photoData: Data?
    var sneaker: Sneaker?

    init(photoData: Data?, takenAt: Date = .now, kilometers: Double) {
        self.photoData = photoData
        self.takenAt = takenAt
        self.kilometers = kilometers
    }
}

/// The date and distance of a sole photo, for the math below.
struct SoleSnapshot: Equatable {
    var takenAt: Date
    var kilometers: Double
}

/// Ordering, compare, and the gentle "time for a sole check" nudge.
enum SoleCheckMath {
    static let nudgeEveryKilometers = 100.0

    /// Oldest first, which is how the timeline reads.
    static func orderedIndices(_ snapshots: [SoleSnapshot]) -> [Int] {
        snapshots.indices.sorted { lhs, rhs in
            if snapshots[lhs].takenAt != snapshots[rhs].takenAt {
                return snapshots[lhs].takenAt < snapshots[rhs].takenAt
            }
            return snapshots[lhs].kilometers < snapshots[rhs].kilometers
        }
    }

    /// First and latest photo for the side-by-side view. Needs two photos.
    static func compareIndices(_ snapshots: [SoleSnapshot]) -> (first: Int, latest: Int)? {
        let order = orderedIndices(snapshots)
        guard order.count >= 2, let first = order.first, let latest = order.last else { return nil }
        return (first, latest)
    }

    static func kilometersSinceLast(_ snapshots: [SoleSnapshot], currentKilometers: Double) -> Double? {
        guard let latest = orderedIndices(snapshots).last else { return nil }
        return max(0, currentKilometers - snapshots[latest].kilometers)
    }

    /// True once a pair has gone another 100 km since its last sole photo.
    static func shouldNudge(_ snapshots: [SoleSnapshot], currentKilometers: Double) -> Bool {
        guard let since = kilometersSinceLast(snapshots, currentKilometers: currentKilometers) else { return false }
        return since >= nudgeEveryKilometers
    }
}

extension Sneaker {
    /// Sole photos, oldest first.
    var orderedSolePhotos: [SolePhoto] {
        let list = solePhotos
        return SoleCheckMath.orderedIndices(list.map { SoleSnapshot(takenAt: $0.takenAt, kilometers: $0.kilometers) }).map { list[$0] }
    }

    var soleSnapshots: [SoleSnapshot] {
        solePhotos.map { SoleSnapshot(takenAt: $0.takenAt, kilometers: $0.kilometers) }
    }

    func addSolePhoto(_ data: Data, in context: ModelContext, at date: Date = .now) {
        let photo = SolePhoto(photoData: data, takenAt: date, kilometers: totalMeters / 1_000)
        context.insert(photo)
        solePhotos.append(photo)
    }
}
