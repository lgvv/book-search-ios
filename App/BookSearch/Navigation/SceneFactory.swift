import UIKit

import BookModel
import FavoriteFeature
import FavoriteFeatureInterface
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
}
