import XCTest

/// Drives the real app in the Simulator like a person would.
final class SoleCountUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITesting"]   // start with an empty, in-memory database
        app.launch()
        let collection = app.tabBars.buttons["Collection"]
        if collection.waitForExistence(timeout: 5) {
            collection.tap()
        }
    }

    @MainActor
    func testAddAPair() throws {
        let addButton = app.buttons["Add a pair"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10), "Empty screen should offer 'Add a pair'")
        addButton.tap()

        addPair(name: "Test Runners", brand: "TestBrand", price: "120")

        XCTAssertTrue(app.element(containing: "Test Runners").waitForExistence(timeout: 5),
                      "The new pair should appear in the list")
    }

    @MainActor
    func testAddFourthPair() throws {
        let firstAdd = app.buttons["Add a pair"]
        XCTAssertTrue(firstAdd.waitForExistence(timeout: 10))
        firstAdd.tap()
        addPair(name: "Pair 1", brand: "", price: "10")

        for number in 2...3 {
            app.buttons["addSneakerButton"].tap()
            addPair(name: "Pair \(number)", brand: "", price: "10")
        }

        app.buttons["addSneakerButton"].tap()
        addPair(name: "Pair 4", brand: "", price: "10")
        XCTAssertTrue(app.element(containing: "Pair 4").waitForExistence(timeout: 5),
                      "A fourth pair should save, because SoleCount is free")
        XCTAssertFalse(app.staticTexts["SoleCount Pro"].exists)
    }

    // MARK: - Helpers

    @MainActor
    private func addPair(name: String, brand: String, price: String) {
        let nameField = app.textFields["Name (e.g. Air Max 90)"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "The New Sneaker form should open")
        nameField.tap()
        nameField.typeText(name)

        if !brand.isEmpty {
            let brandField = app.textFields["Brand (e.g. Nike)"]
            brandField.tap()
            brandField.typeText(brand)
        }

        let priceField = app.textFields["Price paid (e.g. 129.99)"]
        priceField.tap()
        priceField.typeText(price)

        app.buttons["Save"].tap()
        XCTAssertTrue(app.navigationBars["SoleCount"].waitForExistence(timeout: 5))
    }
}
