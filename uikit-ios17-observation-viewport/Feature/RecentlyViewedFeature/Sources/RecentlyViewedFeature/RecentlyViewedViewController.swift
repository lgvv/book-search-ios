import UIKit

import BookModel
import BookUI
import CommonUI
import DesignSystem
import FeatureSupport
import ImageUI
import RecentlyViewedModel
import SharedFoundation

private enum RecentlyViewedSection: Hashable {
    case items
}

final class RecentlyViewedViewController: UIViewController {

    private let store: RecentlyViewedStore

    private var dataSource: UICollectionViewDiffableDataSource<RecentlyViewedSection, String>?

    private var observer: StateObserver?

    private var favoriteISBNsRender = Rendered<Set<String>>()
    private var memoISBNsRender = Rendered<Set<String>>()
    private var itemsRender = Rendered<ResourceState<[ViewedBook]>>()
    private var canClearRender = Rendered<Bool>()

    private func observe() {
        self.observer = StateObserver { [weak self] in
            guard let self else { return }

            if let change = self.favoriteISBNsRender.changed(to: self.store.state.favoriteISBNs) {
                self.applyBadges(from: change.old, to: change.new)
            }
            if let change = self.memoISBNsRender.changed(to: self.store.state.memoISBNs) {
                self.applyBadges(from: change.old, to: change.new)
            }
            if let change = self.itemsRender.changed(to: self.store.state.items) {
                self.applyItems(from: change.old, to: change.new)
            }
            if let change = self.canClearRender.changed(to: self.store.state.canClear) {
                self.clearButton.isEnabled = change.new
                self.navigationItem.rightBarButtonItem = change.new ? self.clearButton : nil
            }
        }
    }

    init(store: RecentlyViewedStore) {
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

    private lazy var clearButton: UIBarButtonItem = {
        UIBarButtonItem(
            title: "전체 지우기",
            primaryAction: UIAction { [weak self] _ in
                self?.confirmClearAll()
            }
        )
    }()

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
        title = "최근 본"
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

    private func confirmClearAll() {
        presentAlert(.confirmDestructive(
            title: "최근 본 기록을 지울까요?",
            message: "목록에서만 사라지고 즐겨찾기와 메모는 그대로입니다.",
            actionTitle: "전체 지우기",
            onConfirm: { [weak self] in
                self?.store.send(.confirmClearAll)
            }
        ))
    }
}

extension RecentlyViewedViewController {
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] _, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            configuration.showsSeparators = false
            configuration.backgroundColor = .dsBackground
            configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
                self?.removeSwipeActions(at: indexPath)
            }
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        }
        return layout
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<BookListCell, String> { [weak self] cell, _, isbn in
            guard let self, let item = self.item(for: isbn) else { return }
            cell.configure(
                with: item.book,
                isFavorite: self.store.state.favoriteISBNs.contains(isbn),
                hasMemo: self.store.state.memoISBNs.contains(isbn),
                caption: DateDisplay.relative(item.viewedAt)
            )
            cell.onToggleFavorite = nil
        }
        dataSource = UICollectionViewDiffableDataSource<RecentlyViewedSection, String>(
            collectionView: collectionView
        ) { collectionView, indexPath, isbn in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: isbn
            )
        }
    }

    private func item(for isbn: String) -> ViewedBook? {
        (store.state.items.value ?? []).first { $0.book.isbn == isbn }
    }

    private func applyItems(
        from old: ResourceState<[ViewedBook]>?,
        to state: ResourceState<[ViewedBook]>
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

        case let .loaded(items, _):
            var snapshot = NSDiffableDataSourceSnapshot<RecentlyViewedSection, String>()
            snapshot.appendSections([.items])
            snapshot.appendItems(items.map(\.id), toSection: .items)

            if let previousItems = old?.value {
                let previous = Dictionary(
                    previousItems.map { ($0.id, $0) },
                    uniquingKeysWith: { _, last in last }
                )
                let changed = items.filter { item in
                    guard let before = previous[item.id] else { return false }
                    return before != item
                }
                snapshot.reconfigureItems(changed.map(\.id))
            }
            dataSource?.apply(snapshot, animatingDifferences: true)

            if items.isEmpty {
                stateView.configure(message: "도서 상세를 열면\n최근 본 목록에 쌓입니다")
                stateView.isHidden = false
            } else {
                stateView.isHidden = true
            }

        case .failed:
            stateView.configure(message: "최근 본 목록을 불러오지 못했습니다", actionTitle: "다시 시도")
            stateView.isHidden = false
        }
    }

    private func applyBadges(from old: Set<String>?, to new: Set<String>) {
        guard let old else { return }

        let changedISBNs = new.symmetricDifference(old)
        guard var snapshot = dataSource?.snapshot() else { return }
        let targets = snapshot.itemIdentifiers.filter { changedISBNs.contains($0) }
        guard !targets.isEmpty else { return }

        snapshot.reconfigureItems(targets)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    private func removeSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let isbn = dataSource?.itemIdentifier(for: indexPath) else { return nil }
        let remove = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completion in
            self?.store.send(.removeItem(isbn: isbn))
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [remove])
    }
}

extension RecentlyViewedViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let isbn = dataSource?.itemIdentifier(for: indexPath),
              let item = item(for: isbn) else { return }
        store.send(.selectBook(item.book))
    }
}

extension RecentlyViewedViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        ImagePrefetcher.prefetch(coverURLs(at: indexPaths), targetSize: BookListCell.coverSize)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        ImagePrefetcher.cancel(coverURLs(at: indexPaths))
    }

    private func coverURLs(at indexPaths: [IndexPath]) -> [URL] {
        indexPaths
            .compactMap { dataSource?.itemIdentifier(for: $0) }
            .compactMap { item(for: $0)?.book.coverImageURL }
    }
}
