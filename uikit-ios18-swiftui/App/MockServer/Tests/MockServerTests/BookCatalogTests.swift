import Foundation
import Testing

@testable import MockServer

struct BookCatalogTests {

    private func makeCatalog(_ books: [BookRecord]) -> BookCatalog {
        BookCatalog(books: books)
    }

    private func makeBook(
        _ isbn: String,
        title: String,
        author: String? = nil,
        publisher: String? = nil,
        publishedAt: String? = nil
    ) -> BookRecord {
        BookRecord(
            isbn: isbn,
            title: title,
            author: author,
            publisher: publisher,
            publishedAt: publishedAt,
            coverImageURL: nil
        )
    }

    @Test
    func 제목의일부가일치하면_결과에넣는다() {
        let sut = self.makeCatalog([makeBook("1", title: "소년이 온다")])

        let result = sut.search(query: "소년", page: 1, size: 20)

        #expect(result.items.map(\.isbn) == ["1"])
    }

    @Test
    func 저자가일치하면_결과에넣는다() {
        let sut = self.makeCatalog([makeBook("1", title: "채식주의자", author: "한강")])

        let result = sut.search(query: "한강", page: 1, size: 20)

        #expect(result.items.map(\.isbn) == ["1"])
    }

    @Test
    func 출판사가일치하면_결과에넣는다() {
        let sut = self.makeCatalog([makeBook("1", title: "채식주의자", publisher: "창비")])

        let result = sut.search(query: "창비", page: 1, size: 20)

        #expect(result.items.map(\.isbn) == ["1"])
    }

    @Test
    func 어디에도없는말은_0건이다() {
        let sut = self.makeCatalog([makeBook("1", title: "채식주의자")])

        let result = sut.search(query: "존재하지않는책", page: 1, size: 20)

        #expect(result.items == [])
        #expect(result.totalCount == 0)
    }

    @Test
    func 대소문자와앞뒤공백은_무시한다() {
        let sut = self.makeCatalog([makeBook("1", title: "Clean Architecture")])

        let result = sut.search(query: "  clean  ", page: 1, size: 20)

        #expect(result.items.map(\.isbn) == ["1"])
    }

    @Test
    func 공백만입력하면_0건이다() {
        let sut = self.makeCatalog([makeBook("1", title: "채식주의자")])

        let result = sut.search(query: "   ", page: 1, size: 20)

        #expect(result.totalCount == 0)
    }

    @Test
    func 제목완전일치가_제목시작보다앞에온다() {
        let sut = self.makeCatalog([
            makeBook("시작", title: "토지 완전판"),
            makeBook("완전", title: "토지"),
        ])

        let result = sut.search(query: "토지", page: 1, size: 20)

        #expect(result.items.map(\.isbn) == ["완전", "시작"])
    }

    @Test
    func 제목일치가_저자일치보다앞에온다() {
        let sut = self.makeCatalog([
            makeBook("저자", title: "다른 책", author: "한강"),
            makeBook("제목", title: "한강 이야기"),
        ])

        let result = sut.search(query: "한강", page: 1, size: 20)

        #expect(result.items.map(\.isbn) == ["제목", "저자"])
    }

    @Test
    func 저자일치가_출판사일치보다앞에온다() {
        let sut = self.makeCatalog([
            makeBook("출판사", title: "다른 책", publisher: "창비"),
            makeBook("저자", title: "또 다른 책", author: "창비"),
        ])

        let result = sut.search(query: "창비", page: 1, size: 20)

        #expect(result.items.map(\.isbn) == ["저자", "출판사"])
    }

    @Test
    func 같은순위안에서는_최신출간순이다() {
        let sut = self.makeCatalog([
            makeBook("옛것", title: "한강 산책", publishedAt: "2020.01.01"),
            makeBook("새것", title: "한강 소풍", publishedAt: "2024.01.01"),
        ])

        let result = sut.search(query: "한강", page: 1, size: 20)

        #expect(result.items.map(\.isbn) == ["새것", "옛것"])
    }

    @Test
    func 전체일치건수는_페이지와무관하게실제건수다() {
        let sut = self.makeCatalog((1 ... 25).map { makeBook("\($0)", title: "민음사 총서 \($0)") })

        let result = sut.search(query: "민음사", page: 2, size: 10)

        #expect(result.totalCount == 25)
        #expect(result.items.count == 10)
    }

    @Test
    func 마지막페이지는_남은만큼만준다() {
        let sut = self.makeCatalog((1 ... 25).map { makeBook("\($0)", title: "민음사 총서 \($0)") })

        let result = sut.search(query: "민음사", page: 3, size: 10)

        #expect(result.items.count == 5)
    }

    @Test
    func 범위를벗어난페이지는_빈배열이다() {
        let sut = self.makeCatalog((1 ... 25).map { makeBook("\($0)", title: "민음사 총서 \($0)") })

        let result = sut.search(query: "민음사", page: 99, size: 10)

        #expect(result.items == [])
        #expect(result.totalCount == 25)
    }

    @Test
    func 페이지가0이하면_빈배열이다() {
        let sut = self.makeCatalog([makeBook("1", title: "민음사 총서")])

        let result = sut.search(query: "민음사", page: 0, size: 10)

        #expect(result.items == [])
    }

    @Test
    func 페이지가겹치지않는다() {
        let sut = self.makeCatalog((1 ... 25).map { makeBook("\($0)", title: "민음사 총서 \($0)") })

        let first = sut.search(query: "민음사", page: 1, size: 10)
        let second = sut.search(query: "민음사", page: 2, size: 10)
        let third = sut.search(query: "민음사", page: 3, size: 10)

        let all = (first.items + second.items + third.items).map(\.isbn)
        #expect(Set(all).count == 25)
        #expect(all.count == 25)
    }

    @Test
    func isbn으로찾으면_그책을돌려준다() {
        let sut = self.makeCatalog([makeBook("9788937473135", title: "파친코")])

        let book = sut.book(isbn: "9788937473135")

        #expect(book?.title == "파친코")
    }

    @Test
    func 카탈로그에없는isbn은_nil이다() {
        let sut = self.makeCatalog([makeBook("1", title: "파친코")])

        #expect(sut.book(isbn: "없는isbn") == nil)
    }

    @Test
    func 실제카탈로그는_다중페이지사례를담고있다() {
        let sut = BookCatalog()

        let result = sut.search(query: "민음사", page: 1, size: 20)

        #expect(result.totalCount > 20)
    }

    @Test
    func 실제카탈로그는_정확히1건인사례를담고있다() {
        let sut = BookCatalog()

        let result = sut.search(query: "파친코", page: 1, size: 20)

        #expect(result.totalCount == 1)
    }

    @Test
    func 실제카탈로그는_0건사례를담고있다() {
        let sut = BookCatalog()

        let result = sut.search(query: "존재하지않는책", page: 1, size: 20)

        #expect(result.totalCount == 0)
    }

    @Test
    func 실제카탈로그의출간일은_2024년8월을넘지않는다() {
        let sut = BookCatalog()

        let dates = BookCatalogData.all.compactMap(\.publishedAt)

        #expect(!(dates.isEmpty))
        for date in dates {
            #expect(date.filter(\.isNumber) <= "20240831", "출간일 상한을 넘었습니다: \(date)")
        }
        #expect(sut.book(isbn: BookCatalogData.all[0].isbn) != nil)
    }

    @Test
    func 실제카탈로그의isbn은_중복되지않는다() {
        let isbns = BookCatalogData.all.map(\.isbn)

        #expect(Set(isbns).count == isbns.count)
    }
}

extension BookRecord: Equatable {
    public static func == (lhs: BookRecord, rhs: BookRecord) -> Bool {
        lhs.isbn == rhs.isbn
    }
}
