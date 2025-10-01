import UIKit

/// Equivalente a int[][] do Java, mas linearizado.
/// pixels armazena RGB compactado em 0x00RRGGBB (8 bits cada canal).
public struct RawImage {
    public let width: Int
    public let height: Int
    public var pixels: [Int] // 0x00RRGGBB

    @inline(__always)
    public func index(_ x: Int, _ y: Int) -> Int { (y * width) + x }

    public subscript(x: Int, y: Int) -> Int {
        get { pixels[index(x, y)] }
        set { pixels[index(x, y)] = newValue }
    }

    public init(width: Int, height: Int, pixels: [Int]) {
        precondition(pixels.count == width * height)
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    public init?(uiImage: UIImage) {
        guard let cg = uiImage.cgImage else { return nil }
        let w = cg.width, h = cg.height
        let bytesPerPixel = 4
        var data = [UInt8](repeating: 0, count: w * h * bytesPerPixel)

        guard let ctx = CGContext(
            data: &data,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * bytesPerPixel,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue // RGBA (alpha descartado)
        ) else { return nil }

        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        var pix = [Int](repeating: 0, count: w*h)
        for y in 0..<h {
            for x in 0..<w {
                let i = (y*w + x) * 4
                let r = Int(data[i+0])
                let g = Int(data[i+1])
                let b = Int(data[i+2])
                pix[y*w + x] = (r << 16) | (g << 8) | b
            }
        }
        self.width = w
        self.height = h
        self.pixels = pix
    }

    public func toUIImage() -> UIImage? {
        let w = width, h = height
        var data = [UInt8](repeating: 0, count: w*h*4)
        for y in 0..<h {
            for x in 0..<w {
                let c = pixels[(y*w + x)]
                let r = UInt8((c >> 16) & 0xFF)
                let g = UInt8((c >> 8)  & 0xFF)
                let b = UInt8(c & 0xFF)
                let i = (y*w + x) * 4
                data[i+0] = r
                data[i+1] = g
                data[i+2] = b
                data[i+3] = 255 // A
            }
        }
        guard let ctx = CGContext(
            data: &data,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w*4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let cg = ctx.makeImage()
        else { return nil }

        return UIImage(cgImage: cg)
    }
}
