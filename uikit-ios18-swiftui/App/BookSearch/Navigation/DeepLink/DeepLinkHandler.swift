import Foundation

@MainActor
final class DeepLinkHandler {
    private weak var navigator: (any Navigator)?
    private let parser: DeepLinkParser

    init(navigator: any Navigator, parser: DeepLinkParser) {
        self.navigator = navigator
        self.parser = parser
    }

    func handle(_ url: URL) {
        guard let route = self.parser.parse(url) else { return }
        self.navigator?.navigate(to: route)
    }
}
