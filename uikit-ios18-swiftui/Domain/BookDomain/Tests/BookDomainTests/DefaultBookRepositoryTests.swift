import Foundation
import Testing

import BookCore
import BookModel
import NetworksInterface
import TestSupport

@testable import BookData

struct DefaultBookRepositoryTests {

    private let baseURL = URL(string: "https://api.booksearch.dev")!

    private func makeSUT(
        pageSize: Int = 20,
        handler: @escaping @Sendable (HTTPRequest) throws -> HTTPResponse
    ) -> (repository: any BookRepository, transport: RecordingTransport) {
        let transport = RecordingTransport(handler: handler)
        let client = HTTPClient(transport: transport, middlewares: [])
        let repository = makeBookRepository(
            httpClient: client,
            baseURL: self.baseURL,
            pageSize: pageSize
        )
        return (repository, transport)
    }

    private func makeSearchResponse(
        items: [(isbn: String, title: String)],
        page: Int,
        pageSize: Int,
        totalCount: Int
    ) -> @Sendable (HTTPRequest) throws -> HTTPResponse {
        let itemsJSON = items.map { item in
            """
            {"isbn":"\(item.isbn)","title":"\(item.title)","author":null,"publisher":null,"publishedAt":null,"coverImageURL":null}
            """
        }.joined(separator: ",")
        let body = Data(#"{"items":[\#(itemsJSON)],"page":\#(page),"pageSize":\#(pageSize),"totalCount":\#(totalCount)}"#.utf8)
        return { request in
            HTTPResponse(requestURL: request.url, statusCode: 200, headers: [:], body: body)
        }
    }

    @Test
    func 검색하면_질의와페이지와크기를질의문자열에싣는다() async throws {
        let (sut, transport) = self.makeSUT(
            pageSize: 30,
            handler: self.makeSearchResponse(items: [], page: 2, pageSize: 30, totalCount: 0)
        )

        _ = try await sut.search(query: "민음사", page: 2)

        let request = try #require(transport.requests.value.first)
        let components = try #require(URLComponents(url: request.url, resolvingAgainstBaseURL: false))
        #expect(components.path == "/v1/books")
        #expect(components.queryItems?.first { $0.name == "query" }?.value == "민음사")
        #expect(components.queryItems?.first { $0.name == "page" }?.value == "2")
        #expect(components.queryItems?.first { $0.name == "size" }?.value == "30")
    }

    @Test
    func 한글질의도_퍼센트인코딩되어나간다() async throws {
        let (sut, transport) = self.makeSUT(
            handler: self.makeSearchResponse(items: [], page: 1, pageSize: 20, totalCount: 0)
        )

        _ = try await sut.search(query: "토지 완전판", page: 1)

        let request = try #require(transport.requests.value.first)
        #expect(request.url.absoluteString.contains("%ED%86%A0%EC%A7%80"))
    }

    @Test
    func 단건조회하면_isbn을경로에붙인다() async throws {
        let body = Data(#"{"isbn":"1","title":"파친코","author":null,"publisher":null,"publishedAt":null,"coverImageURL":null}"#.utf8)
        let (sut, transport) = self.makeSUT { request in
            HTTPResponse(requestURL: request.url, statusCode: 200, headers: [:], body: body)
        }

        _ = try await sut.book(isbn: "9788937473135")

        let request = try #require(transport.requests.value.first)
        #expect(request.url.absoluteString == "https://api.booksearch.dev/v1/books/9788937473135")
    }

    @Test
    func 받은건수가전체보다적으면_다음페이지가있다() async throws {
        let (sut, _) = self.makeSUT(
            handler: self.makeSearchResponse(
                items: [(isbn: "1", title: "책1")],
                page: 1,
                pageSize: 20,
                totalCount: 100
            )
        )

        let page = try await sut.search(query: "민음사", page: 1)

        #expect(page.hasNext)
        #expect(page.totalCount == 100)
        #expect(page.pageNo == 1)
    }

    @Test
    func 현재페이지까지의누적이전체와같으면_다음페이지가없다() async throws {
        let (sut, _) = self.makeSUT(
            handler: self.makeSearchResponse(
                items: [(isbn: "1", title: "책1")],
                page: 5,
                pageSize: 20,
                totalCount: 100
            )
        )

        let page = try await sut.search(query: "민음사", page: 5)

        #expect(!(page.hasNext))
    }

    @Test
    func 누적이전체를넘으면_다음페이지가없다() async throws {
        let (sut, _) = self.makeSUT(
            handler: self.makeSearchResponse(
                items: [(isbn: "1", title: "책1")],
                page: 6,
                pageSize: 20,
                totalCount: 100
            )
        )

        let page = try await sut.search(query: "민음사", page: 6)

        #expect(!(page.hasNext))
    }

    @Test
    func 결과가하나도없으면_빈페이지를돌려준다() async throws {
        let (sut, _) = self.makeSUT(
            handler: self.makeSearchResponse(items: [], page: 1, pageSize: 20, totalCount: 0)
        )

        let page = try await sut.search(query: "존재하지않는책", page: 1)

        #expect(page.books == [])
        #expect(page.totalCount == 0)
        #expect(!(page.hasNext))
    }

    @Test
    func 응답항목을_도메인모델로옮긴다() async throws {
        let body = Data("""
        {"items":[{"isbn":"1","title":"파친코","author":"이민진","publisher":"인플루엔셜","publishedAt":"2022.08.05","coverImageURL":"https://example.com/1.jpg"}],"page":1,"pageSize":20,"totalCount":1}
        """.utf8)
        let (sut, _) = self.makeSUT { request in
            HTTPResponse(requestURL: request.url, statusCode: 200, headers: [:], body: body)
        }

        let page = try await sut.search(query: "파친코", page: 1)

        #expect(page.books.first == Book(
                isbn: "1",
                title: "파친코",
                author: "이민진",
                publisher: "인플루엔셜",
                publishedAt: "2022.08.05",
                coverImageURL: URL(string: "https://example.com/1.jpg")
            ))
    }

    @Test
    func 표지URL이빈문자열이면_nil로옮긴다() async throws {
        let body = Data(#"{"items":[{"isbn":"1","title":"책","author":null,"publisher":null,"publishedAt":null,"coverImageURL":""}],"page":1,"pageSize":20,"totalCount":1}"#.utf8)
        let (sut, _) = self.makeSUT { request in
            HTTPResponse(requestURL: request.url, statusCode: 200, headers: [:], body: body)
        }

        let page = try await sut.search(query: "책", page: 1)

        #expect(page.books.first?.coverImageURL == nil)
    }

    @Test
    func 없는책을조회하면_404를nil로본다() async throws {
        let (sut, _) = self.makeSUT { request in
            let response = HTTPResponse(requestURL: request.url, statusCode: 404, headers: [:], body: nil)
            throw HTTPFailure(
                request: request,
                response: response,
                error: HTTPClientError.unacceptableStatusCode(404)
            )
        }

        let book = try await sut.book(isbn: "없는isbn")

        #expect(book == nil)
    }

    @Test
    func 단건조회가404외의오류로실패하면_던진다() async {
        let (sut, _) = self.makeSUT { request in
            let response = HTTPResponse(requestURL: request.url, statusCode: 500, headers: [:], body: nil)
            throw HTTPFailure(
                request: request,
                response: response,
                error: HTTPClientError.unacceptableStatusCode(500)
            )
        }

        do {
            _ = try await sut.book(isbn: "1")
            Issue.record("실패해야 한다")
        } catch {
            #expect(error is HTTPFailure)
        }
    }

    @Test
    func 검색이실패하면_던진다() async {
        let (sut, _) = self.makeSUT { request in
            let response = HTTPResponse(requestURL: request.url, statusCode: 503, headers: [:], body: nil)
            throw HTTPFailure(
                request: request,
                response: response,
                error: HTTPClientError.unacceptableStatusCode(503)
            )
        }

        do {
            _ = try await sut.search(query: "민음사", page: 1)
            Issue.record("실패해야 한다")
        } catch {
            #expect(error is HTTPFailure)
        }
    }
}

final class RecordingTransport: HTTPTransport {
    let requests = Locked<[HTTPRequest]>([])
    private let handler: @Sendable (HTTPRequest) throws -> HTTPResponse

    init(handler: @escaping @Sendable (HTTPRequest) throws -> HTTPResponse) {
        self.handler = handler
    }

    func send(request: HTTPRequest) async throws -> HTTPResponse {
        self.requests.withValue { $0.append(request) }
        return try self.handler(request)
    }
}
