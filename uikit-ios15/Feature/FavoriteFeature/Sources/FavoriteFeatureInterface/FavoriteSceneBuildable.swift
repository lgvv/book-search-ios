import UIKit

import BookModel

public enum FavoriteDelegateAction: Sendable, Equatable {
    case didSelectBook(Book)
}

@MainActor
public protocol FavoriteSceneBuildable {
    func makeScene(onDelegate: @escaping (FavoriteDelegateAction) -> Void) -> UIViewController
}
