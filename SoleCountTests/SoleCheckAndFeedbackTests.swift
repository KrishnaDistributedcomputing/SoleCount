import Foundation
import SwiftData
import Testing
@testable import SoleCount

struct SoleCheckMathTests {
    private func snap(_ daysAgo: Double, _ km: Double) -> SoleSnapshot {
        SoleSnapshot(takenAt: Date(timeIntervalSince1970: 1_800_000_000 - daysAgo * 86_400), kilometers: km)
    }

    @Test func timelineIsOldestFirst() {
        let list = [snap(1, 300), snap(30, 120), snap(10, 200)]
        #expect(SoleCheckMath.orderedIndices(list) == [1, 2, 0])
        #expect(SoleCheckMath.orderedIndices([]).isEmpty)
    }

    @Test func compareNeedsTwoAndPicksFirstAndLatest() {
        #expect(SoleCheckMath.compareIndices([snap(1, 10)]) == nil)
        let pair = SoleCheckMath.compareIndices([snap(1, 300), snap(30, 120), snap(10, 200)])
        #expect(pair?.first == 1)
        #expect(pair?.latest == 0)
    }

    @Test func nudgeAfterEachHundredKilometres() {
        #expect(!SoleCheckMath.shouldNudge([], currentKilometers: 500))
        let list = [snap(30, 120), snap(5, 410)]
        #expect(SoleCheckMath.kilometersSinceLast(list, currentKilometers: 470) == 60)
        #expect(!SoleCheckMath.shouldNudge(list, currentKilometers: 470))
        #expect(SoleCheckMath.shouldNudge(list, currentKilometers: 510))
        #expect(SoleCheckMath.kilometersSinceLast(list, currentKilometers: 100) == 0)
    }
}

@MainActor
struct SolePhotoModelTests {
    @Test func photosKeepDistanceAndDeleteWithThePair() throws {
        let container = try ModelContainer(
            for: Sneaker.self, SneakerPhotoItem.self, SolePhoto.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let context = container.mainContext
        let sneaker = Sneaker(name: "Sole Test", brand: "", price: 0, startingKilometers: 42)
        context.insert(sneaker)
        sneaker.addSolePhoto(Data([1]), in: context, at: Date(timeIntervalSince1970: 2_000))
        sneaker.startingKilometers = 142
        sneaker.addSolePhoto(Data([2]), in: context, at: Date(timeIntervalSince1970: 1_000))
        try context.save()
        let ordered = sneaker.orderedSolePhotos
        #expect(ordered.count == 2)
        #expect(ordered.first?.photoData == Data([2]))
        #expect(ordered.first?.kilometers == 142)
        #expect(ordered.last?.kilometers == 42)

        context.delete(sneaker)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<SolePhoto>()) == 0)
    }
}

struct FeedbackMailTests {
    @Test func bodyHasOnlyAppAndDeviceDetails() {
        let body = FeedbackMail.body(.feedback, version: "1.0", build: "2", system: "26.1", model: "iPhone17,2")
        #expect(body.contains("App version 1.0 (build 2), iOS 26.1, iPhone17,2"))
        #expect(body.hasPrefix("Hi!"))
    }

    @Test func mailtoCarriesAddressAndSubject() throws {
        let url = try #require(FeedbackMail.mailtoURL(.idea, body: "A + B"))
        #expect(url.scheme == "mailto")
        #expect(url.absoluteString.hasPrefix("mailto:krishnaazure1975@gmail.com?"))
        #expect(url.absoluteString.contains("subject=SoleCount%20idea"))
        #expect(url.absoluteString.contains("A%20%2B%20B"))
    }
}
