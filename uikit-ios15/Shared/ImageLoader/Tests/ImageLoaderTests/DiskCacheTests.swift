import XCTest

import TestSupport

@testable import ImageLoader

final class DiskCacheTests: XCTestCase {

    private var files: InMemoryFileClient!

    private let coverURL = URL(string: "https://picsum.photos/seed/1/200/300")!
    private let otherCoverURL = URL(string: "https://picsum.photos/seed/2/200/300")!

    override func setUp() {
        super.setUp()
        self.files = InMemoryFileClient()
    }

    private func makeSUT(
        maxByteSize: Int = 1_000_000,
        freshLifetime: TimeInterval = 3_600,
        maxEntryByteSize: Int? = nil
    ) -> DiskCache {
        DiskCache(
            client: self.files.client,
            configuration: ImageDiskCacheConfiguration(
                maxByteSize: maxByteSize,
                freshLifetime: freshLifetime,
                maxEntryByteSize: maxEntryByteSize
            )
        )
    }

    private func makeBody(_ byteCount: Int) -> Data {
        Data(repeating: 0xAB, count: byteCount)
    }

    func test_저장한본문을_같은URL로다시읽을수있다() async {
        let sut = self.makeSUT()
        let data = self.makeBody(100)

        await sut.store(data, etag: "v1", for: self.coverURL)

        let entry = await sut.entry(for: self.coverURL)
        XCTAssertEqual(entry?.data, data)
        XCTAssertEqual(entry?.etag, "v1")
    }

    func test_저장한적없는URL은_nil이다() async {
        let sut = self.makeSUT()

        let entry = await sut.entry(for: self.coverURL)

        XCTAssertNil(entry)
    }

    func test_URL이다르면_서로다른항목으로저장된다() async {
        let sut = self.makeSUT()

        await sut.store(self.makeBody(10), etag: "a", for: self.coverURL)
        await sut.store(self.makeBody(20), etag: "b", for: self.otherCoverURL)

        let first = await sut.entry(for: self.coverURL)
        let second = await sut.entry(for: self.otherCoverURL)
        XCTAssertEqual(first?.etag, "a")
        XCTAssertEqual(second?.etag, "b")
    }

    func test_같은키에다시저장하면_세대가올라간다() async {
        let sut = self.makeSUT()
        await sut.store(self.makeBody(10), etag: "v1", for: self.coverURL)
        let first = await sut.entry(for: self.coverURL)

        await sut.store(self.makeBody(20), etag: "v2", for: self.coverURL)

        let second = await sut.entry(for: self.coverURL)
        XCTAssertGreaterThan(second?.generation ?? 0, first?.generation ?? 0)
        XCTAssertEqual(second?.etag, "v2")
    }

    func test_새세대를커밋하면_이전세대파일을지운다() async {
        let sut = self.makeSUT()
        await sut.store(self.makeBody(10), etag: "v1", for: self.coverURL)

        await sut.store(self.makeBody(20), etag: "v2", for: self.coverURL)
        _ = await sut.entry(for: self.coverURL)

        let bodyFiles = self.files.keys.filter { $0 != "manifest.json" }
        XCTAssertEqual(bodyFiles.count, 1)
    }

    func test_축출된키를곧바로다시저장해도_세대번호가되돌아가지않는다() async {
        let sut = self.makeSUT(maxByteSize: 150, maxEntryByteSize: 100)
        await sut.store(self.makeBody(100), etag: "a1", for: self.coverURL)
        let firstGeneration = await sut.entry(for: self.coverURL)?.generation

        await sut.store(self.makeBody(100), etag: "b1", for: self.otherCoverURL)
        let wasEvicted = await sut.entry(for: self.coverURL)
        XCTAssertNil(wasEvicted, "축출되지 않으면 이 테스트의 전제가 성립하지 않는다")

        await sut.store(self.makeBody(100), etag: "a2", for: self.coverURL)

        let reborn = await sut.entry(for: self.coverURL)
        XCTAssertEqual(reborn?.etag, "a2")
        XCTAssertGreaterThan(reborn?.generation ?? 0, firstGeneration ?? 0)
    }

    func test_지난실행이남긴세대파일보다_새세대번호가항상크다() async {
        let key = String(repeating: "0", count: 64)
        self.files.seed(self.makeBody(10), forKey: "\(key).99")
        let sut = self.makeSUT()

        await sut.store(self.makeBody(10), etag: "v1", for: self.coverURL)

        let entry = await sut.entry(for: self.coverURL)
        XCTAssertGreaterThan(entry?.generation ?? 0, 99)
    }

    func test_freshLifetime안에저장한항목은_신선하다() async {
        let sut = self.makeSUT(freshLifetime: 3_600)

        await sut.store(self.makeBody(10), etag: "v1", for: self.coverURL)

        let entry = await sut.entry(for: self.coverURL)
        XCTAssertEqual(entry?.isFresh, true)
    }

    func test_freshLifetime이지난항목은_값은주되신선하지않다() async {
        let sut = self.makeSUT(freshLifetime: 0)

        await sut.store(self.makeBody(10), etag: "v1", for: self.coverURL)

        let entry = await sut.entry(for: self.coverURL)
        XCTAssertNotNil(entry?.data)
        XCTAssertEqual(entry?.isFresh, false)
    }

    func test_재검증을표시하면_같은세대의항목이다시신선해진다() async {
        let sut = self.makeSUT(freshLifetime: 60)
        await sut.store(self.makeBody(10), etag: "v1", for: self.coverURL)
        let stored = await sut.entry(for: self.coverURL)
        let generation = try? XCTUnwrap(stored?.generation)

        sut.markRevalidated(for: self.coverURL, etag: "v2", generation: generation ?? 0)

        let entry = await sut.entry(for: self.coverURL)
        XCTAssertEqual(entry?.etag, "v2")
        XCTAssertEqual(entry?.isFresh, true)
    }

    func test_왕복중에새본문이저장됐으면_옛세대의재검증표시를무시한다() async {
        let sut = self.makeSUT()
        await sut.store(self.makeBody(10), etag: "v1", for: self.coverURL)
        let old = await sut.entry(for: self.coverURL)
        await sut.store(self.makeBody(20), etag: "v2", for: self.coverURL)

        sut.markRevalidated(for: self.coverURL, etag: "옛-ETag", generation: old?.generation ?? 0)

        let entry = await sut.entry(for: self.coverURL)
        XCTAssertEqual(entry?.etag, "v2")
    }

    func test_항목크기상한을넘는본문은_저장하지않는다() async {
        let sut = self.makeSUT(maxByteSize: 1_000, maxEntryByteSize: 100)

        await sut.store(self.makeBody(500), etag: "큰것", for: self.coverURL)

        let entry = await sut.entry(for: self.coverURL)
        XCTAssertNil(entry)
    }

    func test_항목크기상한을넘는저장은_기존항목을건드리지않는다() async {
        let sut = self.makeSUT(maxByteSize: 1_000, maxEntryByteSize: 100)
        await sut.store(self.makeBody(50), etag: "작은것", for: self.otherCoverURL)

        await sut.store(self.makeBody(500), etag: "큰것", for: self.coverURL)

        let survivor = await sut.entry(for: self.otherCoverURL)
        XCTAssertEqual(survivor?.etag, "작은것")
    }

    func test_총량상한을넘으면_가장오래안쓴항목부터지운다() async {
        let sut = self.makeSUT(maxByteSize: 250, maxEntryByteSize: 100)
        let thirdCoverURL = URL(string: "https://picsum.photos/seed/3/200/300")!

        await sut.store(self.makeBody(100), etag: "a", for: self.coverURL)
        await sut.store(self.makeBody(100), etag: "b", for: self.otherCoverURL)
        _ = await sut.entry(for: self.coverURL)

        await sut.store(self.makeBody(100), etag: "c", for: thirdCoverURL)

        let survivor = await sut.entry(for: self.coverURL)
        let evicted = await sut.entry(for: self.otherCoverURL)
        let newest = await sut.entry(for: thirdCoverURL)
        XCTAssertEqual(survivor?.etag, "a")
        XCTAssertNil(evicted)
        XCTAssertEqual(newest?.etag, "c")
    }

    func test_방금저장한항목은_축출대상에서제외한다() async {
        let sut = self.makeSUT(maxByteSize: 100, maxEntryByteSize: 100)
        await sut.store(self.makeBody(100), etag: "a", for: self.coverURL)

        await sut.store(self.makeBody(100), etag: "b", for: self.otherCoverURL)

        let newest = await sut.entry(for: self.otherCoverURL)
        XCTAssertEqual(newest?.etag, "b")
    }

    func test_본문쓰기가실패하면_색인에올리지않는다() async {
        let sut = self.makeSUT()
        self.files.failWrites { $0 != "manifest.json" }

        await sut.store(self.makeBody(10), etag: "v1", for: self.coverURL)

        let entry = await sut.entry(for: self.coverURL)
        XCTAssertNil(entry)
    }

    func test_색인에는있는데파일이없으면_nil을주고색인을정리한다() async {
        let sut = self.makeSUT()
        await sut.store(self.makeBody(10), etag: "v1", for: self.coverURL)
        let bodyKey = self.files.keys.first { $0 != "manifest.json" }

        self.files.removeBehindTheCache(forKey: bodyKey ?? "")

        let entry = await sut.entry(for: self.coverURL)
        XCTAssertNil(entry)

        await sut.store(self.makeBody(20), etag: "v2", for: self.coverURL)
        let reborn = await sut.entry(for: self.coverURL)
        XCTAssertEqual(reborn?.etag, "v2")
    }

    func test_색인에없는본문파일은_시작할때청소한다() async {
        self.files.seed(self.makeBody(10), forKey: "\(String(repeating: "a", count: 64)).1")
        self.files.seed(self.makeBody(10), forKey: "\(String(repeating: "b", count: 64)).2")
        let sut = self.makeSUT()

        _ = await sut.entry(for: self.coverURL)

        XCTAssertEqual(self.files.keys.subtracting(["manifest.json"]), [])
    }

    func test_매니페스트형식이다르면_색인을통째로버린다() async {
        let key = String(repeating: "c", count: 64)
        let manifest = Data(#"{"schemaVersion":999,"entries":{"\#(key)":{"storedAt":0,"lastAccessedAt":0,"byteSize":10,"generation":1}}}"#.utf8)
        self.files.seed(manifest, forKey: "manifest.json")
        self.files.seed(self.makeBody(10), forKey: "\(key).1")
        let sut = self.makeSUT()

        _ = await sut.entry(for: self.coverURL)

        XCTAssertFalse(self.files.keys.contains("\(key).1"))
    }

    func test_매니페스트가있으면_다음실행에서도항목을찾는다() async {
        let first = self.makeSUT()
        await first.store(self.makeBody(10), etag: "v1", for: self.coverURL)
        _ = await first.entry(for: self.coverURL)
        let didFlush = await waitUntil { [files] in files?.data(forKey: "manifest.json") != nil }
        XCTAssertTrue(didFlush)

        let second = DiskCache(
            client: self.files.client,
            configuration: ImageDiskCacheConfiguration(maxByteSize: 1_000_000, freshLifetime: 3_600)
        )

        let entry = await second.entry(for: self.coverURL)
        XCTAssertEqual(entry?.etag, "v1")
    }
}
