import Foundation

final class UserDefaultsStore: @unchecked Sendable {
    private let storage: UserDefaults

    init(suiteName: String) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            assertionFailure("유효하지 않은 suite: \(suiteName)")
            self.storage = .standard
            return
        }
        self.storage = defaults
    }

    func string(forKey key: String) -> String? {
        storage.string(forKey: key)
    }

    func bool(forKey key: String) -> Bool? {
        storage.object(forKey: key) == nil
        ? nil
        : storage.bool(forKey: key)
    }

    func int(forKey key: String) -> Int? {
        storage.object(forKey: key) == nil
        ? nil
        : storage.integer(forKey: key)
    }

    func data(forKey key: String) -> Data? {
        storage.data(forKey: key)
    }

    func set(_ value: Any, forKey key: String) {
        storage.set(value, forKey: key)
    }

    func remove(forKey key: String) {
        storage.removeObject(forKey: key)
    }

    func migrate(keys: [String], from source: UserDefaults) {
        for key in keys where storage.object(forKey: key) == nil {
            if let value = source.object(forKey: key) {
                storage.set(value, forKey: key)
            }
        }
    }
}
