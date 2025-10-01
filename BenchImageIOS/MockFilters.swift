import Foundation

protocol Filtering {
    func process(config: AppConfiguration) async throws -> MockResult
}

struct MockResult {
    let totalTimeMs: Int
    let usedConfig: AppConfiguration
    let statusText: String
    let imageName: String?
}

struct LocalMockFilter: Filtering {
    func process(config: AppConfiguration) async throws -> MockResult {
        try await Task.sleep(nanoseconds: 600_000_000)
        return MockResult(
            totalTimeMs: 600,
            usedConfig: config,
            statusText: "Local processing finished",
            imageName: config.image
        )
    }
}

struct CloudletMockFilter: Filtering {
    func process(config: AppConfiguration) async throws -> MockResult {
        try await Task.sleep(nanoseconds: 1_200_000_000)
        return MockResult(
            totalTimeMs: 1200,
            usedConfig: config,
            statusText: "Cloudlet processing finished",
            imageName: config.image
        )
    }
}
