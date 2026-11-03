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
        // Free user: list, detail, paywall.
        var app = launch(pro: false)
        XCTAssertTrue(app.element(containing: "Daily Runners").waitForExistence(timeout: 10))
        snapshot("01_List")

        app.element(containing: "Daily Runners").tap()
        XCTAssertTrue(app.buttons["Wore today"].waitForExistence(timeout: 5)
                      || app.buttons["Wore them again"].waitForExistence(timeout: 2))
        snapshot("02_Detail")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let unlock = app.buttons["Unlock SoleCount Pro"]
        if !unlock.waitForExistence(timeout: 3) { app.swipeUp() }
        unlock.tap()
        XCTAssertTrue(app.staticTexts["SoleCount Pro"].waitForExistence(timeout: 5))
        snapshot("05_Paywall")   // also used as the In-App Purchase review screenshot
        app.terminate()

        // Pro user: wear history chart.
        app = launch(pro: true)
        XCTAssertTrue(app.element(containing: "White Court Lows").waitForExistence(timeout: 10))
        snapshot("03_ListPro")
        app.element(containing: "White Court Lows").tap()
        app.swipeUp()
        snapshot("04_Chart")
    }
}
