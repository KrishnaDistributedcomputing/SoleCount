import Foundation
import SwiftData
import Testing
@testable import SoleCount

/// US, UK, and EU sizes, and the men's / women's / unisex fit that picks the column.
struct ShoeSizeChartTests {
    @Test func mensUS10IsUK9AndEU44() {
        let line = ShoeSizeChart.equivalentLine(size: "10", system: .us, fit: .mens)
        #expect(line == "Also UK 9 and EU 44")
        #expect(ShoeSizeChart.label(size: "10", system: .us) == "US 10")
    }

    @Test func unisexUsesTheMensColumn() {
        let mens = ShoeSizeChart.equivalentLine(size: "8", system: .us, fit: .mens)
        let unisex = ShoeSizeChart.equivalentLine(size: "8", system: .us, fit: .unisex)
        #expect(mens == "Also UK 7 and EU 41")
        #expect(unisex == mens)
    }

    @Test func womensUS10IsUK75AndEU42() {
        #expect(ShoeSizeChart.equivalentLine(size: "10", system: .us, fit: .womens) == "Also UK 7.5 and EU 42")
        #expect(ShoeSizeChart.equivalentLine(size: "8", system: .us, fit: .womens) == "Also UK 6 and EU 39")
    }

    @Test func ukAndEUConvertBack() {
        #expect(ShoeSizeChart.convert(size: "9", system: .uk, fit: .mens) == ShoeSizeChart.Converted(us: "10", uk: "9", eu: "44"))
        #expect(ShoeSizeChart.equivalentLine(size: "44", system: .eu, fit: .mens) == "Also US 10 and UK 9")
        #expect(ShoeSizeChart.equivalentLine(size: "44", system: .eu, fit: .womens) == "Also US 11.5 and UK 9")
    }

    @Test func aCommaIsADecimalPoint() {
        #expect(ShoeSizeChart.equivalentLine(size: "10,5", system: .us, fit: .mens) == "Also UK 9.5 and EU 44.5")
    }

    @Test func sizesThatAreNotOnTheChartStayAsTyped() {
        #expect(ShoeSizeChart.equivalentLine(size: "wide", system: .us, fit: .mens) == nil)
        #expect(ShoeSizeChart.equivalentLine(size: "10.25", system: .us, fit: .unisex) == nil)
        #expect(ShoeSizeChart.label(size: "wide", system: .uk) == "UK wide")
        #expect(ShoeSizeChart.label(size: "  ", system: .eu) == "")
        #expect(ShoeSizeChart.equivalentLine(size: "", system: .us, fit: .unisex) == nil)
    }

    /// Nike lists UK 6 for both men's 6.5 and men's 7. The app keeps one row:
    /// the one where UK is a full size below the men's US size.
    @Test func duplicateUK6UsesMens7() {
        #expect(ShoeSizeChart.convert(size: "6", system: .uk, fit: .mens) == ShoeSizeChart.Converted(us: "7", uk: "6", eu: "40"))
        #expect(ShoeSizeChart.convert(size: "6", system: .uk, fit: .womens) == ShoeSizeChart.Converted(us: "8.5", uk: "6", eu: "40"))
        #expect(ShoeSizeChart.convert(size: "6.5", system: .us, fit: .mens) == ShoeSizeChart.Converted(us: "6.5", uk: "6", eu: "39"))
    }

    @Test func theChartHasOneRowPerUSAndEUSize() {
        let rows = ShoeSizeChart.rows
        #expect(rows.count == 38)
        #expect(Set(rows.map(\.usMen)).count == rows.count)
        #expect(Set(rows.map(\.usWomen)).count == rows.count)
        #expect(Set(rows.map(\.eu)).count == rows.count)
        let repeatedUK = Dictionary(grouping: rows, by: \.uk).filter { $0.value.count > 1 }
        #expect(repeatedUK.count == 1)
        #expect(repeatedUK[60]?.count == 2)
    }
}

struct ShoeSizeDefaultTests {
    @Test func missingOrUnknownSettingIsUS() throws {
        let name = "ShoeSizeDefaults-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defaults.removePersistentDomain(forName: name)
        #expect(ShoeSizeDefaults.systemKey == "defaultSizeSystem")
        #expect(ShoeSizeDefaults.system(defaults: defaults) == .us)
        ShoeSizeDefaults.setSystem(.eu, defaults: defaults)
        #expect(ShoeSizeDefaults.system(defaults: defaults) == .eu)
        defaults.set("nope", forKey: ShoeSizeDefaults.systemKey)
        #expect(ShoeSizeDefaults.system(defaults: defaults) == .us)
    }
}

/// Empty saved text means US and Unisex. That is how an older pair is read.
@MainActor
struct ShoeSizeModelTests {
    @Test func aNewPairDefaultsToUSAndUnisex() {
        let sneaker = Sneaker(name: "Old Runners", brand: "Nike", price: 120, size: "10")
        #expect(sneaker.size == "10")
        #expect(sneaker.sizeSystem == .us)
        #expect(sneaker.fit == .unisex)
        #expect(sneaker.sizeLabel == "US 10")
        #expect(sneaker.sizeEquivalentLine == "Also UK 9 and EU 44")
        #expect(sneaker.asExportRow().size == "US 10")
    }

    @Test func blankOrUnknownStoredValuesStayUSAndUnisex() {
        let sneaker = Sneaker(name: "Old Runners", brand: "Nike", price: 120, size: "10", fit: .womens)
        sneaker.sizeSystemRaw = ""
        sneaker.fitRaw = ""
        #expect(sneaker.size == "10")
        #expect(sneaker.sizeSystem == .us)
        #expect(sneaker.fit == .unisex)
        sneaker.sizeSystemRaw = "nope"
        sneaker.fitRaw = "nope"
        #expect(sneaker.sizeSystem == .us)
        #expect(sneaker.fit == .unisex)
        #expect(sneaker.sizeLabel == "US 10")
    }

    @Test func womensFitChangesTheUSConversion() {
        let sneaker = Sneaker(name: "Court", brand: "Nike", price: 90, size: "10", sizeSystem: .us, fit: .womens)
        #expect(sneaker.fit == .womens)
        #expect(sneaker.sizeLabel == "US 10")
        #expect(sneaker.sizeEquivalentLine == "Also UK 7.5 and EU 42")
    }

    @Test func euSizeAndWomensFitRoundTripThroughTheStore() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("solecount-size-roundtrip-\(UUID().uuidString).store")
        defer { removeStore(at: url) }
        try writeRoundTrip(at: url)
        let shoe = try readRoundTrip(at: url)
        #expect(shoe.name == "Round")
        #expect(shoe.brand == "Nike")
        #expect(shoe.price == 80)
        #expect(shoe.size == "44")
        #expect(shoe.sizeSystem == .eu)
        #expect(shoe.fit == .womens)
        #expect(shoe.sizeLabel == "EU 44")
        #expect(shoe.equivalentLine == "Also US 11.5 and UK 9")
    }
}

/// An older store has no size-system column and no fit column.
/// Lightweight migration keeps the typed size and fills the new columns with "".
/// The app reads "" as US and Unisex. The app itself does not use a VersionedSchema.
/// This pair of models is only for the test, so the check does not rewrite the real store.
enum SizeShoeSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [SizeShoeSchemaV1.Shoe.self] }

    @Model
    final class Shoe {
        var name: String = ""
        var brand: String = ""
        var price: Double = 0
        var size: String = ""
        var notes: String = ""
        var colorway: String = ""
        var shoeTypeRaw: String = "Other"
        var wearDates: [Date] = []
    }
}

enum SizeShoeSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [SizeShoeSchemaV2.Shoe.self] }

    @Model
    final class Shoe {
        var name: String = ""
        var brand: String = ""
        var price: Double = 0
        var size: String = ""
        var notes: String = ""
        var colorway: String = ""
        var shoeTypeRaw: String = "Other"
        var wearDates: [Date] = []
        var sizeSystemRaw: String = ""
        var fitRaw: String = ""
    }
}

enum SizeShoeMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SizeShoeSchemaV1.self, SizeShoeSchemaV2.self] }
    static var stages: [MigrationStage] {
        [MigrationStage.lightweight(fromVersion: SizeShoeSchemaV1.self, toVersion: SizeShoeSchemaV2.self)]
    }
}

@MainActor
struct ShoeSizeMigrationTests {
    @Test func lightweightMigrationKeepsTheSizeAndLeavesTheNewFieldsEmpty() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("solecount-size-migration-\(UUID().uuidString).store")
        defer { removeStore(at: url) }
        try writeLegacyShoe(at: url)
        let shoe = try readMigratedShoe(at: url)
        #expect(shoe.name == "Old Runners")
        #expect(shoe.brand == "Nike")
        #expect(shoe.price == 120)
        #expect(shoe.size == "10")
        #expect(shoe.notes == "keep me")
        #expect(shoe.colorway == "Grey")
        #expect(shoe.shoeTypeRaw == "Running")
        #expect(shoe.wearCount == 2)
        #expect(shoe.sizeSystemRaw == "")
        #expect(shoe.fitRaw == "")
        #expect(SizeSystem(rawValue: shoe.sizeSystemRaw) ?? .us == .us)
        #expect(ShoeFit(rawValue: shoe.fitRaw) ?? .unisex == .unisex)
        #expect(ShoeSizeChart.label(size: shoe.size, system: .us) == "US 10")
        #expect(ShoeSizeChart.equivalentLine(size: shoe.size, system: .us, fit: .unisex) == "Also UK 9 and EU 44")
    }
}

/// Plain values copied while the database is still open.
private struct StoredShoeFacts: Equatable {
    var name: String
    var brand: String
    var price: Double
    var size: String
    var notes: String = ""
    var colorway: String = ""
    var shoeTypeRaw: String = ""
    var wearCount: Int = 0
    var sizeSystemRaw: String = ""
    var fitRaw: String = ""
    var sizeSystem: SizeSystem = .us
    var fit: ShoeFit = .unisex
    var sizeLabel: String = ""
    var equivalentLine: String?
}

@MainActor
private func writeLegacyShoe(at url: URL) throws {
    let schema = Schema(versionedSchema: SizeShoeSchemaV1.self)
    let configuration = ModelConfiguration("SizeMigrationV1", schema: schema, url: url, cloudKitDatabase: .none)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    let shoe = SizeShoeSchemaV1.Shoe(
        name: "Old Runners",
        brand: "Nike",
        price: 120,
        size: "10",
        notes: "keep me",
        colorway: "Grey",
        shoeTypeRaw: "Running",
        wearDates: [
            Date(timeIntervalSince1970: 1_700_000_000),
            Date(timeIntervalSince1970: 1_700_086_400)
        ]
    )
    container.mainContext.insert(shoe)
    try container.mainContext.save()
}

@MainActor
private func readMigratedShoe(at url: URL) throws -> StoredShoeFacts {
    let schema = Schema(versionedSchema: SizeShoeSchemaV2.self)
    let configuration = ModelConfiguration("SizeMigrationV2", schema: schema, url: url, cloudKitDatabase: .none)
    let container = try ModelContainer(
        for: schema,
        migrationPlan: SizeShoeMigrationPlan.self,
        configurations: [configuration]
    )
    let shoes = try container.mainContext.fetch(FetchDescriptor<SizeShoeSchemaV2.Shoe>())
    let shoe = try #require(shoes.first)
    return StoredShoeFacts(
        name: shoe.name,
        brand: shoe.brand,
        price: shoe.price,
        size: shoe.size,
        notes: shoe.notes,
        colorway: shoe.colorway,
        shoeTypeRaw: shoe.shoeTypeRaw,
        wearCount: shoe.wearDates.count,
        sizeSystemRaw: shoe.sizeSystemRaw,
        fitRaw: shoe.fitRaw
    )
}

@MainActor
private func writeRoundTrip(at url: URL) throws {
    let schema = Schema([Sneaker.self, SneakerPhotoItem.self, SolePhoto.self, WishlistItem.self])
    let configuration = ModelConfiguration("SizeRoundTrip", schema: schema, url: url, cloudKitDatabase: .none)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    let sneaker = Sneaker(
        name: "Round",
        brand: "Nike",
        price: 80,
        size: "44",
        sizeSystem: .eu,
        fit: .womens
    )
    container.mainContext.insert(sneaker)
    try container.mainContext.save()
}

@MainActor
private func readRoundTrip(at url: URL) throws -> StoredShoeFacts {
    let schema = Schema([Sneaker.self, SneakerPhotoItem.self, SolePhoto.self, WishlistItem.self])
    let configuration = ModelConfiguration("SizeRoundTrip", schema: schema, url: url, cloudKitDatabase: .none)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    let shoes = try container.mainContext.fetch(FetchDescriptor<Sneaker>())
    let shoe = try #require(shoes.first)
    return StoredShoeFacts(
        name: shoe.name,
        brand: shoe.brand,
        price: shoe.price,
        size: shoe.size,
        sizeSystem: shoe.sizeSystem,
        fit: shoe.fit,
        sizeLabel: shoe.sizeLabel,
        equivalentLine: shoe.sizeEquivalentLine
    )
}

private func removeStore(at url: URL) {
    let fileManager = FileManager.default
    try? fileManager.removeItem(at: url)
    try? fileManager.removeItem(at: URL(fileURLWithPath: url.path + "-wal"))
    try? fileManager.removeItem(at: URL(fileURLWithPath: url.path + "-shm"))
}
