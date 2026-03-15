import Foundation
import SwiftData

@Model
final class PhotoCollection {
    var id: UUID
    var name: String
    var createdAt: Date
    var images: [ImageItem]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.images = []
    }

    var imageCount: Int { images.count }
}
