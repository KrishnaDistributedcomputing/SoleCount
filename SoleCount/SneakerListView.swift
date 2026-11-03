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
                    ContentUnavailableView {
                        Label("No sneakers yet", systemImage: "shoe.2")
                    } description: {
                        Text("Add your first pair and tap \"Wore today\" whenever you wear them.")
                    } actions: {
                        Button("Add a pair") { addTapped() }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        if !activeSneakers.isEmpty {
                            Section("In rotation") {
                                ForEach(activeSneakers) { sneaker in
                                    NavigationLink(value: sneaker) {
                                        SneakerRow(sneaker: sneaker)
                                    }
                                }
                                .onDelete { offsets in delete(offsets, from: activeSneakers) }
                            }
                        }

                        if !retiredSneakers.isEmpty {
                            Section("Retired") {
                                ForEach(retiredSneakers) { sneaker in
                                    NavigationLink(value: sneaker) {
                                        SneakerRow(sneaker: sneaker)
                                    }
                                }
                                .onDelete { offsets in delete(offsets, from: retiredSneakers) }
                            }
                        }

                        if !store.isPro {
                            Section {
                                Button {
                                    showingPaywall = true
                                } label: {
                                    Label("Unlock SoleCount Pro", systemImage: "star.fill")
                                }
                            } footer: {
                                Text("The free version tracks up to \(StoreManager.freePairLimit) pairs. Swipe left on a pair to delete it.")
                            }
                        }
                    }
                }
            }
            .navigationTitle("SoleCount")
            .navigationDestination(for: Sneaker.self) { sneaker in
                SneakerDetailView(sneaker: sneaker)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addTapped()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add sneaker")
                }
            }
            .sheet(isPresented: $showingAdd) { AddSneakerView() }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .sheet(isPresented: $showingSettings) { SettingsView() }
        }
    }

    /// Free users can add up to 3 pairs. After that we show the Pro screen.
    private func addTapped() {
        if store.isPro || sneakers.count < StoreManager.freePairLimit {
            showingAdd = true
        } else {
            showingPaywall = true
        }
    }

    private func delete(_ offsets: IndexSet, from list: [Sneaker]) {
        for index in offsets {
            modelContext.delete(list[index])
        }
    }
}

/// One row in the list.
struct SneakerRow: View {
    let sneaker: Sneaker

    var body: some View {
        HStack(spacing: 12) {
            SneakerPhoto(data: sneaker.photoData, size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(sneaker.name)
                    .font(.headline)
                if !sneaker.brand.isEmpty {
                    Text(sneaker.brand)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(sneaker.wearCount) wears")
                    .font(.subheadline.bold())
                Text(sneaker.costPerWear.map { "\($0.asCurrency)/wear" } ?? "Not worn yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
