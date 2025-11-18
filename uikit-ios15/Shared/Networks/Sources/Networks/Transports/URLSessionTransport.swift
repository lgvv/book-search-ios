import Foundation
import NetworksInterface

public struct URLSessionTransport: HTTPTransport {
    private let urlSession: URLSession

    public init(urlSession: URLSession) {
        self.urlSession = urlSession
    }

    public func send(request: HTTPRequest) async throws -> HTTPResponse {
        let urlRequest: URLRequest = try HTTPRequestFactory.makeURLRequest(from: request)

        try Task.checkCancellation()
        let (data, response) = try await urlSession.data(for: urlRequest)
        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPClientError.nonHTTPURLResponse(response)
        }

        let httpHeaderResponse: [String: String] = httpResponse.allHeaderFields
            .reduce(into: [:]) { result, pair in
                guard let key = pair.key as? String else { return }
                result[key] = String(describing: pair.value)
            }

        return HTTPResponse(
            requestURL: request.url,
            statusCode: httpResponse.statusCode,
            headers: httpHeaderResponse,
            body: data
        )
    }
}
