import Foundation

public enum AppEnvironment {
    public static let bundleIdentifier = "com.lgvv.booksearch"

    public static var storageSuiteName: String {
#if DEBUG
        return "booksearch.storage.debug"
#else
        return "booksearch.storage"
#endif
    }

    public static let imageCacheDirectoryName = "ImageLoader"

    public static let universalLinkHosts: Set<String> = [
        "booksearch.app",
        "www.booksearch.app"
    ]
}
