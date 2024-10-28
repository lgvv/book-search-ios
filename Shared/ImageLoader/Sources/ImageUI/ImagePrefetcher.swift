import UIKit

import ImageLoader

@MainActor
public enum ImagePrefetcher {
    public static func prefetch(_ urls: [URL], targetSize: CGSize? = nil) {
        ImageLoader.prefetch(urls, targetPixelSize: targetSize.map(Self.pixelSize))
    }

    public static func cancel(_ urls: [URL]) {
        ImageLoader.cancelPrefetch(urls)
    }

    private static func pixelSize(_ points: CGSize) -> CGSize {
        let scale = max(UITraitCollection.current.displayScale, 1)
        return CGSize(width: points.width * scale, height: points.height * scale)
    }
}
