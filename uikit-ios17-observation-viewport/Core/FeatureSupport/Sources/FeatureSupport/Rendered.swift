import Foundation

@MainActor
public struct Rendered<Value: Equatable> {
    private var value: Value?

    public init() {}

    public mutating func changed(to new: Value) -> (old: Value?, new: Value)? {
        guard self.value != new else { return nil }

        let old = self.value
        self.value = new
        return (old, new)
    }
}
