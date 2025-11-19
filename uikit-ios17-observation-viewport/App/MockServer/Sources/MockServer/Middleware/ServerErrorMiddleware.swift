import Foundation

struct ServerErrorMiddleware: MockMiddleware {
    func respond(to request: MockRequest, next: MockResponder) async throws -> MockHTTPResponse {
        do {
            return try await next(request)
        } catch let error as ServerError {
            return error.response
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return ServerError.internalFailure.response
        }
    }
}
