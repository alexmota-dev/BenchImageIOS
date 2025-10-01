import Foundation
import UIKit

public struct AppConfigurationCore {
    public var imageName: String            // ex: "img5" (sem extensão; buscaremos no Assets)
    public var filter: String               // "Original" | "GreyScale" | ...
    public var size: String                 // "All" | "0.3MP" | "1MP" | "2MP" | "4MP" | "8MP"
    public var benchmarkMode: Bool
    public var local: String                // "Local" | "Cloudlet"
    public var rpcMethod: String            // "Local" | "Cloudlet"
    public var ipCloudlet: String

    public init(imageName: String,
                filter: String,
                size: String,
                benchmarkMode: Bool,
                local: String,
                rpcMethod: String,
                ipCloudlet: String) {
        self.imageName = imageName
        self.filter = filter
        self.size = size
        self.benchmarkMode = benchmarkMode
        self.local = local
        self.rpcMethod = rpcMethod
        self.ipCloudlet = ipCloudlet
    }
}

public struct ResultImageCore {
    public var bitmap: UIImage
    public var totalTimeMs: Int
    public var offTimeMs: Int
    public var config: AppConfigurationCore
}

/// Progresso (equivalente a TaskResultAdapter)
public protocol TaskProgressCore: AnyObject {
    func taskOnGoing(_ completed: Int, _ statusText: String)
    func taskOnGoing(_ completed: Int, _ statusText: String, _ execText: String)
    func completedTask(_ result: ResultImageCore?)
}

public final class ImageFilterTaskCore {

    private let filter: Filter
    private var config: AppConfigurationCore
    private weak var progress: TaskProgressCore?

    public init(filter: Filter,
                config: AppConfigurationCore,
                progress: TaskProgressCore?) {
        self.filter = filter
        self.config = config
        self.progress = progress
    }

    // ===== Execução semelhante ao AsyncTask.doInBackground =====
    public func run() {
        Task.detached { [weak self] in
            guard let self else { return }
            do {
                var result: ResultImageCore?
                if self.config.benchmarkMode {
                    result = try await self.benchmarkTask()
                } else {
                    if self.config.filter == "Original" {
                        result = try await self.originalTask()
                    } else if self.config.filter == "GreyScale" {
                        result = try await self.greyTask(self.config.size)
                    } else {
                        result = try await self.originalTask() // fallback
                    }
                }
                await MainActor.run { self.progress?.completedTask(result) }
            } catch {
                await MainActor.run { self.progress?.completedTask(nil) }
            }
        }
    }

    // ===== Helpers =====
    private func sizeToSample(_ size: String) -> Int {
        switch size {
        case "1MP", "2MP": return 2
        case "4MP": return 4
        case "6MP": return 6
        case "8MP": return 8
        default: return 1 // "0.3MP" ou outras -> 1
        }
    }

    private func loadUIImage(named baseName: String, size: String) throws -> UIImage {
        // No Android havia pastas images/{size}/arquivo.jpg; aqui vamos usar Assets.
        // Coloque suas variantes com o mesmo nome (ex.: img5) e redimensionamento via inSampleSize.
        guard let ui = UIImage(named: baseName) else {
            throw NSError(domain: "ImageFilterTask", code: -1, userInfo: [NSLocalizedDescriptionKey: "Asset not found: \(baseName)"])
        }
        let s = sizeToSample(size)
        return ImageUtils.downsample(ui, inSampleSize: s)
    }

    private func generatePhotoFileName() -> String {
        var size = config.size
        if size == "0.7MP" { size = "0_7mp" }
        if size == "0.3MP" { size = "0_3mp" }
        return "\(config.imageName)_\(config.filter)_\(size).jpg"
    }

    // ===== Tarefas =====
    private func originalTask() async throws -> ResultImageCore {
        let t0 = Date().timeIntervalSince1970
        await MainActor.run { self.progress?.taskOnGoing(0, "Loading image!") }
        let image = try loadUIImage(named: config.imageName, size: config.size)
        let total = Int((Date().timeIntervalSince1970 - t0) * 1000.0)
        await MainActor.run { self.progress?.taskOnGoing(0, "Image loaded!") }
        return ResultImageCore(bitmap: image, totalTimeMs: total, offTimeMs: 0, config: config)
    }

    private func greyTask(_ imageSize: String) async throws -> ResultImageCore {
        // Carrega bytes (como no Java), decide local x remoto
        let tStartNs = DispatchTime.now().uptimeNanoseconds
        let ui = try loadUIImage(named: config.imageName, size: imageSize)
        guard let jpegData = ui.jpegData(compressionQuality: 0.95) else {
            throw NSError(domain: "ImageFilterTask", code: -2, userInfo: [NSLocalizedDescriptionKey: "Fail encode source"])
        }

        let imageResult: Data
        var offMs = 0

        if config.local == "Local" {
            // local strategy
            if var raw = try? ImageUtils.decodeJpegToRaw(jpegData) {
                let strat = GrayScaleFilter()
                var stratCopy = strat
                _ = stratCopy.applyFilter(&raw)
                offMs = stratCopy.offloadingTimeMs
                imageResult = (try? ImageUtils.encodeRawToJpeg(raw)) ?? jpegData
            } else {
                imageResult = jpegData
            }
        } else {
            // remoto (mock)
            let remote = ImageFilterFactory.getRemoteMethod(config.rpcMethod, host: config.ipCloudlet, port: 50051)
            let data = remote?.applyFilter(jpegData) ?? jpegData
            offMs = remote?.offloadingTimeMs ?? 0
            remote?.closeChannel()
            imageResult = data
        }

        // “Salvar” e reabrir como no Android (simulado com data->UIImage)
        let outUI = UIImage(data: imageResult) ?? ui

        let totalMs = Int(Double(DispatchTime.now().uptimeNanoseconds - tStartNs) / 1_000_000.0)
        await MainActor.run {
            self.progress?.taskOnGoing(0, "GreyScale Completed!", "\(totalMs)ms")
        }

        return ResultImageCore(bitmap: outUI, totalTimeMs: totalMs, offTimeMs: offMs, config: config)
    }

    private func benchmarkTask() async throws -> ResultImageCore {
        var sizes = ["0.3MP", "1MP", "2MP", "4MP", "8MP"]
        if config.size != "All" { sizes = [config.size] }

        var totalTime = 0
        var last: ResultImageCore? = nil
        var csv = "Round,Method,PhotoSize,TimeCelProc,TimeCelTotal\n"

        for size in sizes {
            for i in 1...50 {
                let r = try await greyTask(size)
                last = r
                totalTime += r.totalTimeMs
                let line = "\(i),\(config.rpcMethod),\(size),\(r.offTimeMs),\(r.totalTimeMs)\n"
                csv += line
                await MainActor.run {
                    self.progress?.taskOnGoing(0, "Benchmark Image \(size) [\(i)/50]", "\(r.totalTimeMs)ms")
                }
            }
        }

        let finalResult: ResultImageCore
        if let last = last {
            finalResult = last
        } else {
            finalResult = try await originalTask()
        }

        var final = finalResult
        final.totalTimeMs = totalTime
        return final
    }
}
