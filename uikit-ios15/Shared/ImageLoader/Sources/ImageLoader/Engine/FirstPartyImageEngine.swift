import UIKit

extension ImageEngine {
    package static func firstParty(dataLoader: ImageDataLoader) -> Self {
        Self(
            load: { url, etag in
                switch try await dataLoader.fetch(url, etag) {
                case let .fresh(data, etag):
                    return .data(data, etag: etag)
                case .notModified:
                    return .notModified
                }
            },
            decode: { data, pixelSize in
                ImageDownsampling.decode(data, pixelSize: pixelSize)
            }
        )
    }
}
