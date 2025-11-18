import UIKit

import BookDetailFeatureInterface
import BookModel
import FavoriteFeature
import FavoriteFeatureInterface
import MemoFeature
import MemoFeatureInterface
import RecentlyViewedFeature
import RecentlyViewedFeatureInterface
import SearchFeature
import SearchFeatureInterface

@MainActor
final class SceneFactory {
    private let container: ApplicationContainer

    init(container: ApplicationContainer) {
        self.container = container
    }

    func makeSearchScene(onSelectBook: @escaping (Book) -> Void) -> UIViewController {
        self.container.searchSceneBuilder.makeScene { action in
            switch action {
            case let .didSelectBook(book):
                onSelectBook(book)
            }
        }
    }

    func makeFavoriteScene(onSelectBook: @escaping (Book) -> Void) -> UIViewController {
        self.container.favoriteSceneBuilder.makeScene { action in
            switch action {
            case let .didSelectBook(book):
                onSelectBook(book)
            }
        }
    }

    func makeMemoScene(onSelectBook: @escaping (Book) -> Void) -> UIViewController {
        self.container.memoSceneBuilder.makeScene { action in
            switch action {
            case let .didSelectBook(book):
                onSelectBook(book)
            }
        }
    }

    func makeRecentlyViewedScene(onSelectBook: @escaping (Book) -> Void) -> UIViewController {
        self.container.recentlyViewedSceneBuilder.makeScene { action in
            switch action {
            case let .didSelectBook(book):
                onSelectBook(book)
            }
        }
    }

    func makeBookDetailScene(
        _ payload: BookDetailPayload,
        onRequestMemoEdit: @escaping (Book) -> Void
    ) -> UIViewController {
        self.container.bookDetailSceneBuilder.makeScene(payload) { action in
            switch action {
            case let .didRequestMemoEdit(book):
                onRequestMemoEdit(book)
            }
        }
    }

    func makeMemoEditScene(book: Book, onFinish: @escaping () -> Void) -> UIViewController {
        self.container.memoEditSceneBuilder.makeScene(book: book) { action in
            switch action {
            case .didFinish:
                onFinish()
            }
        }
    }
}
