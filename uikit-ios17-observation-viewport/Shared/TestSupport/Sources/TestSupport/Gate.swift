import Foundation

public final class Gate: Sendable {
    private struct State {
        var isOpen = false
        var arrivedCount = 0
        var waiters: [CheckedContinuation<Void, Never>] = []
        var observers: [(threshold: Int, continuation: CheckedContinuation<Void, Never>)] = []
    }

    private let state = Locked(State())

    public init() {}

    public var arrivedCount: Int {
        self.state.value.arrivedCount
    }

    public func wait() async {
        await withCheckedContinuation { continuation in
            let (shouldResume, observers) = self.state.withValue { state -> (Bool, [CheckedContinuation<Void, Never>]) in
                state.arrivedCount += 1

                let matured = state.observers.filter { $0.threshold <= state.arrivedCount }
                state.observers.removeAll { $0.threshold <= state.arrivedCount }

                if state.isOpen {
                    return (true, matured.map(\.continuation))
                }
                state.waiters.append(continuation)
                return (false, matured.map(\.continuation))
            }

            observers.forEach { $0.resume() }
            if shouldResume {
                continuation.resume()
            }
        }
    }

    public func open() {
        let waiters = self.state.withValue { state -> [CheckedContinuation<Void, Never>] in
            state.isOpen = true
            defer { state.waiters.removeAll() }
            return state.waiters
        }
        waiters.forEach { $0.resume() }
    }

    public func waitUntilArrived(_ count: Int = 1) async {
        await withCheckedContinuation { continuation in
            let shouldResume = self.state.withValue { state -> Bool in
                if state.arrivedCount >= count {
                    return true
                }
                state.observers.append((threshold: count, continuation: continuation))
                return false
            }
            if shouldResume {
                continuation.resume()
            }
        }
    }
}
