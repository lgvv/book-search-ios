import Foundation

public enum HTTPClientError: Error {
    case nonHTTPURLResponse(URLResponse)
    case missingResponseData
    case decodingFailed(underlyingError: Error, data: Data)
    case unacceptableStatusCode(_ statusCode: Int)
    case malformedStreamChunk(reason: String)
    case unexpectedStreamTermination
}
