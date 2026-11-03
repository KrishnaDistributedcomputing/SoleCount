import SwiftUI

// Links you can change in one place.
// The privacy policy page must be public for App Review.
enum AppLinks {
    static let privacyPolicy = URL(string: "https://github.com/KrishnaDistributedcomputing/SoleCount/blob/main/PRIVACY.md")!
    // Apple's standard license agreement (fine to use for one-time purchases).
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let support = URL(string: "https://github.com/KrishnaDistributedcomputing/SoleCount/issues")!
}

// The gear-icon screen: Pro status, Restore Purchases, privacy, version.
struct SettingsView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showingPaywall = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            List {
                Section("SoleCount Pro") {
                    if store.isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            Label("Unlock Pro", systemImage: "star.fill")
                        }
                    }
                    Button("Restore Purchases") {
                        Task { await store.restore() }
                    }
                    .disabled(store.isLoading)
                }

                Section("About") {
                    Link("Privacy Policy", destination: AppLinks.privacyPolicy)
                    Link("Terms of Use", destination: AppLinks.termsOfUse)
                    Link("Support", destination: AppLinks.support)
                    LabeledContent("Version", value: appVersion)
                }

                Section {
                    Text("SoleCount keeps all your data on this iPhone. No account, no tracking, no ads.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .alert("Store", isPresented: $store.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(store.errorMessage)
            }
        }
    }
}
