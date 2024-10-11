import Foundation

public struct HTTPFailure: Error {
    public let request: HTTPRequest
    public let response: HTTPResponse?
    public let error: any Error

    public init(
        request: HTTPRequest,
        response: HTTPResponse?,
        error: any Error
    ) {
        self.request = request
        self.response = response
        self.error = error
    }
}
