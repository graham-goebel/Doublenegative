import Foundation
import SwiftData

@Model
final class ImageItem {
    var id: UUID
    var filename: String
    /// Security-scoped bookmark — survives across app launches in the sandbox.
    var bookmarkData: Data
    var fileFormat: String      // "RAW" | "JPEG" | "TIFF"
    var rawFormat: String?      // "CR2" | "NEF" | "ARW" | "DNG" | nil
    var width: Int
    var height: Int
    var fileSizeBytes: Int
    var importedAt: Date
    var capturedAt: Date?
    var cameraMake: String?
    var cameraModel: String?
    var lens: String?
    var iso: Int?
    var aperture: Double?
    var shutterSpeed: String?
    var focalLength: Double?
    /// JSON-encoded EditParams — keeps the model simple and Codable-free in SwiftData.
    var editParamsData: Data
    var isEdited: Bool

    @Relationship(deleteRule: .nullify, inverse: \PhotoCollection.images)
    var collections: [PhotoCollection]

    init(
        filename: String,
        bookmarkData: Data,
        fileFormat: String,
        rawFormat: String? = nil,
        width: Int = 0,
        height: Int = 0,
        fileSizeBytes: Int = 0
    ) {
        self.id = UUID()
        self.filename = filename
        self.bookmarkData = bookmarkData
        self.fileFormat = fileFormat
        self.rawFormat = rawFormat
        self.width = width
        self.height = height
        self.fileSizeBytes = fileSizeBytes
        self.importedAt = Date()
        self.editParamsData = (try? JSONEncoder().encode(EditParams())) ?? Data()
        self.isEdited = false
        self.collections = []
    }

    // MARK: - Computed helpers

    var editParams: EditParams {
        get { (try? JSONDecoder().decode(EditParams.self, from: editParamsData)) ?? .default }
        set {
            editParamsData = (try? JSONEncoder().encode(newValue)) ?? Data()
            isEdited = (newValue != .default)
        }
    }

    /// Resolves the stored bookmark back to a usable URL.
    /// Call `url.startAccessingSecurityScopedResource()` before reading the file.
    func resolveURL() -> URL? {
        var isStale = false
        #if os(macOS)
        return try? URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        #else
        return try? URL(
            resolvingBookmarkData: bookmarkData,
            bookmarkDataIsStale: &isStale
        )
        #endif
    }

    // MARK: - Static helpers

    static let rawExtensions: Set<String> = [
        "cr2", "cr3", "nef", "arw", "dng", "raf", "orf", "rw2", "pef", "srw", "x3f"
    ]

    static func makeBookmark(for url: URL) throws -> Data {
        #if os(macOS)
        return try url.bookmarkData(options: .withSecurityScope)
        #else
        return try url.bookmarkData()
        #endif
    }

    static func fileFormat(for url: URL) -> (format: String, raw: String?) {
        let ext = url.pathExtension.lowercased()
        if rawExtensions.contains(ext) {
            return ("RAW", ext.uppercased())
        }
        switch ext {
        case "tif", "tiff": return ("TIFF", nil)
        default:             return ("JPEG", nil)
        }
    }
}
