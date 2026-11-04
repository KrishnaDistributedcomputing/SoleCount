import Foundation

/// Switches that turn big product choices on or off in one place.
enum FeatureFlags {
    /// SoleCount is free. The StoreKit purchase code stays in the project.
    /// Set this to `true` later if the $0.99 unlock should come back.
    /// Fastlane reads this line. Leave it written as `monetizationEnabled = false`.
    static let monetizationEnabled = false
}
