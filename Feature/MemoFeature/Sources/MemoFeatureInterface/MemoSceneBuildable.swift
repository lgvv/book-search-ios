import UIKit

import BookModel

public enum MemoDelegateAction: Sendable, Equatable {
    case didSelectBook(Book)
}

@MainActor
public protocol MemoSceneBuildable {
    func makeScene(onDelegate: @escaping (MemoDelegateAction) -> Void) -> UIViewController
}
