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
                            VStack(spacing: 8) {
                                SneakerPhoto(data: photoData, size: 120)
                                Text(photoData == nil ? "Add photo" : "Change photo")
                                    .font(.footnote)
                            }
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                Section("Details") {
                    TextField("Name (e.g. Air Max 90)", text: $name)
                    TextField("Brand (e.g. Nike)", text: $brand)
                    TextField("Price paid (e.g. 129.99)", value: $price, format: .number)
                        .keyboardType(.decimalPad)
                    DatePicker("Purchased",
                               selection: $purchaseDate,
                               in: ...Date.now,
                               displayedComponents: .date)
                }

                Section {
                    Toggle("Set a wear limit", isOn: $hasWearLimit)
                    if hasWearLimit {
                        Stepper("Retire after \(wearLimit) wears",
                                value: $wearLimit, in: 10...1000, step: 10)
                    }
                } footer: {
                    Text("Optional. SoleCount will suggest retiring the pair when it reaches this many wears.")
                }
            }
            .navigationTitle("New Sneaker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
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
