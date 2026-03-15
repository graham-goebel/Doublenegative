import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO
import UniformTypeIdentifiers
import Foundation

/// GPU-accelerated image processing pipeline using CoreImage.
/// Replaces the entire Python rawpy + numpy + Pillow backend.
/// `actor` ensures all rendering happens off the main thread safely.
actor ImageProcessor {

    /// Shared instance — CIContext creation is expensive; one is enough.
    static let shared = ImageProcessor()

    // Single GPU-backed context, reused for all renders
    private let context: CIContext = {
        let options: [CIContextOption: Any] = [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
            .useSoftwareRenderer: false,
        ]
        return CIContext(options: options)
    }()

    private static let exifDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return fmt
    }()

    // MARK: - Public API

    func renderPreview(from url: URL, params: EditParams, maxLongEdge: Int = 1800) -> CGImage? {
        guard let base = loadCIImage(from: url) else { return nil }
        let edited = applyEdits(to: base, params: params)
        let scaled = scale(edited, maxLongEdge: CGFloat(maxLongEdge))
        return context.createCGImage(scaled, from: scaled.extent)
    }

    func renderThumbnail(from url: URL, maxSize: Int = 256) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: false,
        ]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    func exportJPEG(from url: URL, params: EditParams, quality: Double = 0.92) -> Data? {
        guard let base = loadCIImage(from: url) else { return nil }
        let edited = applyEdits(to: base, params: params)
        guard let cgImage = context.createCGImage(edited, from: edited.extent) else { return nil }

        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            data, UTType.jpeg.identifier as CFString, 1, nil
        ) else { return nil }
        CGImageDestinationAddImage(dest, cgImage, [
            kCGImageDestinationLossyCompressionQuality: quality
        ] as CFDictionary)
        return CGImageDestinationFinalize(dest) ? data as Data : nil
    }

    func extractMetadata(from url: URL) -> ImageMetadata {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
        else { return ImageMetadata() }

        var meta = ImageMetadata()
        meta.width  = props[kCGImagePropertyPixelWidth  as String] as? Int
        meta.height = props[kCGImagePropertyPixelHeight as String] as? Int

        if let tiff = props[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            meta.cameraMake  = tiff[kCGImagePropertyTIFFMake  as String] as? String
            meta.cameraModel = tiff[kCGImagePropertyTIFFModel as String] as? String
        }
        if let exif = props[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            meta.focalLength = exif[kCGImagePropertyExifFocalLength as String] as? Double
            meta.aperture    = exif[kCGImagePropertyExifFNumber     as String] as? Double
            if let isos = exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int] {
                meta.iso = isos.first
            }
            if let exp = exif[kCGImagePropertyExifExposureTime as String] as? Double, exp > 0 {
                meta.shutterSpeed = exp < 1 ? "1/\(Int((1/exp).rounded()))" : "\(exp)s"
            }
            if let dtStr = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                meta.capturedAt = Self.exifDateFormatter.date(from: dtStr)
            }
        }
        return meta
    }

    // MARK: - CoreImage filter chain

    func applyEdits(to image: CIImage, params: EditParams) -> CIImage {
        var img = image

        // 1. Exposure (2^EV multiplication in linear light)
        img = img.applyingFilter("CIExposureAdjust", parameters: [
            kCIInputEVKey: params.exposure
        ])

        // 2. Highlights & Shadows (zone-targeted brightness)
        img = img.applyingFilter("CIHighlightShadowAdjust", parameters: [
            "inputHighlightAmount": max(0, 1.0 + params.highlights / 100.0),
            "inputShadowAmount":    max(0, 1.0 + params.shadows    / 100.0),
        ])

        // 3. Whites & Blacks via tone curve endpoints
        let wShift = params.whites / 200.0
        let bShift = params.blacks / 200.0
        img = img.applyingFilter("CIToneCurve", parameters: [
            "inputPoint0": CIVector(x: CGFloat(bShift),       y: 0),
            "inputPoint1": CIVector(x: 0.25,                  y: 0.25),
            "inputPoint2": CIVector(x: 0.5,                   y: 0.5),
            "inputPoint3": CIVector(x: 0.75,                  y: 0.75),
            "inputPoint4": CIVector(x: 1.0 + CGFloat(wShift), y: 1),
        ])

        // 4. Contrast
        if params.contrast != 0 {
            img = img.applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey:   1.0 + params.contrast / 100.0,
                kCIInputBrightnessKey: 0.0,
                kCIInputSaturationKey: 1.0,
            ])
        }

        // 5. Temperature & Tint
        if params.temperature != 0 || params.tint != 0 {
            let baseTemp: CGFloat = 6500
            img = img.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral":       CIVector(x: baseTemp + CGFloat(params.temperature) * 100,
                                               y: CGFloat(params.tint) * 50),
                "inputTargetNeutral": CIVector(x: baseTemp, y: 0),
            ])
        }

        // 6. Saturation
        if params.saturation != 0 {
            img = img.applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey:   1.0,
                kCIInputBrightnessKey: 0.0,
                kCIInputSaturationKey: max(0, 1.0 + params.saturation / 100.0),
            ])
        }

        // 7. Vibrance (boosts muted colors more than already-saturated ones)
        if params.vibrance != 0 {
            img = img.applyingFilter("CIVibrance", parameters: [
                "inputAmount": params.vibrance / 100.0
            ])
        }

        // 8. Sharpening
        if params.sharpening > 0 {
            img = img.applyingFilter("CISharpenLuminance", parameters: [
                "inputSharpness": params.sharpening / 100.0,
                "inputRadius":    params.sharpeningRadius,
            ])
        }

        // 9. Noise Reduction
        if params.noiseReduction > 0 {
            img = img.applyingFilter("CINoiseReduction", parameters: [
                "inputNoiseLevel": params.noiseReduction / 2000.0,
                "inputSharpness":  params.noiseReductionDetail / 100.0,
            ])
        }

        return img
    }

    // MARK: - Helpers

    private func loadCIImage(from url: URL) -> CIImage? {
        // CGImageSource handles RAW natively via macOS/iOS ImageIO
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldAllowFloat: true,
            kCGImageSourceShouldCache: false,
        ]
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions as CFDictionary),
            let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return nil }
        return CIImage(cgImage: cgImage)
    }

    private func scale(_ image: CIImage, maxLongEdge: CGFloat) -> CIImage {
        let extent = image.extent
        let longEdge = max(extent.width, extent.height)
        guard longEdge > maxLongEdge else { return image }
        let ratio = maxLongEdge / longEdge
        return image.transformed(by: CGAffineTransform(scaleX: ratio, y: ratio))
    }
}

// MARK: - Metadata value type

struct ImageMetadata {
    var width: Int?
    var height: Int?
    var cameraMake: String?
    var cameraModel: String?
    var iso: Int?
    var aperture: Double?
    var shutterSpeed: String?
    var focalLength: Double?
    var capturedAt: Date?
}
