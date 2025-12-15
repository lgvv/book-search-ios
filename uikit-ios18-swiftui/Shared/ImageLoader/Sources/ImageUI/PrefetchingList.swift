import SwiftUI

extension View {
    public func prefetchingCovers<Item: Identifiable>(
        _ items: [Item],
        lookAhead: Int = 6,
        targetSize: CGSize,
        coverURL: @escaping (Item) -> URL?
    ) -> some View where Item.ID: Hashable {
        self.modifier(
            CoverPrefetchModifier(
                items: items,
                lookAhead: lookAhead,
                targetSize: targetSize,
                coverURL: coverURL
            )
        )
    }
}

private struct CoverPrefetchModifier<Item: Identifiable>: ViewModifier where Item.ID: Hashable {
    let items: [Item]
    let lookAhead: Int
    let targetSize: CGSize
    let coverURL: (Item) -> URL?

    @Environment(\.displayScale) private var displayScale

    @State private var warmed: Set<URL> = []

    func body(content: Content) -> some View {
        content.onScrollTargetVisibilityChange(idType: Item.ID.self) { visible in
            self.updatePrefetch(visibleIDs: visible)
        }
    }

    private func updatePrefetch(visibleIDs: [Item.ID]) {
        guard !visibleIDs.isEmpty else { return }

        let visible = Set(visibleIDs)
        let positions = self.items.indices.filter { visible.contains(self.items[$0].id) }
        guard let first = positions.first, let last = positions.last else { return }

        let lower = max(first - self.lookAhead, self.items.startIndex)
        let upper = min(last + self.lookAhead, self.items.endIndex - 1)
        let wanted = Set(self.items[lower...upper].compactMap(self.coverURL))

        let added = wanted.subtracting(self.warmed)
        let dropped = self.warmed.subtracting(wanted)

        if !added.isEmpty {
            ImagePrefetcher.prefetch(
                Array(added),
                targetPixelSize: ImagePixelSize.from(self.targetSize, displayScale: self.displayScale)
            )
        }
        if !dropped.isEmpty {
            ImagePrefetcher.cancel(Array(dropped))
        }
        if !added.isEmpty || !dropped.isEmpty {
            self.warmed = wanted
        }
    }
}
