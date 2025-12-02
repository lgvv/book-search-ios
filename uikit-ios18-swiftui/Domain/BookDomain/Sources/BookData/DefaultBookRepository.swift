import Foundation

import BookModel
import BookCore
import NetworksInterface

struct DefaultBookRepository: BookRepository {
    let httpClient: HTTPClient
    let apiService: BookAPIService

    func book(isbn: String) async throws -> Book? {
        let request = self.apiService.bookRequest(isbn: isbn)
        do {
            let dto: BookItemDTO = try await self.httpClient.send(request: request)
            return dto.asDomain
        } catch let failure as HTTPFailure where failure.response?.statusCode == 404 {
            return nil
        }
    }

    func search(query: String, page: Int) async throws -> SearchPage {
        let request = try self.apiService.searchRequest(query: query, page: page)
        let dto: BookSearchResponseDTO = try await self.httpClient.send(request: request)

        return SearchPage(
            books: dto.items.map(\.asDomain),
            pageNo: dto.page,
            totalCount: dto.totalCount,
            hasNext: dto.page * dto.pageSize < dto.totalCount
        )
    }
}

public func makeBookRepository(
    httpClient: HTTPClient,
    baseURL: URL,
    pageSize: Int = 20
) -> any BookRepository {
    DefaultBookRepository(
        httpClient: httpClient,
        apiService: BookAPIService(baseURL: baseURL, pageSize: pageSize)
    )
}
