import Foundation
import SwiftData

@Model
final class Recipe {
    var id: UUID
    var name: String
    var recipeDescription: String?
    var paramsData: Data
    var createdAt: Date
    var sourceImageId: UUID?

    init(name: String, params: EditParams, description: String? = nil, sourceImageId: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.recipeDescription = description
        self.paramsData = (try? JSONEncoder().encode(params)) ?? Data()
        self.createdAt = Date()
        self.sourceImageId = sourceImageId
    }

    var params: EditParams {
        get { (try? JSONDecoder().decode(EditParams.self, from: paramsData)) ?? .default }
        set { paramsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}
