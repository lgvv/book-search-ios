import SwiftUI

import BookModel
import BookUI
import CommonUI
import DesignSystem
import ImageUI
import SharedFoundation

struct FavoriteView: View {
    let store: FavoriteStore

    var body: some View {
        VStack(spacing: 0) {
            if self.store.state.books.isStale {
                StaleBanner(message: "목록을 최신으로 확인하지 못했습니다") {
                    self.store.send(.retryLoad)
                }
            }

            self.content
        }
        .background(Color.dsBackground)
        .navigationTitle("즐겨찾기")
        .onAppear {
            self.store.send(.start)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch self.store.state.books {
        case .loading:
            Color.dsBackground

        case let .loaded(books, _):
            if books.isEmpty {
                EmptyStateContent(message: "리스트에서 하트를 눌러\n즐겨찾기를 추가해 보세요")
            } else {
                self.list(books)
            }

        case .failed:
            EmptyStateContent(
                message: "즐겨찾기를 불러오지 못했습니다",
                actionTitle: "다시 시도"
            ) {
                self.store.send(.retryLoad)
            }
        }
    }

    private func list(_ books: [Book]) -> some View {
        List {
            ForEach(books, id: \.isbn) { book in
                BookRow(
                    book: book,
                    isFavorite: true,
                    hasMemo: self.store.state.memoISBNs.contains(book.isbn),
                    onToggleFavorite: {
                        self.store.send(.removeFavorite(book))
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    self.store.send(.selectBook(book))
                }
                .swipeActions(edge: .trailing) {
                    Button("제거", role: .destructive) {
                        self.store.send(.removeFavorite(book))
                    }
                }
                .listRowBackground(Color.dsBackground)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .prefetchingCovers(books, targetSize: BookRow.coverSize) { $0.coverImageURL }
    }
}
