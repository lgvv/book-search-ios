import Combine
import Foundation

public final class AsyncValueRecorder<Output: Sendable>: Sendable {
    public enum RecorderError: Error, CustomStringConvertible {
        case timedOut(expected: Int, received: Int)

        public var description: String {
            switch self {
            case let .timedOut(expected, received):
                return "값 \(expected)개를 기다렸지만 \(received)개만 도착했습니다"
            }
        }
    }

    private struct Observer {
        let threshold: Int
        let continuation: CheckedContinuation<Bool, Never>
    }

    private struct State {
        var values: [Output] = []
        var observers: [UUID: Observer] = [:]
        var cancellable: AnyCancellable?
        var consumption: Task<Void, Never>?
    }

    private let state = Locked(State())

    public init<P: Publisher>(_ publisher: P) where P.Output == Output, P.Failure == Never {
        let cancellable = publisher.sink { [weak self] value in
            self?.receive(value)
        }
        self.state.withValue { $0.cancellable = cancellable }
    }

    public init(_ stream: AsyncStream<Output>) {
        let consumption = Task { [weak self] in
            for await value in stream {
                self?.receive(value)
            }
        }
        self.state.withValue { $0.consumption = consumption }
    }

    deinit {
        self.state.withValue { $0.consumption?.cancel() }
    }

    public var values: [Output] {
        self.state.value.values
    }

    public var last: Output? {
        self.state.value.values.last
    }

    @discardableResult
    public func wait(untilCount count: Int, timeout: TimeInterval = 2) async throws -> [Output] {
        let token = UUID()

        let didReach: Bool = await withCheckedContinuation { continuation in
            let resumeNow = self.state.withValue { state -> Bool in
                if state.values.count >= count {
                    return true
                }
                state.observers[token] = Observer(threshold: count, continuation: continuation)
                return false
            }

            guard !resumeNow else {
                continuation.resume(returning: true)
                return
            }

            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                let pending = self.state.withValue { $0.observers.removeValue(forKey: token) }
                pending?.continuation.resume(returning: false)
            }
        }

        let values = self.values
        guard didReach else {
            throw RecorderError.timedOut(expected: count, received: values.count)
        }
        return values
    }

    private func receive(_ value: Output) {
        let matured = self.state.withValue { state -> [CheckedContinuation<Bool, Never>] in
            state.values.append(value)

            let reached = state.observers.filter { $0.value.threshold <= state.values.count }
            reached.keys.forEach { state.observers.removeValue(forKey: $0) }
            return reached.values.map(\.continuation)
        }
        matured.forEach { $0.resume(returning: true) }
    }
}
