import SwiftUI
import StoreKit

// The "SoleCount Pro" screen with Buy and Restore buttons.
struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "shoe.2.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.tint)
                        .padding(.top, 24)

                    Text("SoleCount Pro")
                        .font(.largeTitle.bold())

                    Text("One-time purchase. No subscription.")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(icon: "infinity", text: "Track unlimited pairs (free: \(StoreManager.freePairLimit))")
                        FeatureRow(icon: "chart.bar.fill", text: "Wear history chart for every pair")
                        FeatureRow(icon: "heart.fill", text: "Support an independent developer")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    if store.isPro {
                        Label("You have Pro. Thank you!", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                    } else {
                        Button {
                            Task {
                                await store.purchase()
                                if store.isPro { dismiss() }
                            }
                        } label: {
                            Group {
                                if store.isLoading {
                                    ProgressView()
                                } else {
                                    Text(buyButtonTitle)
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(store.proProduct == nil || store.isLoading)

                        if store.proProduct == nil && !LaunchFlags.screenshots {
                            Button("Try loading the price again") {
                                Task { await store.loadProducts() }
                            }
                            .font(.footnote)
                        }
                    }

                    Button("Restore Purchases") {
                        Task {
                            await store.restore()
                            if store.isPro { dismiss() }
                        }
                    }
                    .disabled(store.isLoading)

                    Text("A one-time payment charged to your Apple Account. Pro stays unlocked on devices signed in to the same Apple Account. Use Restore Purchases on a new device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Link("Privacy Policy", destination: AppLinks.privacyPolicy)
                        Link("Terms of Use", destination: AppLinks.termsOfUse)
                    }
                    .font(.footnote)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                if store.proProduct == nil { await store.loadProducts() }
            }
            .alert("Store", isPresented: $store.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(store.errorMessage)
            }
        }
    }

    private var buyButtonTitle: String {
        if let product = store.proProduct {
            return "Unlock Pro for \(product.displayPrice)"
        }
        #if DEBUG
        // Automated screenshots run without the App Store, so show the real price text.
        if LaunchFlags.screenshots { return "Unlock Pro for $0.99" }
        #endif
        return "Loading price…"
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 30)
            Text(text)
        }
    }
}
