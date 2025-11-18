import Foundation

public struct HTTPClient: Sendable {
    private let transport: any HTTPTransport
    private let middlewares: [any HTTPClientMiddleware]

    public init(
        transport: any HTTPTransport,
        middlewares: [any HTTPClientMiddleware]
    ) {
        self.transport = transport
        self.middlewares = middlewares
    }

    public func replacingTransport(_ transport: any HTTPTransport) -> HTTPClient {
        HTTPClient(transport: transport, middlewares: middlewares)
    }

    public func response(for request: HTTPRequest) async throws -> HTTPResponse {
        do {
            return try await sendThroughPipeline(request: request)
        } catch let failure as HTTPFailure {
            throw failure
        } catch {
            throw HTTPFailure(request: request, response: nil, error: error)
        }
    }

    public func send<ResponseType: Decodable>(
        request: HTTPRequest,
        decoder: some ResponseDecoder = JSONResponseDecoder()
    ) async throws -> ResponseType {
        let response: HTTPResponse
        do {
            response = try await sendThroughPipeline(request: request)
        } catch let failure as HTTPFailure {
            throw failure
        } catch {
            throw HTTPFailure(request: request, response: nil, error: error)
        }

        guard let data = response.body else {
            throw HTTPFailure(
                request: request,
                response: response,
                error: HTTPClientError.missingResponseData
            )
        }

        do {
            return try decoder.decode(ResponseType.self, from: data)
        } catch {
            throw HTTPFailure(
                request: request,
                response: response,
                error: HTTPClientError.decodingFailed(
                    underlyingError: error,
                    data: data
                )
            )
        }
    }

    private func sendThroughPipeline(request: HTTPRequest) async throws -> HTTPResponse {
        let terminal: @Sendable (HTTPRequest) async throws -> HTTPResponse = { _request in
            try await transport.send(request: _request)
        }

        var pipeline = terminal
        for middleware in middlewares.reversed() {
            let next = pipeline
            pipeline = { _request in
                try await middleware.intercept(request: _request, next: next)
            }
        }

        do {
            return try await pipeline(request)
        } catch let failure as HTTPFailure {
            throw failure
        } catch {
            throw HTTPFailure(request: request, response: nil, error: error)
        }
    }
}
