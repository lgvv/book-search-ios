import Foundation

struct DeepLinkParser: Sendable {
    private let parsers: [any DeepLinkParsing]

    init(parsers: [any DeepLinkParsing]) {
        self.parsers = parsers
    }

    static func standard(universalLinkHosts: Set<String>) -> Self {
        DeepLinkParser(parsers: [
            BookSearchSchemeParser(),
            KakaoLinkParser(),
            UniversalLinkParser(allowedHosts: universalLinkHosts),
        ])
    }

    func parse(_ url: URL) -> (any Route)? {
        for parser in self.parsers {
            if let route = parser.parse(url) {
                return route
            }
        }
        return nil
    }
}
