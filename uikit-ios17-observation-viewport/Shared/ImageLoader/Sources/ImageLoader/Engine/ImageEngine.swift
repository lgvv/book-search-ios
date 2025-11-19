import UIKit

package enum ImageEnginePayload: Sendable {
    case data(Data, etag: String?)
    case image(UIImage)
    case notModified
}

package enum ImageEngineError: Error, Sendable {
    case decodingFailed
    case unexpectedNotModified
}

package struct ImageEngine: Sendable {
    package var load: @Sendable (URL, _ etag: String?) async throws -> ImageEnginePayload
    package var decode: @Sendable (Data, _ pixelSize: CGSize?) async -> UIImage?
    package var prefetch: (@Sendable ([URL]) -> Void)?
    package var cancelPrefetch: (@Sendable ([URL]) -> Void)?
    package var teardown: (@Sendable () async -> Void)?

    package init(
        load: @escaping @Sendable (URL, _ etag: String?) async throws -> ImageEnginePayload,
        decode: @escaping @Sendable (Data, _ pixelSize: CGSize?) async -> UIImage?,
        prefetch: (@Sendable ([URL]) -> Void)? = nil,
        cancelPrefetch: (@Sendable ([URL]) -> Void)? = nil,
        teardown: (@Sendable () async -> Void)? = nil
    ) {
        self.load = load
        self.decode = decode
        self.prefetch = prefetch
        self.cancelPrefetch = cancelPrefetch
        self.teardown = teardown
    }
}
