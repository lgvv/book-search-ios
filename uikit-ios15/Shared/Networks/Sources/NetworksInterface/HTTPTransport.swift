import Foundation

public protocol HTTPTransport: Sendable {
    func send(request: HTTPRequest) async throws -> HTTPResponse
}
