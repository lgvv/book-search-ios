import Foundation

import BookModel
import FavoriteCore
import NetworksInterface

struct RemoteFavoriteRepository: FavoriteRepository {
    let httpClient: HTTPClient
    let apiService: FavoriteAPIService

    func list() async throws -> [Book] {
        let dto: FavoriteListResponseDTO = try await self.httpClient.send(request: self.apiService.listRequest())
        return dto.items.map(\.asDomain)
    }

    func add(_ book: Book) async throws {
        do {
            _ = try await self.httpClient.response(for: self.apiService.addRequest(book))
        } catch let failure as HTTPFailure where failure.response?.statusCode == 409 {
        }
    }

    func remove(isbn: String) async throws {
        do {
            _ = try await self.httpClient.response(for: self.apiService.removeRequest(isbn: isbn))
        } catch let failure as HTTPFailure where failure.response?.statusCode == 404 {
        }
    }
}

public func makeFavoriteRepository(httpClient: HTTPClient, baseURL: URL) -> any FavoriteRepository {
    RemoteFavoriteRepository(
        httpClient: httpClient,
        apiService: FavoriteAPIService(baseURL: baseURL)
    )
}
