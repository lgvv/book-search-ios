import Foundation
import Testing

import TestSupport

@testable import MockServer

struct BookSearchAPITests {

    private var sut: MockRouter!

    init() {
        self.sut = MockRouter(
            collections: [BookSearchHandler(catalog: BookCatalog())],
            middlewares: []
        )
    }

    private func performSearch(_ query: String, page: Int? = nil, size: Int? = nil) async throws -> MockHTTPResponse {
        var components = URLComponents(string: "https://api.booksearch.dev/v1/books")!
        var items = [URLQueryItem(name: "query", value: query)]
        if let page { items.append(URLQueryItem(name: "page", value: "\(page)")) }
        if let size { items.append(URLQueryItem(name: "size", value: "\(size)")) }
        components.queryItems = items
        return try await self.sut.respond(to: URLRequest(url: components.url!))
    }

    @Test
    func 검색에성공하면_200과항목과페이지정보를준다() async throws {
        let response = try await self.performSearch("민음사", page: 1, size: 5)

        #expect(response.statusCode == 200)
        #expect((response.json["page"] as? Int) == 1)
        #expect((response.json["pageSize"] as? Int) == 5)
        #expect(((response.json["items"] as? [Any])?.count) == 5)
        #expect((response.json["totalCount"] as? Int) != nil)
    }

    @Test
    func 결과가없어도_200과빈배열을준다() async throws {
        let response = try await self.performSearch("존재하지않는책")

        #expect(response.statusCode == 200)
        #expect(((response.json["items"] as? [Any])?.count) == 0)
        #expect((response.json["totalCount"] as? Int) == 0)
    }

    @Test
    func page와size를주지않으면_1페이지20건을기본으로한다() async throws {
        let response = try await self.performSearch("민음사")

        #expect((response.json["page"] as? Int) == 1)
        #expect((response.json["pageSize"] as? Int) == 20)
    }

    @Test
    func query가없으면_400을준다() async throws {
        let response = try await self.sut.respond(
            to: URLRequest.get("https://api.booksearch.dev/v1/books")
        )

        #expect(response.statusCode == 400)
        #expect(response.errorCode == "BAD_REQUEST")
    }

    @Test
    func query가빈문자열이면_400을준다() async throws {
        let response = try await self.performSearch("")

        #expect(response.statusCode == 400)
    }

    @Test
    func page가0이하면_400을준다() async throws {
        let response = try await self.performSearch("민음사", page: 0)

        #expect(response.statusCode == 400)
    }

    @Test
    func size가범위를벗어나면_400을준다() async throws {
        for size in [0, 101] {
            let response = try await self.performSearch("민음사", size: size)
            #expect(response.statusCode == 400, "size=\(size)")
        }
    }

    @Test
    func size가경계값이면_통과한다() async throws {
        for size in [1, 100] {
            let response = try await self.performSearch("민음사", size: size)
            #expect(response.statusCode == 200, "size=\(size)")
        }
    }

    @Test
    func page를숫자로해석할수없으면_400을준다() async throws {
        var components = URLComponents(string: "https://api.booksearch.dev/v1/books")!
        components.queryItems = [
            URLQueryItem(name: "query", value: "민음사"),
            URLQueryItem(name: "page", value: "두번째"),
        ]

        let response = try await self.sut.respond(to: URLRequest(url: components.url!))

        #expect(response.statusCode == 400)
    }

    @Test
    func 카탈로그에있는isbn을조회하면_200과책을준다() async throws {
        let isbn = BookCatalogData.all[0].isbn

        let response = try await self.sut.respond(
            to: URLRequest.get("https://api.booksearch.dev/v1/books/\(isbn)")
        )

        #expect(response.statusCode == 200)
        #expect((response.json["isbn"] as? String) == isbn)
    }

    @Test
    func 카탈로그에없는isbn을조회하면_404를준다() async throws {
        let response = try await self.sut.respond(
            to: URLRequest.get("https://api.booksearch.dev/v1/books/없는isbn")
        )

        #expect(response.statusCode == 404)
        #expect(response.errorCode == "NOT_FOUND")
    }

    @Test
    func 퍼센트인코딩된한글질의를_해석한다() async throws {
        let url = URL(string: "https://api.booksearch.dev/v1/books?query=%EB%AF%BC%EC%9D%8C%EC%82%AC")!

        let response = try await self.sut.respond(to: URLRequest(url: url))

        #expect(response.statusCode == 200)
        #expect((response.json["totalCount"] as? Int ?? 0) > 0)
    }
}

struct ServerJSONTests {

    private struct Sample: Codable, Equatable {
        let at: Date
    }

    @Test
    func 날짜는_소수초까지담은ISO8601로직렬화된다() throws {
        let sample = Sample(at: Date(timeIntervalSince1970: 1_728_982_800.123))

        let encoded = try ServerJSON.encoder.encode(sample)
        let text = try #require(String(data: encoded, encoding: .utf8))

        #expect(text.contains("."), "소수초가 빠졌습니다: \(text)")
        #expect(text.contains("Z") || text.contains("+"), "시간대가 빠졌습니다: \(text)")
    }

    @Test
    func 직렬화한날짜를_다시읽으면같은시각이다() throws {
        let sample = Sample(at: Date(timeIntervalSince1970: 1_728_982_800.123))

        let decoded = try ServerJSON.decoder.decode(Sample.self, from: ServerJSON.encoder.encode(sample))

        #expect(decoded.at.timeIntervalSince1970 == sample.at.timeIntervalSince1970)
    }

    @Test
    func 같은밀리초안의두시각도_왕복후순서가유지된다() throws {
        let earlier = Sample(at: Date(timeIntervalSince1970: 1_728_982_800.100))
        let later = Sample(at: Date(timeIntervalSince1970: 1_728_982_800.900))

        let earlierDecoded = try ServerJSON.decoder.decode(Sample.self, from: ServerJSON.encoder.encode(earlier))
        let laterDecoded = try ServerJSON.decoder.decode(Sample.self, from: ServerJSON.encoder.encode(later))

        #expect(earlierDecoded.at < laterDecoded.at)
    }

    @Test
    func ISO8601이아닌문자열은_디코딩에실패한다() {
        let data = Data(#"{"at":"2024년 10월 15일"}"#.utf8)

        #expect(throws: (any Error).self) { try ServerJSON.decoder.decode(Sample.self, from: data) }
    }
}

struct FaultInjectionMiddlewareTests {

    private func makeSUT(profile: MockFaultProfile) -> MockRouter {
        MockRouter(
            collections: [
                StubRouteCollection(routes: [
                    StubRouteCollection.naming("읽기", .get, ["v1", "books"]),
                    StubRouteCollection.naming("쓰기", .post, ["v1", "books"]),
                ])
            ],
            middlewares: [FaultInjectionMiddleware(profile: profile)]
        )
    }

    @Test
    func 기본프로파일은_아무것도실패시키지않는다() async throws {
        let sut = self.makeSUT(profile: .disabled)

        let response = try await sut.respond(
            to: URLRequest.make(.post, "https://api.booksearch.dev/v1/books")
        )

        #expect(response.statusCode == 200)
    }

    @Test
    func 실패율이1이면_쓰기가전부실패한다() async throws {
        let sut = self.makeSUT(profile: MockFaultProfile(failureRate: 1.0, statusCodes: [503]))

        let response = try await sut.respond(
            to: URLRequest.make(.post, "https://api.booksearch.dev/v1/books")
        )

        #expect(response.statusCode == 503)
        #expect(response.errorCode == "INJECTED_FAULT")
    }

    @Test
    func 실패율이1이어도_읽기는통과한다() async throws {
        let sut = self.makeSUT(profile: MockFaultProfile(failureRate: 1.0))

        let response = try await sut.respond(to: URLRequest.get("https://api.booksearch.dev/v1/books"))

        #expect(response.statusCode == 200)
    }

    @Test
    func 주입된실패는_핸들러를부르지않는다() async throws {
        let didRun = Locked(false)
        let sut = MockRouter(
            collections: [
                StubRouteCollection(routes: [
                    MockRoute(.post, ["v1", "books"]) { _ in
                        didRun.withValue { $0 = true }
                        return MockHTTPResponse(statusCode: 200, headers: [:], body: Data())
                    }
                ])
            ],
            middlewares: [FaultInjectionMiddleware(profile: MockFaultProfile(failureRate: 1.0))]
        )

        _ = try await sut.respond(to: URLRequest.make(.post, "https://api.booksearch.dev/v1/books"))

        #expect(!(didRun.value))
    }

    @Test
    func 대상메서드를바꾸면_읽기도실패시킬수있다() async throws {
        let sut = self.makeSUT(
            profile: MockFaultProfile(failureRate: 1.0, statusCodes: [500], methodNames: ["GET"])
        )

        let response = try await sut.respond(to: URLRequest.get("https://api.booksearch.dev/v1/books"))

        #expect(response.statusCode == 500)
    }
}
