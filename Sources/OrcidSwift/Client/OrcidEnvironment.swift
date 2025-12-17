import Foundation

/// ORCID server configuration (base URLs for API and OAuth endpoints).
public struct OrcidEnvironment: Sendable, Equatable {
    /// Base URL for the public ORCID API, typically ending in `/v3.0/`.
    public let apiBaseURL: URL

    /// Base URL for ORCID OAuth, typically `https://orcid.org/` or the sandbox.
    public let oauthBaseURL: URL

    /// ORCID public API base: `https://pub.orcid.org/v3.0/`.
    /// OAuth base: `https://orcid.org/`.
    public static let production = OrcidEnvironment(
        apiBaseURL: URL(string: "https://pub.orcid.org/v3.0/")!,
        oauthBaseURL: URL(string: "https://orcid.org/")!
    )

    /// ORCID sandbox public API base: `https://pub.sandbox.orcid.org/v3.0/`.
    /// OAuth base: `https://sandbox.orcid.org/`.
    public static let sandbox = OrcidEnvironment(
        apiBaseURL: URL(string: "https://pub.sandbox.orcid.org/v3.0/")!,
        oauthBaseURL: URL(string: "https://sandbox.orcid.org/")!
    )

    /// Creates a custom environment.
    public init(apiBaseURL: URL, oauthBaseURL: URL) {
        self.apiBaseURL = apiBaseURL
        self.oauthBaseURL = oauthBaseURL
    }
}
