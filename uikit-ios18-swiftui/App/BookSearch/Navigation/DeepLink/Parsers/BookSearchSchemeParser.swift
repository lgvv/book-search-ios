import Foundation

struct BookSearchSchemeParser: DeepLinkParsing {
    func parse(_ url: URL) -> (any Route)? {
        guard url.scheme?.lowercased() == "booksearch" else { return nil }

        switch url.host?.lowercased() {
        case "book":
            guard let isbn = url.deepLinkPathISBN ?? url.deepLinkQueryISBN else { return nil }
            return BookDetailByISBNRoute(isbn: isbn)
        case "memo":
            return MemoListRoute()
        default:
            return nil
        }
    }
}
