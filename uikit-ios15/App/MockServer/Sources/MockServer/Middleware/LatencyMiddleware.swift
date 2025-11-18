import Foundation

struct LatencyMiddleware: MockMiddleware {
    let nanoseconds: UInt64

    func respond(to request: MockRequest, next: MockResponder) async throws -> MockHTTPResponse {
        if self.nanoseconds > 0 {
            try await Task.sleep(nanoseconds: self.nanoseconds)
        }
        return try await next(request)
    }
}
