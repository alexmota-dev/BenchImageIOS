import Foundation

/// Mock para GRPC remoto. Mantem o “shape” do Java:
/// - mede tempo total
/// - processa localmente o grayscale (simulando round-trip)
public final class GrayScaleRemoteGRPCProtoBuffer: RemoteFilterStrategy {
    private let host: String
    private let port: Int
    private(set) public var offloadingTimeMs: Int = 0

    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    public func applyFilter(_ source: Data) -> Data {
        let t0 = DispatchTime.now().uptimeNanoseconds

        // Decodifica, aplica GrayScaleFilter (local), re-encoda:
        guard var raw = try? ImageUtils.decodeJpegToRaw(source) else { return source }
        var filter = GrayScaleFilter()
        _ = filter.applyFilter(&raw)
        let data = (try? ImageUtils.encodeRawToJpeg(raw)) ?? source

        let dt = DispatchTime.now().uptimeNanoseconds - t0
        offloadingTimeMs = Int(Double(dt) / 1_000_000.0)
        return data
    }

    public func closeChannel() {
        // noop no mock
    }
}
