import SwiftUI
import SwiftData
import PhotosUI

// The "New Sneaker" form.
struct AddSneakerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var price: Double?
    @State private var purchaseDate = Date.now
    @State private var hasWearLimit = false
    @State private var wearLimit = 100
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            VStack(spacing: 12) {
                                ZStack {
                                    SneakerPhoto(data: photoData, size: 140)
                                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                                    if photoData == nil {
                                        VStack {
                                            Image(systemName: "camera.fill")
                                                .font(.title)
                                                .foregroundStyle(.white)
                                                .padding(16)
                                                .background(Circle().fill(Color.accentColor))
                                        }
                                    }
                                }

                                Text(photoData == nil ? "Add Photo" : "Change Photo")
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

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 24)
                        TextField("Name (e.g. Air Max 90)", text: $name)
                            .font(.body)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "building.2.fill")
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 24)
                        TextField("Brand (e.g. Nike)", text: $brand)
                            .font(.body)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundStyle(.green)
                            .frame(width: 24)
                        TextField("Price paid (e.g. 129.99)", value: $price, format: .number)
                            .keyboardType(.decimalPad)
                            .font(.body)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        DatePicker("Purchased",
                                   selection: $purchaseDate,
                                   in: ...Date.now,
                                   displayedComponents: .date)
                            .font(.body)
                    }
                } header: {
                    Text("Details")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Section {
                    Toggle(isOn: $hasWearLimit) {
                        HStack(spacing: 12) {
                            Image(systemName: "flag.checkered")
                                .foregroundStyle(.orange)
                                .frame(width: 24)
                            Text("Set a Wear Goal")
                                .font(.body)
                        }
                    }

                    if hasWearLimit {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Retire after")
                                Spacer()
                                Text("\(wearLimit) wears")
                                    .font(.headline)
                                    .foregroundStyle(Color.accentColor)
                            }
                            Slider(value: Binding(
                                get: { Double(wearLimit) },
                                set: { wearLimit = Int($0) }
                            ), in: 10...1000, step: 10)
                            .tint(Color.accentColor)
                        }
                    }
                } header: {
                    Text("Optional")
                        .font(.headline)
                        .foregroundStyle(.primary)
                } footer: {
                    Text("SoleCount will suggest retiring the pair when it reaches this many wears.")
                        .font(.footnote)
                }
            }
            .navigationTitle("New Sneaker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.body)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        Text("Save")
                            .font(.body.weight(.semibold))
                    }
                    .disabled(!canSave)
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task { await loadPhoto(from: newItem) }
            }
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self) else { return }
        photoData = ImageHelper.downsized(data)
    }

    private func save() {
        let sneaker = Sneaker(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
            price: max(0, price ?? 0),
            purchaseDate: purchaseDate,
            photoData: photoData,
            wearLimit: hasWearLimit ? wearLimit : nil
        )
        modelContext.insert(sneaker)
        dismiss()
    }
}
