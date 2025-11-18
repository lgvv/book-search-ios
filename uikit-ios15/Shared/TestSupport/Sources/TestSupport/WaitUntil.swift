import Foundation

public func waitUntil(
    _ condition: @escaping @Sendable () async -> Bool,
    timeout: TimeInterval = 2,
    pollInterval: TimeInterval = 0.005
) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if await condition() {
            return true
        }
        try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
    }
    return await condition()
}

public func stayFalse(
    _ condition: @escaping @Sendable () async -> Bool,
    for duration: TimeInterval = 0.1,
    pollInterval: TimeInterval = 0.005
) async -> Bool {
    let deadline = Date().addingTimeInterval(duration)
    while Date() < deadline {
        if await condition() {
            return false
        }
        try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
    }
    return true
}
