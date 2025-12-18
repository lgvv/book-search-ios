import Foundation
import Testing

import DependencyResolver

@testable import BookSearch

struct DeepLinkParserTests {

    private let hosts: Set<String> = ["booksearch.app", "www.booksearch.app"]

    private func parse(_ string: String) -> (any Route)? {
        guard let url = URL(string: string) else { return nil }
        return withResolver(from: .test) { _ in } operation: {
            DeepLinkParser.standard(universalLinkHosts: self.hosts).parse(url)
        }
    }

    @Test
    func 자체스킴의도서링크를_상세로해석한다() {
        let route = self.parse("booksearch://book/9788937400018")

        #expect(route is BookDetailByISBNRoute)
    }

    @Test
    func 모르는스킴은_해석하지않는다() {
        #expect(self.parse("unknown://book/9788937400018") == nil)
    }

    @Test
    func 허용호스트의링크만_해석한다() {
        let allowed = self.parse("https://booksearch.app/book/9788937400018")
        let foreign = self.parse("https://evil.example.com/book/9788937400018")

        #expect(allowed is BookDetailByISBNRoute)
        #expect(foreign == nil)
    }

    @Test
    func 호스트대소문자는_무시한다() {
        #expect(self.parse("https://BookSearch.App/book/9788937400018") is BookDetailByISBNRoute)
    }

    @Test
    func ISBN13숫자13자리를_통과시킨다() {
        #expect(self.parse("booksearch://book/9788937400018") is BookDetailByISBNRoute)
    }

    @Test
    func 하이픈이있어도_걷어내고통과시킨다() {
        #expect(self.parse("booksearch://book/978-89-374-0001-8") is BookDetailByISBNRoute)
    }

    @Test
    func ISBN10의체크문자X를_허용한다() {
        #expect(self.parse("booksearch://book/097522980X") is BookDetailByISBNRoute)
    }

    @Test
    func 자리수가맞지않으면_해석하지않는다() {
        #expect(self.parse("booksearch://book/12345") == nil)
        #expect(self.parse("booksearch://book/97889374000181234") == nil)
    }

    @Test
    func 경로주입시도를_걸러낸다() {
        #expect(self.parse("booksearch://book/..%2F..%2Fadmin") == nil)
        #expect(self.parse("booksearch://book/9788937400018%2F..") == nil)
    }

    @Test
    func 숫자가아닌13자리는_해석하지않는다() {
        #expect(self.parse("booksearch://book/abcdefghijklm") == nil)
    }

    @Test
    func 앞선파서가해석하면_뒤는보지않는다() {
        let route = self.parse("kakaolink://book?isbn=9788937400018")

        #expect(route is BookDetailByISBNRoute)
    }
}
