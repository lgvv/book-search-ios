import Foundation

public struct UserDefaultsClient: Sendable {
    var string: @Sendable (_ key: String) -> String?
    var bool: @Sendable (_ key: String) -> Bool?
    var int: @Sendable (_ key: String) -> Int?
    var data: @Sendable (_ key: String) -> Data?

    var setString: @Sendable (_ value: String, _ key: String) -> Void
    var setBool: @Sendable (_ value: Bool, _ key: String) -> Void
    var setInt: @Sendable (_ value: Int, _ key: String) -> Void
    var setData: @Sendable (_ value: Data, _ key: String) -> Void

    var remove: @Sendable (_ key: String) -> Void

    public init(
        string: @escaping @Sendable (_ key: String) -> String?,
        bool: @escaping @Sendable (_ key: String) -> Bool?,
        int: @escaping @Sendable (_ key: String) -> Int?,
        data: @escaping @Sendable (_ key: String) -> Data?,
        setString: @escaping @Sendable (_ value: String, _ key: String) -> Void,
        setBool: @escaping @Sendable (_ value: Bool, _ key: String) -> Void,
        setInt: @escaping @Sendable (_ value: Int, _ key: String) -> Void,
        setData: @escaping @Sendable (_ value: Data, _ key: String) -> Void,
        remove: @escaping @Sendable (_ key: String) -> Void
    ) {
        self.string = string
        self.bool = bool
        self.int = int
        self.data = data
        self.setString = setString
        self.setBool = setBool
        self.setInt = setInt
        self.setData = setData
        self.remove = remove
    }
}

extension UserDefaultsClient {
    func object<T: Decodable>(_ type: T.Type = T.self, forKey key: String) -> T? {
        data(key).flatMap { try? JSONDecoder().decode(type, from: $0) }
    }

    func setObject<T: Encodable>(_ value: T, forKey key: String) {
        guard let encoded = try? JSONEncoder().encode(value) else { return }
        setData(encoded, key)
    }
}
