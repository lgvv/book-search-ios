import XCTest

import BookModel
import FavoriteCore
import NetworksInterface
import TestSupport

@testable import FavoriteData

final class RemoteFavoriteRepositoryTests: XCTestCase {

    private let baseURL = URL(string: "https://api.booksearch.dev")!
    private let pachinko = Book.fixture(isbn: "9788937473135", title: "파친코")

    private func makeSUT(
        _ handler: @escaping @Sendable (HTTPRequest) throws -> HTTPResponse
    ) -> (repository: any FavoriteRepository, transport: RecordingTransport) {
        let transport = RecordingTransport(handler: handler)
        let client = HTTPClient(transport: transport, middlewares: [])
        return (makeFavoriteRepository(httpClient: client, baseURL: self.baseURL), transport)
    }

    private func makeResponse(_ statusCode: Int, body: Data? = Data("{}".utf8)) -> @Sendable (HTTPRequest) throws -> HTTPResponse {
        { request in
            let response = HTTPResponse(
                requestURL: request.url,
                statusCode: statusCode,
                headers: [:],
                body: body
            )
            guard (200 ..< 300) ~= statusCode else {
                throw HTTPFailure(
                    request: request,
                    response: response,
                    error: HTTPClientError.unacceptableStatusCode(statusCode)
                )
            }
            return response
        }
    }

    func test_목록을읽으면_v1favorites를GET한다() async throws {
        let body = Data(#"{"items":[]}"#.utf8)
        let (sut, transport) = self.makeSUT(self.makeResponse(200, body: body))

        _ = try await sut.list()

        let request = try XCTUnwrap(transport.requests.value.first)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.absoluteString, "https://api.booksearch.dev/v1/favorites")
    }

    func test_응답의항목을_도메인모델로옮긴다() async throws {
        let body = Data("""
        {"items":[{"isbn":"1","title":"파친코","author":"이민진","publisher":"인플루엔셜","publishedAt":"2022.08.05","coverImageURL":"https://example.com/1.jpg","createdAt":"2024-10-15T09:00:00Z"}]}
        """.utf8)
        let (sut, _) = self.makeSUT(self.makeResponse(200, body: body))

        let books = try await sut.list()

        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?.isbn, "1")
        XCTAssertEqual(books.first?.title, "파친코")
        XCTAssertEqual(books.first?.author, "이민진")
        XCTAssertEqual(books.first?.coverImageURL?.absoluteString, "https://example.com/1.jpg")
    }

    func test_표지URL이빈문자열이면_nil로옮긴다() async throws {
        let body = Data(#"{"items":[{"isbn":"1","title":"pachinko","author":null,"publisher":null,"publishedAt":null,"coverImageURL":"","createdAt":null}]}"#.utf8)
        let (sut, _) = self.makeSUT(self.makeResponse(200, body: body))

        let books = try await sut.list()

        XCTAssertNil(books.first?.coverImageURL)
    }

    func test_목록읽기가실패하면_오류를그대로던진다() async {
        let (sut, _) = self.makeSUT(self.makeResponse(500))

        do {
            _ = try await sut.list()
            XCTFail("실패해야 한다")
        } catch {
            XCTAssertTrue(error is HTTPFailure)
        }
    }

    func test_추가하면_v1favorites에책을POST한다() async throws {
        let (sut, transport) = self.makeSUT(self.makeResponse(201))

        try await sut.add(pachinko)

        let request = try XCTUnwrap(transport.requests.value.first)
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url.absoluteString, "https://api.booksearch.dev/v1/favorites")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")

        let body = try XCTUnwrap(request.body)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["isbn"] as? String, pachinko.isbn)
        XCTAssertEqual(json["title"] as? String, pachinko.title)
    }

    func test_이미즐겨찾기에있으면_409를성공으로본다() async throws {
        let (sut, _) = self.makeSUT(self.makeResponse(409))

        try await sut.add(pachinko)
    }

    func test_추가가409외의오류로실패하면_던진다() async {
        let (sut, _) = self.makeSUT(self.makeResponse(500))

        do {
            try await sut.add(pachinko)
            XCTFail("실패해야 한다")
        } catch {
            XCTAssertTrue(error is HTTPFailure)
        }
    }

    func test_제거하면_isbn경로를DELETE한다() async throws {
        let (sut, transport) = self.makeSUT(self.makeResponse(204, body: nil))

        try await sut.remove(isbn: pachinko.isbn)

        let request = try XCTUnwrap(transport.requests.value.first)
        XCTAssertEqual(request.method, .delete)
        XCTAssertEqual(
            request.url.absoluteString,
            "https://api.booksearch.dev/v1/favorites/\(pachinko.isbn)"
        )
    }

    func test_이미없는책을제거하면_404를성공으로본다() async throws {
        let (sut, _) = self.makeSUT(self.makeResponse(404))

        try await sut.remove(isbn: pachinko.isbn)
    }

    func test_제거가404외의오류로실패하면_던진다() async {
        let (sut, _) = self.makeSUT(self.makeResponse(503))

        do {
            try await sut.remove(isbn: pachinko.isbn)
            XCTFail("실패해야 한다")
        } catch {
            XCTAssertTrue(error is HTTPFailure)
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
