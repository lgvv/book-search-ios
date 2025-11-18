import Combine
import Foundation

import BookModel
import RecentlyViewedModel
import SharedFoundation

public protocol RecentlyViewedRepository: Sendable {
    func record(book: Book, keeping maxCount: Int) async throws
    func list() async throws -> [ViewedBook]
    func remove(isbn: String) async throws
    func clear() async throws
}

final class DefaultRecentlyViewedService: Sendable {
    private let repository: any RecentlyViewedRepository
    private let maxCount: Int

    private let subject: LockIsolated<CurrentValueSubject<ResourceState<[ViewedBook]>, Never>>

    private let publishQueue = SerialTaskQueue()

    private let writeQueue = SerialTaskQueue()

    init(repository: any RecentlyViewedRepository, maxCount: Int) {
        self.repository = repository
        self.maxCount = maxCount
        self.subject = LockIsolated(CurrentValueSubject<ResourceState<[ViewedBook]>, Never>(.loading))
    }

    func start() async {
        await refresh()
    }

    func record(_ book: Book) async {
        let didWrite = await write { [repository, maxCount] in
            try await repository.record(book: book, keeping: maxCount)
        }
        if didWrite {
            await apply { current in
                var items = current.filter { $0.book.isbn != book.isbn }
                items.insert(ViewedBook(book: book, viewedAt: Date()), at: 0)
                return Array(items.prefix(self.maxCount))
            }
        }
        await refresh()
    }

    func remove(isbn: String) async {
        let didWrite = await write { [repository] in
            try await repository.remove(isbn: isbn)
        }
        if didWrite {
            await apply { $0.filter { $0.book.isbn != isbn } }
        }
        await refresh()
    }

    func clear() async {
        let didWrite = await write { [repository] in
            try await repository.clear()
        }
        if didWrite {
            await apply { _ in [] }
        }
        await refresh()
    }

    func list() async -> [ViewedBook] {
        self.subject.value.value.value ?? []
    }

    func observe() -> AnyPublisher<ResourceState<[ViewedBook]>, Never> {
        self.subject.value
            .buffer(size: 64, prefetch: .keepFull, whenFull: .dropOldest)
            .eraseToAnyPublisher()
    }

    func reload() async {
        await refresh()
    }

    private func write(_ operation: @escaping @Sendable () async throws -> Void) async -> Bool {
        let task = self.writeQueue.enqueue {
            try await operation()
            return true
        }
        return (try? await task.value) ?? false
    }

    private func apply(
        _ transform: @escaping @Sendable ([ViewedBook]) -> [ViewedBook]
    ) async {
        try? await self.publishQueue.enqueue { [subject] in
            guard let current = subject.value.value.value else { return }
            subject.value.send(.loaded(transform(current), isStale: subject.value.value.isStale))
        }.value
    }

    private func refresh() async {
        try? await self.publishQueue.enqueue { [repository, subject] in
            if subject.value.value.value == nil {
                subject.value.send(.loading)
            }
            do {
                let items = try await repository.list()
                subject.value.send(.loaded(items))
            } catch {
                if let previous = subject.value.value.value {
                    subject.value.send(.loaded(previous, isStale: true))
                } else {
                    subject.value.send(.failed)
                }
            }
        }.value
    }
}
