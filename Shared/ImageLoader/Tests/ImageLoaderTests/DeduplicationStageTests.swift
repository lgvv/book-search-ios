import UIKit
import XCTest

import TestSupport

@testable import ImageLoader

final class DeduplicationStageTests: XCTestCase {

    private static let coverURL = URL(string: "https://picsum.photos/seed/1/200/300")!

    private static let sampleImage: UIImage = UIGraphicsImageRenderer(
        size: CGSize(width: 1, height: 1)
    ).image { _ in }

    private static func context(
        behavior: CacheBehavior = .standard,
        intent: ImageLoadContext.Intent = .display,
        pixelSize: CGSize? = CGSize(width: 45, height: 80)
    ) -> ImageLoadContext {
        ImageLoadContext(
            url: Self.coverURL,
            behavior: behavior,
            intent: intent,
            etag: nil,
            revalidatingGeneration: nil,
            targetPixelSize: pixelSize
        )
    }

    private static func makePipeline(gate: Gate, callCount: Locked<Int>) -> ImageLoadPipeline {
        ImageLoadPipeline(stages: [.deduplication()]) { _ in
            callCount.withValue { $0 += 1 }
            await gate.wait()
            return ImageLoadOutcome(image: Self.sampleImage, data: nil, etag: nil, source: .network)
        }
    }

    func test_같은요청이동시에오면_아래스테이지를한번만실행한다() async throws {
        let gate = Gate()
        let callCount = Locked(0)
        let sut = Self.makePipeline(gate: gate, callCount: callCount)

        async let first = sut.load(Self.context())
        await gate.waitUntilArrived()
        async let second = sut.load(Self.context())
        async let third = sut.load(Self.context())
        gate.open()
        _ = try await (first, second, third)

        XCTAssertEqual(callCount.value, 1)
    }

    func test_합류한요청들은_모두같은결과를받는다() async throws {
        let gate = Gate()
        let callCount = Locked(0)
        let sut = Self.makePipeline(gate: gate, callCount: callCount)

        async let first = sut.load(Self.context())
        await gate.waitUntilArrived()
        async let second = sut.load(Self.context())
        gate.open()
        let (a, b) = try await (first, second)

        XCTAssertIdentical(a.image, b.image)
    }

    func test_앞요청이끝난뒤에오면_다시실행한다() async throws {
        let gate = Gate()
        let callCount = Locked(0)
        let sut = Self.makePipeline(gate: gate, callCount: callCount)
        gate.open()

        _ = try await sut.load(Self.context())
        _ = try await sut.load(Self.context())

        XCTAssertEqual(callCount.value, 2)
    }

    func test_디코드크기가다르면_합류시키지않는다() async throws {
        let gate = Gate()
        let callCount = Locked(0)
        let sut = Self.makePipeline(gate: gate, callCount: callCount)

        async let small = sut.load(Self.context(pixelSize: CGSize(width: 45, height: 80)))
        async let large = sut.load(Self.context(pixelSize: CGSize(width: 180, height: 260)))
        await gate.waitUntilArrived(2)
        gate.open()
        _ = try await (small, large)

        XCTAssertEqual(callCount.value, 2)
    }

    func test_캐시정책이다르면_합류시키지않는다() async throws {
        let gate = Gate()
        let callCount = Locked(0)
        let sut = Self.makePipeline(gate: gate, callCount: callCount)

        async let standard = sut.load(Self.context(behavior: .standard))
        async let memoryOnly = sut.load(Self.context(behavior: .memoryOnly))
        await gate.waitUntilArrived(2)
        gate.open()
        _ = try await (standard, memoryOnly)

        XCTAssertEqual(callCount.value, 2)
    }

    func test_재검증요청은_합류대상에서제외한다() async throws {
        let gate = Gate()
        let callCount = Locked(0)
        let sut = Self.makePipeline(gate: gate, callCount: callCount)

        async let display = sut.load(Self.context(intent: .display))
        async let revalidate = sut.load(Self.context(intent: .revalidate))
        await gate.waitUntilArrived(2)
        gate.open()
        _ = try await (display, revalidate)

        XCTAssertEqual(callCount.value, 2)
    }

    func test_마지막대기자가취소되면_공유작업도취소된다() async {
        let started = Gate()
        let wasCancelled = Locked(false)
        let sut = ImageLoadPipeline(stages: [.deduplication()]) { _ in
            await started.wait()
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
            } catch {
                wasCancelled.withValue { $0 = true }
            }
            return ImageLoadOutcome(image: Self.sampleImage, data: nil, etag: nil, source: .network)
        }

        let request = Self.context()
        let caller = Task { [sut, request] in _ = try? await sut.load(request) }
        await started.waitUntilArrived()
        started.open()
        await Task.yield()
        caller.cancel()

        let didCancel = await waitUntil { wasCancelled.value }
        XCTAssertTrue(didCancel)
    }

    func test_대기자가남아있으면_한쪽이취소돼도공유작업은계속된다() async {
        let gate = Gate()
        let callCount = Locked(0)
        let sut = Self.makePipeline(gate: gate, callCount: callCount)
        let source = Locked<ImageLoadOutcome.Source?>(nil)

        let request = Self.context()
        let first = Task { [sut, request] in _ = try? await sut.load(request) }
        await gate.waitUntilArrived()
        let second = Task { [sut, request] in
            let outcome = try? await sut.load(request)
            source.withValue { $0 = outcome?.source }
        }
        let didJoin = await waitUntil { callCount.value == 1 }
        XCTAssertTrue(didJoin)

        first.cancel()
        gate.open()

        await second.value
        XCTAssertEqual(source.value, .network)
    }
}
