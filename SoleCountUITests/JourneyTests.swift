import XCTest

/// Main paths, using the real screens. Sample data stays in memory.
final class JourneyTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFirstLaunchAddPairAndLogWear() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITesting"]
        app.launch()
        app.tabBars.buttons["Collection"].tap()
        let add = app.buttons["Add a pair"]
        XCTAssertTrue(add.waitForExistence(timeout: 10), "A new phone should offer Add a pair")
        add.tap()

        let name = app.textFields["Name (e.g. Air Max 90)"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("City Runners")

        let brand = app.textFields["Brand (e.g. Nike)"]
        brand.tap()
        brand.typeText("Nike")
        if app.buttons["Nike"].waitForExistence(timeout: 2) {
            app.buttons["Nike"].firstMatch.tap()
        }

        let price = app.textFields["Price paid (e.g. 129.99)"]
        price.tap()
        price.typeText("80")

        var starting = app.textFields["startingDistanceField"]
        if !starting.waitForExistence(timeout: 2) {
            app.swipeUp()
            starting = app.textFields["startingDistanceField"]
        }
        XCTAssertTrue(starting.waitForExistence(timeout: 4), "Starting distance should be on the add form")
        starting.tap()
        starting.typeText("12")

        app.buttons["Save"].tap()
        XCTAssertTrue(app.element(containing: "City Runners").waitForExistence(timeout: 5))
        app.element(containing: "City Runners").tap()
        let wore = app.buttons["Wore Today"]
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
        XCTAssertTrue(app.buttons["Wore Today"].waitForExistence(timeout: 5)
                      || app.buttons["Wore Them Again"].waitForExistence(timeout: 2))
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
        XCTAssertTrue(app.buttons["All badges"].waitForExistence(timeout: 5))
        app.buttons["All badges"].tap()
        XCTAssertTrue(app.navigationBars["Badges"].waitForExistence(timeout: 5))
        if app.navigationBars["Badges"].buttons["Stats"].waitForExistence(timeout: 2) {
            app.navigationBars["Badges"].buttons["Stats"].tap()
        } else {
            app.navigationBars["Badges"].buttons.element(boundBy: 0).tap()
        }
        XCTAssertTrue(app.buttons["Share collection card"].waitForExistence(timeout: 5))
        app.buttons["Share collection card"].tap()
        if app.buttons["Close"].waitForExistence(timeout: 3) {
            app.buttons["Close"].tap()
        }
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
