import Foundation

@MainActor
public final class ActionQueue<Action> {
    private var isDraining = false

    private var buffer: [Action] = []
    private let onViolation: ((Action) -> Void)?

    public init(onViolation: ((Action) -> Void)? = nil) {
        self.onViolation = onViolation
    }

    public func send(_ action: Action, process: (Action) -> Void) {
        buffer.append(action)
        guard !isDraining else {
            report(action)
            return
        }

        isDraining = true
        defer {
            buffer.removeAll(keepingCapacity: true)
            isDraining = false
        }

        var index = 0
        while index < buffer.count {
            let next = buffer[index]
            index += 1
            process(next)
        }
    }

    private func report(_ action: Action) {
        if let onViolation {
            onViolation(action)
            return
        }
        assertionFailure(
            """
            액션 처리 도중 동기 send가 들어왔다: \(action)
            큐가 순서는 지키지만 이 경로 자체를 없애야 합니다. (사이클 생성 가능성 존재)
            뷰가 상태를 읽어 액션을 파생시키고 있지 않은지 확인할 것.
            """
        )
    }
}
