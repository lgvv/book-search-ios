import UIKit

import DesignSystem

public final class PagingFooterCell: UICollectionViewCell {

    public enum Mode: Hashable, Sendable {
        case loading
        case failed
    }

    public var onRetry: (() -> Void)?

    public func configure(mode: Mode) {
        switch mode {
        case .loading:
            self.spinner.startAnimating()
            self.spinner.isHidden = false
            self.messageLabel.isHidden = true
            self.retryButton.isHidden = true
            self.spinner.isAccessibilityElement = true
            self.spinner.accessibilityLabel = "결과를 더 불러오는 중"
        case .failed:
            self.spinner.stopAnimating()
            self.spinner.isHidden = true
            self.messageLabel.isHidden = false
            self.retryButton.isHidden = false
            UIAccessibility.post(notification: .announcement, argument: self.messageLabel.text)
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.configureUI()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.onRetry = nil
    }

    private let spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "결과를 더 불러오지 못했습니다"
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .dsSubtleInk
        label.textAlignment = .center
        return label
    }()

    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다시 시도", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addAction(UIAction { [weak self] _ in
            self?.onRetry?()
        }, for: .touchUpInside)
        return button
    }()

    private lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [spinner, messageLabel, retryButton])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center
        return stack
    }()

    private func configureUI() {
        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
        ])
    }
}
