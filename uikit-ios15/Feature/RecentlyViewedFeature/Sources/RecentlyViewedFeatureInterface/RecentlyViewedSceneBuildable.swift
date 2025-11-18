import UIKit

import BookModel

public enum RecentlyViewedDelegateAction: Sendable, Equatable {
    case didSelectBook(Book)
}

@MainActor
public protocol RecentlyViewedSceneBuildable {
    func makeScene(onDelegate: @escaping (RecentlyViewedDelegateAction) -> Void) -> UIViewController
}
