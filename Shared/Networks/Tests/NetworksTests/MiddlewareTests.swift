import XCTest

import NetworksInterface
import TestSupport

@testable import Networks

final class StatusCodeValidationMiddlewareTests: XCTestCase {

    private func respond(statusCode: Int) async throws -> HTTPResponse {
        let sut = HTTPClient(
            transport: StubTransport(statusCode: statusCode),
            middlewares: [StatusCodeValidationMiddleware()]
        )
        return try await sut.response(for: .sample())
    }

    func test_2xx응답은_그대로통과시킨다() async throws {
        let response = try await respond(statusCode: 200)

        XCTAssertEqual(response.statusCode, 200)
    }

    func test_경계값인200과299는_모두성공으로본다() async throws {
        for code in [200, 201, 204, 299] {
            let response = try await respond(statusCode: code)
            XCTAssertEqual(response.statusCode, code)
        }
    }

    func test_300이상이면_unacceptableStatusCode로실패한다() async {
        for code in [300, 400, 404, 409, 500, 503] {
            do {
                _ = try await respond(statusCode: code)
                XCTFail("\(code)는 실패해야 한다")
            } catch let failure as HTTPFailure {
                guard case let HTTPClientError.unacceptableStatusCode(reported) = failure.error else {
                    return XCTFail("unacceptableStatusCode여야 한다: \(failure.error)")
                }
                XCTAssertEqual(reported, code)
            } catch {
                XCTFail("HTTPFailure여야 한다: \(error)")
            }
        }
    }

    func test_200미만이면_실패로본다() async {
        do {
            _ = try await respond(statusCode: 199)
            XCTFail("실패해야 한다")
        } catch let failure as HTTPFailure {
            guard case HTTPClientError.unacceptableStatusCode(199) = failure.error else {
                return XCTFail("unacceptableStatusCode(199)여야 한다: \(failure.error)")
            }
        } catch {
            XCTFail("HTTPFailure여야 한다: \(error)")
        }
    }

    func test_실패해도_응답본문을잃지않는다() async {
        let body = Data(#"{"code":"ALREADY_EXISTS"}"#.utf8)
        let sut = HTTPClient(
            transport: StubTransport(statusCode: 409, body: body),
            middlewares: [StatusCodeValidationMiddleware()]
        )

        do {
            _ = try await sut.response(for: .sample())
            XCTFail("실패해야 한다")
        } catch let failure as HTTPFailure {
            XCTAssertEqual(failure.response?.body, body)
            XCTAssertEqual(failure.response?.statusCode, 409)
        } catch {
            XCTFail("HTTPFailure여야 한다: \(error)")
        }
    }
}

final class RequestIDMiddlewareTests: XCTestCase {

    func test_요청에ID가없으면_새ID를헤더에싣는다() async throws {
        let transport = StubTransport()
        let sut = HTTPClient(transport: transport, middlewares: [RequestIDMiddleware()])

        _ = try await sut.response(for: .sample())

        let identifier = transport.receivedRequests.value.first?.headers[RequestIDMiddleware.headerName]
        XCTAssertNotNil(identifier)
        XCTAssertNotNil(UUID(uuidString: identifier ?? ""))
    }

    func test_호출부가이미ID를넣었으면_덮어쓰지않는다() async throws {
        let transport = StubTransport()
        let sut = HTTPClient(transport: transport, middlewares: [RequestIDMiddleware()])
        let request = HTTPRequest(
            method: .get,
            url: URL(string: "https://api.booksearch.dev/books")!,
            headers: [RequestIDMiddleware.headerName: "호출부-ID"]
        )

        _ = try await sut.response(for: request)

        XCTAssertEqual(
            transport.receivedRequests.value.first?.headers[RequestIDMiddleware.headerName],
            "호출부-ID"
        )
    }

    func test_요청이두번나가면_서로다른ID를싣는다() async throws {
        let transport = StubTransport()
        let sut = HTTPClient(transport: transport, middlewares: [RequestIDMiddleware()])

        _ = try await sut.response(for: .sample())
        _ = try await sut.response(for: .sample())

        let identifiers = transport.receivedRequests.value.compactMap {
            $0.headers[RequestIDMiddleware.headerName]
        }
        XCTAssertEqual(identifiers.count, 2)
        XCTAssertNotEqual(identifiers[0], identifiers[1])
    }

    func test_전송이실패해도_실제로나간ID붙은요청으로실패를기록한다() async {
        struct Offline: Error {}
        let sut = HTTPClient(
            transport: StubTransport(failure: Offline()),
            middlewares: [RequestIDMiddleware()]
        )

        do {
            _ = try await sut.response(for: .sample())
            XCTFail("실패해야 한다")
        } catch let failure as HTTPFailure {
            XCTAssertNotNil(failure.request.headers[RequestIDMiddleware.headerName])
        } catch {
            XCTFail("HTTPFailure여야 한다: \(error)")
        }
    }
}

final class HTTPRequestFactoryTests: XCTestCase {

    func test_메서드와URL을_URLRequest에그대로옮긴다() throws {
        let request = HTTPRequest(
            method: .delete,
            url: URL(string: "https://api.booksearch.dev/favorites/9788937473135")!
        )

        let urlRequest = try HTTPRequestFactory.makeURLRequest(from: request)

        XCTAssertEqual(urlRequest.httpMethod, "DELETE")
        XCTAssertEqual(
            urlRequest.url?.absoluteString,
            "https://api.booksearch.dev/favorites/9788937473135"
        )
    }

    func test_헤더를_URLRequest에모두옮긴다() throws {
        let request = HTTPRequest(
            method: .post,
            url: URL(string: "https://api.booksearch.dev/favorites")!,
            headers: ["Content-Type": "application/json", "X-Request-ID": "abc"]
        )

        let urlRequest = try HTTPRequestFactory.makeURLRequest(from: request)

        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "X-Request-ID"), "abc")
    }

    func test_본문이있으면_그대로싣고없으면비운다() throws {
        let body = Data(#"{"isbn":"9788937473135"}"#.utf8)
        let withBody = HTTPRequest(
            method: .post,
            url: URL(string: "https://api.booksearch.dev/favorites")!,
            body: body
        )
        let withoutBody = HTTPRequest.sample()

        let bodied = try HTTPRequestFactory.makeURLRequest(from: withBody)
        let bodiless = try HTTPRequestFactory.makeURLRequest(from: withoutBody)

        XCTAssertEqual(bodied.httpBody, body)
        XCTAssertNil(bodiless.httpBody)
    }

    func test_질의문자열이있는URL도_그대로보존한다() throws {
        let urlString = "https://api.booksearch.dev/books/search?query=%EB%AF%BC%EC%9D%8C%EC%82%AC&page=2"
        let request = HTTPRequest(method: .get, url: URL(string: urlString)!)

        let urlRequest = try HTTPRequestFactory.makeURLRequest(from: request)

        XCTAssertEqual(urlRequest.url?.absoluteString, urlString)
    }
}
