import Foundation
import NetworksInterface

public struct RequestIDMiddleware: HTTPClientMiddleware {
    public static let headerName = "X-Request-ID"

    public init() {}

    public func intercept(
        request: HTTPRequest,
        next: @escaping @Sendable (HTTPRequest) async throws -> HTTPResponse
    ) async throws -> HTTPResponse {
        guard request.headers[Self.headerName] == nil else {
            return try await next(request)
        }
        var headers = request.headers
        headers[Self.headerName] = UUID().uuidString
        let identified = HTTPRequest(
            method: request.method,
            url: request.url,
            headers: headers,
            body: request.body
        )

        do {
            return try await next(identified)
        } catch let failure as HTTPFailure {
            throw failure
        } catch {
            throw HTTPFailure(request: identified, response: nil, error: error)
        }
    }
}
