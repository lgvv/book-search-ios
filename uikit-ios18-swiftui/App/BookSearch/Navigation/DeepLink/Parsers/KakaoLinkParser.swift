import Foundation

struct KakaoLinkParser: DeepLinkParsing {
    func parse(_ url: URL) -> (any Route)? {
        guard url.scheme?.lowercased() == "kakaolink" else { return nil }
        guard url.host?.lowercased() == "book" else { return nil }
        guard let isbn = url.deepLinkQueryISBN ?? url.deepLinkPathISBN else { return nil }
        return BookDetailByISBNRoute(isbn: isbn)
    }
}
