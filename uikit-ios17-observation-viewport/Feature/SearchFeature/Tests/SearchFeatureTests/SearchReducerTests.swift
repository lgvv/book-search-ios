import XCTest

import BookModel
import SearchFeatureInterface

@testable import SearchFeature

final class SearchReducerTests: XCTestCase {

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

    func test_화면이뜨면_최근검색어와즐겨찾기와메모를관찰한다() {
        var state = SearchReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.viewDidLoad))

        XCTAssertEqual(effects, [.loadRecentTerms, .observeFavorites, .observeMemos])
    }

    func test_검색어가비어있으면_최근검색어화면을보인다() {
        let state = SearchReducer.State()

        XCTAssertTrue(state.isShowingRecents)
    }

    func test_검색어를입력하면_디바운스검색을요청한다() {
        var state = SearchReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.queryChanged("민음사")))

        XCTAssertEqual(effects, [.searchDebounced(query: "민음사")])
        XCTAssertEqual(state.query, "민음사")
        XCTAssertEqual(state.pagination, .loading(isFirstPage: true))
    }

    func test_앞뒤공백은_잘라내고본다() {
        var state = SearchReducer.State()

        _ = self.sut.reduce(into: &state, action: .view(.queryChanged("  민음사  ")))

        XCTAssertEqual(state.query, "민음사")
    }

    func test_트림결과가같은입력은_요청을내지않는다() {
        var state = SearchReducer.State()
        _ = self.sut.reduce(into: &state, action: .view(.queryChanged("민음사")))

        let effects = self.sut.reduce(into: &state, action: .view(.queryChanged("민음사 ")))

        XCTAssertEqual(effects, [])
    }

    func test_입력을비우면_진행중검색을취소하고최근검색어로돌아간다() {
        var state = self.makeLoadedState()

        let effects = self.sut.reduce(into: &state, action: .view(.queryChanged("")))

        XCTAssertEqual(effects, [.cancel(.search)])
        XCTAssertEqual(state.books, [])
        XCTAssertEqual(state.seenBookIDs, [])
        XCTAssertEqual(state.resultsQuery, "")
        XCTAssertEqual(state.pagination, .idle)
        XCTAssertTrue(state.isShowingRecents)
    }

    func test_입력이바뀌어도_결과가도착하기전에는목록을비우지않는다() {
        var state = self.makeLoadedState(query: "민음", books: ["1", "2"])

        _ = self.sut.reduce(into: &state, action: .view(.queryChanged("민음사")))

        XCTAssertEqual(state.books.map(\.isbn), ["1", "2"])
    }

    func test_새질의를시작하면_페이지계수기를되돌린다() {
        var state = self.makeLoadedState()
        state.currentPage = 3
        state.consecutiveEmptyPages = 2

        _ = self.sut.reduce(into: &state, action: .view(.queryChanged("파친코")))

        XCTAssertEqual(state.currentPage, 0)
        XCTAssertEqual(state.totalCount, 0)
        XCTAssertEqual(state.consecutiveEmptyPages, 0)
    }

    func test_검색을제출하면_최근검색어로기록한다() {
        var state = SearchReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.submitQuery("민음사")))

        XCTAssertTrue(effects.contains(.recordRecentTerm("민음사")))
    }

    func test_이미같은질의의결과가있으면_다시가져오지않는다() {
        var state = self.makeLoadedState(query: "민음사")

        let effects = self.sut.reduce(into: &state, action: .view(.submitQuery("민음사")))

        XCTAssertEqual(effects, [.recordRecentTerm("민음사")])
    }

    func test_같은질의여도_결과가비어있으면다시가져온다() {
        var state = self.makeLoadedState(query: "민음사", books: [])

        let effects = self.sut.reduce(into: &state, action: .view(.submitQuery("민음사")))

        XCTAssertEqual(effects, [.recordRecentTerm("민음사"), .search(query: "민음사", page: 1)])
    }

    func test_다른질의를제출하면_기록하고첫페이지를가져온다() {
        var state = self.makeLoadedState(query: "민음사")

        let effects = self.sut.reduce(into: &state, action: .view(.submitQuery("파친코")))

        XCTAssertEqual(effects, [.recordRecentTerm("파친코"), .search(query: "파친코", page: 1)])
        XCTAssertEqual(state.pagination, .loading(isFirstPage: true))
    }

    func test_빈질의를제출하면_아무것도하지않는다() {
        var state = SearchReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.submitQuery("   ")))

        XCTAssertEqual(effects, [])
    }

    func test_첫페이지응답은_이전결과를이어붙이지않고갈아치운다() {
        var state = self.makeLoadedState(query: "파친코", books: ["옛1", "옛2"])
        state.resultsQuery = "민음사"

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "파친코",
            .success(books: self.makeBooks(["새1"]), pageNo: 1, totalCount: 10, hasNext: true)
        )))

        XCTAssertEqual(state.books.map(\.isbn), ["새1"])
        XCTAssertEqual(state.resultsQuery, "파친코")
    }

    func test_다음페이지응답은_기존목록뒤에이어붙인다() {
        var state = self.makeLoadedState(books: ["1", "2"], totalCount: 100)

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["3", "4"]), pageNo: 2, totalCount: 100, hasNext: true)
        )))

        XCTAssertEqual(state.books.map(\.isbn), ["1", "2", "3", "4"])
        XCTAssertEqual(state.pagination, .ready)
    }

    func test_현재질의와다른응답은_버린다() {
        var state = self.makeLoadedState(query: "파친코", books: ["1"])

        let effects = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["다른질의"]), pageNo: 1, totalCount: 10, hasNext: true)
        )))

        XCTAssertEqual(effects, [])
        XCTAssertEqual(state.books.map(\.isbn), ["1"])
    }

    func test_중복된책은_목록에두번들어가지않는다() {
        var state = self.makeLoadedState(books: ["1", "2"], totalCount: 100)

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["2", "3"]), pageNo: 2, totalCount: 100, hasNext: true)
        )))

        XCTAssertEqual(state.books.map(\.isbn), ["1", "2", "3"])
    }

    func test_빈페이지가오면_끝으로본다() {
        var state = self.makeLoadedState(totalCount: 100)

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: [], pageNo: 2, totalCount: 100, hasNext: true)
        )))

        XCTAssertEqual(state.pagination, .exhausted)
    }

    func test_hasNext가거짓이면_끝으로본다() {
        var state = self.makeLoadedState(totalCount: 100)

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["3"]), pageNo: 2, totalCount: 100, hasNext: false)
        )))

        XCTAssertEqual(state.pagination, .exhausted)
    }

    func test_hasNext가참이어도_누적건수가전체에닿으면끝으로본다() {
        var state = self.makeLoadedState(books: ["1", "2"], totalCount: 3)

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["3"]), pageNo: 2, totalCount: 3, hasNext: true)
        )))

        XCTAssertEqual(state.pagination, .exhausted)
    }

    func test_중복만담긴페이지가오면_다음페이지를이어서요청한다() {
        var state = self.makeLoadedState(books: ["1", "2"], totalCount: 100)

        let effects = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["1", "2"]), pageNo: 2, totalCount: 100, hasNext: true)
        )))

        XCTAssertEqual(effects, [.search(query: "민음사", page: 3)])
        XCTAssertEqual(state.consecutiveEmptyPages, 1)
        XCTAssertEqual(state.pagination, .loading(isFirstPage: false))
    }

    func test_중복페이지가세번연속이면_끝으로보고멈춘다() {
        var state = self.makeLoadedState(books: ["1"], totalCount: 100)
        state.consecutiveEmptyPages = 2

        let effects = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["1"]), pageNo: 2, totalCount: 100, hasNext: true)
        )))

        XCTAssertEqual(effects, [])
        XCTAssertEqual(state.pagination, .exhausted)
    }

    func test_새항목이하나라도있으면_중복계수기를되돌린다() {
        var state = self.makeLoadedState(books: ["1"], totalCount: 100)
        state.consecutiveEmptyPages = 2

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사",
            .success(books: self.makeBooks(["1", "2"]), pageNo: 2, totalCount: 100, hasNext: true)
        )))

        XCTAssertEqual(state.consecutiveEmptyPages, 0)
        XCTAssertEqual(state.pagination, .ready)
    }

    func test_바닥에닿으면_다음페이지를요청한다() {
        var state = self.makeLoadedState()

        let effects = self.sut.reduce(into: &state, action: .view(.reachedNearBottom))

        XCTAssertEqual(effects, [.search(query: "민음사", page: 2)])
        XCTAssertEqual(state.pagination, .loading(isFirstPage: false))
    }

    func test_이미로딩중이면_바닥에닿아도요청하지않는다() {
        var state = self.makeLoadedState()
        state.pagination = .loading(isFirstPage: false)

        let effects = self.sut.reduce(into: &state, action: .view(.reachedNearBottom))

        XCTAssertEqual(effects, [])
    }

    func test_끝까지받았으면_바닥에닿아도요청하지않는다() {
        var state = self.makeLoadedState()
        state.pagination = .exhausted

        let effects = self.sut.reduce(into: &state, action: .view(.reachedNearBottom))

        XCTAssertEqual(effects, [])
    }

    func test_실패상태에서는_바닥에닿아도자동으로재시도하지않는다() {
        var state = self.makeLoadedState()
        state.pagination = .failed

        let effects = self.sut.reduce(into: &state, action: .view(.reachedNearBottom))

        XCTAssertEqual(effects, [])
    }

    func test_재시도를누르면_실패한페이지를다시요청한다() {
        var state = self.makeLoadedState()
        state.pagination = .failed

        let effects = self.sut.reduce(into: &state, action: .view(.retryPagination))

        XCTAssertEqual(effects, [.search(query: "민음사", page: 2)])
    }

    func test_실패상태가아니면_재시도가아무것도하지않는다() {
        var state = self.makeLoadedState()

        let effects = self.sut.reduce(into: &state, action: .view(.retryPagination))

        XCTAssertEqual(effects, [])
    }

    func test_첫페이지재시도는_하단푸터가아니라전체로딩이다() {
        var state = SearchReducer.State()
        state.query = "민음사"
        state.currentPage = 0
        state.pagination = .failed

        _ = self.sut.reduce(into: &state, action: .view(.retryPagination))

        XCTAssertEqual(state.pagination, .loading(isFirstPage: true))
    }

    func test_요청이실패하면_실패상태로남긴다() {
        var state = self.makeLoadedState()

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사", .failure
        )))

        XCTAssertEqual(state.pagination, .failed)
    }

    func test_추가페이지가실패해도_이미받은결과는유지한다() {
        var state = self.makeLoadedState(books: ["1", "2"])

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "민음사", .failure
        )))

        XCTAssertEqual(state.books.map(\.isbn), ["1", "2"])
    }

    func test_새질의의첫페이지가실패하면_이전질의결과를치운다() {
        var state = self.makeLoadedState(query: "민음사", books: ["1", "2"])
        state.query = "파친코"
        state.resultsQuery = "민음사"

        _ = self.sut.reduce(into: &state, action: .feedback(.searchResponse(
            requestQuery: "파친코", .failure
        )))

        XCTAssertEqual(state.books, [])
        XCTAssertEqual(state.seenBookIDs, [])
        XCTAssertEqual(state.pagination, .failed)
    }

    func test_하트를누르면_상태를먼저뒤집고쓰기를낸다() {
        var state = SearchReducer.State()
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.toggleFavorite(book)))

        XCTAssertTrue(state.favoriteISBNs.contains("1"))
        XCTAssertEqual(effects, [.setFavorite(book, to: true)])
    }

    func test_이미즐겨찾기인책의하트를누르면_해제로낸다() {
        var state = SearchReducer.State()
        state.favoriteISBNs = ["1"]
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.toggleFavorite(book)))

        XCTAssertFalse(state.favoriteISBNs.contains("1"))
        XCTAssertEqual(effects, [.setFavorite(book, to: false)])
    }

    func test_즐겨찾기스트림이바뀌면_상태를그값으로맞춘다() {
        var state = SearchReducer.State()
        state.favoriteISBNs = ["1"]

        _ = self.sut.reduce(into: &state, action: .feedback(.favoritesChanged(["2", "3"])))

        XCTAssertEqual(state.favoriteISBNs, ["2", "3"])
    }

    func test_메모스트림이바뀌면_배지대상을맞춘다() {
        var state = SearchReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(.memosChanged(["1"])))

        XCTAssertEqual(state.memoISBNs, ["1"])
    }

    func test_최근검색어를불러오면_상태에담는다() {
        var state = SearchReducer.State()

        _ = self.sut.reduce(into: &state, action: .feedback(.recentTermsLoaded(["민음사", "파친코"])))

        XCTAssertEqual(state.recentTerms, ["민음사", "파친코"])
    }

    func test_최근검색어를지우면_삭제를낸다() {
        var state = SearchReducer.State()

        let effects = self.sut.reduce(into: &state, action: .view(.removeRecentTerm("민음사")))

        XCTAssertEqual(effects, [.removeRecentTerm("민음사")])
    }

    func test_책을고르면_상세로넘긴다() {
        var state = SearchReducer.State()
        let book = self.makeBook("1")

        let effects = self.sut.reduce(into: &state, action: .view(.selectBook(book)))

        XCTAssertEqual(effects, [.delegate(.didSelectBook(book))])
    }

    func test_로딩상태만_isLoading이참이다() {
        XCTAssertTrue(SearchReducer.Pagination.loading(isFirstPage: true).isLoading)
        XCTAssertTrue(SearchReducer.Pagination.loading(isFirstPage: false).isLoading)
        XCTAssertFalse(SearchReducer.Pagination.idle.isLoading)
        XCTAssertFalse(SearchReducer.Pagination.ready.isLoading)
        XCTAssertFalse(SearchReducer.Pagination.exhausted.isLoading)
        XCTAssertFalse(SearchReducer.Pagination.failed.isLoading)
    }
}
