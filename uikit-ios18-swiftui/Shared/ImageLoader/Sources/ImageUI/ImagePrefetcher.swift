import CoreGraphics
import Foundation

import ImageLoader

@MainActor
public enum ImagePrefetcher {
    public static func prefetch(_ urls: [URL], targetPixelSize: CGSize? = nil) {
        ImageLoader.prefetch(urls, targetPixelSize: targetPixelSize)
    }

    public static func cancel(_ urls: [URL]) {
        ImageLoader.cancelPrefetch(urls)
    }
}
