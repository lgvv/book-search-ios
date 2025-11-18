import Foundation
import NetworksInterface

public enum HTTPRequestFactory {
    public static func makeURLRequest(from request: HTTPRequest) throws -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue

        for header in request.headers {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }

        if let httpBody = request.body {
            urlRequest.httpBody = httpBody
        }

        return urlRequest
    }
}
