import UIKit

import DesignSystem

public final class EmptyStateView: UIView {

    public var onAction: (() -> Void)?

    private var actionTitle: String?

    public func configure(message: String, actionTitle: String? = nil) {
        let changed = self.messageLabel.text != message || self.actionTitle != actionTitle
        self.messageLabel.text = message
        self.actionTitle = actionTitle
        self.actionButton.setTitle(actionTitle, for: .normal)
        self.actionButton.isHidden = actionTitle == nil

        if changed {
            UIAccessibility.post(notification: .layoutChanged, argument: self.messageLabel)
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureUI()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .dsSubtleInk
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.isHidden = true
        button.addAction(UIAction { [weak self] _ in
            self?.onAction?()
        }, for: .touchUpInside)
        return button
    }()

    private lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [messageLabel, actionButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()

    private func configureUI() {
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
        ])
    }
}
