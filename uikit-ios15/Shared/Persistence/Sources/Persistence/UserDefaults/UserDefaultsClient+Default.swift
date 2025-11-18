import Foundation

import PersistenceInterface

extension UserDefaultsClient {
    public static func live(suiteName: String) -> UserDefaultsClient {
        let store = UserDefaultsStore(suiteName: suiteName)
        return UserDefaultsClient(
            string: { key in store.string(forKey: key) },
            bool: { key in store.bool(forKey: key) },
            int: { key in store.int(forKey: key) },
            data: { key in store.data(forKey: key) },
            setString: { value, key in store.set(value, forKey: key) },
            setBool: { value, key in store.set(value, forKey: key) },
            setInt: { value, key in store.set(value, forKey: key) },
            setData: { value, key in store.set(value, forKey: key) },
            remove: { key in store.remove(forKey: key) }
        )
    }
}
