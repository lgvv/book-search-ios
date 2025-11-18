import Foundation

public protocol HTTPClientMiddleware: Sendable {
    func intercept(
        request: HTTPRequest,
        next: @escaping @Sendable (HTTPRequest) async throws -> HTTPResponse
    ) async throws -> HTTPResponse
}
