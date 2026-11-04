import PhotosUI
import SwiftData
import SwiftUI
import UIKit

// The form for a new pair, or for editing one you already saved.
struct AddSneakerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private var existing: Sneaker?

    @State private var name: String
    @State private var brand: String
    @State private var price: Double?
    @State private var purchaseDate: Date
    @State private var hasWearLimit: Bool
    @State private var wearLimit: Int
    @State private var photoItem: PhotosPickerItem?
    @State private var extraItems: [PhotosPickerItem] = []
    @State private var photos: [Data]
    @State private var shoeType: ShoeType
    @State private var size: String
    @State private var colorway: String
    @State private var condition: ShoeCondition
    @State private var notes: String
    @State private var hasReplaceTarget: Bool
    @State private var replaceDisplay: Double
    @State private var replaceEdited: Bool
    @State private var startingWears: Int
    @State private var startingDisplay: Double

    init(existing: Sneaker? = nil) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _brand = State(initialValue: existing?.brand ?? "")
        _price = State(initialValue: existing?.price)
        _purchaseDate = State(initialValue: existing?.purchaseDate ?? .now)
        _hasWearLimit = State(initialValue: existing?.wearLimit != nil)
        _wearLimit = State(initialValue: existing?.wearLimit ?? 100)
        _photos = State(initialValue: existing?.gallery ?? [])
        _shoeType = State(initialValue: existing?.shoeType ?? .other)
        _size = State(initialValue: existing?.size ?? "")
        _colorway = State(initialValue: existing?.colorway ?? "")
        _condition = State(initialValue: existing?.condition ?? .good)
        _notes = State(initialValue: existing?.notes ?? "")
        let goal = existing?.replaceAtKilometers ?? 0
        _hasReplaceTarget = State(initialValue: goal > 0)
        _replaceDisplay = State(initialValue: goal > 0 ? DistanceFormat.displayValue(kilometers: goal) : 600)
        _replaceEdited = State(initialValue: existing != nil)
        _startingWears = State(initialValue: existing?.startingWears ?? 0)
        _startingDisplay = State(initialValue: DistanceFormat.displayValue(kilometers: existing?.startingKilometers ?? 0))
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var suggestions: [String] {
        ShoeCatalog.brandChoices(query: brand, recent: ShoeCatalog.recentBrands()).filter {
            $0.caseInsensitiveCompare(brand) != .orderedSame
        }
    }

    private var modelIdeas: [String] {
        ShoeCatalog.models(forBrand: brand, query: name)
    }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                detailsSection
                shoeSection
                optionalSection
            }
            .navigationTitle(existing == nil ? "New Sneaker" : "Edit Sneaker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.body.weight(.semibold))
                        .disabled(!canSave)
                        .accessibilityIdentifier("saveSneakerButton")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Hide keyboard") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                        .accessibilityIdentifier("hideKeyboard")
                }
            }
            .onChange(of: photoItem) { _, item in
                Task { await loadMainPhoto(from: item) }
            }
            .onChange(of: extraItems) { _, items in
                Task { await loadExtra(from: items) }
            }
            .onChange(of: shoeType) { _, newType in
                guard !replaceEdited else { return }
                if let kilometers = newType.defaultReplaceKilometers {
                    hasReplaceTarget = true
                    replaceDisplay = DistanceFormat.displayValue(kilometers: kilometers)
                } else {
                    hasReplaceTarget = false
                }
            }
        }
    }

    private var photoSection: some View {
        Section {
            HStack {
                Spacer()
                PhotosPicker(selection: $photoItem, matching: .images) {
                    VStack(spacing: 12) {
                        SneakerPhoto(data: photos.first, size: 140)
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                        Text(photos.isEmpty ? "Add Photo" : "Change Photo")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .listRowBackground(Color.clear)
    }

    private var detailsSection: some View {
        Section {
            labeledField(symbol: "tag.fill", tint: Color.accentColor) {
                TextField("Name (e.g. Air Max 90)", text: $name)
            }
            labeledField(symbol: "building.2.fill", tint: Color.accentColor) {
                TextField("Brand (e.g. Nike)", text: $brand)
            }
            labeledField(symbol: "dollarsign.circle.fill", tint: .green) {
                TextField("Price paid (e.g. 129.99)", value: $price, format: .number)
                    .keyboardType(.decimalPad)
            }
            labeledField(symbol: "calendar", tint: .blue) {
                DatePicker("Purchased", selection: $purchaseDate, in: ...Date.now, displayedComponents: .date)
            }
        } header: {
            Text("Details")
        }
    }

    private var shoeSection: some View {
        Section {
            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(suggestions.prefix(12), id: \.self) { choice in
                            Button(choice) { brand = choice }
                                .buttonStyle(.bordered)
                        }
                        Button("Other…") { brand = "" }
                            .buttonStyle(.bordered)
                    }
                }
                .accessibilityLabel("Popular brands")
            }
            Picker("Type", selection: $shoeType) {
                ForEach(ShoeType.allCases) { type in
                    Label(type.rawValue, systemImage: type.symbolName).tag(type)
                }
            }
            if !modelIdeas.isEmpty && !brand.trimmingCharacters(in: .whitespaces).isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(modelIdeas.prefix(8), id: \.self) { model in
                            Button(model) { name = model }
                                .buttonStyle(.bordered)
                        }
                    }
                }
                .accessibilityLabel("Model ideas")
            }
            TextField("Size (e.g. 10)", text: $size)
            TextField("Colorway (e.g. White/Black)", text: $colorway)
            Picker("Condition", selection: $condition) {
                ForEach(ShoeCondition.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Text("Shoe")
        } footer: {
            Text("Type any brand. The list is only a shortcut. No logos are stored.")
        }
    }

    private var optionalSection: some View {
        Section {
            Stepper("Starting wears: \(startingWears)", value: $startingWears, in: 0...20_000, step: 1)
            HStack {
                Text("Starting distance")
                Spacer()
                TextField("0", value: $startingDisplay, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 80)
                    .accessibilityIdentifier("startingDistanceField")
                Text(DistanceFormat.unitWord())
                    .foregroundStyle(.secondary)
            }
            Toggle("Set a Wear Goal", isOn: $hasWearLimit)
            if hasWearLimit {
                Stepper("Retire after \(wearLimit) wears", value: $wearLimit, in: 10...1000, step: 10)
            }
            Toggle("Replacement distance", isOn: $hasReplaceTarget)
            if hasReplaceTarget {
                HStack {
                    Text("Replace at")
                    Spacer()
                    TextField("Distance", value: Binding(
                        get: { replaceDisplay },
                        set: { replaceDisplay = $0; replaceEdited = true }
                    ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                    Text(DistanceFormat.unitWord())
                        .foregroundStyle(.secondary)
                }
            }
            if photos.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(photos.enumerated()), id: \.offset) { index, data in
                            SneakerPhoto(data: data, size: 64)
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        photos.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                    .accessibilityLabel("Remove photo \(index + 1)")
                                }
                        }
                    }
                }
            }
            PhotosPicker(selection: $extraItems, maxSelectionCount: 5, matching: .images) {
                Label("Add more photos", systemImage: "photo.on.rectangle.angled")
            }
        } header: {
            Text("Optional")
        } footer: {
            Text("Running and training start at 650. Walking starts higher. Casual shoes start with the target off. Starting distance is included in the total. You can change any of this.")
        }
    }

    private func labeledField(symbol: String, tint: Color, @ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .frame(width: 24)
                .accessibilityHidden(true)
            content()
        }
    }

    private func loadMainPhoto(from item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let shrunk = ImageHelper.downsized(data) else { return }
        if photos.isEmpty {
            photos = [shrunk]
        } else {
            photos[0] = shrunk
        }
    }

    private func loadExtra(from items: [PhotosPickerItem]) async {
        var loaded: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let shrunk = ImageHelper.downsized(data) {
                loaded.append(shrunk)
            }
        }
        let main = photos.first
        photos = (main.map { [$0] } ?? []) + loaded
    }

    private func save() {
        let trimmedBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let kilometers = hasReplaceTarget ? max(0, DistanceFormat.kilometers(fromDisplay: replaceDisplay)) : 0
        let startingKilometers = max(0, DistanceFormat.kilometers(fromDisplay: startingDisplay))
        ShoeCatalog.rememberBrand(trimmedBrand)
        if let existing {
            existing.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.brand = trimmedBrand
            existing.price = max(0, price ?? 0)
            existing.purchaseDate = purchaseDate
            existing.wearLimit = hasWearLimit ? wearLimit : nil
            existing.shoeType = shoeType
            existing.size = size.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.colorway = colorway.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.condition = condition
            existing.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let previousGoal = existing.replaceAtKilometers
            existing.replaceAtKilometers = kilometers
            if previousGoal != kilometers {
                existing.retirementAlertBaselined = false
                existing.retirementAlertMark = 0
            }
            existing.startingWears = startingWears
            existing.startingKilometers = startingKilometers
            existing.replacePhotos(photos, in: modelContext)
        } else {
            let sneaker = Sneaker(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                brand: trimmedBrand,
                price: max(0, price ?? 0),
                purchaseDate: purchaseDate,
                photoData: photos.first,
                wearLimit: hasWearLimit ? wearLimit : nil,
                shoeType: shoeType,
                size: size.trimmingCharacters(in: .whitespacesAndNewlines),
                colorway: colorway.trimmingCharacters(in: .whitespacesAndNewlines),
                condition: condition,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                replaceAtKilometers: kilometers,
                startingWears: startingWears,
                startingKilometers: startingKilometers
            )
            modelContext.insert(sneaker)
            sneaker.replacePhotos(photos, in: modelContext)
        }
        dismiss()
    }
}
