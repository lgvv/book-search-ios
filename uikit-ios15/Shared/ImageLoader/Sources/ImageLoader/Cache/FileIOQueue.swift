import Foundation

final class FileIOQueue: Sendable {
    private let queue: DispatchQueue

    init(label: String) {
        self.queue = DispatchQueue(label: label, qos: .utility)
    }

    func run<T: Sendable>(_ work: @escaping @Sendable () -> T) async -> T {
        await withCheckedContinuation { continuation in
            self.queue.async {
                continuation.resume(returning: work())
            }
        }
    }

    func enqueue(_ work: @escaping @Sendable () -> Void) {
        self.queue.async(execute: work)
    }
}
