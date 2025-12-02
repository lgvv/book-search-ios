import Foundation
import Observation

@MainActor
public final class StateObserver {

    private let render: @MainActor @Sendable () -> Void

    public init(_ render: @escaping @MainActor @Sendable () -> Void) {
        self.render = render
        self.track()
    }

    private func track() {
        withObservationTracking {
            self.render()
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.track()
            }
        }
    }
}
