import UIKit

import SharedFoundation

extension ImagePipelineStage {
    static func deduplication() -> Self {
        struct Key: Hashable {
            let url: URL
            let behavior: CacheBehavior
            let targetPixelSize: CGSize?
        }
        struct InFlight {
            let id: UUID
            let task: Task<ImageLoadOutcome, Error>
            var waiters: Int
        }
        let inFlight = LockIsolated([Key: InFlight]())

        return Self { context, next in
            guard context.intent != .revalidate else {
                return try await next(context)
            }

            let key = Key(
                url: context.url,
                behavior: context.behavior,
                targetPixelSize: context.targetPixelSize
            )
            let entry: InFlight = inFlight.withValue { map in
                if var existing = map[key] {
                    existing.waiters += 1
                    map[key] = existing
                    return existing
                }
                let created = InFlight(
                    id: UUID(),
                    task: Task { try await next(context) },
                    waiters: 1
                )
                map[key] = created
                return created
            }

            let didLeave = LockIsolated(false)
            let leaveOnce: @Sendable () -> Void = {
                let isFirst = didLeave.withValue { left -> Bool in
                    if left { return false }
                    left = true
                    return true
                }
                guard isFirst else { return }
                inFlight.withValue { map in
                    guard var current = map[key], current.id == entry.id else { return }
                    current.waiters -= 1
                    if current.waiters <= 0 {
                        current.task.cancel()
                        map[key] = nil
                    } else {
                        map[key] = current
                    }
                }
            }

            return try await withTaskCancellationHandler {
                defer { leaveOnce() }
                return try await entry.task.value
            } onCancel: {
                leaveOnce()
            }
        }
    }
}
