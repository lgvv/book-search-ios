import RemoteConfigInterface

enum Configs {
    static let searchPageSize = ConfigKey(
        key: "search.pageSize",
        defaultValue: 20,
        owner: "lgvv"
    )

    static let mockWriteFailureRate = ConfigKey(
        key: "mock.writeFailureRate",
        defaultValue: 0.0,
        owner: "lgvv"
    )
}
