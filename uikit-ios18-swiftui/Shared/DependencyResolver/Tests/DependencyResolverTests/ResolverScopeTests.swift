import Foundation
import Testing

@testable import DependencyResolver

struct ResolverScopeTests {

    private enum GreetingKey: ResolverKey {
        static var testValue: String { "테스트 기본값" }
    }

    private enum NumberKey: ResolverKey {
        static var testValue: Int { -1 }
    }

    @Test
    func test스코프에서주입하지않은키는_testValue로채운다() {
        let value = withResolver(from: .test) { _ in } operation: {
            Resolver[GreetingKey.self]
        }

        #expect(value == "테스트 기본값")
    }

    @Test
    func 스코프에주입한값이있으면_testValue대신그값을쓴다() {
        let value = withResolver(from: .test) { values in
            values[GreetingKey.self] = "주입된 값"
        } operation: {
            Resolver[GreetingKey.self]
        }

        #expect(value == "주입된 값")
    }

    @Test
    func 한스코프에여러키를주입하면_각각독립적으로해석된다() {
        let result = withResolver(from: .test) { values in
            values[GreetingKey.self] = "안녕"
            values[NumberKey.self] = 42
        } operation: {
            (Resolver[GreetingKey.self], Resolver[NumberKey.self])
        }

        #expect(result.0 == "안녕")
        #expect(result.1 == 42)
    }

    @Test
    func 스코프를벗어나면_주입한값이사라진다() {
        let inside = withResolver(from: .test) { values in
            values[GreetingKey.self] = "안쪽"
        } operation: {
            Resolver[GreetingKey.self]
        }

        let outside = withResolver(from: .test) { _ in } operation: {
            Resolver[GreetingKey.self]
        }

        #expect(inside == "안쪽")
        #expect(outside == "테스트 기본값")
    }

    @Test
    func 스코프를중첩하면_안쪽주입이바깥을가린다() {
        let result: (String, String) = withResolver(from: .test) { values in
            values[GreetingKey.self] = "바깥"
        } operation: {
            let outer = Resolver[GreetingKey.self]
            let inner = withResolver(from: .inheritingCurrent) { values in
                values[GreetingKey.self] = "안쪽"
            } operation: {
                Resolver[GreetingKey.self]
            }
            return (outer, inner)
        }

        #expect(result.0 == "바깥")
        #expect(result.1 == "안쪽")
    }

    @Test
    func 안쪽스코프가끝나면_바깥주입이돌아온다() {
        let after = withResolver(from: .test) { values in
            values[GreetingKey.self] = "바깥"
        } operation: { () -> String in
            _ = withResolver(from: .inheritingCurrent) { values in
                values[GreetingKey.self] = "안쪽"
            } operation: {
                Resolver[GreetingKey.self]
            }
            return Resolver[GreetingKey.self]
        }

        #expect(after == "바깥")
    }

    @Test
    func 현재를상속한스코프는_바깥에주입한값을그대로본다() {
        let value = withResolver(from: .test) { values in
            values[GreetingKey.self] = "물려받은 값"
        } operation: {
            withResolver(from: .inheritingCurrent) { _ in } operation: {
                Resolver[GreetingKey.self]
            }
        }

        #expect(value == "물려받은 값")
    }

    @Test
    func 현재를상속한스코프에서_바깥의testValue대체도이어진다() {
        let value = withResolver(from: .test) { _ in } operation: {
            withResolver(from: .inheritingCurrent) { _ in } operation: {
                Resolver[NumberKey.self]
            }
        }

        #expect(value == -1)
    }

    @Test
    func 비동기작업안에서도_스코프주입이유지된다() async {
        let value = await withResolver(from: .test) { values in
            values[GreetingKey.self] = "비동기"
        } operation: { () async -> String in
            await Task.yield()
            return Resolver[GreetingKey.self]
        }

        #expect(value == "비동기")
    }

    @Test
    func Resolved는_생성시점의스코프에서값을읽는다() {
        struct Consumer {
            @Resolved(GreetingKey.self) var greeting: String
        }

        let consumer = withResolver(from: .test) { values in
            values[GreetingKey.self] = "생성 시점"
        } operation: {
            Consumer()
        }

        #expect(consumer.greeting == "생성 시점")
    }

    @Test
    func ResolverValues에같은키를두번넣으면_나중값이남는다() {
        var values = ResolverValues()

        values[GreetingKey.self] = "처음"
        values[GreetingKey.self] = "나중"

        #expect(values[GreetingKey.self] == "나중")
    }
}
