import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var router: AppRouter?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        guard let container = (UIApplication.shared.delegate as? AppDelegate)?.container else {
            preconditionFailure("ApplicationContainer가 없다. didFinishLaunching이 먼저 끝나야 한다")
        }

        let router = AppRouter(container: container)
        self.router = router

        let window = UIWindow(windowScene: windowScene)
        Appearance.configure(window: window)
        window.rootViewController = router.rootViewController
        window.makeKeyAndVisible()
        self.window = window

        router.start()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        self.router = nil
        self.window = nil
    }
}
