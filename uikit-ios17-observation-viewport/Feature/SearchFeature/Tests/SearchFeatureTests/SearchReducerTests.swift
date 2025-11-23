import Foundation
import Testing

import BookModel
import SearchFeatureInterface

@testable import SearchFeature

struct SearchReducerTests {

    private let sut = SearchReducer()

    private func makeBook(_ isbn: String) -> Book {
        Book(isbn: isbn, title: "책 \(isbn)")
    }

    private func makeBooks(_ isbns: [String]) -> [Book] {
        isbns.map(self.makeBook)
    }

    private func makeLoadedState(
        query: String = "민음사",
        books: [String] = ["1", "2"],
        totalCount: Int = 100
    ) -> SearchReducer.State {
        var state = SearchReducer.State()
        state.query = query
        state.resultsQuery = query
        state.books = self.makeBooks(books)
        state.seenBookIDs = Set(books)
        state.currentPage = 1
        state.totalCount = totalCount
        state.pagination = .ready
        return state
    }

    @Test
    func 화면이뜨면_최근검색어와즐겨찾기와메모를관찰한다() {
        var state = SearchReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.viewDidLoad))

        #expect(effects == [.loadRecentTerms, .observeFavorites, .observeMemos])
    }

    @Test
    func 검색어가비어있으면_최근검색어화면을보인다() {
        let state = SearchReducer.State()

        #expect(state.isShowingRecents)
    }

    @Test
    func 검색어를입력하면_디바운스검색을요청한다() {
        var state = SearchReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.queryChanged("민음사")))

        #expect(effects == [.searchDebounced(query: "민음사")])
        #expect(state.query == "민음사")
        #expect(state.pagination == .loading(isFirstPage: true))
    }

    @Test
    func 앞뒤공백은_잘라내고본다() {
        var state = SearchReducer.State()

        _ = self.sut.reduce(into: &state, action: .view(.queryChanged("  민음사  ")))

        #expect(state.query == "민음사")
    }

    @Test
    func 트림결과가같은입력은_요청을내지않는다() {
        var state = SearchReducer.State()
        _ = self.sut.reduce(into: &state, action: .view(.queryChanged("민음사")))

        let effects = self.sut.reduce(into: &state, action: .view(.queryChanged("민음사 ")))

        #expect(effects == [])
    }

    @Test
    func 입력을비우면_진행중검색을취소하고최근검색어로돌아간다() {
        var state = self.makeLoadedState()

        let effects = self.sut.reduce(into: &state, action: .view(.queryChanged("")))

        #expect(effects == [.cancel(.search)])
        #expect(state.books == [])
        #expect(state.seenBookIDs == [])
        #expect(state.resultsQuery == "")
        #expect(state.pagination == .idle)
        #expect(state.isShowingRecents)
    }

    @Test
    func 입력이바뀌어도_결과가도착하기전에는목록을비우지않는다() {
        var state = self.makeLoadedState(query: "민음", books: ["1", "2"])

        _ = self.sut.reduce(into: &state, action: .view(.queryChanged("민음사")))

        #expect(state.books.map(\.isbn) == ["1", "2"])
    }

    @Test
    func 새질의를시작하면_페이지계수기를되돌린다() {
        var state = self.makeLoadedState()
        state.currentPage = 3
        state.consecutiveEmptyPages = 2

        _ = self.sut.reduce(into: &state, action: .view(.queryChanged("파친코")))

        #expect(state.currentPage == 0)
        #expect(state.totalCount == 0)
        #expect(state.consecutiveEmptyPages == 0)
    }

    @Test
    func 검색을제출하면_최근검색어로기록한다() {
        var state = SearchReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.submitQuery("민음사")))

        #expect(effects.contains(.recordRecentTerm("민음사")))
    }

    @Test
    func 이미같은질의의결과가있으면_다시가져오지않는다() {
        var state = self.makeLoadedState(query: "민음사")

        let effects = self.sut.reduce(into: &state, action: .view(.submitQuery("민음사")))

        #expect(effects == [.recordRecentTerm("민음사")])
    }

    @Test
    func 같은질의여도_결과가비어있으면다시가져온다() {
        var state = self.makeLoadedState(query: "민음사", books: [])

        let effects = self.sut.reduce(into: &state, action: .view(.submitQuery("민음사")))

        #expect(effects == [.recordRecentTerm("민음사"), .search(query: "민음사", page: 1)])
    }

    @Test
    func 다른질의를제출하면_기록하고첫페이지를가져온다() {
        var state = self.makeLoadedState(query: "민음사")

        let effects = self.sut.reduce(into: &state, action: .view(.submitQuery("파친코")))

        #expect(effects == [.recordRecentTerm("파친코"), .search(query: "파친코", page: 1)])
        #expect(state.pagination == .loading(isFirstPage: true))
    }

    @Test
    func 빈질의를제출하면_아무것도하지않는다() {
        var state = SearchReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.submitQuery("   ")))

        #expect(effects == [])
    }

    @Test
    func 첫페이지응답은_이전결과를이어붙이지않고갈아치운다() {
        var state = self.makeLoadedState(query: "파친코", books: ["옛1", "옛2"])
        state.resultsQuery = "민음사"

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "파친코",
            .success(books: self.makeBooks(["새1"]), pageNo: 1, totalCount: 10, hasNext: true)
        )))

        #expect(state.books.map(\.isbn) == ["새1"])
        #expect(state.resultsQuery == "파친코")
    }

    @Test
    func 다음페이지응답은_기존목록뒤에이어붙인다() {
        var state = self.makeLoadedState(books: ["1", "2"], totalCount: 100)

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["3", "4"]), pageNo: 2, totalCount: 100, hasNext: true)
        )))

        #expect(state.books.map(\.isbn) == ["1", "2", "3", "4"])
        #expect(state.pagination == .ready)
    }

    @Test
    func 현재질의와다른응답은_버린다() {
        var state = self.makeLoadedState(query: "파친코", books: ["1"])

        let effects = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["다른질의"]), pageNo: 1, totalCount: 10, hasNext: true)
        )))

        #expect(effects == [])
        #expect(state.books.map(\.isbn) == ["1"])
    }

    @Test
    func 중복된책은_목록에두번들어가지않는다() {
        var state = self.makeLoadedState(books: ["1", "2"], totalCount: 100)

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["2", "3"]), pageNo: 2, totalCount: 100, hasNext: true)
        )))

        #expect(state.books.map(\.isbn) == ["1", "2", "3"])
    }

    @Test
    func 빈페이지가오면_끝으로본다() {
        var state = self.makeLoadedState(totalCount: 100)

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: [], pageNo: 2, totalCount: 100, hasNext: true)
        )))

        #expect(state.pagination == .exhausted)
    }

    @Test
    func hasNext가거짓이면_끝으로본다() {
        var state = self.makeLoadedState(totalCount: 100)

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["3"]), pageNo: 2, totalCount: 100, hasNext: false)
        )))

        #expect(state.pagination == .exhausted)
    }

    @Test
    func hasNext가참이어도_누적건수가전체에닿으면끝으로본다() {
        var state = self.makeLoadedState(books: ["1", "2"], totalCount: 3)

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["3"]), pageNo: 2, totalCount: 3, hasNext: true)
        )))

        #expect(state.pagination == .exhausted)
    }

    @Test
    func 중복만담긴페이지가오면_다음페이지를이어서요청한다() {
        var state = self.makeLoadedState(books: ["1", "2"], totalCount: 100)

        let effects = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["1", "2"]), pageNo: 2, totalCount: 100, hasNext: true)
        )))

        #expect(effects == [.search(query: "민음사", page: 3)])
        #expect(state.consecutiveEmptyPages == 1)
        #expect(state.pagination == .loading(isFirstPage: false))
    }

    @Test
    func 중복페이지가세번연속이면_끝으로보고멈춘다() {
        var state = self.makeLoadedState(books: ["1"], totalCount: 100)
        state.consecutiveEmptyPages = 2

        let effects = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["1"]), pageNo: 2, totalCount: 100, hasNext: true)
        )))

        #expect(effects == [])
        #expect(state.pagination == .exhausted)
    }

    @Test
    func 새항목이하나라도있으면_중복계수기를되돌린다() {
        var state = self.makeLoadedState(books: ["1"], totalCount: 100)
        state.consecutiveEmptyPages = 2

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["1", "2"]), pageNo: 2, totalCount: 100, hasNext: true)
        )))

        #expect(state.consecutiveEmptyPages == 0)
        #expect(state.pagination == .ready)
    }

    @Test
    func 바닥에닿으면_다음페이지를요청한다() {
        var state = self.makeLoadedState()

        let effects = self.sut.reduce(into: &state, action: .view(.reachedNearBottom))

        #expect(effects == [.search(query: "민음사", page: 2)])
        #expect(state.pagination == .loading(isFirstPage: false))
    }

    @Test
    func 이미로딩중이면_바닥에닿아도요청하지않는다() {
        var state = self.makeLoadedState()
        state.pagination = .loading(isFirstPage: false)

        let effects = self.sut.reduce(into: &state, action: .view(.reachedNearBottom))

        #expect(effects == [])
    }

    @Test
    func 끝까지받았으면_바닥에닿아도요청하지않는다() {
        var state = self.makeLoadedState()
        state.pagination = .exhausted

        let effects = self.sut.reduce(into: &state, action: .view(.reachedNearBottom))

        #expect(effects == [])
    }

    @Test
    func 실패상태에서는_바닥에닿아도자동으로재시도하지않는다() {
        var state = self.makeLoadedState()
        state.pagination = .failed

        let effects = self.sut.reduce(into: &state, action: .view(.reachedNearBottom))

        #expect(effects == [])
    }

    @Test
    func 재시도를누르면_실패한페이지를다시요청한다() {
        var state = self.makeLoadedState()
        state.pagination = .failed

        let effects = self.sut.reduce(into: &state, action: .view(.retryPagination))

        #expect(effects == [.search(query: "민음사", page: 2)])
    }

    @Test
    func 실패상태가아니면_재시도가아무것도하지않는다() {
        var state = self.makeLoadedState()

        let effects = self.sut.reduce(into: &state, action: .view(.retryPagination))

        #expect(effects == [])
    }

    @Test
    func 첫페이지재시도는_하단푸터가아니라전체로딩이다() {
        var state = SearchReducer.State()
        state.query = "민음사"
        state.currentPage = 0
        state.pagination = .failed

        _ = self.sut.reduce(into: &state, action: .view(.retryPagination))

        #expect(state.pagination == .loading(isFirstPage: true))
    }

    @Test
    func 요청이실패하면_실패상태로남긴다() {
        var state = self.makeLoadedState()

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사", .failure
        )))

        #expect(state.pagination == .failed)
    }

    @Test
    func 추가페이지가실패해도_이미받은결과는유지한다() {
        var state = self.makeLoadedState(books: ["1", "2"])

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사", .failure
        )))

        #expect(state.books.map(\.isbn) == ["1", "2"])
    }

    @Test
    func 새질의의첫페이지가실패하면_이전질의결과를치운다() {
        var state = self.makeLoadedState(query: "민음사", books: ["1", "2"])
        state.query = "파친코"
        state.resultsQuery = "민음사"

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "파친코", .failure
        )))

        #expect(state.books == [])
        #expect(state.seenBookIDs == [])
        #expect(state.pagination == .failed)
    }

    @Test
    func 하트를누르면_상태를먼저뒤집고쓰기를낸다() {
        var state = SearchReducer.State()
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.toggleFavorite(book)))

        #expect(state.favoriteISBNs.contains("1"))
        #expect(effects == [.setFavorite(book, to: true)])
    }

    @Test
    func 이미즐겨찾기인책의하트를누르면_해제로낸다() {
        var state = SearchReducer.State()
        state.favoriteISBNs = ["1"]
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.toggleFavorite(book)))

        #expect(!(state.favoriteISBNs.contains("1")))
        #expect(effects == [.setFavorite(book, to: false)])
    }

    @Test
    func 즐겨찾기스트림이바뀌면_상태를그값으로맞춘다() {
        var state = SearchReducer.State()
        state.favoriteISBNs = ["1"]

        _ = self.sut.reduce(into: &state, action: .feedback(.favoritesChanged(["2", "3"])))

        #expect(state.favoriteISBNs == ["2", "3"])
    }

    @Test
    func 메모스트림이바뀌면_배지대상을맞춘다() {
        var state = SearchReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(.memosChanged(["1"])))

        #expect(state.memoISBNs == ["1"])
    }

    @Test
    func 최근검색어를불러오면_상태에담는다() {
        var state = SearchReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(.recentTermsLoaded(["민음사", "파친코"])))

        #expect(state.recentTerms == ["민음사", "파친코"])
    }

    @Test
    func 최근검색어를지우면_삭제를낸다() {
        var state = SearchReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.removeRecentTerm("민음사")))

        #expect(effects == [.removeRecentTerm("민음사")])
    }

    @Test
    func 책을고르면_상세로넘긴다() {
        var state = SearchReducer.State()
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.selectBook(book)))

        #expect(effects == [.delegate(.didSelectBook(book))])
    }

    @Test
    func 로딩상태만_isLoading이참이다() {
        #expect(SearchReducer.Pagination.loading(isFirstPage: true).isLoading)
        #expect(SearchReducer.Pagination.loading(isFirstPage: false).isLoading)
        #expect(!(SearchReducer.Pagination.idle.isLoading))
        #expect(!(SearchReducer.Pagination.ready.isLoading))
        #expect(!(SearchReducer.Pagination.exhausted.isLoading))
        #expect(!(SearchReducer.Pagination.failed.isLoading))
    }
}
