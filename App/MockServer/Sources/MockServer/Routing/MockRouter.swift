import Foundation

final class MockRouter: Sendable {
    private let responder: MockResponder

    init(collections: [any MockRouteCollection], middlewares: [any MockMiddleware]) {
        let routes = collections.flatMap(\.routes).sorted(by: MockRoute.isMoreSpecific)
        let dispatch: MockResponder = { request in
            try await Self.dispatch(request, to: routes)
        }

        let chain: [any MockMiddleware] = middlewares + [ServerErrorMiddleware()]
        self.responder = chain.chained(to: dispatch)
    }

    func respond(to urlRequest: URLRequest) async throws -> MockHTTPResponse {
        guard let request = MockRequest(urlRequest) else {
            return ServerError.badRequest("URL이 없는 요청입니다").response
        }
        return try await self.responder(request)
    }

    private static func dispatch(_ request: MockRequest, to routes: [MockRoute]) async throws -> MockHTTPResponse {
        var allowedMethods: [HTTPMethod] = []

        for route in routes {
            guard let parameters = route.matchPath(request.pathComponents) else { continue }
            guard route.method == request.method else {
                allowedMethods.append(route.method)
                continue
            }
            return try await route.handler(request.resolving(pathParameters: parameters))
        }

        guard allowedMethods.isEmpty else {
            throw ServerError.methodNotAllowed(allowed: allowedMethods)
        }
        throw ServerError.notFound(
            "요청과 일치하는 라우트가 없습니다: \(request.method.rawValue) \(request.url.path)"
        )
    }
}
