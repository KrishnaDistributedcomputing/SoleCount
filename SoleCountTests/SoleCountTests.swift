import Foundation
import Testing
import SwiftData
@testable import SoleCount

/// Fast checks of the app's core math and rules (no Simulator screen needed).
@MainActor
struct CostPerWearTests {
    /// Every test gets its own empty, in-memory database.
    private let container: ModelContainer

    init() throws {
        container = try ModelContainer(
            for: Sneaker.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func makeSneaker(price: Double, wearLimit: Int? = nil) -> Sneaker {
        let sneaker = Sneaker(name: "Test Pair", brand: "Test", price: price, wearLimit: wearLimit)
        container.mainContext.insert(sneaker)
        return sneaker
    }

    @Test func noWearsMeansNoCostPerWearYet() {
        let sneaker = makeSneaker(price: 120)
        #expect(sneaker.wearCount == 0)
        #expect(sneaker.costPerWear == nil)
    }

    @Test func firstWearCostsTheFullPrice() {
        let sneaker = makeSneaker(price: 120)
        sneaker.logWear()
        #expect(sneaker.costPerWear == 120)
    }

    @Test(arguments: [(100.0, 4, 25.0), (129.99, 10, 12.999), (0.0, 3, 0.0)])
    func costPerWearIsPriceDividedByWears(price: Double, wears: Int, expected: Double) throws {
        let sneaker = makeSneaker(price: price)
        for day in 0..<wears {
            sneaker.logWear(on: Date.now.addingTimeInterval(Double(-day) * 86_400))
        }
        let cost = try #require(sneaker.costPerWear)
        #expect(abs(cost - expected) < 0.0001)
    }

    @Test func undoRemovesOnlyTodaysWear() {
        let sneaker = makeSneaker(price: 90)
        sneaker.logWear(on: Date.now.addingTimeInterval(-3 * 86_400))
        sneaker.logWear()
        #expect(sneaker.woreToday)
        sneaker.undoTodayWear()
        #expect(!sneaker.woreToday)
        #expect(sneaker.wearCount == 1)
    }

    @Test func wearLimitIsReached() {
        let sneaker = makeSneaker(price: 60, wearLimit: 2)
        sneaker.logWear()
        #expect(!sneaker.hasReachedLimit)
        sneaker.logWear()
        #expect(sneaker.hasReachedLimit)
    }
}

/// The free version allows 3 pairs; Pro is unlimited.
struct FreeLimitTests {
    @Test func freeLimitIsThreePairs() {
        #expect(StoreManager.freePairLimit == 3)
    }

    @Test(arguments: [0, 1, 2])
    func freeUserCanAddUpToThree(currentCount: Int) {
        #expect(StoreManager.canAddPair(currentCount: currentCount, isPro: false))
    }

    @Test(arguments: [3, 4, 10])
    func freeUserIsBlockedAfterThree(currentCount: Int) {
        #expect(!StoreManager.canAddPair(currentCount: currentCount, isPro: false))
    }

    @Test(arguments: [0, 3, 50])
    func proUserIsNeverBlocked(currentCount: Int) {
        #expect(StoreManager.canAddPair(currentCount: currentCount, isPro: true))
    }

    @Test func productIDMatchesAppStoreConnect() {
        #expect(StoreManager.proProductID == "com.krishnav.SoleCount.pro")
    }
}
