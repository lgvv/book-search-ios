import Foundation

import RemoteConfigInterface

extension RemoteConfigClient {
    public static func resolving(sources: [any ConfigSource]) -> RemoteConfigClient {
        RemoteConfigClient(
            rawValues: { key in
                sources.compactMap { $0.rawValue(forKey: key) }
            }
        )
    }
}
