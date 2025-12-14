import SwiftUI

import BookModel
import BookUI
import CommonUI
import DesignSystem
import ImageUI

struct SearchView: View {
    let store: SearchStore

    @State private var queryText = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            self.searchField
            self.content
        }
        .background(Color.dsBackground)
        .navigationTitle("검색")
        .onAppear {
            self.store.send(.start)
        }
    }

    private var searchField: some View {
        HStack(spacing: DSSpacing.s) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.dsSubtleInk)

            TextField("책 제목 검색", text: self.$queryText)
                .dsFont(.body)
                .foregroundStyle(Color.dsInk)
                .focused(self.$isSearchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .onChange(of: self.queryText) {
                    self.store.send(.queryChanged(self.queryText))
                }
                .onSubmit {
                    self.submit(self.queryText)
                }
                .accessibilityLabel("책 제목 검색")

            if !self.queryText.isEmpty {
                Button {
                    self.queryText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.dsSubtleInk)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("검색어 지우기")
            }
        }
        .padding(.horizontal, DSSpacing.m)
        .padding(.vertical, DSSpacing.s)
        .background(Color.dsSurface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.m))
        .padding(.horizontal, DSSpacing.l)
        .padding(.bottom, DSSpacing.s)
    }

    private func submit(_ term: String) {
        self.isSearchFocused = false
        self.store.send(.submitQuery(term))
    }

    @ViewBuilder
    private var content: some View {
        if self.store.state.isShowingRecents {
            RecentTermsList(store: self.store) { term in
                self.queryText = term
                self.submit(term)
            }
        } else {
            SearchResultsList(store: self.store)
        }
    }
}

private struct RecentTermsList: View {
    let store: SearchStore
    let onSelect: (String) -> Void

    var body: some View {
        List {
            ForEach(self.store.state.recentTerms, id: \.self) { term in
                Label(term, systemImage: "clock")
                    .dsFont(.body)
                    .foregroundStyle(Color.dsInk)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.onSelect(term)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("삭제", role: .destructive) {
                            self.store.send(.removeRecentTerm(term))
                        }
                    }
                    .accessibilityActions {
                        Button("삭제") {
                            self.store.send(.removeRecentTerm(term))
                        }
                    }
                    .listRowBackground(Color.dsBackground)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
    }
}

private struct SearchResultsList: View {
    let store: SearchStore

    private static let prefetchThreshold = 5

    var body: some View {
        switch self.store.state.emptyState {
        case .noResults:
            EmptyStateContent(message: "검색 결과가 없습니다")

        case .failed:
            EmptyStateContent(
                message: "검색 결과를 가져오지 못했습니다",
                actionTitle: "다시 시도"
            ) {
                self.store.send(.retryPagination)
            }

        case nil:
            self.list
        }
    }

    private var list: some View {
        let triggers = Set(
            self.store.state.books.suffix(Self.prefetchThreshold).map(\.isbn)
        )

        return ScrollViewReader { proxy in
            List {
                ForEach(self.store.state.books, id: \.isbn) { book in
                    BookRow(
                        book: book,
                        isFavorite: self.store.state.favoriteISBNs.contains(book.isbn),
                        hasMemo: self.store.state.memoISBNs.contains(book.isbn),
                        onToggleFavorite: {
                            self.store.send(.toggleFavorite(book))
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.store.send(.selectBook(book))
                    }
                    .listRowBackground(Color.dsBackground)
                    .onAppear {
                        guard triggers.contains(book.isbn) else { return }
                        self.store.send(.reachedNearBottom)
                    }
                }

                self.footer
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .prefetchingCovers(self.store.state.books, targetSize: BookRow.coverSize) { $0.coverImageURL }
            .onChange(of: self.store.state.resultsQuery) {
                guard let first = self.store.state.books.first else { return }
                proxy.scrollTo(first.isbn, anchor: .top)
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch self.store.state.pagingFooter {
        case .loading:
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, DSSpacing.l)
            .listRowBackground(Color.dsBackground)
            .accessibilityLabel("다음 페이지를 불러오는 중")

        case .failed:
            HStack {
                Spacer()
                Button("다시 시도") {
                    self.store.send(.retryPagination)
                }
                .dsFont(.body)
                Spacer()
            }
            .padding(.vertical, DSSpacing.l)
            .listRowBackground(Color.dsBackground)

        case nil:
            EmptyView()
        }
    }
}
