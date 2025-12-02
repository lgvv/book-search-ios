import UIKit

import BookModel

public enum SearchDelegateAction: Sendable, Equatable {
    case didSelectBook(Book)
}

@MainActor
public protocol SearchSceneBuildable {
    func makeScene(onDelegate: @escaping (SearchDelegateAction) -> Void) -> UIViewController
}
