import Foundation
import Synchronization

import SharedFoundation

public final class MockServerURLProtocol: URLProtocol, @unchecked Sendable {
    private let taskBox = Mutex<Task<Void, Never>?>(nil)

    override public class func canInit(with request: URLRequest) -> Bool {
        guard MockServer.router != nil,
              let url = request.url,
              url.scheme?.lowercased() == "https",
              let host = url.host,
              let mockHost = MockServer.baseURL.host
        else { return false }
        return host.caseInsensitiveCompare(mockHost) == .orderedSame
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override public func startLoading() {
        let request = self.request
        let task = Task { @Sendable [weak self] in
            guard let self else { return }
            do {
                guard let router = MockServer.router, let url = request.url else {
                    throw URLError(.unsupportedURL)
                }
                let response = try await router.respond(to: request)
                guard !Task.isCancelled else { return }

                guard let httpResponse = HTTPURLResponse(
                    url: url,
                    statusCode: response.statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: response.headers
                ) else {
                    throw URLError(.badServerResponse)
                }
                self.client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
                self.client?.urlProtocol(self, didLoad: response.body)
                self.client?.urlProtocolDidFinishLoading(self)
            } catch is CancellationError {
            } catch {
                self.client?.urlProtocol(self, didFailWithError: error)
            }
        }
        self.taskBox.withLock { $0 = task }
    }

    override public func stopLoading() {
        self.taskBox.withLock { task in
            task?.cancel()
            task = nil
        }
    }
}
