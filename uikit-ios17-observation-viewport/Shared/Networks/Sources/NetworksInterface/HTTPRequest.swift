import Foundation

public struct HTTPRequest: Sendable {
    public let method: HTTPMethod
    public let url: URL
    public let headers: [String: String]
    public let body: Data?

    public init(
        method: HTTPMethod,
        url: URL,
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }

    public init?(
        method: HTTPMethod,
        urlString: String,
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        guard let url = URL(string: urlString) else { return nil }
        self.init(method: method, url: url, headers: headers, body: body)
    }
}

extension HTTPRequest {
    public func headerValue(forName name: String) -> String? {
        self.headers.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
    }
}
