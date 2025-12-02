import Foundation

public protocol ConfigSource: Sendable {
    func rawValue(forKey key: String) -> String?
}
