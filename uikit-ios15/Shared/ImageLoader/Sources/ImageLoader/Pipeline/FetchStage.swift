import UIKit

extension ImageLoadPipeline {
    static func fetchTerminal(
        engine: ImageEngine,
        decode: @escaping @Sendable (Data, _ pixelSize: CGSize?) async -> UIImage?
    ) -> ImagePipelineStage.Next {
        { context in
            switch try await engine.load(context.url, context.etag) {
            case let .data(data, etag):
                guard let image = await decode(data, context.targetPixelSize) else {
                    throw ImageEngineError.decodingFailed
                }
                return ImageLoadOutcome(image: image, data: data, etag: etag, source: .network)

            case let .image(image):
                return ImageLoadOutcome(image: image, data: nil, etag: nil, source: .network)

            case .notModified:
                guard context.etag != nil else {
                    throw ImageEngineError.unexpectedNotModified
                }
                throw ImagePipelineSignal.notModified
            }
        }
    }
}
