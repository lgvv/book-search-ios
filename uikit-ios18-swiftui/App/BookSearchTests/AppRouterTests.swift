import Foundation
import Testing
import UIKit

import BookDetailFeatureInterface
import BookModel
import DependencyResolver
import FavoriteCore
import MemoCore
import MemoModel
import RecentlyViewedCore
import TestSupport

@testable import BookSearch

@MainActor
struct AppRouterTests {

    private let pachinko = Book(isbn: "1", title: "파친코")
    private let almond = Book(isbn: "2", title: "아몬드")

    @Test
    func start이_탭네개를_순서대로세운다() {
        let requested = Locked<[String]>([])
        let sut = self.makeRouter(scenes: Self.tabScenes(requested: requested))

        sut.start()

        #expect(requested.value == ["search", "favorite", "memo", "recentlyViewed"])

        let tabBar = sut.rootViewController as? UITabBarController
        #expect(tabBar?.viewControllers?.count == 4)
        #expect(tabBar?.viewControllers?.allSatisfy { $0 is UINavigationController } == true)
    }

    @Test
    func 각탭은_자기씬을루트로가진다() {
        let sut = self.makeRouter(scenes: Self.tabScenes(requested: Locked([])))

        sut.start()

        let roots = self.navigationControllers(of: sut).map { $0.viewControllers.first?.title }
        #expect(roots == ["search", "favorite", "memo", "recentlyViewed"])
    }

    @Test
    func 탭전환딥링크가_해당탭을선택한다() async {
        let sut = self.makeRouter(scenes: Self.tabScenes(requested: Locked([])))
        sut.start()
        let tabBar = sut.rootViewController as? UITabBarController
        #expect(tabBar?.selectedIndex == 0)

        sut.handle(deepLink: URL(string: "booksearch://memo")!)

        #expect(await self.waitUntilOnMain { tabBar?.selectedIndex == AppTab.memo.rawValue })
    }

    @Test
    func 해석되지않는딥링크는_아무것도하지않는다() async {
        let sut = self.makeRouter(scenes: Self.tabScenes(requested: Locked([])))
        sut.start()
        let tabBar = sut.rootViewController as? UITabBarController

        sut.handle(deepLink: URL(string: "unknownscheme://book/9788937400018")!)

        #expect(await self.stayFalseOnMain { tabBar?.selectedIndex != 0 })
        #expect(self.navigationControllers(of: sut).allSatisfy { $0.viewControllers.count == 1 })
    }

    @Test
    func 상세라우트는_현재탭에push한다() async {
        let sut = self.makeRouter(scenes: Self.detailScenes())
        sut.start()
        let route = Self.makeDetailRoute(book: self.pachinko, memoGate: nil, calls: Locked(0))

        sut.navigate(to: route)

        let nav = self.navigationControllers(of: sut)[0]
        #expect(await self.waitUntilOnMain { nav.viewControllers.count == 2 })
        #expect(nav.viewControllers.last?.title == "1")
        #expect(nav.viewControllers.last?.hidesBottomBarWhenPushed == true)
    }

    @Test
    func 라우팅이겹치면_마지막회차만표시된다() async {
        let gate = Gate()
        let calls = Locked(0)
        let sut = self.makeRouter(scenes: Self.detailScenes())
        sut.start()
        let nav = self.navigationControllers(of: sut)[0]

        let first = Self.makeDetailRoute(book: self.pachinko, memoGate: gate, calls: calls)
        let second = Self.makeDetailRoute(book: self.almond, memoGate: gate, calls: calls)

        sut.navigate(to: first)
        await gate.waitUntilArrived(1)
        sut.navigate(to: second)
        gate.open()

        #expect(await self.waitUntilOnMain { nav.viewControllers.count == 2 })
        #expect(nav.viewControllers.last?.title == "2")
        #expect(await self.stayFalseOnMain { nav.viewControllers.count > 2 })
    }

    private func makeRouter(scenes: SceneFactory) -> AppRouter {
        AppRouter(
            scenes: scenes,
            favoriteClient: Self.silentFavoriteClient(),
            universalLinkHosts: ["booksearch.app"]
        )
    }

    private func navigationControllers(of router: AppRouter) -> [UINavigationController] {
        let tabBar = router.rootViewController as? UITabBarController
        return tabBar?.viewControllers?.compactMap { $0 as? UINavigationController } ?? []
    }

    private static func tabScenes(requested: Locked<[String]>) -> SceneFactory {
        var scenes = SceneFactory.testValue
        scenes.makeSearchScene = { _ in Self.tagged("search", into: requested) }
        scenes.makeFavoriteScene = { _ in Self.tagged("favorite", into: requested) }
        scenes.makeMemoScene = { _ in Self.tagged("memo", into: requested) }
        scenes.makeRecentlyViewedScene = { _ in Self.tagged("recentlyViewed", into: requested) }
        return scenes
    }

    private static func detailScenes() -> SceneFactory {
        var scenes = Self.tabScenes(requested: Locked([]))
        scenes.makeBookDetailScene = { payload, _ in
            let viewController = UIViewController()
            viewController.title = payload.book.isbn
            return viewController
        }
        return scenes
    }

    private static func tagged(_ name: String, into requested: Locked<[String]>) -> UIViewController {
        requested.withValue { $0.append(name) }
        let viewController = UIViewController()
        viewController.title = name
        return viewController
    }

    private static func makeDetailRoute(
        book: Book,
        memoGate: Gate?,
        calls: Locked<Int>
    ) -> BookDetailRoute {
        withResolver(from: .test) { values in
            values[FavoriteClientKey.self] = Self.silentFavoriteClient()
            values[MemoClientKey.self] = Self.memoClient(gate: memoGate, calls: calls)
            values[RecentlyViewedClientKey.self] = Self.silentRecentlyViewedClient()
        } operation: {
            BookDetailRoute(book: book)
        }
    }

    private static func silentFavoriteClient() -> FavoriteClient {
        FavoriteClient(
            submitAdd: { _ in },
            submitRemove: { _ in },
            list: { [] },
            isFavorite: { _ in false },
            observe: { AsyncStream { $0.finish() } },
            observeFailures: { AsyncStream { _ in } },
            reload: {},
            start: {}
        )
    }

    private static func memoClient(gate: Gate?, calls: Locked<Int>) -> MemoClient {
        MemoClient(
            save: { _, _ in },
            list: { [] },
            memo: { _ in
                let ordinal = calls.withValue { count -> Int in
                    count += 1
                    return count
                }
                if let gate, ordinal == 1 {
                    await gate.wait()
                }
                return .notFound
            },
            observe: { AsyncStream { $0.finish() } },
            reload: {},
            start: {}
        )
    }

    private static func silentRecentlyViewedClient() -> RecentlyViewedClient {
        RecentlyViewedClient(
            record: { _ in },
            list: { [] },
            remove: { _ in },
            clear: {},
            observe: { AsyncStream { $0.finish() } },
            reload: {},
            start: {}
        )
    }

    private func waitUntilOnMain(
        timeout: TimeInterval = 2,
        _ condition: () -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        return condition()
    }

    private func stayFalseOnMain(
        for duration: TimeInterval = 0.1,
        _ condition: () -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(duration)
        while Date() < deadline {
            if condition() { return false }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        return true
    }
}
