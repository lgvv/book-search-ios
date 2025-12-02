import UIKit

import ImageLoader

public final class AsyncImageView: UIImageView {
    public var cachePolicy: ImageCachePolicy = .standard

    private var currentLoadTask: Task<Void, Never>?
    private var currentImageURL: URL?

    private var explicitTargetSize: CGSize?

    private var deferredURL: URL?

    public func setImage(from url: URL?, placeholder: UIImage? = nil, targetSize: CGSize? = nil) {
        guard url != self.currentImageURL else { return }

        self.currentLoadTask?.cancel()
        self.currentLoadTask = nil
        self.currentImageURL = url
        self.explicitTargetSize = targetSize
        self.deferredURL = nil
        self.image = placeholder

        guard let url else { return }

        guard let pixelSize = self.resolvedPixelSize() else {
            self.deferredURL = url
            return
        }
        self.start(url, pixelSize: pixelSize)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        guard let deferredURL, let pixelSize = self.resolvedPixelSize() else { return }
        self.deferredURL = nil
        self.start(deferredURL, pixelSize: pixelSize)
    }

    private func resolvedPixelSize() -> CGSize? {
        let points = self.explicitTargetSize ?? self.bounds.size
        guard points.width > 0, points.height > 0 else { return nil }

        var scale = self.traitCollection.displayScale
        if scale <= 0 { scale = UITraitCollection.current.displayScale }
        if scale <= 0 { scale = 1 }

        return CGSize(width: points.width * scale, height: points.height * scale)
    }

    private func start(_ url: URL, pixelSize: CGSize) {
        self.currentLoadTask = Task { [weak self, cachePolicy] in
            let image = try? await ImageLoader.load(
                url,
                policy: cachePolicy,
                targetPixelSize: pixelSize
            )
            guard !Task.isCancelled else { return }
            guard let image else {
                self?.currentImageURL = nil
                return
            }
            self?.image = image
        }
    }
}
