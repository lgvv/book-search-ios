import Foundation

struct FileStore: Sendable {
    private let directory: URL

    init(directoryName: String, in searchPath: FileManager.SearchPathDirectory) {
        let base = FileManager.default.urls(for: searchPath, in: .userDomainMask)[0]
        self.directory = base.appendingPathComponent(directoryName, isDirectory: true)
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    func data(forKey key: String) -> Data? {
        try? Data(contentsOf: self.directory.appendingPathComponent(key))
    }

    func set(_ data: Data, forKey key: String) throws {
        try data.write(to: self.directory.appendingPathComponent(key), options: .atomic)
    }

    func keys() throws -> [String] {
        try FileManager.default
            .contentsOfDirectory(at: self.directory, includingPropertiesForKeys: nil)
            .map(\.lastPathComponent)
    }

    func remove(forKey key: String) throws {
        do {
            try FileManager.default.removeItem(at: self.directory.appendingPathComponent(key))
        } catch CocoaError.fileNoSuchFile {
        }
    }
}
