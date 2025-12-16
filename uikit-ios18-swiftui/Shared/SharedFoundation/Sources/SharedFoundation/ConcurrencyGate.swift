import Foundation
import Synchronization

public final class ConcurrencyGate: Sendable {
    private struct Waiter {
        let id: UUID
        let continuation: CheckedContinuation<Bool, Never>
    }

    private struct State {
        var available: Int
        var waiters: [Waiter] = []
        var cancelledBeforeEnqueue: Set<UUID> = []
    }

    private let capacity: Int
    private let state: Mutex<State>

    public init(capacity: Int) {
        let capacity = max(1, capacity)
        self.capacity = capacity
        self.state = Mutex(State(available: capacity))
    }

    public static func forCPUBoundWork() -> ConcurrencyGate {
        ConcurrencyGate(capacity: min(4, max(2, ProcessInfo.processInfo.activeProcessorCount)))
    }

    public func withPermit<T: Sendable>(_ operation: () async throws -> T) async throws -> T {
        try await self.acquire()
        defer { self.release() }
        return try await operation()
    }

    var waiterCountForTesting: Int {
        self.state.withLock { $0.waiters.count }
    }

    private func acquire() async throws {
        try Task.checkCancellation()

        let id = UUID()
        defer {
            self.state.withLock { _ = $0.cancelledBeforeEnqueue.remove(id) }
        }

        let didAcquire = await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                enum Verdict {
                    case granted
                    case enqueued
                    case cancelled
                }
                let verdict = self.state.withLock { state -> Verdict in
                    if state.cancelledBeforeEnqueue.remove(id) != nil {
                        return .cancelled
                    }
                    if state.available > 0 {
                        state.available -= 1
                        return .granted
                    }
                    state.waiters.append(Waiter(id: id, continuation: continuation))
                    return .enqueued
                }
                switch verdict {
                case .granted: continuation.resume(returning: true)
                case .cancelled: continuation.resume(returning: false)
                case .enqueued: break
                }
            }
        } onCancel: {
            let waiting = self.state.withLock { state -> CheckedContinuation<Bool, Never>? in
                guard let index = state.waiters.firstIndex(where: { $0.id == id }) else {
                    state.cancelledBeforeEnqueue.insert(id)
                    return nil
                }
                return state.waiters.remove(at: index).continuation
            }
            waiting?.resume(returning: false)
        }

        guard didAcquire else {
            throw CancellationError()
        }
        guard !Task.isCancelled else {
            self.release()
            throw CancellationError()
        }
    }

    private func release() {
        let next = self.state.withLock { state -> CheckedContinuation<Bool, Never>? in
            if state.waiters.isEmpty {
                state.available = min(self.capacity, state.available + 1)
                return nil
            }
            return state.waiters.removeFirst().continuation
        }
        next?.resume(returning: true)
    }
}
