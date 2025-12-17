import UIKit

import BookModel
import BookDetailFeature
import BookDetailFeatureInterface
import FavoriteFeature
import FavoriteFeatureInterface
import MemoFeature
import MemoFeatureInterface
import RecentlyViewedFeature
import RecentlyViewedFeatureInterface
import SearchFeature
import SearchFeatureInterface

extension SceneFactory {
    static func live(container: ApplicationContainer) -> Self {
        Self(
            makeSearchScene: { onSelectBook in
                container.searchSceneBuilder.makeScene { action in
                    switch action {
                    case let .didSelectBook(book):
                        onSelectBook(book)
                    }
                }
            },
            makeFavoriteScene: { onSelectBook in
                container.favoriteSceneBuilder.makeScene { action in
                    switch action {
                    case let .didSelectBook(book):
                        onSelectBook(book)
                    }
                }
            },
            makeMemoScene: { onSelectBook in
                container.memoSceneBuilder.makeScene { action in
                    switch action {
                    case let .didSelectBook(book):
                        onSelectBook(book)
                    }
                }
            },
            makeRecentlyViewedScene: { onSelectBook in
                container.recentlyViewedSceneBuilder.makeScene { action in
                    switch action {
                    case let .didSelectBook(book):
                        onSelectBook(book)
                    }
                }
            },
            makeBookDetailScene: { payload, onRequestMemoEdit in
                container.bookDetailSceneBuilder.makeScene(payload) { action in
                    switch action {
                    case let .didRequestMemoEdit(book):
                        onRequestMemoEdit(book)
                    }
                }
            },
            makeMemoEditScene: { book, onFinish in
                container.memoEditSceneBuilder.makeScene(book: book) { action in
                    switch action {
                    case .didFinish:
                        onFinish()
                    }
                }
            }
        )
    }
}
