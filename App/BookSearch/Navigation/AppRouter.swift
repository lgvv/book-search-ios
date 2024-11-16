import UIKit

import BookModel
import CommonUI
import FavoriteCore

@MainActor
final class AppRouter {
    let rootViewController = UITabBarController()

    private var navigationControllers: [AppTab: UINavigationController] = [:]
    private let scenes: SceneFactory

    private let toasts = ToastPresenter()

    private var failureObservation: Task<Void, Never>?

    private let favoriteClient: FavoriteClient

    init(container: ApplicationContainer) {
        self.scenes = SceneFactory(container: container)
        self.favoriteClient = container.favoriteClient
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
        self.rootViewController.viewControllers = AppTab.allCases.compactMap {
            self.navigationControllers[$0]
        }

        self.observeFavoriteWriteFailures()
    }

    private func observeFavoriteWriteFailures() {
        self.failureObservation = Task { [weak self, favoriteClient] in
            for await failure in favoriteClient.observeFailures().values {
                guard let self else { return }
                let message = failure.desiredIsFavorite
                    ? "즐겨찾기에 추가하지 못했습니다"
                    : "즐겨찾기에서 제거하지 못했습니다"
                self.toasts.show(
                    message,
                    over: self.rootViewController.view,
                    bottomInset: self.rootViewController.tabBar.bounds.height + 16
                )
            }
        }
    }

    private func makeTabRoot(_ tab: AppTab) -> UIViewController {
        let onSelectBook: (Book) -> Void = { _ in }
        switch tab {
        case .search:
            return self.scenes.makeSearchScene(onSelectBook: onSelectBook)
        case .favorite:
            return self.scenes.makeFavoriteScene(onSelectBook: onSelectBook)
        }
    }
}
