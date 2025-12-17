import Foundation

/// Raw HTTP response returned by the internal networking layer.
struct HTTPResponse {
    let statusCode: Int
    let headers: [AnyHashable: Any]
    let data: Data
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public protocol HTTPDataLoading: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension URLSession: HTTPDataLoading {
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        // Use Apple’s native async API when available
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return try await self.data(for: request, delegate: nil)
        }

        // Back-deploy for older OS versions using a continuation
        return try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data, let response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
    }
}

enum HTTP {
    static func perform(_ request: URLRequest, loader: any HTTPDataLoading) async throws -> HTTPResponse {
        do {
            let (data, response) = try await loader.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw OrcidError.transportError("Non-HTTP response")
            }
            return HTTPResponse(statusCode: http.statusCode, headers: http.allHeaderFields, data: data)
        } catch {
            throw OrcidError.transportError(String(describing: error))
        }
    }

    static func bodyString(_ data: Data) -> String? {
        String(data: data, encoding: .utf8)
    }
}
