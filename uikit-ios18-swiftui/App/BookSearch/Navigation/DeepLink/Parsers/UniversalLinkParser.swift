import Foundation

struct UniversalLinkParser: DeepLinkParsing {
    private let allowedHosts: Set<String>

    init(allowedHosts: Set<String>) {
        self.allowedHosts = allowedHosts
    }

    func parse(_ url: URL) -> (any Route)? {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }
        guard let host = url.host?.lowercased(), self.allowedHosts.contains(host) else {
            return nil
        }
        guard let isbn = url.deepLinkPathISBN else { return nil }
        return BookDetailByISBNRoute(isbn: isbn)
    }
}
