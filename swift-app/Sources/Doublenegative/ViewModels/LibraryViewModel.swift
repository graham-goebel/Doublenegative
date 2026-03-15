import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@Observable
final class LibraryViewModel {
    var selectedImageIDs: Set<UUID> = []
    var activeCollectionID: UUID?       // nil = All Photos
    var isImporting = false
    var importError: String?

    private let processor = ImageProcessor.shared

    func toggleSelection(_ image: ImageItem, multiSelect: Bool) {
        if multiSelect {
            if selectedImageIDs.contains(image.id) {
                selectedImageIDs.remove(image.id)
            } else {
                selectedImageIDs.insert(image.id)
            }
        } else {
            selectedImageIDs = [image.id]
        }
    }

    func clearSelection() {
        selectedImageIDs = []
    }

    // MARK: - Import

    /// Imports an array of file URLs picked via fileImporter / drop.
    func importImages(_ urls: [URL], into context: ModelContext) async {
        await MainActor.run { isImporting = true }

        for url in urls {
            await url.withSecurityScope {
                do {
                    let bookmarkData = try ImageItem.makeBookmark(for: url)
                    let (format, rawFormat) = ImageItem.fileFormat(for: url)
                    let meta = await processor.extractMetadata(from: url)

                    let item = ImageItem(
                        filename: url.lastPathComponent,
                        bookmarkData: bookmarkData,
                        fileFormat: format,
                        rawFormat: rawFormat,
                        width: meta.width ?? 0,
                        height: meta.height ?? 0,
                        fileSizeBytes: (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                    )
                    item.cameraMake   = meta.cameraMake
                    item.cameraModel  = meta.cameraModel
                    item.iso          = meta.iso
                    item.aperture     = meta.aperture
                    item.shutterSpeed = meta.shutterSpeed
                    item.focalLength  = meta.focalLength
                    item.capturedAt   = meta.capturedAt

                    await MainActor.run { context.insert(item) }
                } catch {
                    await MainActor.run { importError = error.localizedDescription }
                }
            }
        }

        await MainActor.run {
            try? context.save()
            isImporting = false
        }
    }

    // MARK: - Collections

    func createCollection(named name: String, context: ModelContext) {
        let collection = PhotoCollection(name: name)
        context.insert(collection)
        try? context.save()
    }

    func addSelected(to collection: PhotoCollection, allImages: [ImageItem]) {
        let toAdd = allImages.filter { selectedImageIDs.contains($0.id) }
        for image in toAdd where !collection.images.contains(image) {
            collection.images.append(image)
        }
        try? collection.modelContext?.save()
    }

    func deleteCollection(_ collection: PhotoCollection, context: ModelContext) {
        context.delete(collection)
        try? context.save()
    }

    // MARK: - Deletion

    func deleteImages(_ images: [ImageItem], context: ModelContext) {
        images.forEach { context.delete($0) }
        try? context.save()
        selectedImageIDs.subtract(images.map(\.id))
    }

    // MARK: - Accepted file types

    static let acceptedTypes: [UTType] = [
        .jpeg, .tiff, .png, .rawImage,
        UTType("com.canon.cr2-raw-image")        ?? .rawImage,
        UTType("com.nikon.raw-image")            ?? .rawImage,
        UTType("com.sony.arw-raw-image")         ?? .rawImage,
        UTType("com.adobe.raw-image")            ?? .rawImage,   // DNG
        UTType("com.fuji.raw-image")             ?? .rawImage,
        UTType("com.olympus.raw-image")          ?? .rawImage,
        UTType("com.panasonic.raw-image")        ?? .rawImage,
    ]
}
