import CoreTransferable
import PhotosUI
import UniformTypeIdentifiers

/// A library photo. The picker offers a picture (`public.image`, often HEIC).
/// It does not offer raw `public.data`, so loading `Data` directly comes back empty.
struct LibraryPhoto: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            // Copy the bytes now. The picker deletes its temporary file after this returns.
            LibraryPhoto(data: Data(data))
        }
    }
}

enum PhotoImport {
    /// The JPEG SoleCount stores, or nil when the picture cannot be read.
    static func data(from item: PhotosPickerItem?) async -> Data? {
        guard let item else { return nil }
        guard let photo = try? await item.loadTransferable(type: LibraryPhoto.self) else { return nil }
        return ImageHelper.downsized(photo.data)
    }
}
