import SwiftUI

import BookModel
import DesignSystem
import ImageUI

public struct BookRow: View {
    public static let coverSize = CGSize(width: 45, height: 80)

    private let book: Book
    private let isFavorite: Bool
    private let hasMemo: Bool
    private let caption: String?
    private let onToggleFavorite: (() -> Void)?

    private let subtitle: String
    private let accessibilityStatement: String

    public init(
        book: Book,
        isFavorite: Bool,
        hasMemo: Bool,
        caption: String? = nil,
        onToggleFavorite: (() -> Void)? = nil
    ) {
        self.book = book
        self.isFavorite = isFavorite
        self.hasMemo = hasMemo
        self.caption = caption
        self.onToggleFavorite = onToggleFavorite

        self.subtitle = [book.author, book.publisher]
            .compactMap { $0 }
            .joined(separator: " · ")
        self.accessibilityStatement = Self.makeAccessibilityStatement(
            book: book,
            isFavorite: isFavorite,
            hasMemo: hasMemo,
            caption: caption
        )
    }

    public var body: some View {
        HStack(spacing: DSSpacing.m) {
            DSAsyncImage(url: self.book.coverImageURL, targetSize: BookRow.coverSize)
                .frame(width: BookRow.coverSize.width, height: BookRow.coverSize.height)
                .background(Color.dsSurface)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.s))

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(self.book.title)
                    .font(.headline)
                    .foregroundStyle(Color.dsInk)
                    .lineLimit(2)

                Text(self.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.dsSubtleInk)
                    .lineLimit(1)

                if let caption = self.caption {
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(Color.dsSubtleInk)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if self.hasMemo {
                Image(systemName: "note.text")
                    .foregroundStyle(Color.dsSubtleInk)
            }

            if let onToggleFavorite = self.onToggleFavorite {
                Button {
                    onToggleFavorite()
                } label: {
                    Image(systemName: self.isFavorite ? "heart.fill" : "heart")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.borderless)
                .tint(Color.dsFavorite)
            } else {
                Image(systemName: self.isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(Color.dsFavorite)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.accessibilityStatement)
        .accessibilityAddTraits(.isButton)
        .accessibilityActions {
            if let onToggleFavorite = self.onToggleFavorite {
                Button(self.isFavorite ? "즐겨찾기 해제" : "즐겨찾기 추가") {
                    onToggleFavorite()
                }
            }
        }
    }

    private static func makeAccessibilityStatement(
        book: Book,
        isFavorite: Bool,
        hasMemo: Bool,
        caption: String?
    ) -> String {
        let details = [book.author, book.publisher, caption]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        let states = [
            isFavorite ? "즐겨찾기됨" : nil,
            hasMemo ? "메모 있음" : nil
        ].compactMap { $0 }

        return ([book.title] + details + states).joined(separator: ", ")
    }
}
