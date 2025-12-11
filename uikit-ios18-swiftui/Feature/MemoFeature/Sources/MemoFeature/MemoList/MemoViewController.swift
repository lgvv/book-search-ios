import UIKit

import BookModel
import BookUI
import CommonUI
import DesignSystem
import ImageUI
import MemoCore
import MemoModel
import FeatureSupport
import SharedFoundation

private enum MemoSection: Hashable {
    case memos
}

final class MemoViewController: UIViewController {

    private let store: MemoStore

    private var dataSource: UICollectionViewDiffableDataSource<MemoSection, String>?

    private var observer: StateObserver?

    private var favoriteISBNsRender = Rendered<Set<String>>()
    private var memosRender = Rendered<ResourceState<[BookMemo]>>()

    private func observe() {
        self.observer = StateObserver { [weak self] in
            guard let self else { return }

            if let change = self.favoriteISBNsRender.changed(to: self.store.state.favoriteISBNs) {
                self.applyFavorites(from: change.old, to: change.new)
            }
            if let change = self.memosRender.changed(to: self.store.state.memos) {
                self.applyMemos(from: change.old, to: change.new)
            }
        }
    }

    init(store: MemoStore) {
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

        store.send(.start)
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
        title = "메모"
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

extension MemoViewController {
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { _, environment in
            BookListLayout.section(environment: environment)
        }
        return layout
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<BookListCell, String> { [weak self] cell, _, isbn in
            guard let self, let memo = self.memo(for: isbn) else { return }
            let book = memo.book
            cell.configure(
                with: book,
                isFavorite: self.store.state.favoriteISBNs.contains(book.isbn),
                hasMemo: true,
                caption: DateDisplay.relative(memo.updatedAt)
            )
            cell.onToggleFavorite = { [weak self] in
                self?.store.send(.toggleFavorite(book))
            }
        }
        dataSource = UICollectionViewDiffableDataSource<MemoSection, String>(
            collectionView: collectionView
        ) { collectionView, indexPath, isbn in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: isbn
            )
        }
    }

    private func memo(for isbn: String) -> BookMemo? {
        (store.state.memos.value ?? []).first { $0.id == isbn }
    }

    private func applyMemos(
        from old: ResourceState<[BookMemo]>?,
        to state: ResourceState<[BookMemo]>
    ) {
        if state.isStale {
            staleBanner.configure(message: "목록을 최신으로 확인하지 못했습니다")
            staleBanner.isHidden = false
        } else {
            staleBanner.isHidden = true
        }

        switch state {
        case .loading:
            stateView.isHidden = true

        case let .loaded(memos, _):
            var snapshot = NSDiffableDataSourceSnapshot<MemoSection, String>()
            snapshot.appendSections([.memos])
            snapshot.appendItems(memos.map(\.id), toSection: .memos)

            if let previousMemos = old?.value {
                let previous = Dictionary(
                    previousMemos.map { ($0.id, $0) },
                    uniquingKeysWith: { _, last in last }
                )
                let changed = memos.filter { memo in
                    guard let before = previous[memo.id] else { return false }
                    return before != memo
                }
                snapshot.reconfigureItems(changed.map(\.id))
            }
            dataSource?.apply(snapshot, animatingDifferences: false)

            if memos.isEmpty {
                stateView.configure(message: "도서 상세에서 메모 작성을 눌러\n첫 메모를 남겨 보세요")
                stateView.isHidden = false
            } else {
                stateView.isHidden = true
            }

        case .failed:
            stateView.configure(message: "메모 목록을 불러오지 못했습니다", actionTitle: "다시 시도")
            stateView.isHidden = false
        }
    }

    private func applyFavorites(from old: Set<String>?, to new: Set<String>) {
        guard let old else { return }

        let changedISBNs = new.symmetricDifference(old)
        guard var snapshot = dataSource?.snapshot() else { return }
        let targets = snapshot.itemIdentifiers.filter { changedISBNs.contains($0) }
        guard !targets.isEmpty else { return }

        snapshot.reconfigureItems(targets)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}

extension MemoViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let isbn = dataSource?.itemIdentifier(for: indexPath),
              let memo = memo(for: isbn) else { return }
        store.send(.selectBook(memo.book))
    }
}

extension MemoViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        ImagePrefetcher.prefetch(coverURLs(at: indexPaths), targetSize: BookListCell.coverSize)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        ImagePrefetcher.cancel(coverURLs(at: indexPaths))
    }

    private func coverURLs(at indexPaths: [IndexPath]) -> [URL] {
        indexPaths.compactMap { indexPath in
            guard let isbn = dataSource?.itemIdentifier(for: indexPath) else { return nil }
            return memo(for: isbn)?.book.coverImageURL
        }
    }
}
