import UIKit

import BookModel
import DesignSystem
import FeatureSupport
import ImageUI

final class BookDetailViewController: UIViewController {

    private let store: BookDetailStore

    private var observer: StateObserver?

    private func observe() {
        self.observer = StateObserver { [weak self] in
            guard let self else { return }

            self.updateFavoriteButton(self.store.state.isFavorite)
            self.updateMemo(self.store.state.memoText)
        }
    }

    init(store: BookDetailStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        configureContent()

        observe()

        store.send(.viewDidLoad)
    }

    private static let coverSize = CGSize(width: 180, height: 260)

    private lazy var coverImageView: AsyncImageView = {
        let imageView = AsyncImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.backgroundColor = .dsSurface
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = DSTypography.largeTitle()
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits.insert(.header)
        label.textColor = .dsInk
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .dsSubtleInk
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var memoTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "메모"
        label.font = DSTypography.heading()
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits.insert(.header)
        label.textColor = .dsInk
        return label
    }()

    private lazy var memoBodyLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private lazy var memoEditButton: DSButton = {
        let button = DSButton(title: "메모 작성")
        button.addAction(UIAction { [weak self] _ in
            self?.store.send(.editMemo)
        }, for: .touchUpInside)
        return button
    }()

    private lazy var memoStack: UIStackView = {
        let stack = UIStackView(
            arrangedSubviews: [memoTitleLabel, memoBodyLabel, memoEditButton]
        )
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        return stack
    }()

    private lazy var scrollView = UIScrollView()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [coverImageView, titleLabel, infoLabel, memoStack])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()

    private lazy var favoriteBarButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "heart"),
            primaryAction: UIAction { [weak self] _ in
                self?.store.send(.toggleFavorite)
            }
        )
        button.tintColor = .dsFavorite
        button.accessibilityLabel = "즐겨찾기"
        return button
    }()

    private func configureUI() {
        title = "도서 상세"
        view.backgroundColor = .dsBackground
        navigationItem.rightBarButtonItem = favoriteBarButton

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])

        NSLayoutConstraint.activate([
            coverImageView.widthAnchor.constraint(equalToConstant: Self.coverSize.width),
            coverImageView.heightAnchor.constraint(equalToConstant: Self.coverSize.height)
        ])

        NSLayoutConstraint.activate([
            memoStack.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        ])
    }
}

extension BookDetailViewController {
    private func configureContent() {
        let book = store.state.book
        coverImageView.setImage(from: book.coverImageURL, targetSize: Self.coverSize)
        titleLabel.text = book.title

        infoLabel.text = [
            book.author.map { "저자  \($0)" },
            book.publisher.map { "출판사  \($0)" },
            book.publishedAt.map { "출간예정  \($0)" },
            "ISBN  \(book.isbn)"
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }

    private func updateFavoriteButton(_ isFavorite: Bool) {
        favoriteBarButton.image = UIImage(
            systemName: isFavorite ? "heart.fill" : "heart"
        )
        favoriteBarButton.accessibilityValue = isFavorite ? "설정됨" : "해제됨"
    }

    private func updateMemo(_ memoText: String) {
        let hasMemo = !memoText.isEmpty
        memoBodyLabel.text = hasMemo ? memoText : "작성된 메모가 없습니다"
        memoBodyLabel.textColor = hasMemo ? .dsInk : .dsSubtleInk
        memoEditButton.setTitle(hasMemo ? "메모 수정" : "메모 작성", for: .normal)
    }
}
