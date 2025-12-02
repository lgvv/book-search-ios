import Foundation

struct FavoriteHandler: Sendable {
    let store: FavoriteRecordStore

    @Sendable
    func list(_ request: MockRequest) async throws -> MockHTTPResponse {
        let records = try await self.store.all()
        return try .json(200, FavoriteListServerDTO(items: records.map(FavoriteItemServerDTO.init)))
    }

    @Sendable
    func add(_ request: MockRequest) async throws -> MockHTTPResponse {
        let dto = try request.decodeBody(FavoriteItemServerDTO.self)

        guard let created = try await self.store.insertIfAbsent(dto.record(createdAt: Date())) else {
            throw ServerError.conflict(
                code: "DUPLICATE_ISBN",
                message: "이미 즐겨찾기에 있는 isbn입니다: \(dto.isbn)"
            )
        }
        return try .json(201, FavoriteItemServerDTO(created))
    }

    @Sendable
    func remove(_ request: MockRequest) async throws -> MockHTTPResponse {
        let isbn = try request.pathParameter("isbn")
        guard try await self.store.delete(isbn: isbn) else {
            throw ServerError.notFound("즐겨찾기에 없는 isbn입니다: \(isbn)")
        }
        return .noContent
    }
}

extension FavoriteHandler: MockRouteCollection {
    var routes: [MockRoute] {
        [
            MockRoute(.get, ["v1", "favorites"], handler: self.list),
            MockRoute(.post, ["v1", "favorites"], handler: self.add),
            MockRoute(.delete, ["v1", "favorites", .parameter("isbn")], handler: self.remove),
        ]
    }
}
