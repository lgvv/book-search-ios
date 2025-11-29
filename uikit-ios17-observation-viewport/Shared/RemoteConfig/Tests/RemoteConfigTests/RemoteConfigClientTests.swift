import Foundation
import Testing

import RemoteConfigInterface

struct RemoteConfigClientTests {

    private let pageSize = ConfigKey(
        key: "search.pageSize",
        defaultValue: 20,
        owner: "테스트",
        isValid: { (1 ... 100).contains($0) }
    )

    private func makeClient(_ rawValues: [String]) -> RemoteConfigClient {
        RemoteConfigClient(rawValues: { _ in rawValues })
    }

    @Test
    func 유효한값이면_그대로쓴다() {
        #expect(self.makeClient(["30"]).value(self.pageSize) == 30)
    }

    @Test
    func 값이하나도없으면_기본값을쓴다() {
        #expect(self.makeClient([]).value(self.pageSize) == 20)
    }

    @Test
    func 파싱할수없는값이면_기본값으로물러선다() {
        #expect(self.makeClient(["서른"]).value(self.pageSize) == 20)
    }

    @Test
    func 범위밖값이면_기본값으로물러선다() {
        #expect(self.makeClient(["0"]).value(self.pageSize) == 20)
        #expect(self.makeClient(["-5"]).value(self.pageSize) == 20)
        #expect(self.makeClient(["101"]).value(self.pageSize) == 20)
    }

    @Test
    func 경계값은_통과한다() {
        #expect(self.makeClient(["1"]).value(self.pageSize) == 1)
        #expect(self.makeClient(["100"]).value(self.pageSize) == 100)
    }

    @Test
    func 앞선소스가범위밖이면_다음소스의유효한값을쓴다() {
        #expect(self.makeClient(["0", "30"]).value(self.pageSize) == 30)
    }

    @Test
    func 검증을지정하지않으면_파싱만으로통과한다() {
        let key = ConfigKey(key: "임의", defaultValue: 20, owner: "테스트")

        #expect(self.makeClient(["0"]).value(key) == 0)
    }
}
