import Foundation

public struct DataResponseDecoder: ResponseDecoder {
    public init() {}

    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        guard type == Data.self, let value = data as? T else {
            let error = NSError(domain: "DataResponseDecoder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Expected Data type but got \(type)"])
            throw HTTPClientError.decodingFailed(underlyingError: error, data: data)
        }
        return value
    }
}
