import Foundation

public struct HTTPResponse: Sendable, Decodable {
    public let requestURL: URL
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data?

    public init(
        requestURL: URL,
        statusCode: Int,
        headers: [String: String],
        body: Data?
    ) {
        self.requestURL = requestURL
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

public extension HTTPResponse {
    func bodyString(encoding: String.Encoding = .utf8) -> String? {
        guard let body else { return nil }
        return String(data: body, encoding: encoding)
    }

    func jsonObject() throws -> Any? {
        guard let body else { return nil }
        return try JSONSerialization.jsonObject(with: body, options: [])
    }

    func prettyPrintedJSON(encoding: String.Encoding = .utf8) -> String? {
        guard let body else { return nil }
        guard
            let object = try? JSONSerialization.jsonObject(with: body, options: []),
            JSONSerialization.isValidJSONObject(object),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
        else { return nil }

        return String(data: data, encoding: encoding)
    }

    func decode<T: Decodable>(
        _: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        guard let body else {
            throw HTTPClientError.missingResponseData
        }
        return try decoder.decode(T.self, from: body)
    }
}
