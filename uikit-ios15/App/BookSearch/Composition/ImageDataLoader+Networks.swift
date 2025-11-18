import Foundation

import ImageLoader
import NetworksInterface

extension ImageDataLoader {
    static func networks(client: HTTPClient) -> Self {
        Self { url, etag in
            var headers: [String: String] = [:]
            if let etag {
                headers["If-None-Match"] = etag
            }
            let request = HTTPRequest(method: .get, url: url, headers: headers)

            do {
                let response = try await client.response(for: request)
                guard let body = response.body else {
                    throw HTTPFailure(
                        request: request,
                        response: response,
                        error: HTTPClientError.missingResponseData
                    )
                }
                return .fresh(body, etag: response.etag)
            } catch let failure as HTTPFailure where failure.response?.statusCode == 304 {
                return .notModified
            }
        }
    }
}

private extension HTTPResponse {
    var etag: String? {
        headers.first { $0.key.caseInsensitiveCompare("ETag") == .orderedSame }?.value
    }
}
