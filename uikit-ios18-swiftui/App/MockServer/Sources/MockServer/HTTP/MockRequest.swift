import Foundation

struct MockRequest: Sendable {
    static let requestIDHeaderName = "X-Request-ID"

    let method: HTTPMethod
    let url: URL
    let pathComponents: [String]
    let queryItems: [URLQueryItem]
    let headers: [String: String]
    let body: Data?

    var requestID: String? {
        self.headers.first { $0.key.caseInsensitiveCompare(Self.requestIDHeaderName) == .orderedSame }?.value
    }

    private(set) var pathParameters: [String: String] = [:]

    func resolving(pathParameters: [String: String]) -> Self {
        var copy = self
        copy.pathParameters = pathParameters
        return copy
    }
}

extension MockRequest {
    init?(_ urlRequest: URLRequest) {
        guard let url = urlRequest.url else { return nil }

        self.init(
            method: HTTPMethod(rawValue: urlRequest.httpMethod ?? HTTPMethod.get.rawValue),
            url: url,
            pathComponents: url.path.split(separator: "/").map(String.init),
            queryItems: URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [],
            headers: urlRequest.allHTTPHeaderFields ?? [:],
            body: Self.drainBody(of: urlRequest)
        )
    }

    private static func drainBody(of request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }

        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let count = stream.read(buffer, maxLength: bufferSize)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

extension MockRequest {
    func pathParameter(_ name: String) throws -> String {
        guard let value = self.pathParameters[name], !value.isEmpty else {
            throw ServerError.badRequest("\(name) 경로 파라미터가 없습니다")
        }
        return value
    }

    func query(_ name: String) -> String? {
        self.queryItems.first { $0.name == name }?.value
    }

    func requiredQuery(_ name: String) throws -> String {
        guard let value = self.query(name), !value.isEmpty else {
            throw ServerError.badRequest("\(name) 파라미터가 없습니다")
        }
        return value
    }

    func query<Value: LosslessStringConvertible>(_ name: String, default fallback: Value) throws -> Value {
        guard let raw = self.query(name), !raw.isEmpty else { return fallback }
        guard let value = Value(raw) else {
            throw ServerError.badRequest("\(name) 파라미터를 해석할 수 없습니다: \(raw)")
        }
        return value
    }

    func decodeBody<Value: Decodable>(_ type: Value.Type) throws -> Value {
        guard let body = self.body else {
            throw ServerError.badRequest("요청 본문이 없습니다")
        }
        guard let value = try? ServerJSON.decoder.decode(Value.self, from: body) else {
            throw ServerError.badRequest("요청 본문을 해석할 수 없습니다")
        }
        return value
    }
}
