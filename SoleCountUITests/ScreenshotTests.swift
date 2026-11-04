import XCTest

/// App Store screenshots, taken automatically by `fastlane screenshots`.
/// Uses sample data (generic names, no real brands) and never touches your real data.
/// The file names (01_..., 05_Paywall) are used by fastlane; don't rename them.
final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(pro: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["-UITesting", "-DemoData", "-Screenshots"]
        if pro { app.launchArguments += ["-DemoPro"] }
        app.launch()
        return app
    }

    @MainActor
    func testTakeScreenshots() throws {
        let app = launch(pro: false)
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10)
                      || app.staticTexts["Today"].waitForExistence(timeout: 2))
        snapshot("01_Today")

        app.tabBars.buttons["Collection"].tap()
        XCTAssertTrue(app.element(containing: "Daily Runners").waitForExistence(timeout: 10))
        snapshot("02_List")

        app.element(containing: "Daily Runners").tap()
        XCTAssertTrue(app.buttons["Wore Today"].waitForExistence(timeout: 5)
                      || app.buttons["Wore today"].waitForExistence(timeout: 2)
                      || app.buttons["Wore Them Again"].waitForExistence(timeout: 2)
                      || app.buttons["Wore them again"].exists)
        snapshot("03_Detail")

        app.tabBars.buttons["Stats"].tap()
        snapshot("04_Stats")
        app.tabBars.buttons["Calendar"].tap()
        snapshot("05_Calendar")
    }
}
