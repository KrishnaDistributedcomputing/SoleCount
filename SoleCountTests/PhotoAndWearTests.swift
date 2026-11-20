import Testing
import SwiftData
import UIKit
@testable import SoleCount

struct PhotoImportTests {
    @Test func aLargeJPEGShrinksToTheLongSideLimit() throws {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2000, height: 800), format: format)
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2000, height: 800))
        }
        let original = try #require(image.jpegData(compressionQuality: 0.9))
        let small = try #require(ImageHelper.downsized(original))
        let result = try #require(UIImage(data: small))
        #expect(max(result.size.width, result.size.height) <= 1024)
        #expect(min(result.size.width, result.size.height) > 0)
    }

    @Test func textIsNotAPhoto() {
        #expect(ImageHelper.downsized(Data("not a photo".utf8)) == nil)
    }

    @Test func aCameraImageIsShrunkBeforeItIsSaved() throws {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1800, height: 1800), format: format)
        let image = renderer.image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1800, height: 1800))
        }
        let saved = try #require(ImageHelper.jpeg(from: image))
        let result = try #require(UIImage(data: saved))
        #expect(max(result.size.width, result.size.height) <= 1024)
    }
}

struct ShoeTypeListTests {
    @Test func addAndFilterCanUseTheShoeTypesPeopleAskedFor() {
        let names = Set(ShoeType.allCases.map(\.rawValue))
        for name in ["Running", "Basketball", "Lifestyle/Casual", "Training/Gym", "Skate", "Boots", "Other", "Hiking", "Trail"] {
            #expect(names.contains(name))
        }
    }
}

struct WearActivityTests {
    @Test func wearsSavedBeforeActivitiesCountAsCasual() {
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let records = WearActivityMath.records(dates: [day, day.addingTimeInterval(86_400)], activityRaws: [])
        #expect(records.map(\.activity) == [.casual, .casual])
    }

    @Test func aNameThisVersionDoesNotKnowCountsAsOther() {
        let records = WearActivityMath.records(dates: [.now], activityRaws: ["Skate"])
        #expect(records.first?.activity == .other)
    }

    @Test func theBreakdownKeepsTheActivityOrderAndSkipsZeros() {
        let records = [
            WearRecord(date: .now, activity: .running),
            WearRecord(date: .now, activity: .gym),
            WearRecord(date: .now, activity: .running)
        ]
        let counts = WearActivityMath.counts(records)
        #expect(counts.map(\.activity) == [.running, .gym])
        #expect(counts.map(\.count) == [2, 1])
    }

    @Test
    @MainActor
    func loggingAndUndoKeepEachActivityWithItsDate() throws {
        let container = try ModelContainer(
            for: Sneaker.self,
            SneakerPhotoItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let sneaker = Sneaker(name: "Trail Pair", brand: "Test", price: 80)
        container.mainContext.insert(sneaker)
        sneaker.wearDates = [Date.now.addingTimeInterval(-86_400)]
        #expect(sneaker.wearRecords.map(\.activity) == [.casual])
        sneaker.logWear(activity: .running)
        #expect(sneaker.wearRecords.map(\.activity) == [.casual, .running])
        sneaker.undoTodayWear()
        #expect(sneaker.wearRecords.map(\.activity) == [.casual])
        #expect(sneaker.wearDates.count == 1)
        #expect(sneaker.wearActivityRaws == [WearActivity.casual.rawValue])
    }
}
