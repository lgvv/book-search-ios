import Foundation

public struct MockFaultProfile: Sendable {
    public var failureRate: Double
    public var statusCodes: [Int]
    public var methodNames: Set<String>

    public init(
        failureRate: Double,
        statusCodes: [Int] = [500, 503],
        methodNames: Set<String> = ["POST", "PUT", "PATCH", "DELETE"]
    ) {
        self.failureRate = failureRate
        self.statusCodes = statusCodes
        self.methodNames = methodNames
    }

    public static let disabled = Self(failureRate: 0)
}

struct FaultInjectionMiddleware: MockMiddleware {
    let profile: MockFaultProfile

    func respond(to request: MockRequest, next: MockResponder) async throws -> MockHTTPResponse {
        guard
            self.profile.failureRate > 0,
            self.profile.methodNames.contains(request.method.rawValue.uppercased()),
            let statusCode = self.profile.statusCodes.randomElement(),
            Double.random(in: 0..<1) < self.profile.failureRate
        else {
            return try await next(request)
        }

        return ServerError.injected(statusCode: statusCode).response
    }
}
