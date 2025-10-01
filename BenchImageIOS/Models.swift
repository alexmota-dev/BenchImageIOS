import Foundation

struct AppConfiguration {
    var ipCloudlet: String = ""
    var benchmarkMode: Bool = false

    var image: String? = nil          // "img1.jpg", "img4.jpg", "img5.jpg"
    var filter: String = "Cartoonizer"
    var size: String = "8MP"          // "All", "2MP", "4MP", "8MP"
    var local: String = "Local"       // "Local", "Cloudlet"

    var rpcMethod: String = "Local"
    var outputDirectory: String = ""  // mock: nao usado no iOS
}

enum MockError: Error {
    case unsupportedFilter
}
