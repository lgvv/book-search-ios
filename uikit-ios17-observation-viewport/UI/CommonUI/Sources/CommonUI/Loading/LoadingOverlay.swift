import UIKit

import DesignSystem

@MainActor
public final class LoadingOverlay {
    public struct Session: Sendable {
        fileprivate let id: Int
    }

    private let grace: TimeInterval

    private var currentID = 0
    private var hostView: UIView?
    private var container: UIView?
    private var showTask: Task<Void, Never>?

    public init(grace: TimeInterval = 0.25) {
        self.grace = grace
    }

    public func begin(over view: UIView) -> Session {
        self.currentID += 1
        let session = Session(id: self.currentID)

        if let container = self.container, self.hostView !== view {
            container.removeFromSuperview()
            self.container = nil
            self.hostView = view
            self.attach()
            return session
        }

        self.hostView = view

        guard self.showTask == nil, self.container == nil else { return session }

        let delay = UInt64(self.grace * 1_000_000_000)
        self.showTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            self?.attach()
        }
        return session
    }

    public func end(_ session: Session) {
        guard session.id == self.currentID else { return }

        self.showTask?.cancel()
        self.showTask = nil
        self.container?.removeFromSuperview()
        self.container = nil
        self.hostView = nil
    }

    private func attach() {
        guard let hostView, self.container == nil else { return }

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.dsBackground.withAlphaComponent(0.6)
        container.accessibilityViewIsModal = true
        container.isAccessibilityElement = true
        container.accessibilityLabel = "불러오는 중"

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .dsInk
        indicator.startAnimating()

        container.addSubview(indicator)
        hostView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: hostView.topAnchor),
            container.bottomAnchor.constraint(equalTo: hostView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        self.container = container

        guard !UIAccessibility.isReduceMotionEnabled else { return }
        container.alpha = 0
        UIView.animate(withDuration: 0.15) { container.alpha = 1 }
    }
}
