import Foundation

public enum MemoLookup: Sendable, Hashable {
    case found(BookMemo)
    case notFound

    public var memo: BookMemo? {
        guard case let .found(memo) = self else { return nil }
        return memo
    }
}
