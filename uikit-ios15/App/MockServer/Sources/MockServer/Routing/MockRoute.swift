import Foundation

struct MockRoute: Sendable {
    enum Segment: Sendable, ExpressibleByStringLiteral {
        case fixed(String)
        case parameter(String)

        init(stringLiteral value: String) {
            self = .fixed(value)
        }
    }

    let method: HTTPMethod
    let path: [Segment]
    let handler: MockResponder

    init(_ method: HTTPMethod, _ path: [Segment], handler: @escaping MockResponder) {
        self.method = method
        self.path = path
        self.handler = handler
    }

    func matchPath(_ components: [String]) -> [String: String]? {
        guard components.count == self.path.count else { return nil }

        var parameters: [String: String] = [:]
        for (segment, component) in zip(self.path, components) {
            switch segment {
            case .fixed(let value):
                guard component == value else { return nil }
            case .parameter(let name):
                parameters[name] = component
            }
        }
        return parameters
    }
}

extension MockRoute {
    static func isMoreSpecific(_ lhs: MockRoute, _ rhs: MockRoute) -> Bool {
        for (left, right) in zip(lhs.path, rhs.path) {
            switch (left, right) {
            case (.fixed, .parameter):
                return true
            case (.parameter, .fixed):
                return false
            default:
                continue
            }
        }
        return lhs.path.count > rhs.path.count
    }
}

protocol MockRouteCollection: Sendable {
    var routes: [MockRoute] { get }
}
