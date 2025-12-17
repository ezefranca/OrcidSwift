import Foundation

/// Errors produced by OrcidSwift.
public enum OrcidError: Error, Sendable, Equatable {
    /// The provided string could not be parsed as an ORCID iD.
    case invalidOrcidID(String)

    /// The library failed to build a valid URL.
    case invalidURL

    /// A transport-layer error occurred (e.g. DNS, TLS, connectivity, URLSession error).
    case transportError(String)

    /// The server responded with a non-2xx status code.
    case httpError(status: Int, body: String?)

    /// JSON decoding failed.
    case decodingError(String)

    /// Request body encoding failed.
    case encodingError(String)
}
