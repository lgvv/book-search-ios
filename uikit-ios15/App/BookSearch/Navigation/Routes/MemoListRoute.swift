import UIKit

struct MemoListRoute: Route {
    var presentation: RoutePresentation { .selectTab(.memo) }

    func makeViewController(context: RouteContext) async -> UIViewController? {
        nil
    }
}
