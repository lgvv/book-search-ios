import Foundation

@testable import MockServer

extension MockRequest {
    static func make(
        _ method: HTTPMethod = .get,
        _ urlString: String,
        headers: [String: String] = [:],
        body: Data? = nil
    ) -> MockRequest {
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = method.rawValue
        request.httpBody = body
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        return MockRequest(request)!
    }
}

extension MockHTTPResponse {
    var json: [String: Any] {
        (try? JSONSerialization.jsonObject(with: self.body)) as? [String: Any] ?? [:]
    }

    var errorCode: String? {
        (self.json["error"] as? [String: Any])?["code"] as? String
    }
}

struct StubRouteCollection: MockRouteCollection {
    let routes: [MockRoute]

    static func echoing(_ method: HTTPMethod, _ path: [MockRoute.Segment]) -> MockRoute {
        MockRoute(method, path) { request in
            MockHTTPResponse(
                statusCode: 200,
                headers: [:],
                body: try JSONSerialization.data(withJSONObject: request.pathParameters)
            )
        }
    }

    static func naming(_ name: String, _ method: HTTPMethod, _ path: [MockRoute.Segment]) -> MockRoute {
        MockRoute(method, path) { _ in
            MockHTTPResponse(
                statusCode: 200,
                headers: [:],
                body: Data(name.utf8)
            )
        }
    }
}
