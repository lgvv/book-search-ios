import Testing

import TestSupport

@testable import SharedFoundation

struct AsyncValueChannelTests {

    @Test
    func 구독을시작하면_현재값을곧바로받는다() async {
        let sut = AsyncValueChannel(10)

        var iterator = sut.stream().makeAsyncIterator()

        let first = await iterator.next()
        #expect(first == 10)
    }

    @Test
    func 늦게구독해도_그시점의현재값부터받는다() async {
        let sut = AsyncValueChannel(10)
        sut.send(20)
        sut.send(30)

        var iterator = sut.stream().makeAsyncIterator()

        let first = await iterator.next()
        #expect(first == 30)
    }

    @Test
    func 여러구독자가_같은변경을각자받는다() async {
        let sut = AsyncValueChannel(0)
        let first = AsyncValueRecorder(sut.stream())
        let second = AsyncValueRecorder(sut.stream())

        sut.send(1)
        sut.send(2)

        let firstValues = try? await first.wait(untilCount: 3)
        let secondValues = try? await second.wait(untilCount: 3)
        #expect(firstValues == [0, 1, 2])
        #expect(secondValues == [0, 1, 2])
    }

    @Test
    func 구독중간의변경도_순서대로도착한다() async {
        let sut = AsyncValueChannel("a")
        let recorder = AsyncValueRecorder(sut.stream())

        sut.send("b")
        sut.send("c")

        let values = try? await recorder.wait(untilCount: 3)
        #expect(values == ["a", "b", "c"])
    }

    @Test
    func 현재값은_마지막으로보낸값이다() {
        let sut = AsyncValueChannel(1)

        sut.send(7)

        #expect(sut.value == 7)
    }

    @Test
    func 한구독자가떠나도_남은구독자는계속받는다() async {
        let sut = AsyncValueChannel(0)
        let remaining = AsyncValueRecorder(sut.stream())

        let leaving = Task {
            for await value in sut.stream() where value >= 0 {
                break
            }
        }
        await leaving.value

        sut.send(1)

        let values = try? await remaining.wait(untilCount: 2)
        #expect(values == [0, 1])
    }

    @Test
    func 채널이사라지면_스트림이끝난다() async {
        var sut: AsyncValueChannel? = AsyncValueChannel(0)
        let stream = sut!.stream()

        let finished = Task {
            var received: [Int] = []
            for await value in stream {
                received.append(value)
            }
            return received
        }

        sut = nil

        let received = await finished.value
        #expect(received == [0])
    }
}

struct AsyncEventChannelTests {

    @Test
    func 구독전에보낸사건은_받지않는다() async {
        let sut = AsyncEventChannel<String>()
        sut.send("지난 사건")

        let recorder = AsyncValueRecorder(sut.stream())
        sut.send("새 사건")

        let values = try? await recorder.wait(untilCount: 1)
        #expect(values == ["새 사건"])
    }

    @Test
    func 여러구독자가_같은사건을각자받는다() async {
        let sut = AsyncEventChannel<Int>()
        let first = AsyncValueRecorder(sut.stream())
        let second = AsyncValueRecorder(sut.stream())

        sut.send(1)
        sut.send(2)

        let firstValues = try? await first.wait(untilCount: 2)
        let secondValues = try? await second.wait(untilCount: 2)
        #expect(firstValues == [1, 2])
        #expect(secondValues == [1, 2])
    }

    @Test
    func 채널이사라지면_스트림이끝난다() async {
        var sut: AsyncEventChannel? = AsyncEventChannel<Int>()
        let stream = sut!.stream()

        let finished = Task {
            var count = 0
            for await _ in stream {
                count += 1
            }
            return count
        }

        sut = nil

        let count = await finished.value
        #expect(count == 0)
    }
}
