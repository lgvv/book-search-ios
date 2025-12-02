import UIKit

import BookModel
import BookUI
import CommonUI
import DesignSystem
import FeatureSupport
import ImageUI
import SharedFoundation

private enum FavoriteSection: Hashable {
    case favorites
}

final class FavoriteViewController: UIViewController {

    private let store: FavoriteStore
    private var dataSource: UICollectionViewDiffableDataSource<FavoriteSection, Book>?

    private var observer: StateObserver?

    private var booksRender = Rendered<ResourceState<[Book]>>()
    private var memoISBNsRender = Rendered<Set<String>>()

    private func observe() {
        self.observer = StateObserver { [weak self] in
            guard let self else { return }

            if let change = self.memoISBNsRender.changed(to: self.store.state.memoISBNs) {
                self.applyMemos(from: change.old, to: change.new)
            }
            if let change = self.booksRender.changed(to: self.store.state.books) {
                self.applyBooks(change.new)
            }
        }
    }

    init(store: FavoriteStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        configureDataSource()

        observe()

        store.send(.viewDidLoad)
    }

    private lazy var stateView: EmptyStateView = {
        let view = EmptyStateView()
        view.isHidden = true
        view.onAction = { [weak self] in
            self?.store.send(.retryLoad)
        }
        return view
    }()

    private lazy var staleBanner: StaleBannerView = {
        let view = StaleBannerView()
        view.isHidden = true
        view.onRetry = { [weak self] in
            self?.store.send(.retryLoad)
        }
        return view
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        return collectionView
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [staleBanner, collectionView])
        stack.axis = .vertical
        return stack
    }()

    private func configureUI() {
        title = "즐겨찾기"
        view.backgroundColor = .dsBackground

        view.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        view.addSubview(stateView)
        stateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stateView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            stateView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),
            stateView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            stateView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor)
        ])
    }
}

extension FavoriteViewController {
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] _, environment in
            BookListLayout.section(environment: environment) { [weak self] indexPath in
                self?.removeSwipeActions(at: indexPath)
            }
        }
        return layout
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<BookListCell, Book> { [weak self] cell, _, book in
            cell.configure(
                with: book,
                isFavorite: true,
                hasMemo: self?.store.state.memoISBNs.contains(book.isbn) ?? false
            )
            cell.onToggleFavorite = { [weak self] in
                self?.store.send(.removeFavorite(book))
            }
        }
        dataSource = UICollectionViewDiffableDataSource<FavoriteSection, Book>(
            collectionView: collectionView
        ) { collectionView, indexPath, book in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: book
            )
        }
    }

    private func applyBooks(_ state: ResourceState<[Book]>) {
        if state.isStale {
            staleBanner.configure(message: "목록을 최신으로 확인하지 못했습니다")
            staleBanner.isHidden = false
        } else {
            staleBanner.isHidden = true
        }

        switch state {
        case .loading:
            stateView.isHidden = true

        case let .loaded(books, _):
            var snapshot = NSDiffableDataSourceSnapshot<FavoriteSection, Book>()
            snapshot.appendSections([.favorites])
            snapshot.appendItems(books, toSection: .favorites)
            dataSource?.apply(snapshot, animatingDifferences: true)

            if books.isEmpty {
                stateView.configure(message: "리스트에서 하트를 눌러\n즐겨찾기를 추가해 보세요")
                stateView.isHidden = false
            } else {
                stateView.isHidden = true
            }

        case .failed:
            stateView.configure(message: "즐겨찾기를 불러오지 못했습니다", actionTitle: "다시 시도")
            stateView.isHidden = false
        }
    }

    private func applyMemos(from old: Set<String>?, to new: Set<String>) {
        guard let old else { return }

        let changedISBNs = new.symmetricDifference(old)
        guard var snapshot = dataSource?.snapshot() else { return }
        let targets = snapshot.itemIdentifiers.filter { changedISBNs.contains($0.isbn) }
        guard !targets.isEmpty else { return }

        snapshot.reconfigureItems(targets)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    private func removeSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let book = dataSource?.itemIdentifier(for: indexPath) else { return nil }
        let remove = UIContextualAction(style: .destructive, title: "제거") { [weak self] _, _, completion in
            self?.store.send(.removeFavorite(book))
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [remove])
    }
}

extension FavoriteViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let book = dataSource?.itemIdentifier(for: indexPath) else { return }
        store.send(.selectBook(book))
    }
}

extension FavoriteViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        ImagePrefetcher.prefetch(coverURLs(at: indexPaths), targetSize: BookListCell.coverSize)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        ImagePrefetcher.cancel(coverURLs(at: indexPaths))
    }

    private func coverURLs(at indexPaths: [IndexPath]) -> [URL] {
        indexPaths.compactMap { dataSource?.itemIdentifier(for: $0)?.coverImageURL }
    }
}
