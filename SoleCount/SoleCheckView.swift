import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// A pair's sole photos over time. Every photo stays on this iPhone.
struct SoleCheckSection: View {
    @Bindable var sneaker: Sneaker
    @Environment(\.modelContext) private var modelContext

    @State private var showingTip = false
    @State private var showingCamera = false
    @State private var showingLibrary = false
    @State private var libraryItem: PhotosPickerItem?
    @State private var viewing: SolePhoto?

    private var photos: [SolePhoto] { sneaker.orderedSolePhotos }
    private var currentKilometers: Double { sneaker.totalMeters / 1_000 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sole check", systemImage: "shoeprints.fill")
                .font(.headline)
            Text("Compare your soles over time. When the tread looks smooth, it may be time for a send-off.")
                .font(.subheadline)
                .foregroundStyle(ShoeTheme.softText)
                .fixedSize(horizontal: false, vertical: true)

            if !sneaker.isRetired, SoleCheckMath.shouldNudge(sneaker.soleSnapshots, currentKilometers: currentKilometers) {
                Label(nudgeLine, systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ShoeTheme.goldTint.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityIdentifier("soleNudge")
            }

            if !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(photos) { photo in
                            Button {
                                viewing = photo
                            } label: {
                                VStack(spacing: 4) {
                                    thumbnail(photo, width: 88, height: 116)
                                    Text(photo.takenAt.formatted(.dateTime.month(.abbreviated).day()))
                                        .font(.caption.weight(.semibold))
                                    Text(DistanceFormat.string(meters: photo.kilometers * 1_000))
                                        .font(.caption2)
                                        .foregroundStyle(ShoeTheme.softText)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Sole photo from \(photo.takenAt.formatted(date: .abbreviated, time: .omitted)), at \(DistanceFormat.string(meters: photo.kilometers * 1_000))")
                            .accessibilityHint("Opens the photo")
                        }
                    }
                    .padding(.vertical, 2)
                }
                .accessibilityIdentifier("soleTimeline")
            }

            if let pair = SoleCheckMath.compareIndices(sneaker.soleSnapshots) {
                let list = sneaker.solePhotos
                compare(first: list[pair.first], latest: list[pair.latest])
            }

            Button {
                showingTip = true
            } label: {
                Label("Take a sole photo", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SunriseButtonStyle())
            .accessibilityIdentifier("takeSolePhotoButton")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
        .sheet(isPresented: $showingTip) {
            SoleTipSheet(
                cameraAvailable: CameraPicker.isAvailable,
                onCamera: {
                    showingTip = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showingCamera = true }
                },
                onLibrary: {
                    showingTip = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showingLibrary = true }
                }
            )
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { data in save(data) }
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showingLibrary, selection: $libraryItem, matching: .images)
        .onChange(of: libraryItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    save(data)
                }
                libraryItem = nil
            }
        }
        .fullScreenCover(item: $viewing) { photo in
            SolePhotoViewer(photo: photo) {
                delete(photo)
            }
        }
    }

    private var nudgeLine: String {
        let since = SoleCheckMath.kilometersSinceLast(sneaker.soleSnapshots, currentKilometers: currentKilometers) ?? 0
        return "About \(DistanceFormat.string(meters: since * 1_000)) since the last sole photo. A quick check?"
    }

    private func compare(first: SolePhoto, latest: SolePhoto) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("First and latest")
                .font(.subheadline.weight(.semibold))
            HStack(spacing: 12) {
                compareColumn(first, title: "First")
                compareColumn(latest, title: "Latest")
            }
        }
        .accessibilityIdentifier("soleCompare")
    }

    private func compareColumn(_ photo: SolePhoto, title: String) -> some View {
        VStack(spacing: 4) {
            thumbnail(photo, width: nil, height: 180)
            Text(title)
                .font(.caption.weight(.semibold))
            Text("\(photo.takenAt.formatted(date: .abbreviated, time: .omitted)) · \(DistanceFormat.string(meters: photo.kilometers * 1_000))")
                .font(.caption2)
                .foregroundStyle(ShoeTheme.softText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func thumbnail(_ photo: SolePhoto, width: CGFloat?, height: CGFloat) -> some View {
        Group {
            if let data = photo.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ShoeTheme.cardFill
            }
        }
        .frame(width: width, height: height)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityHidden(true)
    }

    private func save(_ data: Data) {
        guard let shrunk = ImageHelper.downsized(data) else { return }
        sneaker.addSolePhoto(shrunk, in: modelContext)
    }

    private func delete(_ photo: SolePhoto) {
        viewing = nil
        sneaker.solePhotos.removeAll { $0.persistentModelID == photo.persistentModelID }
        modelContext.delete(photo)
    }
}

/// A short tip before the camera opens.
private struct SoleTipSheet: View {
    var cameraAvailable: Bool
    var onCamera: () -> Void
    var onLibrary: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "shoeprints.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(ShoeTheme.coralTint)
                    .rotationEffect(.degrees(-90))
                    .accessibilityHidden(true)
                Text("Flip your shoe and line up the sole, heel at the bottom.")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Good light helps. Take it the same way each time so the photos are easy to compare.")
                    .font(.subheadline)
                    .foregroundStyle(ShoeTheme.softText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if cameraAvailable {
                    Button(action: onCamera) {
                        Label("Open camera", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SunriseButtonStyle())
                    .accessibilityIdentifier("soleOpenCamera")
                }
                Button(action: onLibrary) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("soleChooseLibrary")
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

/// One sole photo, full screen, with a way to delete it.
private struct SolePhotoViewer: View {
    var photo: SolePhoto
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirming = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let data = photo.photoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel("Sole photo")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text("\(photo.takenAt.formatted(date: .long, time: .omitted)) · \(DistanceFormat.string(meters: photo.kilometers * 1_000))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        confirming = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("deleteSolePhoto")
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .confirmationDialog("Delete this sole photo?", isPresented: $confirming, titleVisibility: .visible) {
                Button("Delete Photo", role: .destructive) { onDelete() }
                Button("Keep", role: .cancel) { }
            }
        }
    }
}
