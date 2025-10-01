import Foundation

public final class GrayScaleFilter: FilterStrategy {
    private(set) public var offloadingTimeMs: Int = 0

    public init() {}

    public func applyFilter(_ source: inout RawImage) -> RawImage {
        let t0 = DispatchTime.now().uptimeNanoseconds

        let w = source.width, h = source.height
        let rW = 0.299, gW = 0.587, bW = 0.114

        for x in 0..<w {
            for y in 0..<h {
                let p = source[x, y]
                let r = ImageUtils.getRed(p)
                let g = ImageUtils.getGreen(p)
                let b = ImageUtils.getBlue(p)
                let gray = Int(rW * Double(r) + gW * Double(g) + bW * Double(b))
                source[x, y] = ImageUtils.setColor(gray, gray, gray)
            }
        }

        let dt = DispatchTime.now().uptimeNanoseconds - t0
        offloadingTimeMs = Int(Double(dt) / 1_000_000.0)
        return source
    }
}
