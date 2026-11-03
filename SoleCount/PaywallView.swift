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
                VStack(spacing: 28) {
                    // Hero section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 140, height: 140)
                                .blur(radius: 30)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .orange.opacity(0.5), radius: 12, y: 6)
                        }
                        .padding(.top, 24)

                        Text("SoleCount Pro")
                            .font(.system(size: 38, weight: .bold, design: .rounded))

                        Text("One-time purchase • No subscription")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    // Features
                    VStack(spacing: 16) {
                        PremiumFeatureRow(
                            icon: "infinity",
                            color: .blue,
                            title: "Unlimited Pairs",
                            description: "Track as many sneakers as you want"
                        )
                        PremiumFeatureRow(
                            icon: "chart.bar.fill",
                            color: .purple,
                            title: "Wear History Charts",
                            description: "Visualize your wearing patterns"
                        )
                        PremiumFeatureRow(
                            icon: "sparkles",
                            color: .pink,
                            title: "Premium Experience",
                            description: "All features unlocked forever"
                        )
                        PremiumFeatureRow(
                            icon: "heart.fill",
                            color: .red,
                            title: "Support Development",
                            description: "Help an independent developer"
                        )
                    }
                    .padding(.horizontal, 4)

                    // Purchase section
                    VStack(spacing: 16) {
                        if store.isPro {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title)
                                    .foregroundStyle(.green)
                                Text("You have Pro. Thank you!")
                                    .font(.headline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.green.opacity(0.1))
                            )
                        } else {
                            Button {
                                Task {
                                    await store.purchase()
                                    if store.isPro { dismiss() }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    if store.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "crown.fill")
                                            .font(.title3)
                                        Text(buyButtonTitle)
                                            .font(.title3.bold())
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.accentColor.opacity(0.5), radius: 12, y: 6)
                                )
                            }
                            .disabled(store.proProduct == nil || store.isLoading)

                            if store.proProduct == nil && !LaunchFlags.screenshots {
                                Button {
                                    Task { await store.loadProducts() }
                                } label: {
                                    Label("Retry Loading Price", systemImage: "arrow.clockwise")
                                        .font(.footnote.weight(.medium))
                                }
                            }
                        }

                        Button {
                            Task {
                                await store.restore()
                                if store.isPro { dismiss() }
                            }
                        } label: {
                            Text("Restore Purchases")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        .disabled(store.isLoading)
                    }

                    // Footer
                    VStack(spacing: 16) {
                        Text("A one-time payment charged to your Apple Account. Pro unlocks on all devices signed in to the same Apple Account. Use **Restore Purchases** on a new device.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 20) {
                            Link(destination: AppLinks.privacyPolicy) {
                                Text("Privacy Policy")
                                    .font(.footnote.weight(.medium))
                            }
                            Link(destination: AppLinks.termsOfUse) {
                                Text("Terms of Use")
                                    .font(.footnote.weight(.medium))
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                    }
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
        return "Loading Price…"
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}
