import Foundation

/// All non-destructive edit parameters for a single image.
/// Stored as JSON in SwiftData and used as the recipe format.
struct EditParams: Codable, Equatable, Hashable {
    // MARK: Light
    var exposure: Double    = 0   // -5.0 to +5.0 (EV stops)
    var contrast: Double    = 0   // -100 to +100
    var highlights: Double  = 0   // -100 to +100
    var shadows: Double     = 0   // -100 to +100
    var whites: Double      = 0   // -100 to +100
    var blacks: Double      = 0   // -100 to +100

    // MARK: Color
    var temperature: Double = 0   // -100 (cool) to +100 (warm)
    var tint: Double        = 0   // -100 (green) to +100 (magenta)
    var saturation: Double  = 0   // -100 to +100
    var vibrance: Double    = 0   // -100 to +100

    // MARK: Detail
    var sharpening: Double          = 0    // 0 to 150
    var sharpeningRadius: Double    = 1.0  // 0.5 to 3.0
    var sharpeningDetail: Double    = 25   // 0 to 100
    var noiseReduction: Double      = 0    // 0 to 100
    var noiseReductionDetail: Double = 50  // 0 to 100
    var noiseReductionColor: Double  = 25  // 0 to 100

    static let `default` = EditParams()
}
