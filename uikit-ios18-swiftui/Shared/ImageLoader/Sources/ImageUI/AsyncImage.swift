import SwiftUI

import ImageLoader

public struct DSAsyncImage: View {
    private let url: URL?
    private let targetSize: CGSize?
    private let contentMode: ContentMode
    private let cachePolicy: ImageCachePolicy

    @Environment(\.displayScale) private var displayScale

    @State private var loaded: LoadedImage?
    @State private var measuredSize: CGSize?

    public init(
        url: URL?,
        targetSize: CGSize? = nil,
        contentMode: ContentMode = .fill,
        cachePolicy: ImageCachePolicy = .standard
    ) {
        self.url = url
        self.targetSize = targetSize
        self.contentMode = contentMode
        self.cachePolicy = cachePolicy
    }

    public var body: some View {
        ZStack {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: self.contentMode)
            }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            guard self.targetSize == nil else { return }
            guard self.measuredSize == nil, size.width > 0, size.height > 0 else { return }
            self.measuredSize = size
        }
        .task(id: self.loadKey) {
            await self.load()
        }
    }

    private var loadedImage: UIImage? {
        guard let loaded, loaded.url == self.url else { return nil }
        return loaded.image
    }

    private var resolvedPointSize: CGSize? {
        self.targetSize ?? self.measuredSize
    }

    private var loadKey: LoadKey {
        LoadKey(url: self.url, size: self.resolvedPointSize.map { "\($0)" } ?? "")
    }

    private func load() async {
        guard let url else {
            self.loaded = nil
            return
        }
        guard loadedImage == nil, let points = self.resolvedPointSize else { return }

        let pixelSize = ImagePixelSize.from(points, displayScale: self.displayScale)

        guard let image = try? await ImageLoader.load(
            url,
            policy: self.cachePolicy,
            targetPixelSize: pixelSize
        ) else { return }
        guard !Task.isCancelled else { return }

        self.loaded = LoadedImage(url: url, image: image)
    }

    private struct LoadedImage {
        let url: URL
        let image: UIImage
    }

    private struct LoadKey: Equatable {
        let url: URL?
        let size: String
    }
}
