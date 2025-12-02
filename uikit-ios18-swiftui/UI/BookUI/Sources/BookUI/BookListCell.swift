import UIKit

import BookModel
import DesignSystem
import ImageUI

public final class BookListCell: UICollectionViewCell {

    public static let coverSize = CGSize(width: 45, height: 80)

    public var onToggleFavorite: (() -> Void)?

    public func configure(
        with book: Book,
        isFavorite: Bool,
        hasMemo: Bool,
        caption: String? = nil
    ) {
        titleLabel.text = book.title
        subtitleLabel.text = [book.author, book.publisher]
            .compactMap { $0 }
            .joined(separator: " · ")
        coverImageView.setImage(from: book.coverImageURL, targetSize: Self.coverSize)
        favoriteButton.setImage(
            UIImage(systemName: isFavorite ? "heart.fill" : "heart"),
            for: .normal
        )
        memoIndicator.isHidden = !hasMemo

        captionLabel.text = caption
        captionLabel.isHidden = caption == nil

        self.content = Content(book: book, isFavorite: isFavorite, hasMemo: hasMemo, caption: caption)
    }

    private struct Content {
        let book: Book
        let isFavorite: Bool
        let hasMemo: Bool
        let caption: String?
    }

    private var content: Content?

    private func configureAccessibility() {
        contentView.isAccessibilityElementBlock = { true }
        contentView.accessibilityTraitsBlock = { .button }

        contentView.accessibilityLabelBlock = { [weak self] in
            self?.accessibilityStatement
        }

        contentView.accessibilityCustomActionsBlock = { [weak self] in
            guard let self, let content = self.content else { return nil }

            let title = content.isFavorite ? "즐겨찾기 해제" : "즐겨찾기 추가"
            return [
                UIAccessibilityCustomAction(name: title) { [weak self] _ in
                    self?.onToggleFavorite?()
                    return true
                }
            ]
        }
    }

    private var accessibilityStatement: String? {
        guard let content = self.content else { return nil }

        let details = [content.book.author, content.book.publisher, content.caption]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        let states = [
            content.isFavorite ? "즐겨찾기됨" : nil,
            content.hasMemo ? "메모 있음" : nil
        ].compactMap { $0 }

        return ([content.book.title] + details + states).joined(separator: ", ")
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        configureAccessibility()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let coverImageView: AsyncImageView = {
        let imageView = AsyncImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.backgroundColor = .dsSurface
        imageView.isAccessibilityElementBlock = { false }
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .dsInk
        label.numberOfLines = 2
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .dsSubtleInk
        label.numberOfLines = 1
        return label
    }()

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .dsSubtleInk
        label.numberOfLines = 1
        label.isHidden = true
        return label
    }()

    private let memoIndicator: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "note.text"))
        imageView.tintColor = .dsSubtleInk
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        imageView.isAccessibilityElementBlock = { false }
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.isHidden = true
        return imageView
    }()

    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .dsFavorite
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.addAction(UIAction { [weak self] _ in
            self?.onToggleFavorite?()
        }, for: .touchUpInside)
        return button
    }()

    private lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, captionLabel])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [coverImageView, textStack, memoIndicator, favoriteButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()

    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .dsSeparator
        return view
    }()

    private func configureUI() {
        contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 10,
            leading: DSSpacing.l,
            bottom: 10,
            trailing: DSSpacing.l
        )
        let margins = contentView.layoutMarginsGuide

        contentView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let bottom = contentStack.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
        bottom.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: margins.topAnchor),
            bottom,
            contentStack.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
        ])

        contentView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        NSLayoutConstraint.activate([
            coverImageView.widthAnchor.constraint(equalToConstant: Self.coverSize.width),
            coverImageView.heightAnchor.constraint(equalToConstant: Self.coverSize.height)
        ])

        NSLayoutConstraint.activate([
            memoIndicator.widthAnchor.constraint(equalToConstant: 22),
            memoIndicator.heightAnchor.constraint(equalToConstant: 22)
        ])

        NSLayoutConstraint.activate([
            favoriteButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            favoriteButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
}
