import UIKit

import BookModel
import CommonUI
import FavoriteCore

@MainActor
final class AppRouter: Navigator {
    var rootViewController: UIViewController { self.tabBarController }

    private let tabBarController = UITabBarController()

    private var navigationControllers: [AppTab: UINavigationController] = [:]
    private let scenes: SceneFactory

    private var routingTask: Task<Void, Never>?

    private var routeGeneration = 0

    private let loading = LoadingOverlay()
    private let toasts = ToastPresenter()

    private var failureObservation: Task<Void, Never>?

    private let favoriteClient: FavoriteClient

    private lazy var deepLinks = DeepLinkHandler(
        navigator: self,
        parser: .standard(universalLinkHosts: self.universalLinkHosts)
    )

    private let universalLinkHosts: Set<String>

    init(
        scenes: SceneFactory,
        favoriteClient: FavoriteClient,
        universalLinkHosts: Set<String>
    ) {
        self.scenes = scenes
        self.favoriteClient = favoriteClient
        self.universalLinkHosts = universalLinkHosts
    }

    deinit {
        self.failureObservation?.cancel()
    }

    func start() {
        for tab in AppTab.allCases {
            let root = self.makeTabRoot(tab)
            root.tabBarItem = UITabBarItem(
                title: tab.title,
                image: UIImage(systemName: tab.systemImage),
                tag: tab.rawValue
            )
            self.navigationControllers[tab] = UINavigationController(rootViewController: root)
        }
        self.tabBarController.viewControllers = AppTab.allCases.compactMap {
            self.navigationControllers[$0]
        }

        self.observeFavoriteWriteFailures()
    }

    private func observeFavoriteWriteFailures() {
        self.failureObservation = Task { [weak self, favoriteClient] in
            for await failure in favoriteClient.observeFailures() {
                guard let self else { return }
                let message = failure.desiredIsFavorite
                    ? "즐겨찾기에 추가하지 못했습니다"
                    : "즐겨찾기에서 제거하지 못했습니다"
                self.toasts.show(
                    message,
                    over: self.tabBarController.view,
                    bottomInset: self.tabBarController.tabBar.bounds.height + 16
                )
            }
        }
    }

    func handle(deepLink url: URL) {
        self.deepLinks.handle(url)
    }

    func navigate(to route: any Route) {
        let context = RouteContext(scenes: self.scenes, navigator: self)

        self.routeGeneration += 1
        let generation = self.routeGeneration

        self.routingTask?.cancel()
        self.routingTask = Task { [weak self] in
            guard let self else { return }
            let session = self.loading.begin(over: self.tabBarController.topmostPresentedViewController.view)
            defer { self.loading.end(session) }

            do {
                let viewController = try await route.makeViewController(context: context)
                guard !Task.isCancelled, generation == self.routeGeneration else { return }

                if route.presentation.requiresViewController, viewController == nil {
                    self.notifyFailure(of: route, kind: .notFound)
                    return
                }
                self.present(viewController, using: route.presentation, generation: generation)
            } catch {
                guard !Task.isCancelled, generation == self.routeGeneration else { return }
                self.notifyFailure(of: route, kind: .unavailable)
            }
        }
    }

    private func notifyFailure(of route: any Route, kind: RouteFailureKind) {
        guard let message = route.failureMessage else { return }

        let alert: Alert = switch kind {
        case .notFound:
            .notice(message: message.text(for: kind))

        case .unavailable:
            .retry(message: message.text(for: kind)) { [weak self] in
                self?.navigate(to: route)
            }
        }
        self.tabBarController.presentAlert(alert)
    }

    func pop() {
        self.currentNavigationController.popViewController(animated: true)
    }

    func dismiss() {
        self.tabBarController.dismiss(animated: true)
    }

    private func present(
        _ viewController: UIViewController?,
        using presentation: RoutePresentation,
        generation: Int
    ) {
        switch presentation {
        case .push:
            guard let viewController else { return }
            self.currentNavigationController.pushViewController(viewController, animated: true)

        case .selectTab(let tab):
            self.tabBarController.dismiss(animated: false)
            self.tabBarController.selectedIndex = tab.rawValue

        case .modal:
            guard let viewController else { return }
            self.presentModally(viewController, generation: generation)
        }
    }

    private func presentModally(_ viewController: UIViewController, generation: Int) {
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in
                self?.dismiss()
            }
        )
        let wrapped = UINavigationController(rootViewController: viewController)

        if self.tabBarController.presentedViewController != nil {
            self.tabBarController.dismiss(animated: false) { [weak self] in
                guard let self, generation == self.routeGeneration else { return }
                self.tabBarController.present(wrapped, animated: true)
            }
        } else {
            self.tabBarController.present(wrapped, animated: true)
        }
    }

    private var currentNavigationController: UINavigationController {
        if let presented = self.tabBarController.presentedViewController as? UINavigationController {
            return presented
        }
        return self.tabBarController.selectedViewController as? UINavigationController
            ?? self.navigationControllers[.search]!
    }

    private func makeTabRoot(_ tab: AppTab) -> UIViewController {
        let onSelectBook: (Book) -> Void = { [weak self] book in
            self?.navigate(to: BookDetailRoute(book: book))
        }
        switch tab {
        case .search:
            return self.scenes.makeSearchScene(onSelectBook)
        case .favorite:
            return self.scenes.makeFavoriteScene(onSelectBook)
        case .memo:
            return self.scenes.makeMemoScene(onSelectBook)
        case .recentlyViewed:
            return self.scenes.makeRecentlyViewedScene(onSelectBook)
        }
    }
}
