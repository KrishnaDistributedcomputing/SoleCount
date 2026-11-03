import SwiftUI
import SwiftData

// The first screen: all your sneakers, with wears and cost per wear.
struct SneakerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Query(sort: \Sneaker.createdAt, order: .reverse) private var sneakers: [Sneaker]

    @State private var showingAdd = false
    @State private var showingPaywall = false
    @State private var showingSettings = false

    private var activeSneakers: [Sneaker] { sneakers.filter { !$0.isRetired } }
    private var retiredSneakers: [Sneaker] { sneakers.filter { $0.isRetired } }

    var body: some View {
        NavigationStack {
            Group {
                if sneakers.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            if !activeSneakers.isEmpty {
                                Section {
                                    ForEach(activeSneakers) { sneaker in
                                        NavigationLink(value: sneaker) {
                                            SneakerCard(sneaker: sneaker)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                } header: {
                                    SectionHeader(title: "In Rotation", count: activeSneakers.count)
                                }
                            }

                            if !retiredSneakers.isEmpty {
                                Section {
                                    ForEach(retiredSneakers) { sneaker in
                                        NavigationLink(value: sneaker) {
                                            SneakerCard(sneaker: sneaker)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                } header: {
                                    SectionHeader(title: "Retired", count: retiredSneakers.count)
                                }
                            }

                            if !store.isPro {
                                proUpsellCard
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("SoleCount")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Sneaker.self) { sneaker in
                SneakerDetailView(sneaker: sneaker)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.headline)
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addTapped()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel("Add sneaker")
                    .accessibilityIdentifier("addSneakerButton")
                }
            }
            .sheet(isPresented: $showingAdd) { AddSneakerView() }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .sheet(isPresented: $showingSettings) { SettingsView() }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Sneakers Yet", systemImage: "shoe.2.fill")
        } description: {
            Text("Add your first pair and tap \"Wore today\" whenever you wear them.")
                .multilineTextAlignment(.center)
        } actions: {
            Button("Add a pair") {
                addTapped()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var proUpsellCard: some View {
        Button {
            showingPaywall = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "star.circle.fill")
                    .font(.title)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlock SoleCount Pro")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Unlimited pairs + wear history charts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.top, 8)
    }

    /// Free users can add up to 3 pairs. After that we show the Pro screen.
    private func addTapped() {
        if StoreManager.canAddPair(currentCount: sneakers.count, isPro: store.isPro) {
            showingAdd = true
        } else {
            showingPaywall = true
        }
    }
}

/// Section header with count badge
struct SectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.title2.bold())
            Text("\(count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                )
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
}

/// Modern photo-forward sneaker card
struct SneakerCard: View {
    let sneaker: Sneaker

    var body: some View {
        HStack(spacing: 16) {
            SneakerPhoto(data: sneaker.photoData, size: 80)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(sneaker.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !sneaker.brand.isEmpty {
                    Text(sneaker.brand)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Label("\(sneaker.wearCount)", systemImage: "figure.walk")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    if let cpp = sneaker.costPerWear {
                        Label(cpp.asCurrency, systemImage: "dollarsign.circle")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
}
