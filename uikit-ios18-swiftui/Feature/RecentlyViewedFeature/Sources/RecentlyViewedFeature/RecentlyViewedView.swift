import SwiftUI

import BookModel
import BookUI
import CommonUI
import DesignSystem
import ImageUI
import FeatureSupport
import RecentlyViewedModel
import SharedFoundation

struct RecentlyViewedView: View {
    let store: RecentlyViewedStore

    @State private var isConfirmingClearAll = false

    var body: some View {
        VStack(spacing: 0) {
            if self.store.state.items.isStale {
                StaleBanner(message: "목록을 최신으로 확인하지 못했습니다") {
                    self.store.send(.retryLoad)
                }
            }

            self.content
        }
        .background(Color.dsBackground)
        .navigationTitle("최근 본")
        .toolbar {
            if self.store.state.canClear {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("전체 지우기") {
                        self.isConfirmingClearAll = true
                    }
                }
            }
        }
        .alert("최근 본 기록을 지울까요?", isPresented: self.$isConfirmingClearAll) {
            Button("전체 지우기", role: .destructive) {
                self.store.send(.confirmClearAll)
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("목록에서만 사라지고 즐겨찾기와 메모는 그대로입니다.")
        }
        .onAppear {
            self.store.send(.start)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch self.store.state.items {
        case .loading:
            Color.dsBackground

        case let .loaded(items, _):
            if items.isEmpty {
                EmptyStateContent(message: "도서 상세를 열면\n최근 본 목록에 쌓입니다")
            } else {
                self.list(items)
            }

        case .failed:
            EmptyStateContent(
                message: "최근 본 목록을 불러오지 못했습니다",
                actionTitle: "다시 시도"
            ) {
                self.store.send(.retryLoad)
            }
        }
    }

    private func list(_ items: [ViewedBook]) -> some View {
        List {
            ForEach(items) { item in
                BookRow(
                    book: item.book,
                    isFavorite: self.store.state.favoriteISBNs.contains(item.book.isbn),
                    hasMemo: self.store.state.memoISBNs.contains(item.book.isbn),
                    caption: DateDisplay.relative(item.viewedAt)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    self.store.send(.selectBook(item.book))
                }
                .swipeActions(edge: .trailing) {
                    Button("삭제", role: .destructive) {
                        self.store.send(.removeItem(isbn: item.book.isbn))
                    }
                }
                .listRowBackground(Color.dsBackground)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .prefetchingCovers(items, targetSize: BookRow.coverSize) { $0.book.coverImageURL }
    }
}
