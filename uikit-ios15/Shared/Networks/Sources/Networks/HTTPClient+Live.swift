import Foundation
import NetworksInterface

public extension HTTPClient {
    static let live: HTTPClient = .init(
        transport: URLSessionTransport(urlSession: .app),
        middlewares: [
            RequestIDMiddleware(),
            StatusCodeValidationMiddleware(),
        ]
    )
}

private extension URLSession {
    static let app: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 60
        return URLSession(configuration: configuration)
    }()
}
