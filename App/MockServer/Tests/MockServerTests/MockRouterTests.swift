import XCTest

import TestSupport

@testable import MockServer

final class MockRouterTests: XCTestCase {

    private func makeSUT(
        routes: [MockRoute],
        middlewares: [any MockMiddleware] = []
    ) -> MockRouter {
        MockRouter(
            collections: [StubRouteCollection(routes: routes)],
            middlewares: middlewares
        )
    }

    func test_경로와메서드가맞으면_그핸들러로보낸다() async throws {
        let sut = self.makeSUT(routes: [
            StubRouteCollection.naming("책목록", .get, ["v1", "books"])
        ])

        let response = try await sut.respond(to: URLRequest.get("https://api.booksearch.dev/v1/books"))

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(String(data: response.body, encoding: .utf8), "책목록")
    }

    func test_경로파라미터를_핸들러에전달한다() async throws {
        let sut = self.makeSUT(routes: [
            StubRouteCollection.echoing(.get, ["v1", "books", .parameter("isbn")])
        ])

        let response = try await sut.respond(
            to: URLRequest.get("https://api.booksearch.dev/v1/books/9788937473135")
        )

        XCTAssertEqual(response.json["isbn"] as? String, "9788937473135")
    }

    func test_파라미터가여럿이면_모두전달한다() async throws {
        let sut = self.makeSUT(routes: [
            StubRouteCollection.echoing(
                .get,
                ["v1", .parameter("domain"), .parameter("id")]
            )
        ])

        let response = try await sut.respond(to: URLRequest.get("https://api.booksearch.dev/v1/books/1"))

        XCTAssertEqual(response.json["domain"] as? String, "books")
        XCTAssertEqual(response.json["id"] as? String, "1")
    }

    func test_경로부터없으면_404를돌려준다() async throws {
        let sut = self.makeSUT(routes: [
            StubRouteCollection.naming("책목록", .get, ["v1", "books"])
        ])

        let response = try await sut.respond(to: URLRequest.get("https://api.booksearch.dev/v1/없는것"))

        XCTAssertEqual(response.statusCode, 404)
        XCTAssertEqual(response.errorCode, "NOT_FOUND")
    }

    func test_경로는맞고메서드만다르면_405를돌려준다() async throws {
        let sut = self.makeSUT(routes: [
            StubRouteCollection.naming("책목록", .get, ["v1", "books"])
        ])

        let response = try await sut.respond(
            to: URLRequest.make(.delete, "https://api.booksearch.dev/v1/books")
        )

        XCTAssertEqual(response.statusCode, 405)
        XCTAssertEqual(response.errorCode, "METHOD_NOT_ALLOWED")
    }

    func test_405응답은_허용메서드를Allow헤더에담는다() async throws {
        let sut = self.makeSUT(routes: [
            StubRouteCollection.naming("조회", .get, ["v1", "favorites"]),
            StubRouteCollection.naming("추가", .post, ["v1", "favorites"]),
        ])

        let response = try await sut.respond(
            to: URLRequest.make(.delete, "https://api.booksearch.dev/v1/favorites")
        )

        XCTAssertEqual(response.headers["Allow"], "GET, POST")
    }

    func test_세그먼트개수가다르면_경로가일치하지않는다() async throws {
        let sut = self.makeSUT(routes: [
            StubRouteCollection.naming("책목록", .get, ["v1", "books"])
        ])

        let response = try await sut.respond(
            to: URLRequest.get("https://api.booksearch.dev/v1/books/1/reviews")
        )

        XCTAssertEqual(response.statusCode, 404)
    }

    func test_고정세그먼트가_파라미터보다먼저매칭된다() async throws {
        let sut = self.makeSUT(routes: [
            StubRouteCollection.naming("단건", .get, ["v1", "books", .parameter("isbn")]),
            StubRouteCollection.naming("인기", .get, ["v1", "books", "popular"]),
        ])

        let response = try await sut.respond(
            to: URLRequest.get("https://api.booksearch.dev/v1/books/popular")
        )

        XCTAssertEqual(String(data: response.body, encoding: .utf8), "인기")
    }

    func test_고정라우트에걸리지않는값은_파라미터라우트가받는다() async throws {
        let sut = self.makeSUT(routes: [
            StubRouteCollection.naming("단건", .get, ["v1", "books", .parameter("isbn")]),
            StubRouteCollection.naming("인기", .get, ["v1", "books", "popular"]),
        ])

        let response = try await sut.respond(
            to: URLRequest.get("https://api.booksearch.dev/v1/books/9788937473135")
        )

        XCTAssertEqual(String(data: response.body, encoding: .utf8), "단건")
    }

    func test_미들웨어는_앞이바깥이다() async throws {
        let trace = Locked<[String]>([])
        let sut = self.makeSUT(
            routes: [StubRouteCollection.naming("핸들러", .get, ["v1", "books"])],
            middlewares: [
                TracingMiddleware(name: "바깥", trace: trace),
                TracingMiddleware(name: "안쪽", trace: trace),
            ]
        )

        _ = try await sut.respond(to: URLRequest.get("https://api.booksearch.dev/v1/books"))

        XCTAssertEqual(
            trace.value,
            ["바깥-진입", "안쪽-진입", "안쪽-이탈", "바깥-이탈"]
        )
    }

    func test_예외변환은_가장안쪽에서일어난다() async throws {
        let observed = Locked<Int?>(nil)
        let sut = self.makeSUT(
            routes: [
                MockRoute(.get, ["v1", "books"]) { _ in
                    throw ServerError.notFound("없다")
                }
            ],
            middlewares: [StatusObservingMiddleware(observed: observed)]
        )

        _ = try await sut.respond(to: URLRequest.get("https://api.booksearch.dev/v1/books"))

        XCTAssertEqual(observed.value, 404)
    }

    func test_라우트를찾지못한요청도_미들웨어를지난다() async throws {
        let observed = Locked<Int?>(nil)
        let sut = self.makeSUT(
            routes: [StubRouteCollection.naming("책목록", .get, ["v1", "books"])],
            middlewares: [StatusObservingMiddleware(observed: observed)]
        )

        _ = try await sut.respond(to: URLRequest.get("https://api.booksearch.dev/v1/없는것"))

        XCTAssertEqual(observed.value, 404)
    }

    func test_핸들러가정체모를오류를던지면_500으로바꾸고상세를숨긴다() async throws {
        struct InternalTrouble: Error { let sensitiveValue = "DB 비밀번호" }
        let sut = self.makeSUT(routes: [
            MockRoute(.get, ["v1", "books"]) { _ in throw InternalTrouble() }
        ])

        let response = try await sut.respond(to: URLRequest.get("https://api.booksearch.dev/v1/books"))

        XCTAssertEqual(response.statusCode, 500)
        XCTAssertEqual(response.errorCode, "INTERNAL_ERROR")
        let body = String(data: response.body, encoding: .utf8) ?? ""
        XCTAssertFalse(body.contains("DB 비밀번호"))
    }

    func test_취소는_응답으로바꾸지않고그대로올린다() async {
        let sut = self.makeSUT(routes: [
            MockRoute(.get, ["v1", "books"]) { _ in throw CancellationError() }
        ])

        do {
            _ = try await sut.respond(to: URLRequest.get("https://api.booksearch.dev/v1/books"))
            XCTFail("취소가 전달되어야 한다")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }

    func test_URL이없는요청은_400을돌려준다() async throws {
        let sut = self.makeSUT(routes: [])

        let response = try await sut.respond(to: URLRequest(url: URL(string: "about:blank")!))

        XCTAssertGreaterThanOrEqual(response.statusCode, 400)
    }
}

private struct TracingMiddleware: MockMiddleware {
    let name: String
    let trace: Locked<[String]>

    func respond(to request: MockRequest, next: MockResponder) async throws -> MockHTTPResponse {
        self.trace.withValue { $0.append("\(self.name)-진입") }
        let response = try await next(request)
        self.trace.withValue { $0.append("\(self.name)-이탈") }
        return response
    }
}

private struct StatusObservingMiddleware: MockMiddleware {
    let observed: Locked<Int?>

    func respond(to request: MockRequest, next: MockResponder) async throws -> MockHTTPResponse {
        let response = try await next(request)
        self.observed.withValue { $0 = response.statusCode }
        return response
    }
}

extension URLRequest {
    static func get(_ urlString: String) -> URLRequest {
        URLRequest(url: URL(string: urlString)!)
    }

    static func make(_ method: HTTPMethod, _ urlString: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = method.rawValue
        request.httpBody = body
        return request
    }
}
