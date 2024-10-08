import CoreData
import Foundation

import PersistenceInterface

extension CoreDataStoreFactory {
    public static let live = Self { name, schema in
        DefaultCoreDataStore(name: name, schema: schema)
    }

    public static let inMemory = Self { name, schema in
        DefaultCoreDataStore(name: name, schema: schema, inMemory: true)
    }
}
