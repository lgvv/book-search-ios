import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        guard let container = (UIApplication.shared.delegate as? AppDelegate)?.container else {
            preconditionFailure("ApplicationContainer가 없다. didFinishLaunching이 먼저 끝나야 한다")
        }

        let root = container.searchSceneBuilder.makeScene { _ in }

        let window = UIWindow(windowScene: windowScene)
        Appearance.configure(window: window)
        window.rootViewController = UINavigationController(rootViewController: root)
        window.makeKeyAndVisible()
        self.window = window
    }
}
