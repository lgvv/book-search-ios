import RemoteConfigInterface

enum Configs {
    static let searchPageSize = ConfigKey(
        key: "search.pageSize",
        defaultValue: 20,
        owner: "lgvv",
        isValid: { (1 ... 100).contains($0) }
    )

    static let mockWriteFailureRate = ConfigKey(
        key: "mock.writeFailureRate",
        defaultValue: 0.0,
        owner: "lgvv",
        isValid: { (0.0 ... 1.0).contains($0) }
    )
}
