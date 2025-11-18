import UIKit

struct ImageLoadContext: Sendable {
    enum Intent: Sendable {
        case display
        case prefetch
        case revalidate
    }

    let url: URL
    let behavior: CacheBehavior
    let intent: Intent

    let etag: String?

    var revalidatingGeneration: Int?

    let targetPixelSize: CGSize?
}

struct ImageLoadOutcome: Sendable {
    enum Source: Sendable {
        case memory
        case disk
        case network
    }

    let image: UIImage
    let data: Data?
    let etag: String?
    let source: Source

    var staleETag: StaleETag?

    struct StaleETag: Sendable {
        let etag: String?
        let generation: Int
    }
}

enum ImagePipelineSignal: Error {
    case notModified
}

struct ImagePipelineStage: Sendable {
    typealias Next = @Sendable (ImageLoadContext) async throws -> ImageLoadOutcome

    var run: @Sendable (ImageLoadContext, _ next: @escaping Next) async throws -> ImageLoadOutcome
}

struct ImageLoadPipeline: Sendable {
    private let entry: ImagePipelineStage.Next

    init(stages: [ImagePipelineStage], terminal: @escaping ImagePipelineStage.Next) {
        var chain = terminal
        for stage in stages.reversed() {
            let next = chain
            chain = { context in
                try await stage.run(context, next)
            }
        }
        self.entry = chain
    }

    func load(_ context: ImageLoadContext) async throws -> ImageLoadOutcome {
        try await entry(context)
    }
}
