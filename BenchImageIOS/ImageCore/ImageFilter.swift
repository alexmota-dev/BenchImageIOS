import Foundation
import UIKit

public final class ImageFilter: CloudletFilter, InternetFilter {

    // ===== mapTone(byte[], byte[]) =====
    public func mapTone(_ source: Data, _ map: Data) -> Data? {
        do {
            var src = try ImageUtils.decodeJpegToRaw(source)
            let mp  = try ImageUtils.decodeJpegToRaw(map)
            src = mapTone(&src, mp)
            return try ImageUtils.encodeRawToJpeg(src)
        } catch {
            return nil
        }
    }

    // ===== mapTone(int[][], int[][]) =====
    public func mapTone(_ source: inout RawImage, _ map: RawImage) -> RawImage {
        let w = source.width, h = source.height
        let filterHeight = map.height // espelha “map[0].length” do Java usando altura

        for x in 0..<w {
            for y in 0..<h {
                let color = source[x, y]
                var r = ImageUtils.getRed(color)
                var g = ImageUtils.getGreen(color)
                var b = ImageUtils.getBlue(color)

                if filterHeight == 1 {
                    r = ImageUtils.getRed(map[r, 0])
                    g = ImageUtils.getRed(map[g, 0])
                    b = ImageUtils.getRed(map[b, 0])
                } else {
                    r = ImageUtils.getRed(map[r, 0])
                    g = ImageUtils.getGreen(map[g, 1])
                    b = ImageUtils.getBlue(map[b, 2])
                }
                source[x, y] = ImageUtils.setColor(
                    ImageUtils.getRed(r),
                    ImageUtils.getGreen(g),
                    ImageUtils.getBlue(b)
                )
            }
        }
        return source
    }

    // ===== cartoonizerImage(byte[]) =====
    public func cartoonizerImage(_ source: Data) -> Data? {
        do {
            var img = try ImageUtils.decodeJpegToRaw(source)
            img = cartoonizerImage(&img)
            return try ImageUtils.encodeRawToJpeg(img)
        } catch {
            return nil
        }
    }

    // ===== cartoonizerImage(int[][]) =====
    public func cartoonizerImage(_ source: inout RawImage) -> RawImage {
        // grayscale
        var gray = greyScaleImage(&source)

        // invert + blur gaussiano 3x3 (como no Java: { {1,2,1}, {2,4,2}, {1,2,1} } e factor 1/16.020)
        var inverted = invertColors(gray) // clone + invert
        let mask: [[Double]] = [
            [1,2,1],
            [2,4,2],
            [1,2,1]
        ]
        inverted = filterApply(&inverted, mask, 1.0 / 16.020, 0.0)

        // color dodge blend
        let blended = colorDodgeBlendOptimized(inverted, gray)
        return blended
    }

    // ===== filterApply(byte[], filter, factor, offset) =====
    public func filterApply(_ source: Data, _ filter: [[Double]], _ factor: Double, _ offset: Double) -> Data? {
        do {
            var img = try ImageUtils.decodeJpegToRaw(source)
            img = filterApply(&img, filter, factor, offset)
            return try ImageUtils.encodeRawToJpeg(img)
        } catch {
            return nil
        }
    }

    // ===== filterApply(int[][], filter, factor, offset) =====
    public func filterApply(_ source: inout RawImage, _ filter: [[Double]], _ factor: Double, _ offset: Double) -> RawImage {
        let w = source.width, h = source.height
        let fh = filter.count
        let fw = filter[0].count
        var out = source // processa in-place para manter custo, mas salvando antes
        // (aqui espelhando o Java: usa “wrap” modular).
        for x in 0..<w {
            for y in 0..<h {
                var red = 0.0, green = 0.0, blue = 0.0
                for fx in 0..<fw {
                    for fy in 0..<fh {
                        let ix = (x - (fw/2) + fx + w) % w
                        let iy = (y - (fh/2) + fy + h) % h
                        let c = source[ix, iy]
                        let k = filter[fx][fy]
                        red   += Double(ImageUtils.getRed(c))   * k
                        green += Double(ImageUtils.getGreen(c)) * k
                        blue  += Double(ImageUtils.getBlue(c))  * k
                    }
                }
                var r = Int(factor * red + offset)
                var g = Int(factor * green + offset)
                var b = Int(factor * blue + offset)
                r = min(max(r, 0), 255)
                g = min(max(g, 0), 255)
                b = min(max(b, 0), 255)
                out[x, y] = ImageUtils.setColor(r, g, b)
            }
        }
        return out
    }

    // ===== greyScaleImage(int[][]) =====
    public func greyScaleImage(_ source: inout RawImage) -> RawImage {
        let rW = 0.299, gW = 0.587, bW = 0.114
        let w = source.width, h = source.height
        for x in 0..<w {
            for y in 0..<h {
                let p = source[x, y]
                let r = ImageUtils.getRed(p), g = ImageUtils.getGreen(p), b = ImageUtils.getBlue(p)
                let gray = Int(rW * Double(r) + gW * Double(g) + bW * Double(b))
                source[x, y] = ImageUtils.setColor(gray, gray, gray)
            }
        }
        return source
    }

    // ===== sepiaScaleImage(int[][]) =====
    public func sepiaScaleImage(_ source: inout RawImage) -> RawImage {
        let w = source.width, h = source.height
        for x in 0..<w {
            for y in 0..<h {
                let p = source[x, y]
                let r0 = Double(ImageUtils.getRed(p))
                let g0 = Double(ImageUtils.getGreen(p))
                let b0 = Double(ImageUtils.getBlue(p))

                var r = Int((r0 * 0.393) + (g0 * 0.769) + (b0 * 0.189))
                var g = Int((r0 * 0.349) + (g0 * 0.686) + (b0 * 0.168))
                var b = Int((r0 * 0.272) + (g0 * 0.534) + (b0 * 0.131))

                if r > 255 { r = 255 }
                if g > 255 { g = 255 }
                if b > 255 { b = 255 }

                source[x, y] = ImageUtils.setColor(r, g, b)
            }
        }
        return source
    }

    // ===== Helpers que existem no Java =====
    private func invertColors(_ src: RawImage) -> RawImage {
        var out = src
        let w = src.width, h = src.height
        for y in 0..<h {
            for x in 0..<w {
                let c = src[x, y]
                let r = 255 - ImageUtils.getRed(c)
                let g = 255 - ImageUtils.getGreen(c)
                let b = 255 - ImageUtils.getBlue(c)
                out[x, y] = ImageUtils.setColor(r, g, b)
            }
        }
        return out
    }

    private func colordodge(_ in1: Int, _ in2: Int) -> Int {
        let image = Float(in2)
        let mask = Float(in1)
        if image == 255 { return Int(image) }
        let v = min(255.0, (Float(Int(mask) << 8) / max(1.0, 255.0 - image)))
        return Int(v)
    }

    private func colorDodgeBlendOptimized(_ source: RawImage, _ layer: RawImage) -> RawImage {
        var out = source
        let w = source.width, h = source.height
        for i in 0..<h {
            for j in 0..<w {
                let filterInt = layer[j, i]
                let srcInt    = source[j, i]
                let r = colordodge(ImageUtils.getRed(filterInt),   ImageUtils.getRed(srcInt))
                let g = colordodge(ImageUtils.getGreen(filterInt), ImageUtils.getGreen(srcInt))
                let b = colordodge(ImageUtils.getBlue(filterInt),  ImageUtils.getBlue(srcInt))
                out[j, i] = ImageUtils.setColor(r, g, b)
            }
        }
        return out
    }
}
