import UIKit

enum ImageUtils {

    // ===== Canais (equivalentes aos do Java) =====
    @inline(__always) static func getRed(_ color: Int) -> Int   { (color >> 16) & 0xFF }
    @inline(__always) static func getGreen(_ color: Int) -> Int { (color >> 8)  & 0xFF }
    @inline(__always) static func getBlue(_ color: Int) -> Int  { color & 0xFF }

    @inline(__always) static func setColor(_ r: Int, _ g: Int, _ b: Int) -> Int {
        ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF)
    }

    // ===== Encode/Decode (JPEG <-> RawImage) =====
    static func decodeJpegToRaw(_ data: Data) throws -> RawImage {
        guard let ui = UIImage(data: data), let raw = RawImage(uiImage: ui) else {
            throw NSError(domain: "ImageUtils", code: -1, userInfo: [NSLocalizedDescriptionKey: "Decode fail"])
        }
        return raw
    }

    static func encodeRawToJpeg(_ raw: RawImage, quality: CGFloat = 0.9) throws -> Data {
        guard let ui = raw.toUIImage(),
              let jpeg = ui.jpegData(compressionQuality: quality)
        else {
            throw NSError(domain: "ImageUtils", code: -2, userInfo: [NSLocalizedDescriptionKey: "Encode fail"])
        }
        return jpeg
    }

    // ===== Escalonamento aproximando Android inSampleSize =====
    // inSampleSize = 1,2,4,6,8 => reduz por fator aproximado
    static func downsample(_ ui: UIImage, inSampleSize: Int) -> UIImage {
        guard inSampleSize > 1, let cg = ui.cgImage else { return ui }
        let newW = max(1, cg.width / inSampleSize)
        let newH = max(1, cg.height / inSampleSize)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: newW, height: newH), format: format)
        return renderer.image { _ in
            ui.draw(in: CGRect(x: 0, y: 0, width: newW, height: newH))
        }
    }
}
