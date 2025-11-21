import Foundation
import Testing

import NetworksInterface
import TestSupport

@testable import Networks

struct StatusCodeValidationMiddlewareTests {

    private func respond(statusCode: Int) async throws -> HTTPResponse {
        let sut = HTTPClient(
            transport: StubTransport(statusCode: statusCode),
            middlewares: [StatusCodeValidationMiddleware()]
        )
        return try await sut.response(for: .sample())
    }

    @Test
    func 응답이2xx면_그대로통과시킨다() async throws {
        let response = try await respond(statusCode: 200)

        #expect(response.statusCode == 200)
    }

    @Test
    func 경계값인200과299는_모두성공으로본다() async throws {
        for code in [200, 201, 204, 299] {
            let response = try await respond(statusCode: code)
            #expect(response.statusCode == code)
        }
    }

    @Test
    func 상태코드가300이상이면_unacceptableStatusCode로실패한다() async {
        for code in [300, 400, 404, 409, 500, 503] {
            do {
                _ = try await respond(statusCode: code)
                Issue.record("\(code)는 실패해야 한다")
            } catch let failure as HTTPFailure {
                guard case let HTTPClientError.unacceptableStatusCode(reported) = failure.error else {
                    Issue.record("unacceptableStatusCode여야 한다: \(failure.error)")
                    return
                }
                #expect(reported == code)
            } catch {
                Issue.record("HTTPFailure여야 한다: \(error)")
            }
        }
    }

    @Test
    func 상태코드가200미만이면_실패로본다() async {
        do {
            _ = try await respond(statusCode: 199)
            Issue.record("실패해야 한다")
        } catch let failure as HTTPFailure {
            guard case HTTPClientError.unacceptableStatusCode(199) = failure.error else {
                Issue.record("unacceptableStatusCode(199)여야 한다: \(failure.error)")
                return
            }
        } catch {
            Issue.record("HTTPFailure여야 한다: \(error)")
        }
    }

    @Test
    func 실패해도_응답본문을잃지않는다() async {
        let body = Data(#"{"code":"ALREADY_EXISTS"}"#.utf8)
        let sut = HTTPClient(
            transport: StubTransport(statusCode: 409, body: body),
            middlewares: [StatusCodeValidationMiddleware()]
        )

        do {
            _ = try await sut.response(for: .sample())
            Issue.record("실패해야 한다")
        } catch let failure as HTTPFailure {
            #expect(failure.response?.body == body)
            #expect(failure.response?.statusCode == 409)
        } catch {
            Issue.record("HTTPFailure여야 한다: \(error)")
        }
    }
}

struct RequestIDMiddlewareTests {

    @Test
    func 요청에ID가없으면_새ID를헤더에싣는다() async throws {
        let transport = StubTransport()
        let sut = HTTPClient(transport: transport, middlewares: [RequestIDMiddleware()])

        _ = try await sut.response(for: .sample())

        let identifier = transport.receivedRequests.value.first?.headers[RequestIDMiddleware.headerName]
        #expect(identifier != nil)
        #expect((UUID(uuidString: identifier ?? "")) != nil)
    }

    @Test
    func 호출부가이미ID를넣었으면_덮어쓰지않는다() async throws {
        let transport = StubTransport()
        let sut = HTTPClient(transport: transport, middlewares: [RequestIDMiddleware()])
        let request = HTTPRequest(
            method: .get,
            url: URL(string: "https://api.booksearch.dev/books")!,
            headers: [RequestIDMiddleware.headerName: "호출부-ID"]
        )

        _ = try await sut.response(for: request)

        #expect(transport.receivedRequests.value.first?.headers[RequestIDMiddleware.headerName] == "호출부-ID")
    }

    @Test
    func 요청이두번나가면_서로다른ID를싣는다() async throws {
        let transport = StubTransport()
        let sut = HTTPClient(transport: transport, middlewares: [RequestIDMiddleware()])

        _ = try await sut.response(for: .sample())
        _ = try await sut.response(for: .sample())

        let identifiers = transport.receivedRequests.value.compactMap {
            $0.headers[RequestIDMiddleware.headerName]
        }
        #expect(identifiers.count == 2)
        #expect(identifiers[0] != identifiers[1])
    }

    @Test
    func 전송이실패해도_실제로나간ID붙은요청으로실패를기록한다() async {
        struct Offline: Error {}
        let sut = HTTPClient(
            transport: StubTransport(failure: Offline()),
            middlewares: [RequestIDMiddleware()]
        )

        do {
            _ = try await sut.response(for: .sample())
            Issue.record("실패해야 한다")
        } catch let failure as HTTPFailure {
            #expect(failure.request.headers[RequestIDMiddleware.headerName] != nil)
        } catch {
            Issue.record("HTTPFailure여야 한다: \(error)")
        }
    }
}

struct HTTPRequestFactoryTests {

    @Test
    func 메서드와URL을_URLRequest에그대로옮긴다() throws {
        let request = HTTPRequest(
            method: .delete,
            url: URL(string: "https://api.booksearch.dev/favorites/9788937473135")!
        )

        let urlRequest = try HTTPRequestFactory.makeURLRequest(from: request)

        #expect(urlRequest.httpMethod == "DELETE")
        #expect(urlRequest.url?.absoluteString == "https://api.booksearch.dev/favorites/9788937473135")
    }

    @Test
    func 헤더를_URLRequest에모두옮긴다() throws {
        let request = HTTPRequest(
            method: .post,
            url: URL(string: "https://api.booksearch.dev/favorites")!,
            headers: ["Content-Type": "application/json", "X-Request-ID": "abc"]
        )

        let urlRequest = try HTTPRequestFactory.makeURLRequest(from: request)

        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(urlRequest.value(forHTTPHeaderField: "X-Request-ID") == "abc")
    }

    @Test
    func 본문이있으면_그대로싣고없으면비운다() throws {
        let body = Data(#"{"isbn":"9788937473135"}"#.utf8)
        let withBody = HTTPRequest(
            method: .post,
            url: URL(string: "https://api.booksearch.dev/favorites")!,
            body: body
        )
        let withoutBody = HTTPRequest.sample()

        let bodied = try HTTPRequestFactory.makeURLRequest(from: withBody)
        let bodiless = try HTTPRequestFactory.makeURLRequest(from: withoutBody)

        #expect(bodied.httpBody == body)
        #expect(bodiless.httpBody == nil)
    }

    @Test
    func 질의문자열이있는URL도_그대로보존한다() throws {
        let urlString = "https://api.booksearch.dev/books/search?query=%EB%AF%BC%EC%9D%8C%EC%82%AC&page=2"
        let request = HTTPRequest(method: .get, url: URL(string: urlString)!)

        let urlRequest = try HTTPRequestFactory.makeURLRequest(from: request)

        #expect(urlRequest.url?.absoluteString == urlString)
    }
}
