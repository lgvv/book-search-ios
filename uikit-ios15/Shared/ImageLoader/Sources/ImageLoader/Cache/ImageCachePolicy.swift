import Foundation

public enum ImageCachePolicy: Sendable {
    case standard
    case memoryOnly
    case refresh
    case noCache
}

enum CacheBehavior: Sendable {
    case standard
    case memoryOnly
    case refresh
    case none
}

extension ImageCachePolicy {
    var cacheBehavior: CacheBehavior {
        switch self {
        case .standard: .standard
        case .memoryOnly: .memoryOnly
        case .refresh: .refresh
        case .noCache: .none
        }
    }
}
