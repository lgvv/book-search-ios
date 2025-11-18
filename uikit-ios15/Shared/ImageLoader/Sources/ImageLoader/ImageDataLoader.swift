import Foundation

public struct ImageDataLoader: Sendable {
    public var fetch: @Sendable (_ url: URL, _ etag: String?) async throws -> ImageDataResponse

    public init(fetch: @escaping @Sendable (_ url: URL, _ etag: String?) async throws -> ImageDataResponse) {
        self.fetch = fetch
    }
}

public enum ImageDataResponse: Sendable {
    case fresh(Data, etag: String?)
    case notModified
}
