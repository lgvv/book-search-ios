import UIKit

final class MemoryCache: Sendable {
    nonisolated(unsafe) private let cache = NSCache<NSString, UIImage>()
    nonisolated(unsafe) private let memoryWarningObserver: NSObjectProtocol

    init(countLimit: Int = 300, totalCostLimit: Int = MemoryCache.defaultCostLimit) {
        self.cache.countLimit = countLimit
        self.cache.totalCostLimit = totalCostLimit

        nonisolated(unsafe) let cache = self.cache
        self.memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { _ in
            cache.removeAllObjects()
        }
    }

    static var defaultCostLimit: Int {
        min(128 * 1024 * 1024, Int(ProcessInfo.processInfo.physicalMemory / 8))
    }

    func image(for url: URL, pixelSize: CGSize?) -> UIImage? {
        self.cache.object(forKey: Self.key(url, pixelSize))
    }

    func store(_ image: UIImage, for url: URL, pixelSize: CGSize?) {
        self.cache.setObject(
            image,
            forKey: Self.key(url, pixelSize),
            cost: Self.cost(of: image)
        )
    }

    private static func key(_ url: URL, _ pixelSize: CGSize?) -> NSString {
        guard let pixelSize else {
            return "\(url.absoluteString)|full" as NSString
        }
        let width = Int(pixelSize.width.rounded())
        let height = Int(pixelSize.height.rounded())
        return "\(url.absoluteString)|\(width)x\(height)" as NSString
    }

    private static func cost(of image: UIImage) -> Int {
        if let cgImage = image.cgImage {
            return cgImage.bytesPerRow * cgImage.height
        }
        let pixels = image.size.width * image.size.height * image.scale * image.scale
        return Int(pixels) * 4
    }
}
