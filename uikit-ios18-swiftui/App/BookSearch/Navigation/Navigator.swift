import Foundation

@MainActor
protocol Navigator: AnyObject {
    func navigate(to route: any Route)
    func pop()
    func dismiss()
}
