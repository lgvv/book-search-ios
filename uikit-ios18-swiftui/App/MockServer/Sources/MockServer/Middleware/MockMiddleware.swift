import Foundation

typealias MockResponder = @Sendable (MockRequest) async throws -> MockHTTPResponse

protocol MockMiddleware: Sendable {
    func respond(to request: MockRequest, next: MockResponder) async throws -> MockHTTPResponse
}

extension Array where Element == any MockMiddleware {
    func chained(to responder: @escaping MockResponder) -> MockResponder {
        var next = responder
        for middleware in self.reversed() {
            let inner = next
            next = { @Sendable request in
                try await middleware.respond(to: request, next: inner)
            }
        }
        return next
    }
}
