import PhotosUI
import SwiftData
import SwiftUI

/// Pairs you might buy. "I bought it" copies the details into the collection.
struct WishlistView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WishlistItem.createdAt, order: .reverse) private var items: [WishlistItem]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("No next pairs yet", systemImage: "gift")
                    } description: {
                        Text("Save a brand, a model, and a price. It stays on this iPhone.")
                    }
                } else {
                    List(items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.modelName.isEmpty ? item.brand : item.modelName)
                                .font(.headline)
                            if !item.brand.isEmpty, !item.modelName.isEmpty {
                                Text(item.brand)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if item.targetPrice > 0 {
                                Text(item.targetPrice.asCurrency)
                                    .font(.subheadline)
                            }
                            if !item.notes.isEmpty {
                                Text(item.notes)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Button("I bought it") { buy(item) }
                                .accessibilityIdentifier("boughtItButton")
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Next pairs")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add a wish")
                    .accessibilityIdentifier("addWishlistButton")
                }
            }
            .sheet(isPresented: $showingAdd) { WishlistEditor() }
        }
    }

    private func buy(_ item: WishlistItem) {
        let draft = WishlistMath.bought(
            WishlistDraft(
                brand: item.brand,
                modelName: item.modelName,
                targetPrice: item.targetPrice,
                notes: item.notes
            )
        )
        let sneaker = Sneaker(
            name: draft.name,
            brand: draft.brand,
            price: draft.price,
            photoData: item.photoData,
            notes: draft.notes
        )
        modelContext.insert(sneaker)
        modelContext.delete(item)
    }
}

/// A short form for a pair you have not bought.
private struct WishlistEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var brand = ""
    @State private var modelName = ""
    @State private var price: Double?
    @State private var notes = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photo: Data?

    private var suggestions: [String] {
        ShoeCatalog.brandChoices(query: brand, recent: ShoeCatalog.recentBrands()).filter {
            $0.caseInsensitiveCompare(brand) != .orderedSame
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Brand (e.g. Nike)", text: $brand)
                if !suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(suggestions.prefix(8), id: \.self) { choice in
                                Button(choice) { brand = choice }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                TextField("Model (e.g. Air Max 90)", text: $modelName)
                TextField("Target price", value: $price, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(photo == nil ? "Add photo" : "Change photo", systemImage: "photo")
                }
            }
            .navigationTitle("Next pair")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(brand.trimmingCharacters(in: .whitespaces).isEmpty && modelName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let item, let data = try? await item.loadTransferable(type: Data.self) {
                        photo = ImageHelper.downsized(data)
                    }
                }
            }
        }
    }

    private func save() {
        let trimmed = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        ShoeCatalog.rememberBrand(trimmed)
        let item = WishlistItem(
            brand: trimmed,
            modelName: modelName.trimmingCharacters(in: .whitespacesAndNewlines),
            targetPrice: max(0, price ?? 0),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            photoData: photo
        )
        modelContext.insert(item)
        dismiss()
    }
}
