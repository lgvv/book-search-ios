import Foundation

public final class ConcurrencyGate: Sendable {
    private struct State {
        var available: Int
        var waiters: [CheckedContinuation<Void, Never>] = []
    }

    private let capacity: Int
    private let state: LockIsolated<State>

    public init(capacity: Int) {
        let capacity = max(1, capacity)
        self.capacity = capacity
        self.state = LockIsolated(State(available: capacity))
    }

    public static func forCPUBoundWork() -> ConcurrencyGate {
        ConcurrencyGate(capacity: min(4, max(2, ProcessInfo.processInfo.activeProcessorCount)))
    }

    public func withPermit<T: Sendable>(_ operation: () async throws -> T) async rethrows -> T {
        await self.acquire()
        defer { self.release() }
        return try await operation()
    }

    private func acquire() async {
        await withCheckedContinuation { continuation in
            let resumeNow = self.state.withValue { state -> Bool in
                if state.available > 0 {
                    state.available -= 1
                    return true
                }
                state.waiters.append(continuation)
                return false
            }
            if resumeNow {
                continuation.resume()
            }
        }
    }

    private func release() {
        let next = self.state.withValue { state -> CheckedContinuation<Void, Never>? in
            if state.waiters.isEmpty {
                state.available = min(self.capacity, state.available + 1)
                return nil
            }
            return state.waiters.removeFirst()
        }
        next?.resume()
    }
}
