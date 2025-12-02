import Foundation
import Testing

import BookCore
import BookModel
import DependencyResolver
import FeatureSupport
import FavoriteCore
import MemoCore
import MemoModel
import RecentSearchCore
import SharedFoundation
import TestSupport

@testable import SearchFeature

@MainActor
struct SearchStoreTests {

    private func makeBook(_ isbn: String) -> Book {
        Book(isbn: isbn, title: "책 \(isbn)")
    }

    private func makeStore(
        search: (@Sendable (String, Int) async throws -> SearchPage)? = nil
    ) -> (store: SearchStore, calls: CallRecorder) {
        let recorder = CallRecorder()
        let favorites = AsyncValueChannel<ResourceState<[Book]>>(.loaded([]))
        let memos = AsyncValueChannel<ResourceState<[BookMemo]>>(.loaded([]))

        let store = withResolver(from: .test) { values in
            values[BookSearchClientKey.self] = BookSearchClient(
                search: { query, page in
                    recorder.record("search(\(query),\(page))")
                    if let search { return try await search(query, page) }
                    return SearchPage(books: [], pageNo: page, totalCount: 0, hasNext: false)
                },
                book: { _ in nil }
            )
            values[RecentSearchClientKey.self] = RecentSearchClient(
                record: { recorder.record("recordTerm(\($0))") },
                list: { recorder.record("listTerms"); return ["민음사"] },
                remove: { recorder.record("removeTerm(\($0))") }
            )
            values[FavoriteClientKey.self] = FavoriteClient(
                submitAdd: { recorder.record("addFavorite(\($0.isbn))") },
                submitRemove: { recorder.record("removeFavorite(\($0))") },
                list: { [] },
                isFavorite: { _ in false },
                observe: { favorites.stream() },
                observeFailures: { AsyncStream { $0.finish() } },
                reload: {},
                start: {}
            )
            values[MemoClientKey.self] = MemoClient(
                save: { _, _ in },
                list: { [] },
                memo: { _ in .notFound },
                observe: { memos.stream() },
                reload: {},
                start: {}
            )
        } operation: {
            SearchStore()
        }
        return (store, recorder)
    }

    @Test
    func 화면이뜨면_최근검색어를읽는다() async {
        let (store, recorder) = self.makeStore()

        store.send(.viewDidLoad)

        let didLoad = await waitUntil { recorder.contains("listTerms") }
        #expect(didLoad)
    }

    @Test
    func 입력직후에는_검색요청이나가지않는다() async {
        let (store, recorder) = self.makeStore()

        store.send(.queryChanged("민음사"))

        let stayedQuiet = await stayFalse({ recorder.contains("search(민음사,1)") }, for: 0.1)
        #expect(stayedQuiet)
    }

    @Test
    func 입력후기다리면_검색요청이나간다() async {
        let (store, recorder) = self.makeStore()

        store.send(.queryChanged("민음사"))

        let didSearch = await waitUntil({ recorder.contains("search(민음사,1)") }, timeout: 3)
        #expect(didSearch)
    }

    @Test
    func 대기중에새입력이오면_이전요청은나가지않는다() async {
        let (store, recorder) = self.makeStore()
        store.send(.queryChanged("민"))
        store.send(.queryChanged("민음"))

        store.send(.queryChanged("민음사"))

        let didSearch = await waitUntil({ recorder.contains("search(민음사,1)") }, timeout: 3)
        #expect(didSearch)
        #expect(!(recorder.contains("search(민,1)")))
        #expect(!(recorder.contains("search(민음,1)")))
    }

    @Test
    func 입력을비우면_대기중인검색이취소된다() async {
        let (store, recorder) = self.makeStore()
        store.send(.queryChanged("민음사"))

        store.send(.queryChanged(""))

        let stayedQuiet = await stayFalse({ recorder.contains("search(민음사,1)") }, for: 0.5)
        #expect(stayedQuiet)
    }

    @Test
    func 검색이성공하면_결과가상태에담긴다() async {
        let page = SearchPage(
            books: [Book(isbn: "1", title: "파친코")],
            pageNo: 1,
            totalCount: 1,
            hasNext: false
        )
        let (store, _) = self.makeStore(search: { _, _ in page })

        store.send(.submitQuery("파친코"))

        let didLoad = await waitUntil { @MainActor in store.state.books.count == 1 }
        #expect(didLoad)
        #expect(store.state.books.first?.isbn == "1")
        #expect(store.state.pagination == .exhausted)
    }

    @Test
    func 검색이실패하면_실패상태로남는다() async {
        struct Boom: Error {}
        let (store, _) = self.makeStore(search: { _, _ in throw Boom() })

        store.send(.submitQuery("파친코"))

        let didFail = await waitUntil { @MainActor in store.state.pagination == .failed }
        #expect(didFail)
    }

    @Test
    func 하트를누르면_즐겨찾기추가를제출한다() async {
        let (store, recorder) = self.makeStore()

        store.send(.toggleFavorite(self.makeBook("1")))

        let didSubmit = await waitUntil { recorder.contains("addFavorite(1)") }
        #expect(didSubmit)
    }

    @Test
    func 이미즐겨찾기인책의하트를누르면_제거를제출한다() async {
        let (store, recorder) = self.makeStore()
        store.send(.toggleFavorite(self.makeBook("1")))
        _ = await waitUntil { recorder.contains("addFavorite(1)") }

        store.send(.toggleFavorite(self.makeBook("1")))

        let didRemove = await waitUntil { recorder.contains("removeFavorite(1)") }
        #expect(didRemove)
    }

    @Test
    func 검색을제출하면_최근검색어로기록하고목록을다시읽는다() async {
        let (store, recorder) = self.makeStore()

        store.send(.submitQuery("파친코"))

        let didRecord = await waitUntil { recorder.contains("recordTerm(파친코)") }
        #expect(didRecord)
        #expect(recorder.contains("listTerms"))
    }

    @Test
    func 최근검색어를지우면_삭제하고목록을다시읽는다() async {
        let (store, recorder) = self.makeStore()

        store.send(.removeRecentTerm("민음사"))

        let didRemove = await waitUntil { recorder.contains("removeTerm(민음사)") }
        #expect(didRemove)
        #expect(recorder.contains("listTerms"))
    }

    @Test
    func 책을고르면_위임으로알린다() {
        let (store, _) = self.makeStore()
        let selected = Locked<Book?>(nil)
        store.onDelegate = { action in
            if case let .didSelectBook(book) = action {
                selected.withValue { $0 = book }
            }
        }

        store.send(.selectBook(self.makeBook("1")))

        #expect(selected.value?.isbn == "1")
    }

    @Test
    func 관찰을시작하면_현재값으로한번렌더한다() {
        let (store, _) = self.makeStore()
        var rendered: [Int] = []

        let observer = StateObserver { rendered.append(store.state.books.count) }

        #expect(rendered == [0])
        withExtendedLifetime(observer) {}
    }

    @Test
    func 상태가바뀌면_다음차례에다시렌더한다() async {
        let (store, _) = self.makeStore()
        var rendered: [Int] = []
        let observer = StateObserver { rendered.append(store.state.favoriteISBNs.count) }

        store.send(.toggleFavorite(self.makeBook("9788937400001")))

        await Task.yield()

        #expect(rendered == [0, 1])
        withExtendedLifetime(observer) {}
    }
}

final class CallRecorder: Sendable {
    private let calls = Locked<[String]>([])

    func record(_ call: String) {
        self.calls.withValue { $0.append(call) }
    }

    func contains(_ call: String) -> Bool {
        self.calls.value.contains(call)
    }

    var all: [String] {
        self.calls.value
    }
}
