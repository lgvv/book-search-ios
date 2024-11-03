import Combine
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
    private let subject: LockIsolated<CurrentValueSubject<ResourceState<[BookMemo]>, Never>>
    private let publishQueue = SerialTaskQueue()
    private let writeQueue = KeyedSerialQueue<String>()

    init(repository: any MemoRepository) {
        self.repository = repository
        self.subject = LockIsolated(CurrentValueSubject<ResourceState<[BookMemo]>, Never>(.loading))
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

    func observe() -> AnyPublisher<ResourceState<[BookMemo]>, Never> {
        subject.value
            .buffer(size: 64, prefetch: .keepFull, whenFull: .dropOldest)
            .eraseToAnyPublisher()
    }

    func reload() async {
        if loadedMemos == nil {
            try? await loadIfNeeded()
        } else {
            await refresh()
        }
    }

    private var loadedMemos: [BookMemo]? {
        subject.value.value.value
    }

    private func loadIfNeeded() async throws {
        guard loadedMemos == nil else { return }
        try await publishQueue.enqueue { [repository, subject] in
            guard subject.value.value.value == nil else { return }
            subject.value.send(.loading)
            do {
                let memos = try await repository.list()
                subject.value.send(.loaded(memos))
            } catch {
                subject.value.send(.failed)
                throw error
            }
        }.value
    }

    private func apply(isbn: String, memo: BookMemo?) async {
        try? await publishQueue.enqueue { [subject] in
            guard let current = subject.value.value.value else { return }
            var memos = current.filter { $0.book.isbn != isbn }
            if let memo {
                memos.append(memo)
                memos.sort { $0.updatedAt > $1.updatedAt }
            }
            subject.value.send(.loaded(memos, isStale: subject.value.value.isStale))
        }.value
    }

    private func refresh() async {
        try? await publishQueue.enqueue { [repository, subject] in
            do {
                let memos = try await repository.list()
                subject.value.send(.loaded(memos))
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
