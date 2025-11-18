import Foundation

import NetworksInterface
import TestSupport

final class StubTransport: HTTPTransport {
    let receivedRequests = Locked<[HTTPRequest]>([])

    private let handler: @Sendable (HTTPRequest) throws -> HTTPResponse

    init(handler: @escaping @Sendable (HTTPRequest) throws -> HTTPResponse) {
        self.handler = handler
    }

    convenience init(statusCode: Int = 200, body: Data? = Data("{}".utf8), headers: [String: String] = [:]) {
        self.init { request in
            HTTPResponse(
                requestURL: request.url,
                statusCode: statusCode,
                headers: headers,
                body: body
            )
        }
    }

    convenience init(failure: any Error) {
        self.init { _ in throw failure }
    }

    func send(request: HTTPRequest) async throws -> HTTPResponse {
        self.receivedRequests.withValue { $0.append(request) }
        return try self.handler(request)
    }
}

struct TracingMiddleware: HTTPClientMiddleware {
    let name: String
    let trace: Locked<[String]>

    func intercept(
        request: HTTPRequest,
        next: @escaping @Sendable (HTTPRequest) async throws -> HTTPResponse
    ) async throws -> HTTPResponse {
        self.trace.withValue { $0.append("\(self.name)-요청") }
        let response = try await next(request)
        self.trace.withValue { $0.append("\(self.name)-응답") }
        return response
    }
}

struct HeaderStampingMiddleware: HTTPClientMiddleware {
    let key: String
    let value: String

    func intercept(
        request: HTTPRequest,
        next: @escaping @Sendable (HTTPRequest) async throws -> HTTPResponse
    ) async throws -> HTTPResponse {
        var headers = request.headers
        headers[self.key] = self.value
        return try await next(
            HTTPRequest(
                method: request.method,
                url: request.url,
                headers: headers,
                body: request.body
            )
        )
    }
}

extension HTTPRequest {
    static func sample(_ urlString: String = "https://api.booksearch.dev/books") -> HTTPRequest {
        HTTPRequest(method: .get, url: URL(string: urlString)!)
    }
}
