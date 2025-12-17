import Foundation

/// OAuth token response returned by ORCID's `/oauth/token` endpoint.
public struct OrcidOAuthToken: Decodable, Sendable, Equatable {
    /// Access token.
    public let accessToken: String
    /// Token type (typically `bearer`).
    public let tokenType: String?
    /// Refresh token, if issued.
    public let refreshToken: String?
    /// Lifetime in seconds.
    public let expiresIn: Int?
    /// Granted scope string.
    public let scope: String?
    /// Display name associated with the token, if present.
    public let name: String?
    /// ORCID iD string associated with the token, if present.
    public let orcid: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope
        case name
        case orcid
    }
}
