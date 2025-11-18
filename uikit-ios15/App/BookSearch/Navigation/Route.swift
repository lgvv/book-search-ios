import UIKit

protocol Route: Sendable {
    var presentation: RoutePresentation { get }

    var failureMessage: RouteFailureMessage? { get }

    @MainActor
    func makeViewController(context: RouteContext) async throws -> UIViewController?
}

extension Route {
    var failureMessage: RouteFailureMessage? { nil }
}

enum RouteFailureKind {
    case notFound
    case unavailable
}

struct RouteFailureMessage: Sendable {
    let notFound: String
    let unavailable: String

    init(notFound: String, unavailable: String) {
        self.notFound = notFound
        self.unavailable = unavailable
    }

    func text(for kind: RouteFailureKind) -> String {
        switch kind {
        case .notFound: self.notFound
        case .unavailable: self.unavailable
        }
    }
}

enum RoutePresentation: Sendable {
    case push
    case selectTab(AppTab)
    case modal

    var requiresViewController: Bool {
        if case .selectTab = self { return false }
        return true
    }
}

@MainActor
struct RouteContext {
    let scenes: SceneFactory
    let navigator: any Navigator
}
