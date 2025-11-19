import Foundation

import NetworksInterface

enum BookSearchError: Error {
    case invalidRequest
}

struct BookAPIService: Sendable {
    let baseURL: URL
    let pageSize: Int

    func searchRequest(query: String, page: Int) throws -> HTTPRequest {
        var components = URLComponents(
            url: self.baseURL.appendingPathComponent("v1/books"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(self.pageSize))
        ]
        guard let url = components?.url else {
            throw BookSearchError.invalidRequest
        }
        return HTTPRequest(method: .get, url: url)
    }

    func bookRequest(isbn: String) -> HTTPRequest {
        let url = self.baseURL
            .appendingPathComponent("v1/books")
            .appendingPathComponent(isbn)
        return HTTPRequest(method: .get, url: url)
    }
}
