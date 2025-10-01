import Foundation

public enum ImageFilterFactory {

    public static func getLocalMethod(_ method: String) -> FilterStrategy? {
        if method == "Normal" {
            return GrayScaleFilter()
        }
        return nil
    }

    public static func getRemoteMethod(_ method: String, host: String, port: Int) -> RemoteFilterStrategy? {
        if method == "Cloudlet" {
            return GrayScaleRemoteGRPCProtoBuffer(host: host, port: port) // mock
        }
        return nil
    }
}
