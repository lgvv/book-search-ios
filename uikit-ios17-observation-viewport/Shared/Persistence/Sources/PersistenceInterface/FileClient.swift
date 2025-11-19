import Foundation

public struct FileClient: Sendable {
    public var data: @Sendable (_ key: String) -> Data?

    public var setData: @Sendable (_ data: Data, _ key: String) throws -> Void

    public var remove: @Sendable (_ key: String) throws -> Void

    public var keys: @Sendable () throws -> [String]

    public init(
        data: @escaping @Sendable (_ key: String) -> Data?,
        setData: @escaping @Sendable (_ data: Data, _ key: String) throws -> Void,
        remove: @escaping @Sendable (_ key: String) throws -> Void,
        keys: @escaping @Sendable () throws -> [String]
    ) {
        self.data = data
        self.setData = setData
        self.remove = remove
        self.keys = keys
    }
}
