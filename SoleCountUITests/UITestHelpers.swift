import XCTest

extension XCUIApplication {
    /// Finds any on-screen element whose label contains `text`
    /// (SwiftUI list rows sometimes expose text as part of a button).
    func element(containing text: String) -> XCUIElement {
        descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", text))
            .firstMatch
    }
}
