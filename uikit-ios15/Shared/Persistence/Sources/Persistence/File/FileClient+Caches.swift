import Foundation

import PersistenceInterface

extension FileClient {
    public static func caches(directoryName: String) -> FileClient {
        let store = FileStore(directoryName: directoryName, in: .cachesDirectory)
        return FileClient(
            data: { key in store.data(forKey: key) },
            setData: { data, key in try store.set(data, forKey: key) },
            remove: { key in try store.remove(forKey: key) },
            keys: { try store.keys() }
        )
    }
}
