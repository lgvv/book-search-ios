import Foundation

import PersistenceInterface
import TestSupport

final class InMemoryFileClient: Sendable {
    struct WriteBlocked: Error {}

    private let storage = Locked<[String: Data]>([:])
    private let writeBlock = Locked<(@Sendable (String) -> Bool)?>(nil)

    var keys: Set<String> {
        Set(self.storage.value.keys)
    }

    func data(forKey key: String) -> Data? {
        self.storage.value[key]
    }

    func seed(_ data: Data, forKey key: String) {
        self.storage.withValue { $0[key] = data }
    }

    func removeBehindTheCache(forKey key: String) {
        self.storage.withValue { $0[key] = nil }
    }

    func failWrites(where predicate: @escaping @Sendable (String) -> Bool) {
        self.writeBlock.withValue { $0 = predicate }
    }

    var client: FileClient {
        FileClient(
            data: { [storage] key in storage.value[key] },
            setData: { [storage, writeBlock] data, key in
                if writeBlock.value?(key) == true { throw WriteBlocked() }
                storage.withValue { $0[key] = data }
            },
            remove: { [storage] key in storage.withValue { $0[key] = nil } },
            keys: { [storage] in Array(storage.value.keys) }
        )
    }
}
