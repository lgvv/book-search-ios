import Foundation

struct HTTPMethod: RawRepresentable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue.uppercased()
    }

    static let get = Self(rawValue: "GET")
    static let post = Self(rawValue: "POST")
    static let put = Self(rawValue: "PUT")
    static let patch = Self(rawValue: "PATCH")
    static let delete = Self(rawValue: "DELETE")
}
