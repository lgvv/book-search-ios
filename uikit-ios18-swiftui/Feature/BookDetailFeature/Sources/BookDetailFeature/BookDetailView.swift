import SwiftUI

import BookModel
import DesignSystem
import ImageUI

struct BookDetailView: View {
    let store: BookDetailStore

    private let bookInfo: String

    init(store: BookDetailStore) {
        self.store = store
        self.bookInfo = Self.makeBookInfo(store.state.book)
    }

    private static let coverSize = CGSize(width: 180, height: 260)

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.l) {
                self.cover
                self.titleSection
                self.memoSection
            }
            .padding(.vertical, DSSpacing.xl)
            .padding(.horizontal, DSSpacing.l)
            .frame(maxWidth: 672)
            .frame(maxWidth: .infinity)
        }
        .background(Color.dsBackground)
        .navigationTitle("도서 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                self.favoriteButton
            }
        }
        .onAppear {
            self.store.send(.start)
        }
    }

    private var cover: some View {
        DSAsyncImage(
            url: self.store.state.book.coverImageURL,
            targetSize: Self.coverSize,
            contentMode: .fit
        )
            .frame(width: Self.coverSize.width, height: Self.coverSize.height)
            .background(Color.dsSurface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var titleSection: some View {
        VStack(spacing: DSSpacing.l) {
            Text(self.store.state.book.title)
                .dsFont(.largeTitle)
                .foregroundStyle(Color.dsInk)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(self.bookInfo)
                .font(.subheadline)
                .foregroundStyle(Color.dsSubtleInk)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
        }
    }

    private static func makeBookInfo(_ book: Book) -> String {
        [
            book.author.map { "저자  \($0)" },
            book.publisher.map { "출판사  \($0)" },
            book.publishedAt.map { "출간예정  \($0)" },
            "ISBN  \(book.isbn)"
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }

    private var memoSection: some View {
        let memoText = self.store.state.memoText
        let hasMemo = !memoText.isEmpty

        return VStack(alignment: .leading, spacing: DSSpacing.s) {
            Text("메모")
                .dsFont(.heading)
                .foregroundStyle(Color.dsInk)
                .accessibilityAddTraits(.isHeader)

            Text(hasMemo ? memoText : "작성된 메모가 없습니다")
                .dsFont(.body)
                .foregroundStyle(hasMemo ? Color.dsInk : Color.dsSubtleInk)
                .textSelection(.enabled)

            Button(hasMemo ? "메모 수정" : "메모 작성") {
                self.store.send(.editMemo)
            }
            .buttonStyle(.dsPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var favoriteButton: some View {
        let isFavorite = self.store.state.isFavorite

        return Button {
            self.store.send(.toggleFavorite)
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
        }
        .tint(Color.dsFavorite)
        .accessibilityLabel("즐겨찾기")
        .accessibilityValue(isFavorite ? "설정됨" : "해제됨")
    }
}
