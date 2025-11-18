import UIKit

import DesignSystem

@MainActor
public final class ToastPresenter {
    private let duration: TimeInterval

    private var currentToast: UIView?
    private var dismissTask: Task<Void, Never>?

    public init(duration: TimeInterval = 2.4) {
        self.duration = duration
    }

    public func show(_ message: String, over view: UIView, bottomInset: CGFloat = 16) {
        self.dismissTask?.cancel()
        self.currentToast?.removeFromSuperview()

        let host = view.window ?? view
        let toast = Self.makeToast(message: message)
        host.addSubview(toast)
        host.bringSubviewToFront(toast)
        toast.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: host.leadingAnchor, constant: 24),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: host.trailingAnchor, constant: -24),
            toast.centerXAnchor.constraint(equalTo: host.centerXAnchor),
            toast.bottomAnchor.constraint(
                equalTo: host.safeAreaLayoutGuide.bottomAnchor,
                constant: -bottomInset
            )
        ])

        self.currentToast = toast
        toast.alpha = 0
        UIView.animate(withDuration: 0.2) { toast.alpha = 1 }

        let duration = self.duration
        self.dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.dismiss(toast)
        }
    }

    private func dismiss(_ toast: UIView) {
        UIView.animate(withDuration: 0.2) {
            toast.alpha = 0
        } completion: { [weak self] _ in
            toast.removeFromSuperview()
            if self?.currentToast === toast {
                self?.currentToast = nil
            }
        }
    }

    private static func makeToast(message: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .dsInk.withAlphaComponent(0.92)
        container.layer.cornerRadius = 10
        container.isUserInteractionEnabled = false

        let label = UILabel()
        label.text = message
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .dsBackground
        label.numberOfLines = 0
        label.textAlignment = .center

        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])

        UIAccessibility.post(notification: .announcement, argument: message)
        return container
    }
}
