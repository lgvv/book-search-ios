import UIKit

import BookModel

public enum MemoEditDelegateAction: Sendable, Equatable {
    case didFinish
}

@MainActor
public protocol MemoEditSceneBuildable {
    func makeScene(
        book: Book,
        onDelegate: @escaping (MemoEditDelegateAction) -> Void
    ) -> UIViewController
}
