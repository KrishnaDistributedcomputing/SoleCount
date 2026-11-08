import SwiftUI

/// Name, version, build, and the App Store release of this version.
/// Privacy, terms, and support stay here so Settings has one About place.
struct AboutView: View {
    var identity: AppIdentity
    var releaseLine: String

    var body: some View {
        List {
            Section {
                Text(identity.name)
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)
                LabeledContent(AppAboutCopy.version, value: identity.version)
                LabeledContent(AppAboutCopy.build, value: identity.build)
                LabeledContent(AppAboutCopy.lastUpdate) {
                    Text(releaseLine)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("lastUpdateValue")
                }
                Text(AppAboutCopy.meaning)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("releaseMeaning")
            }
            Section {
                Link("Privacy Policy", destination: AppLinks.privacyPolicy)
                Link("Terms of Use", destination: AppLinks.termsOfUse)
                Link("Support", destination: AppLinks.support)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("aboutScreen")
    }
}

extension AboutView {
    /// The running app. Tests build `AboutView` with their own values.
    init(bundle: Bundle = .main, locale: Locale = .current, timeZone: TimeZone = .current) {
        let info = bundle.infoDictionary ?? [:]
        let identity = AppRelease.identity(from: info)
        let status = AppRelease.status(for: identity.version, bundle: bundle)
        self.init(
            identity: identity,
            releaseLine: AppRelease.lastUpdateValue(status, locale: locale, timeZone: timeZone)
        )
    }
}
