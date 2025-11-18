import Foundation
import NetworksInterface

public struct StatusCodeValidationMiddleware: HTTPClientMiddleware {
    public init() {}

    public func intercept(
        request: HTTPRequest,
        next: @escaping @Sendable (HTTPRequest) async throws -> HTTPResponse
    ) async throws -> HTTPResponse {
        let response = try await next(request)
        guard (200 ..< 300) ~= response.statusCode else {
            throw HTTPFailure(
                request: request,
                response: response,
                error: HTTPClientError.unacceptableStatusCode(response.statusCode)
            )
        }
        return response
    }
}
