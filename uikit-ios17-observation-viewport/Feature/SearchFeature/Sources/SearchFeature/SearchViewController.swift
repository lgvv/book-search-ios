import UIKit

import BookModel
import BookUI
import CommonUI
import DesignSystem
import FeatureSupport
import ImageUI

private enum SearchSection: Hashable {
    case recents
    case results
}

private enum SearchItem: Hashable {
    case recentTerm(String)
    case book(Book)
    case pagingFooter(PagingFooterCell.Mode)
}

private enum SearchEmptyState: Equatable {
    case noResults
    case failed
}

private struct SearchRender: Equatable {
    let query: String
    let isShowingRecents: Bool
    let recentTerms: [String]
    let books: [Book]
    let favoriteISBNs: Set<String>
    let memoISBNs: Set<String>
    let footer: PagingFooterCell.Mode?
    let emptyState: SearchEmptyState?

    init(_ state: SearchReducer.State) {
        self.query = state.query
        self.isShowingRecents = state.isShowingRecents
        self.recentTerms = state.recentTerms
        self.books = state.books
        self.favoriteISBNs = state.favoriteISBNs
        self.memoISBNs = state.memoISBNs

        let hasResults = !state.books.isEmpty
        switch state.pagination {
        case .loading(isFirstPage: false) where hasResults:
            self.footer = .loading
            self.emptyState = nil
        case .failed where hasResults:
            self.footer = .failed
            self.emptyState = nil
        case .failed:
            self.footer = nil
            self.emptyState = .failed
        case .exhausted where !hasResults && !state.query.isEmpty:
            self.footer = nil
            self.emptyState = .noResults
        default:
            self.footer = nil
            self.emptyState = nil
        }
    }
}

final class SearchViewController: UIViewController {

    private let store: SearchStore
    private var dataSource: UICollectionViewDiffableDataSource<SearchSection, SearchItem>?

    private var observer: StateObserver?

    private var searchRender = Rendered<SearchRender>()

    private func observe() {
        self.observer = StateObserver { [weak self] in
            guard let self else { return }

            if let change = self.searchRender.changed(to: SearchRender(self.store.state)) {
                self.applySnapshot(from: change.old, to: change.new)
            }
        }
    }

    init(store: SearchStore) {
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

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "책 제목 검색"
        searchController.searchBar.accessibilityLabel = "책 제목 검색"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        return searchController
    }()

    private lazy var emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        view.isHidden = true
        view.onAction = { [weak self] in
            self?.store.send(.retryPagination)
        }
        return view
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.keyboardDismissMode = .onDrag
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        return collectionView
    }()

    private func configureUI() {
        title = "검색"
        view.backgroundColor = .dsBackground
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        view.addSubview(emptyStateView)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor)
        ])
    }

    private func renderEmptyState(_ state: SearchEmptyState?) {
        switch state {
        case .noResults:
            emptyStateView.configure(message: "검색 결과가 없습니다")
        case .failed:
            emptyStateView.configure(message: "검색 결과를 가져오지 못했습니다", actionTitle: "다시 시도")
        case nil:
            break
        }
        emptyStateView.isHidden = state == nil
    }
}

extension SearchViewController {
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] _, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            configuration.showsSeparators = false
            configuration.backgroundColor = .dsBackground
            if self?.store.state.isShowingRecents == true {
                configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
                    self?.recentTermSwipeActions(at: indexPath)
                }
            }
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        }
        return layout
    }

    private func configureDataSource() {
        let bookRegistration = UICollectionView.CellRegistration<BookListCell, Book> { [weak self] cell, _, book in
            guard let self else { return }
            cell.configure(
                with: book,
                isFavorite: store.state.favoriteISBNs.contains(book.isbn),
                hasMemo: store.state.memoISBNs.contains(book.isbn)
            )
            cell.onToggleFavorite = { [weak self] in
                self?.store.send(.toggleFavorite(book))
            }
        }
        let recentRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, String> {
            [weak self] cell, _, term in
            var content = cell.defaultContentConfiguration()
            content.text = term
            content.image = UIImage(systemName: "clock")
            content.imageProperties.tintColor = .secondaryLabel
            cell.contentConfiguration = content

            cell.accessibilityCustomActions = [
                UIAccessibilityCustomAction(name: "삭제") { [weak self] _ in
                    self?.store.send(.removeRecentTerm(term))
                    return true
                }
            ]
        }
        let footerRegistration = UICollectionView.CellRegistration<PagingFooterCell, PagingFooterCell.Mode> {
            [weak self] cell, _, mode in
            cell.configure(mode: mode)
            cell.onRetry = { [weak self] in
                self?.store.send(.retryPagination)
            }
        }
        dataSource = UICollectionViewDiffableDataSource<SearchSection, SearchItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .book(let book):
                collectionView.dequeueConfiguredReusableCell(using: bookRegistration, for: indexPath, item: book)
            case .recentTerm(let term):
                collectionView.dequeueConfiguredReusableCell(using: recentRegistration, for: indexPath, item: term)
            case .pagingFooter(let mode):
                collectionView.dequeueConfiguredReusableCell(using: footerRegistration, for: indexPath, item: mode)
            }
        }
    }

    private func applySnapshot(from old: SearchRender?, to new: SearchRender) {
        let displayed = Set(dataSource?.snapshot().itemIdentifiers ?? [])

        let changedISBNs = old.map { previous in
            new.favoriteISBNs.symmetricDifference(previous.favoriteISBNs)
                .union(new.memoISBNs.symmetricDifference(previous.memoISBNs))
        } ?? []

        var snapshot = NSDiffableDataSourceSnapshot<SearchSection, SearchItem>()
        if new.isShowingRecents {
            snapshot.appendSections([.recents])
            snapshot.appendItems(new.recentTerms.map(SearchItem.recentTerm), toSection: .recents)
        } else {
            snapshot.appendSections([.results])
            snapshot.appendItems(new.books.map(SearchItem.book), toSection: .results)
            if let footer = new.footer {
                snapshot.appendItems([.pagingFooter(footer)], toSection: .results)
            }
        }
        snapshot.reconfigureItems(
            snapshot.itemIdentifiers.filter { item in
                guard case .book(let book) = item else { return false }
                return displayed.contains(item) && changedISBNs.contains(book.isbn)
            }
        )
        let queryChanged = old.map { $0.query != new.query } ?? false
        dataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
            guard queryChanged, let collectionView = self?.collectionView else { return }
            collectionView.setContentOffset(
                CGPoint(x: 0, y: -collectionView.adjustedContentInset.top),
                animated: false
            )
        }
        renderEmptyState(new.emptyState)
    }

    private func recentTermSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard case .recentTerm(let term) = dataSource?.itemIdentifier(for: indexPath) else { return nil }
        let delete = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completion in
            self?.store.send(.removeRecentTerm(term))
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        store.send(.submitQuery(searchBar.text ?? ""))
        searchController.isActive = false
        searchController.searchBar.text = store.state.query
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        store.send(.queryChanged(searchText))
    }
}

extension SearchViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard !store.state.isShowingRecents,
              case .book = dataSource?.itemIdentifier(for: indexPath) else { return }
        if indexPath.item >= store.state.books.count - 5 {
            DispatchQueue.main.async { [weak self] in
                self?.store.send(.reachedNearBottom)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        switch dataSource?.itemIdentifier(for: indexPath) {
        case .book(let book):
            store.send(.selectBook(book))
        case .recentTerm(let term):
            searchController.searchBar.text = term
            store.send(.submitQuery(term))
        case .pagingFooter:
            break
        case nil:
            break
        }
    }
}

extension SearchViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        ImagePrefetcher.prefetch(coverURLs(at: indexPaths), targetSize: BookListCell.coverSize)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        ImagePrefetcher.cancel(coverURLs(at: indexPaths))
    }

    private func coverURLs(at indexPaths: [IndexPath]) -> [URL] {
        indexPaths.compactMap { indexPath in
            guard case .book(let book) = dataSource?.itemIdentifier(for: indexPath) else { return nil }
            return book.coverImageURL
        }
    }
}
