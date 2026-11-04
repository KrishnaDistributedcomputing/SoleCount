import SwiftData
import SwiftUI

private struct ShoeNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var shoeNamespace: Namespace.ID? {
        get { self[ShoeNamespaceKey.self] }
        set { self[ShoeNamespaceKey.self] = newValue }
    }
}

/// Zooms a card into its detail page on iOS 18. Skipped when there is no shared namespace.
struct ShoeZoomTransition: ViewModifier {
    var id: PersistentIdentifier
    var space: Namespace.ID?

    func body(content: Content) -> some View {
        Group {
            if let space {
                content.navigationTransition(.zoom(sourceID: id, in: space))
            } else {
                content
            }
        }
    }
}
