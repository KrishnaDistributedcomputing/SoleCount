import SwiftData
import SwiftUI

// The collection: every pair, with wears, distance, and cost per wear.
struct SneakerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Environment(HealthSync.self) private var health
    @Environment(MotivationStore.self) private var motivation
    @Query(sort: \Sneaker.createdAt, order: .reverse) private var sneakers: [Sneaker]

    @State private var showingAdd = false
    @State private var showingPaywall = false
    @State private var showingSettings = false
    @State private var showingWishlist = false
    @State private var brandFilter: String?
    @State private var typeFilter: String?
    @State private var sort: CollectionSort = .newest
    @Namespace private var shoeSpace

    private var rows: [CollectionRow] { sneakers.map { $0.asRow() } }

    private var active: [Sneaker] {
        CollectionMath.indices(rows: rows, brand: brandFilter, type: typeFilter, sort: sort, retired: false)
            .map { sneakers[$0] }
    }

    private var retired: [Sneaker] {
        CollectionMath.indices(rows: rows, brand: brandFilter, type: typeFilter, sort: sort, retired: true)
            .map { sneakers[$0] }
    }

    private var hints: [RotationHint] {
        CollectionMath.forgotten(
            pairs: sneakers.map { ($0.name, $0.lastWorn, $0.isRetired) },
            now: .now,
            calendar: .current
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if sneakers.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("SoleCount")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Sneaker.self) { sneaker in
                SneakerDetailView(sneaker: sneaker)
            }
            .environment(\.shoeNamespace, shoeSpace)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 16) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                        }
                        .accessibilityLabel("Settings")
                        filterMenu
                        Button {
                            showingWishlist = true
                        } label: {
                            Image(systemName: "gift")
                        }
                        .accessibilityLabel("Next pairs")
                        .accessibilityIdentifier("nextPairsButton")
                    }
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
            .sheet(isPresented: $showingWishlist) { WishlistView() }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                if let hint = hints.first, brandFilter == nil, typeFilter == nil {
                    Text(CollectionMath.hintLine(hint))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .warmCard()
                }
                if active.isEmpty && retired.isEmpty {
                    ContentUnavailableView("No pairs in this view yet", systemImage: "line.3.horizontal.decrease.circle", description: Text("Clear the filter and every pair is here."))
                    Button("Clear filters") {
                        brandFilter = nil
                        typeFilter = nil
                    }
                }
                if !active.isEmpty {
                    Section {
                        ForEach(active) { sneaker in
                            cardLink(sneaker)
                        }
                    } header: {
                        SectionHeader(title: "In Rotation", count: active.count)
                    }
                }
                if !retired.isEmpty {
                    Section {
                        Text("Retired pairs keep their stats.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(retired) { sneaker in
                            cardLink(sneaker)
                        }
                    } header: {
                        SectionHeader(title: "Retired", count: retired.count)
                    }
                }
                if !store.hasFullAccess {
                    proUpsellCard
                }
            }
            .padding()
        }
        .background(ShoeTheme.canvas)
    }

    private func cardLink(_ sneaker: Sneaker) -> some View {
        NavigationLink(value: sneaker) {
            SneakerCard(sneaker: sneaker)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pairRow")
        .matchedTransitionSource(id: sneaker.persistentModelID, in: shoeSpace)
    }

    private var filterMenu: some View {
        Menu {
            Picker("Sort", selection: $sort) {
                ForEach(CollectionSort.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            Menu("Brand") {
                Button("All brands") { brandFilter = nil }
                ForEach(brandNames, id: \.self) { brand in
                    Button(brand) { brandFilter = brand }
                }
            }
            Menu("Type") {
                Button("All types") { typeFilter = nil }
                ForEach(ShoeType.allCases) { type in
                    Button(type.rawValue) { typeFilter = type.rawValue }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filter and sort")
    }

    private var brandNames: [String] {
        Array(Set(sneakers.map(\.brand).filter { !$0.isEmpty })).sorted()
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ShoeEmptyArt()
            Text("Your first pair belongs here")
                .font(.title2.bold())
            Text("Add one pair. Log a wear when you feel like it. That is a lovely start.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add a pair") {
                addTapped()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    private var proUpsellCard: some View {
        Button {
            showingPaywall = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "star.circle.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlock SoleCount Pro")
                        .font(.headline)
                    Text("Unlimited pairs, charts, and shoe mileage")
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
        }
        .buttonStyle(.plain)
    }

    private func addTapped() {
        if StoreManager.canAddPair(currentCount: sneakers.count, isPro: store.isPro) {
            showingAdd = true
        } else if FeatureFlags.monetizationEnabled {
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
                .background(Capsule().fill(Color.secondary.opacity(0.2)))
            Spacer()
        }
        .padding(.vertical, 8)
        .background(ShoeTheme.canvas)
    }
}

/// Photo-forward sneaker card with the type colour and the cached distance.
struct SneakerCard: View {
    let sneaker: Sneaker

    var body: some View {
        HStack(spacing: 16) {
            SneakerPhoto(data: sneaker.gallery.first, size: 80)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            VStack(alignment: .leading, spacing: 6) {
                Text(sneaker.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Image(systemName: sneaker.shoeType.symbolName)
                        .foregroundStyle(ShoeTheme.accent(for: sneaker.shoeType))
                        .accessibilityHidden(true)
                    Text(sneaker.brand.isEmpty ? sneaker.shoeType.rawValue : sneaker.brand)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 12) {
                    Label("\(sneaker.wearCount)", systemImage: "figure.walk")
                    if sneaker.healthUpdatedAt != nil || sneaker.totalMeters > 0 {
                        Text(DistanceFormat.string(meters: sneaker.totalMeters))
                    }
                    if let cost = sneaker.costPerWear {
                        Text(cost.asCurrency)
                    }
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                if let fraction = sneaker.lifeFraction {
                    LifeBar(fraction: fraction)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ShoeTheme.cardFill)
                .shadow(color: ShoeTheme.shadow.opacity(0.2), radius: 10, y: 4)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(ShoeTheme.accent(for: sneaker.shoeType))
                .frame(width: 5)
                .padding(.vertical, 12)
        }
    }
}
