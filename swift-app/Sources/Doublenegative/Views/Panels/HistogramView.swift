import SwiftUI

/// Draws an RGB histogram from a CGImage using Canvas.
struct HistogramView: View {
    let image: CGImage?

    var body: some View {
        Canvas { ctx, size in
            guard let cgImage = image else {
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.clear))
                return
            }
            let hist = computeHistogram(from: cgImage)
            drawHistogram(hist, in: ctx, size: size)
        }
        .background(Color.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Histogram computation

    private func computeHistogram(from cgImage: CGImage) -> ([Int], [Int], [Int]) {
        let w = min(cgImage.width, 256)
        let h = min(cgImage.height, 256)
        guard
            let ctx = CGContext(
                data: nil, width: w, height: h,
                bitsPerComponent: 8, bytesPerRow: w * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )
        else { return ([], [], []) }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let data = ctx.data else { return ([], [], []) }
        let ptr = data.bindMemory(to: UInt8.self, capacity: w * h * 4)

        var r = [Int](repeating: 0, count: 256)
        var g = [Int](repeating: 0, count: 256)
        var b = [Int](repeating: 0, count: 256)
        for i in 0 ..< w * h {
            r[Int(ptr[i * 4])]     += 1
            g[Int(ptr[i * 4 + 1])] += 1
            b[Int(ptr[i * 4 + 2])] += 1
        }
        return (r, g, b)
    }

    // MARK: - Draw

    private func drawHistogram(_ hist: ([Int], [Int], [Int]), in ctx: GraphicsContext, size: CGSize) {
        let (r, g, b) = hist
        guard !r.isEmpty else { return }
        let peak = max(r.max() ?? 1, g.max() ?? 1, b.max() ?? 1, 1)

        let channels: [([Int], Color)] = [(r, .red), (g, .green), (b, .blue)]
        for (ch, color) in channels {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height))
            for (i, val) in ch.enumerated() {
                let x = CGFloat(i) / 255 * size.width
                let y = size.height - CGFloat(val) / CGFloat(peak) * size.height * 0.9
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
            ctx.fill(path, with: .color(color.opacity(0.4)))
        }
    }
}
