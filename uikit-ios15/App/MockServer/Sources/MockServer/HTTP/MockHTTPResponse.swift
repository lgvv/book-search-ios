import Foundation

struct MockHTTPResponse: Sendable {
    let statusCode: Int
    let headers: [String: String]
    let body: Data
}

extension MockHTTPResponse {
    static func json(_ statusCode: Int, _ body: some Encodable) throws -> Self {
        MockHTTPResponse(
            statusCode: statusCode,
            headers: ["Content-Type": "application/json"],
            body: try ServerJSON.encoder.encode(body)
        )
    }

    static let noContent = MockHTTPResponse(statusCode: 204, headers: [:], body: Data())
}
