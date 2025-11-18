import Foundation

enum ServerError: Error {
    case badRequest(String)
    case notFound(String)
    case conflict(code: String, message: String)
    case methodNotAllowed(allowed: [HTTPMethod])
    case internalFailure
    case injected(statusCode: Int)
}

extension ServerError {
    var response: MockHTTPResponse {
        var headers = ["Content-Type": "application/json"]
        let statusCode: Int
        let code: String
        let message: String

        switch self {
        case .badRequest(let detail):
            (statusCode, code, message) = (400, "BAD_REQUEST", detail)
        case .notFound(let detail):
            (statusCode, code, message) = (404, "NOT_FOUND", detail)
        case .conflict(let conflictCode, let detail):
            (statusCode, code, message) = (409, conflictCode, detail)
        case .methodNotAllowed(let allowed):
            (statusCode, code, message) = (405, "METHOD_NOT_ALLOWED", "허용되지 않은 메서드입니다")
            headers["Allow"] = allowed.map(\.rawValue).sorted().joined(separator: ", ")
        case .internalFailure:
            (statusCode, code, message) = (500, "INTERNAL_ERROR", "서버 내부 오류가 발생했습니다")
        case .injected(let injectedStatusCode):
            (statusCode, code, message) = (injectedStatusCode, "INJECTED_FAULT", "주입된 실패입니다")
        }

        let dto = ServerErrorDTO(error: .init(code: code, message: message))
        return MockHTTPResponse(
            statusCode: statusCode,
            headers: headers,
            body: (try? ServerJSON.encoder.encode(dto)) ?? Data()
        )
    }
}

struct ServerErrorDTO: Encodable {
    struct Payload: Encodable {
        let code: String
        let message: String
    }

    let error: Payload
}
