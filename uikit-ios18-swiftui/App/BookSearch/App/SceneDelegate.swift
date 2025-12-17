import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var router: AppRouter?
    private var deepLinkHandler: DeepLinkHandler?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        guard let container = (UIApplication.shared.delegate as? AppDelegate)?.container else {
            preconditionFailure("ApplicationContainer가 없다. didFinishLaunching이 먼저 끝나야 한다")
        }

        let router = AppRouter(scenes: .live(container: container), favoriteClient: container.favoriteClient)
        self.router = router
        self.deepLinkHandler = DeepLinkHandler(navigator: router)

        let window = UIWindow(windowScene: windowScene)
        Appearance.configure(window: window)
        window.rootViewController = router.rootViewController
        window.makeKeyAndVisible()
        self.window = window

        router.start()

        if let url = connectionOptions.urlContexts.first?.url {
            self.deepLinkHandler?.handle(url)
        } else if let url = connectionOptions.userActivities
            .first(where: { $0.activityType == NSUserActivityTypeBrowsingWeb })?.webpageURL {
            self.deepLinkHandler?.handle(url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        self.deepLinkHandler?.handle(url)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return }
        self.deepLinkHandler?.handle(url)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        self.deepLinkHandler = nil
        self.router = nil
        self.window = nil
    }
}
