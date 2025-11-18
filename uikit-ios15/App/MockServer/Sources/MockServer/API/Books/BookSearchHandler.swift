import Foundation

struct BookSearchHandler: Sendable {
    let catalog: BookCatalog

    @Sendable
    func search(_ request: MockRequest) async throws -> MockHTTPResponse {
        let query = try request.requiredQuery("query")
        let page = try request.query("page", default: 1)
        let size = try request.query("size", default: 20)
        guard page > 0, (1...100).contains(size) else {
            throw ServerError.badRequest("page는 1 이상, size는 1에서 100 사이여야 합니다")
        }

        let result = self.catalog.search(query: query, page: page, size: size)
        return try .json(200, BookSearchServerDTO(
            items: result.items.map(BookItemServerDTO.init),
            page: page,
            pageSize: size,
            totalCount: result.totalCount
        ))
    }

    @Sendable
    func book(_ request: MockRequest) async throws -> MockHTTPResponse {
        let isbn = try request.pathParameter("isbn")
        guard let book = self.catalog.book(isbn: isbn) else {
            throw ServerError.notFound("카탈로그에 없는 isbn입니다: \(isbn)")
        }
        return try .json(200, BookItemServerDTO(book))
    }
}

extension BookSearchHandler: MockRouteCollection {
    var routes: [MockRoute] {
        [
            MockRoute(.get, ["v1", "books"], handler: self.search),
            MockRoute(.get, ["v1", "books", .parameter("isbn")], handler: self.book),
        ]
    }
}
