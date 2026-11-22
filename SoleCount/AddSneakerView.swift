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
    @State private var showingLibrary = false
    @State private var showingCamera = false
    @State private var extraItems: [PhotosPickerItem] = []
    @State private var photoNote = ""
    @State private var photos: [Data]
    @State private var shoeType: ShoeType
    @State private var size: String
    @State private var sizeSystem: SizeSystem
    @State private var fit: ShoeFit
    @State private var colorway: String
    @State private var condition: ShoeCondition
    @State private var notes: String
    @State private var hasReplaceTarget: Bool
    @State private var replaceDisplay: Double
    @State private var replaceEdited: Bool
    @State private var startingWears: Int
    @State private var startingDisplay: Double
    @State private var didSave = false

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
        _sizeSystem = State(initialValue: existing?.sizeSystem ?? ShoeSizeDefaults.system())
        _fit = State(initialValue: existing?.fit ?? .unisex)
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
                    SavePairButton(enabled: canSave) { save() }
                        .fixedSize()
                }
            }
            .photosPicker(isPresented: $showingLibrary, selection: $photoItem, matching: .images)
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPicker { data in setMainPhoto(data) }
                    .ignoresSafeArea()
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

    /// Take Photo only shows on a phone with a camera. The simulator keeps the library picker.
    private var canTakePhoto: Bool {
        CameraPicker.isAvailable || LaunchFlags.showCameraOption
    }

    private var photoLabel: some View {
        VStack(spacing: 12) {
            SneakerPhoto(data: photos.first, size: 140)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .accessibilityIdentifier(photos.isEmpty ? "mainPhotoEmpty" : "mainPhotoFilled")
            Text(photos.isEmpty ? "Add Photo" : "Change Photo")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 8)
    }

    private var photoSection: some View {
        Section {
            VStack(spacing: 8) {
                if canTakePhoto {
                    Menu {
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                        }
                        .accessibilityIdentifier("takePhotoOption")
                        Button {
                            showingLibrary = true
                        } label: {
                            Label("Choose from Library", systemImage: "photo.on.rectangle")
                        }
                        .accessibilityIdentifier("chooseLibraryOption")
                    } label: {
                        photoLabel
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("photoMenu")
                } else {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        photoLabel
                    }
                    .buttonStyle(.plain)
                }
                if LaunchFlags.uiTesting {
                    Button("Use a sample photo") { applySamplePhoto() }
                        .accessibilityIdentifier("samplePhotoButton")
                }
                if !photoNote.isEmpty {
                    Text(photoNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
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
            labeledField(symbol: "dollarsign.circle.fill", tint: ShoeTheme.mintTint) {
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Type of shoe")
                    .font(.subheadline.weight(.semibold))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(ShoeType.allCases) { type in
                            Button {
                                selectShoeType(type)
                            } label: {
                                Label(type.rawValue, systemImage: type.symbolName)
                            }
                            .buttonStyle(.bordered)
                            .tint(shoeType == type ? Color.accentColor : Color.secondary)
                            // The form can use the first tap only to close the keyboard.
                            // This gesture still picks the type on that tap.
                            .highPriorityGesture(TapGesture().onEnded { selectShoeType(type) })
                            .accessibilityIdentifier("shoeType-\(type.rawValue)")
                            .accessibilityAddTraits(shoeType == type ? .isSelected : AccessibilityTraits())
                        }
                    }
                }
                .accessibilityIdentifier("shoeTypePicker")
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
            Picker("Fit", selection: $fit) {
                ForEach(ShoeFit.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("shoeFitPicker")
            Picker("Size system", selection: $sizeSystem) {
                ForEach(SizeSystem.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("sizeSystemPicker")
            TextField(sizePlaceholder, text: $size)
                .keyboardType(.decimalPad)
                .accessibilityIdentifier("sizeField")
            if !sizeHint.isEmpty {
                Text(sizeHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
            Text("Type any brand. The list is only a shortcut. No logos are stored. Fit picks the men's or women's chart. Unisex uses the men's chart. Equivalents follow Nike's published sizes.")
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
                    .foregroundStyle(ShoeTheme.softText)
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
                        .foregroundStyle(ShoeTheme.softText)
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

    private var sizePlaceholder: String {
        switch sizeSystem {
        case .us: "Size (e.g. 10)"
        case .uk: "Size (e.g. 9)"
        case .eu: "Size (e.g. 44)"
        }
    }

    private var sizeHint: String {
        let trimmed = size.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if let line = ShoeSizeChart.equivalentLine(size: trimmed, system: sizeSystem, fit: fit) {
            return line
        }
        return "That size is saved as typed. It is not on the chart, so the other systems are not shown."
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
        guard let item else { return }
        guard let shrunk = await PhotoImport.data(from: item) else {
            photoNote = "That photo could not be read. Try another one."
            return
        }
        setMainPhoto(shrunk)
    }

    /// Camera and library photos are stored the same way. The bytes are already a small JPEG.
    private func setMainPhoto(_ data: Data) {
        guard let shrunk = ImageHelper.downsized(data) else {
            photoNote = "That photo could not be read. Try another one."
            return
        }
        photoNote = ""
        if photos.isEmpty {
            photos = [shrunk]
        } else {
            photos[0] = shrunk
        }
    }

    private func applySamplePhoto() {
        guard let data = ImageHelper.sampleJPEG() else { return }
        setMainPhoto(data)
    }

    private func loadExtra(from items: [PhotosPickerItem]) async {
        var loaded: [Data] = []
        for item in items {
            if let shrunk = await PhotoImport.data(from: item) {
                loaded.append(shrunk)
            }
        }
        if loaded.isEmpty && !items.isEmpty {
            photoNote = "Those photos could not be read. Try another one."
        } else if !loaded.isEmpty {
            photoNote = ""
        }
        let main = photos.first
        photos = (main.map { [$0] } ?? []) + loaded
    }

    /// Picks a shoe type and closes the keyboard in the same tap.
    private func selectShoeType(_ type: ShoeType) {
        shoeType = type
        endTyping()
    }

    private func endTyping() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func save() {
        guard !didSave, canSave else { return }
        didSave = true
        endTyping()
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
            existing.sizeSystem = sizeSystem
            existing.fit = fit
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
                startingKilometers: startingKilometers,
                sizeSystem: sizeSystem,
                fit: fit
            )
            modelContext.insert(sneaker)
            sneaker.replacePhotos(photos, in: modelContext)
        }
        dismiss()
    }
}
