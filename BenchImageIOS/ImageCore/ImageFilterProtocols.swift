import Foundation

public protocol Filter {
    func greyScaleImage(_ source: inout RawImage) -> RawImage
    func mapTone(_ source: Data, _ map: Data) -> Data?
    func mapTone(_ source: inout RawImage, _ map: RawImage) -> RawImage
    func filterApply(_ source: Data, _ filter: [[Double]], _ factor: Double, _ offset: Double) -> Data?
    func filterApply(_ source: inout RawImage, _ filter: [[Double]], _ factor: Double, _ offset: Double) -> RawImage
    func cartoonizerImage(_ source: Data) -> Data?
    func cartoonizerImage(_ source: inout RawImage) -> RawImage
    func sepiaScaleImage(_ source: inout RawImage) -> RawImage
}

public protocol CloudletFilter: Filter { }
public protocol InternetFilter: Filter { }

public protocol FilterStrategy {
    func applyFilter(_ source: inout RawImage) -> RawImage
    var offloadingTimeMs: Int { get }
}

public protocol RemoteFilterStrategy {
    func applyFilter(_ source: Data) -> Data
    func closeChannel()
    var offloadingTimeMs: Int { get }
}
