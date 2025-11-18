import UIKit

import BookModel

public enum BookDetailDelegateAction: Sendable, Equatable {
    case didRequestMemoEdit(Book)
}

@MainActor
public protocol BookDetailSceneBuildable {
    func makeScene(
        _ payload: BookDetailPayload,
        onDelegate: @escaping (BookDetailDelegateAction) -> Void
    ) -> UIViewController
}
