import SwiftUI

import BookModel
import BookUI
import CommonUI
import DesignSystem
import ImageUI
import FeatureSupport
import MemoModel
import SharedFoundation

struct MemoListView: View {
    let store: MemoStore

    var body: some View {
        VStack(spacing: 0) {
            if self.store.state.memos.isStale {
                StaleBanner(message: "목록을 최신으로 확인하지 못했습니다") {
                    self.store.send(.retryLoad)
                }
            }

            self.content
        }
        .background(Color.dsBackground)
        .navigationTitle("메모")
        .onAppear {
            self.store.send(.start)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch self.store.state.memos {
        case .loading:
            Color.dsBackground

        case let .loaded(memos, _):
            if memos.isEmpty {
                EmptyStateContent(message: "도서 상세에서 메모 작성을 눌러\n첫 메모를 남겨 보세요")
            } else {
                self.list(memos)
            }

        case .failed:
            EmptyStateContent(
                message: "메모 목록을 불러오지 못했습니다",
                actionTitle: "다시 시도"
            ) {
                self.store.send(.retryLoad)
            }
        }
    }

    private func list(_ memos: [BookMemo]) -> some View {
        List {
            ForEach(memos) { memo in
                BookRow(
                    book: memo.book,
                    isFavorite: self.store.state.favoriteISBNs.contains(memo.book.isbn),
                    hasMemo: true,
                    caption: DateDisplay.relative(memo.updatedAt),
                    onToggleFavorite: {
                        self.store.send(.toggleFavorite(memo.book))
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    self.store.send(.selectBook(memo.book))
                }
                .listRowBackground(Color.dsBackground)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .prefetchingCovers(memos, targetSize: BookRow.coverSize) { $0.book.coverImageURL }
    }
}
