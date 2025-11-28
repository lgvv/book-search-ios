import Foundation

import BookModel
import DependencyResolver
import SharedFoundation

public protocol FavoriteRepository: Sendable {
    func list() async throws -> [Book]
    func add(_ book: Book) async throws
    func remove(isbn: String) async throws
}

public struct FavoriteWriteFailure: Sendable, Equatable {
    public let isbn: String
    public let desiredIsFavorite: Bool
}

struct FavoriteWriteOutcome: Sendable {
    let isbn: String
    let isFavorite: Bool
    let book: Book?
    let didSucceed: Bool
    let isSupersededByNewerIntent: Bool
}

private final class FavoriteWriteCoalescer: Sendable {
    private struct Write {
        let isFavorite: Bool
        let book: Book?
    }

    private struct QueueState {
        var inFlight: [String: Bool] = [:]
        var pending: [String: Write] = [:]
    }

    private let state = LockIsolated(QueueState())
    private let repository: any FavoriteRepository
    private let afterWrite: @Sendable (FavoriteWriteOutcome) async -> Void

    init(
        repository: any FavoriteRepository,
        afterWrite: @escaping @Sendable (FavoriteWriteOutcome) async -> Void
    ) {
        self.repository = repository
        self.afterWrite = afterWrite
    }

    func submit(isbn: String, isFavorite: Bool, book: Book?) {
        let first: Write? = state.withValue { state in
            if state.inFlight[isbn] != nil {
                state.pending[isbn] = Write(isFavorite: isFavorite, book: book)
                return nil
            }
            state.inFlight[isbn] = isFavorite
            return Write(isFavorite: isFavorite, book: book)
        }
        guard let first else { return }
        drain(isbn: isbn, first: first)
    }

    private func drain(isbn: String, first: Write) {
        Task {
            var current: Write? = first
            while let write = current {
                let didSucceed: Bool
                do {
                    if write.isFavorite, let book = write.book {
                        try await repository.add(book)
                    } else {
                        try await repository.remove(isbn: isbn)
                    }
                    didSucceed = true
                } catch {
                    didSucceed = false
                }

                let hasNewerIntent = state.withValue { $0.pending[isbn] != nil }

                await afterWrite(FavoriteWriteOutcome(
                    isbn: isbn,
                    isFavorite: write.isFavorite,
                    book: write.book,
                    didSucceed: didSucceed,
                    isSupersededByNewerIntent: hasNewerIntent
                ))

                current = state.withValue { state in
                    guard let next = state.pending.removeValue(forKey: isbn) else {
                        state.inFlight[isbn] = nil
                        return nil
                    }
                    if didSucceed, next.isFavorite == write.isFavorite {
                        state.inFlight[isbn] = nil
                        return nil
                    }
                    state.inFlight[isbn] = next.isFavorite
                    return next
                }
            }
        }
    }
}

final class DefaultFavoriteService: Sendable {
    private let cache: AsyncValueChannel<ResourceState<[Book]>>
    private let coalescer: FavoriteWriteCoalescer
    private let refreshAction: @Sendable () async -> Void
    private let failures: AsyncEventChannel<FavoriteWriteFailure>

    init(repository: any FavoriteRepository) {
        let cache = AsyncValueChannel<ResourceState<[Book]>>(.loading)
        let publishQueue = SerialTaskQueue()
        let refresh: @Sendable () async -> Void = {
            try? await publishQueue.enqueue {
                if cache.value.value == nil {
                    cache.send(.loading)
                }
                do {
                    let books = try await repository.list()
                    cache.send(.loaded(books))
                } catch {
                    if let previous = cache.value.value {
                        cache.send(.loaded(previous, isStale: true))
                    } else {
                        cache.send(.failed)
                    }
                }
            }.value
        }

        let apply: @Sendable (FavoriteWriteOutcome) async -> Void = { outcome in
            try? await publishQueue.enqueue {
                guard let current = cache.value.value else { return }
                var books = current.filter { $0.isbn != outcome.isbn }
                if outcome.isFavorite, let book = outcome.book {
                    books.insert(book, at: 0)
                }
                cache.send(.loaded(books, isStale: cache.value.isStale))
            }.value
        }

        let failures = AsyncEventChannel<FavoriteWriteFailure>()

        let afterWrite: @Sendable (FavoriteWriteOutcome) async -> Void = { outcome in
            if outcome.didSucceed {
                await apply(outcome)
            } else if !outcome.isSupersededByNewerIntent {
                failures.send(
                    FavoriteWriteFailure(isbn: outcome.isbn, desiredIsFavorite: outcome.isFavorite)
                )
            }
            await refresh()
        }

        self.cache = cache
        self.failures = failures
        self.coalescer = FavoriteWriteCoalescer(repository: repository, afterWrite: afterWrite)
        self.refreshAction = refresh
    }

    func start() async {
        await refreshAction()
    }

    func add(_ book: Book) async {
        coalescer.submit(isbn: book.isbn, isFavorite: true, book: book)
    }

    func remove(isbn: String) async {
        coalescer.submit(isbn: isbn, isFavorite: false, book: nil)
    }

    func list() async -> [Book] {
        self.cache.value.value ?? []
    }

    func isFavorite(_ isbn: String) async -> Bool {
        (self.cache.value.value ?? []).contains { $0.isbn == isbn }
    }

    func observe() -> AsyncStream<ResourceState<[Book]>> {
        self.cache.stream()
    }

    func observeFailures() -> AsyncStream<FavoriteWriteFailure> {
        self.failures.stream()
    }

    func reload() async {
        await refreshAction()
    }
}
