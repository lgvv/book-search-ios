import UIKit

public final class DSButton: UIButton {

    public init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = DSTypography.heading()
        titleLabel?.adjustsFontForContentSizeCategory = true
        backgroundColor = .dsTint
        setTitleColor(.dsOnTint, for: .normal)
        tintColor = .dsOnTint
        layer.cornerRadius = DSRadius.m
        heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var isHighlighted: Bool {
        didSet {
            guard oldValue != isHighlighted else { return }
            setPressed(isHighlighted)
        }
    }

    private func setPressed(_ pressed: Bool) {
        let transform: CGAffineTransform = if UIAccessibility.isReduceMotionEnabled {
            .identity
        } else {
            pressed ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
        }
        UIView.animate(
            withDuration: 0.1,
            delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut]
        ) {
            self.transform = transform
            self.alpha = pressed ? 0.85 : 1
        }
    }
}
