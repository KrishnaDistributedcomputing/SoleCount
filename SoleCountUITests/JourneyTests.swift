import XCTest

/// Main paths, using the real screens. Sample data stays in memory.
final class JourneyTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFirstLaunchAddPairAndLogWear() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITesting", "-HealthUnavailable"]
        app.launch()
        let healthOff = app.staticTexts["Apple Health is not on this device, and that is okay. Wears, cost per wear, and the rest of SoleCount still work."]
        XCTAssertTrue(healthOff.waitForExistence(timeout: 10), "The app should explain Health is off and keep working")
        app.tabBars.buttons["Collection"].tap()
        let add = app.buttons["Add a pair"]
        XCTAssertTrue(add.waitForExistence(timeout: 10), "A new phone should offer Add a pair")
        add.tap()

        let name = app.textFields["Name (e.g. Air Max 90)"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("City Runners")

        let price = app.textFields["Price paid (e.g. 129.99)"]
        price.tap()
        price.typeText("80")

        let brand = app.textFields["Brand (e.g. Nike)"]
        brand.tap()
        brand.typeText("Ni")
        let nike = app.buttons["Nike"]
        XCTAssertTrue(nike.waitForExistence(timeout: 3), "The catalog should offer Nike")
        nike.tap()

        var starting = app.descendants(matching: .any)["startingDistanceField"]
        var swipes = 0
        while !starting.waitForExistence(timeout: 1), swipes < 4 {
            app.swipeUp()
            starting = app.descendants(matching: .any)["startingDistanceField"]
            swipes += 1
        }
        XCTAssertTrue(starting.waitForExistence(timeout: 2), "Starting distance should be on the add form")
        starting.tap()
        starting.typeText("12")

        let save = app.buttons["saveSneakerButton"]
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        save.tap()
        XCTAssertTrue(app.navigationBars["New Sneaker"].waitForNonExistence(timeout: 5), "Saving should close the form")
        let saved = app.buttons.matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "pairRow", "City Runners")).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        saved.tap()
        var wore = app.buttons["woreTodayButton"]
        if !wore.waitForExistence(timeout: 2) {
            app.swipeUp()
            wore = app.buttons["woreTodayButton"]
        }
        XCTAssertTrue(wore.waitForExistence(timeout: 5))
        wore.tap()
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5) || app.staticTexts["Today"].exists)
    }

    @MainActor
    func testSeededRetireWishlistBadgesShareAndHealthOff() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITesting", "-DemoData", "-HealthUnavailable"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Wear your forgotten pairs"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Collection"].tap()
        XCTAssertTrue(app.element(containing: "Daily Runners").waitForExistence(timeout: 8))
        app.element(containing: "Daily Runners").tap()
        XCTAssertTrue(app.buttons["woreTodayButton"].waitForExistence(timeout: 5))
        app.buttons["More"].tap()
        app.buttons["Retire this pair"].tap()
        XCTAssertTrue(app.staticTexts["Send-off"].waitForExistence(timeout: 5))
        app.buttons["Keep in the Hall of Fame"].tap()

        if app.navigationBars["Daily Runners"].buttons["SoleCount"].waitForExistence(timeout: 3) {
            app.navigationBars["Daily Runners"].buttons["SoleCount"].tap()
        } else {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        if !app.buttons["nextPairsButton"].waitForExistence(timeout: 3) {
            app.tabBars.buttons["Collection"].tap()
        }
        app.buttons["nextPairsButton"].tap()
        let bought = app.buttons["I bought it"]
        XCTAssertTrue(bought.waitForExistence(timeout: 5))
        bought.tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.element(containing: "Air Max 90").waitForExistence(timeout: 5))

        app.tabBars.buttons["Stats"].tap()
        if !app.navigationBars["Stats"].waitForExistence(timeout: 5) {
            app.tabBars.buttons["Stats"].tap()
        }
        XCTAssertTrue(app.navigationBars["Stats"].waitForExistence(timeout: 5), "Stats should open after the wishlist closes")
        let badges = reveal(app, identifier: "allBadgesButton")
        XCTAssertTrue(badges.waitForExistence(timeout: 3), "Stats should offer All badges")
        badges.tap()
        XCTAssertTrue(app.navigationBars["Badges"].waitForExistence(timeout: 5))
        if app.navigationBars["Badges"].buttons["Stats"].waitForExistence(timeout: 2) {
            app.navigationBars["Badges"].buttons["Stats"].tap()
        } else {
            app.navigationBars["Badges"].buttons.element(boundBy: 0).tap()
        }
        let share = reveal(app, identifier: "shareCollectionButton")
        XCTAssertTrue(share.waitForExistence(timeout: 3), "Stats should offer the collection card")
        share.tap()
        if app.buttons["Close"].waitForExistence(timeout: 3) {
            app.buttons["Close"].tap()
        }
    }

    /// Stats puts badges and the share card below the summary. Scroll until the
    /// identifier exists. A short wait covers the tab animation on a slow runner.
    @MainActor
    private func reveal(_ app: XCUIApplication, identifier: String) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier]
        var swipes = 0
        while !element.waitForExistence(timeout: 2), swipes < 4 {
            app.swipeUp()
            swipes += 1
        }
        return element
    }

    @MainActor
    func testAccessibilityAndLargeType() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITesting", "-DemoData", "-HealthUnavailable"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 10) || app.navigationBars["Today"].exists)
        if #available(iOS 17.0, *) {
            try app.performAccessibilityAudit { issue in
                issue.auditType.contains(.contrast) || issue.auditType.contains(.hitRegion)
            }
        }
        app.terminate()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 10) || app.navigationBars["Today"].exists)
        app.tabBars.buttons["Collection"].tap()
        XCTAssertTrue(app.element(containing: "Daily Runners").waitForExistence(timeout: 8))
    }
}
