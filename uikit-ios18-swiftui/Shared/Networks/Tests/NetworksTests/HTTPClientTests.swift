import Foundation
import Testing

import NetworksInterface
import TestSupport

@testable import Networks

struct HTTPClientTests {

    private struct ResponseBody: Decodable, Equatable {
        let title: String
    }

    @Test
    func 미들웨어는_등록순서대로요청을감싸고역순으로응답을받는다() async throws {
        let trace = Locked<[String]>([])
        let sut = HTTPClient(
            transport: StubTransport(),
            middlewares: [
                TracingMiddleware(name: "바깥", trace: trace),
                TracingMiddleware(name: "가운데", trace: trace),
                TracingMiddleware(name: "안쪽", trace: trace),
            ]
        )

        _ = try await sut.response(for: .sample())

        #expect(trace.value == ["바깥-요청", "가운데-요청", "안쪽-요청", "안쪽-응답", "가운데-응답", "바깥-응답"])
    }

    @Test
    func 미들웨어가요청을바꾸면_바뀐요청이전송계층에도착한다() async throws {
        let transport = StubTransport()
        let sut = HTTPClient(
            transport: transport,
            middlewares: [HeaderStampingMiddleware(key: "X-Test", value: "표식")]
        )

        _ = try await sut.response(for: .sample())

        #expect(transport.receivedRequests.value.first?.headers["X-Test"] == "표식")
    }

    @Test
    func 미들웨어가없어도_요청이전송계층에도착한다() async throws {
        let transport = StubTransport()
        let sut = HTTPClient(transport: transport, middlewares: [])

        _ = try await sut.response(for: .sample())

        #expect(transport.receivedRequests.value.count == 1)
    }

    @Test
    func 전송계층을교체하면_미들웨어는그대로유지된다() async throws {
        let trace = Locked<[String]>([])
        let original = HTTPClient(
            transport: StubTransport(),
            middlewares: [TracingMiddleware(name: "유지", trace: trace)]
        )
        let replacement = StubTransport()

        let sut = original.replacingTransport(replacement)
        _ = try await sut.response(for: .sample())

        #expect(replacement.receivedRequests.value.count == 1)
        #expect(trace.value == ["유지-요청", "유지-응답"])
    }

    @Test
    func 전송이던지면_HTTPFailure로감싸서전달한다() async {
        struct Offline: Error {}
        let sut = HTTPClient(transport: StubTransport(failure: Offline()), middlewares: [])

        do {
            _ = try await sut.response(for: .sample())
            Issue.record("실패해야 한다")
        } catch let failure as HTTPFailure {
            #expect(failure.error is Offline)
            #expect(failure.response == nil)
            #expect(failure.request.url.absoluteString == "https://api.booksearch.dev/books")
        } catch {
            Issue.record("HTTPFailure로 감싸져야 한다: \(error)")
        }
    }

    @Test
    func 이미HTTPFailure인오류는_두번감싸지않는다() async {
        let request = HTTPRequest.sample()
        let inner = HTTPFailure(
            request: request,
            response: HTTPResponse(requestURL: request.url, statusCode: 409, headers: [:], body: nil),
            error: HTTPClientError.unacceptableStatusCode(409)
        )
        let sut = HTTPClient(transport: StubTransport(failure: inner), middlewares: [])

        do {
            _ = try await sut.response(for: request)
            Issue.record("실패해야 한다")
        } catch let failure as HTTPFailure {
            #expect(failure.response?.statusCode == 409)
            #expect(!(failure.error is HTTPFailure))
        } catch {
            Issue.record("HTTPFailure여야 한다: \(error)")
        }
    }

    @Test
    func 본문이올바른JSON이면_디코딩해서돌려준다() async throws {
        let body = Data(#"{"title":"파친코"}"#.utf8)
        let sut = HTTPClient(transport: StubTransport(body: body), middlewares: [])

        let decoded: ResponseBody = try await sut.send(request: .sample())

        #expect(decoded == ResponseBody(title: "파친코"))
    }

    @Test
    func 본문이없으면_missingResponseData로실패한다() async {
        let sut = HTTPClient(transport: StubTransport(body: nil), middlewares: [])

        do {
            let _: ResponseBody = try await sut.send(request: .sample())
            Issue.record("실패해야 한다")
        } catch let failure as HTTPFailure {
            guard case HTTPClientError.missingResponseData = failure.error else {
                Issue.record("missingResponseData여야 한다: \(failure.error)")
                return
            }
            #expect(failure.response != nil)
        } catch {
            Issue.record("HTTPFailure여야 한다: \(error)")
        }
    }

    @Test
    func 디코딩에실패하면_원본데이터를실어서알린다() async {
        let body = Data(#"{"제목":"파친코"}"#.utf8)
        let sut = HTTPClient(transport: StubTransport(body: body), middlewares: [])

        do {
            let _: ResponseBody = try await sut.send(request: .sample())
            Issue.record("실패해야 한다")
        } catch let failure as HTTPFailure {
            guard case let HTTPClientError.decodingFailed(_, data) = failure.error else {
                Issue.record("decodingFailed여야 한다: \(failure.error)")
                return
            }
            #expect(data == body)
        } catch {
            Issue.record("HTTPFailure여야 한다: \(error)")
        }
    }

    @Test
    func send도_전송오류를HTTPFailure로감싼다() async {
        struct Offline: Error {}
        let sut = HTTPClient(transport: StubTransport(failure: Offline()), middlewares: [])

        do {
            let _: ResponseBody = try await sut.send(request: .sample())
            Issue.record("실패해야 한다")
        } catch let failure as HTTPFailure {
            #expect(failure.error is Offline)
        } catch {
            Issue.record("HTTPFailure여야 한다: \(error)")
        }
    }
}
