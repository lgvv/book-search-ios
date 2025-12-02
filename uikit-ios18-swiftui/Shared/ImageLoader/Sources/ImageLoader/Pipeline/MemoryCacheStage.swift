import Foundation

extension ImagePipelineStage {
    static func memoryCache(_ memory: MemoryCache) -> Self {
        Self { context, next in
            guard context.behavior != .none else {
                return try await next(context)
            }

            if context.behavior != .refresh,
               context.intent != .revalidate,
               let image = memory.image(for: context.url, pixelSize: context.targetPixelSize) {
                return ImageLoadOutcome(image: image, data: nil, etag: nil, source: .memory)
            }

            let outcome = try await next(context)
            if outcome.staleETag == nil {
                memory.store(outcome.image, for: context.url, pixelSize: context.targetPixelSize)
            }
            return outcome
        }
    }
}
