import Foundation

import BookModel
import MemoModel
import SharedFoundation

public protocol MemoRepository: Sendable {
    func list() async throws -> [BookMemo]
    func save(_ book: Book, text: String, updatedAt: Date) async throws
    func remove(isbn: String) async throws
}

final class DefaultMemoService: Sendable {
    private let repository: any MemoRepository
    private let cache: AsyncValueChannel<ResourceState<[BookMemo]>>
    private let publishQueue = SerialTaskQueue()
    private let writeQueue = KeyedSerialQueue<String>()

    init(repository: any MemoRepository) {
        self.repository = repository
        self.cache = AsyncValueChannel<ResourceState<[BookMemo]>>(.loading)
    }

    func start() async {
        try? await loadIfNeeded()
    }

    func save(_ book: Book, text: String) async throws {
        try await self.writeQueue.enqueue(book.isbn) { [weak self] in
            guard let self else { return }
            try await self.performSave(book, text: text)
        }.value
    }

    private func performSave(_ book: Book, text: String) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            try await loadIfNeeded()
            try await repository.remove(isbn: book.isbn)
            await apply(isbn: book.isbn, memo: nil)
        } else {
            let updatedAt = Date()
            try await repository.save(book, text: trimmed, updatedAt: updatedAt)
            await apply(
                isbn: book.isbn,
                memo: BookMemo(book: book, text: trimmed, updatedAt: updatedAt)
            )
        }
        await refresh()
    }

    func list() async -> [BookMemo] {
        loadedMemos ?? []
    }

    func memo(_ isbn: String) async throws -> MemoLookup {
        try await loadIfNeeded()
        guard let memo = (loadedMemos ?? []).first(where: { $0.book.isbn == isbn }) else {
            return .notFound
        }
        return .found(memo)
    }

    func observe() -> AsyncStream<ResourceState<[BookMemo]>> {
        cache.stream()
    }

    func reload() async {
        if loadedMemos == nil {
            try? await loadIfNeeded()
        } else {
            await refresh()
        }
    }

    private var loadedMemos: [BookMemo]? {
        cache.value.value
    }

    private func loadIfNeeded() async throws {
        guard loadedMemos == nil else { return }
        try await publishQueue.enqueue { [repository, cache] in
            guard cache.value.value == nil else { return }
            cache.send(.loading)
            do {
                let memos = try await repository.list()
                cache.send(.loaded(memos))
            } catch {
                cache.send(.failed)
                throw error
            }
        }.value
    }

    private func apply(isbn: String, memo: BookMemo?) async {
        try? await publishQueue.enqueue { [cache] in
            guard let current = cache.value.value else { return }
            var memos = current.filter { $0.book.isbn != isbn }
            if let memo {
                memos.append(memo)
                memos.sort { $0.updatedAt > $1.updatedAt }
            }
            cache.send(.loaded(memos, isStale: cache.value.isStale))
        }.value
    }

    private func refresh() async {
        try? await publishQueue.enqueue { [repository, cache] in
            do {
                let memos = try await repository.list()
                cache.send(.loaded(memos))
            } catch {
                if let previous = cache.value.value {
                    cache.send(.loaded(previous, isStale: true))
                } else {
                    cache.send(.failed)
                }
            }
        }.value
    }
}
