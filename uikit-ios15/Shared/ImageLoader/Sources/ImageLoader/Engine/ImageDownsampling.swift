import ImageIO
import UIKit

enum ImageDownsampling {
    static func decode(_ data: Data, pixelSize: CGSize?) -> UIImage? {
        guard let pixelSize, pixelSize.width > 0, pixelSize.height > 0 else {
            return UIImage(data: data)?.preparingForDisplay() ?? UIImage(data: data)
        }

        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return UIImage(data: data)
        }

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Self.maxPixelSize(for: source, filling: pixelSize)
        ] as CFDictionary

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: thumbnail)
    }

    private static func maxPixelSize(for source: CGImageSource, filling pixelSize: CGSize) -> Int {
        let fallback = Int(max(pixelSize.width, pixelSize.height).rounded())

        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
            let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue,
            width > 0, height > 0
        else {
            return fallback
        }

        let fillScale = max(pixelSize.width / width, pixelSize.height / height)
        guard fillScale < 1 else { return Int(max(width, height).rounded()) }

        return Int((max(width, height) * fillScale).rounded())
    }
}
