import Foundation

/// High-level async client for the public ORCID API.
///
/// Use `fetchRecord(orcid:)` and `fetchWorks(orcid:)` to access public data.
/// For OAuth, use `makeAuthorizeURL(...)` and `exchangeCodeForToken(...)`.
public final class OrcidClient: @unchecked Sendable {
    /// Client configuration.
    public struct Configuration: Sendable, Equatable {
        /// Server environment (production or sandbox).
        public let environment: OrcidEnvironment

        /// User-Agent header value to send with requests.
        public let userAgent: String

        /// Creates a configuration.
        public init(
            environment: OrcidEnvironment = .production,
            userAgent: String = "OrcidKit/1.0"
        ) {
            self.environment = environment
            self.userAgent = userAgent
        }
    }

    private let config: Configuration
    private let loader: any HTTPDataLoading
    private let decoder: JSONDecoder
    private let urlComponentsFactory: (URL) -> URLComponents?

    /// Creates a client.
    /// - Parameters:
    ///   - config: Client configuration.
    ///   - session: URLSession used for requests. Provide a custom session for testing.
    public init(config: Configuration = .init(), session: URLSession = .shared) {
        self.config = config
        self.loader = session
        self.decoder = JSONDecoder()
        self.urlComponentsFactory = { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
    }
    /// Creates a client with a custom HTTP loader and URL components factory.
    /// - Parameters:
    ///
    ///  - config: Client configuration.
    ///  - session: URLSession used for requests. Provide a custom session for testing.
    ///  - loader: Custom HTTP data loader. If `nil`, uses the provided `session`.
    ///  - urlComponentsFactory: Factory function to create `URLComponents` from a `URL`.
    ///
    ///  Note: This initializer is primarily intended for testing purposes.
    public init(
        config: Configuration = .init(),
        session: URLSession = .shared,
        loader: (any HTTPDataLoading)? = nil,
        urlComponentsFactory: @escaping (URL) -> URLComponents?
    ) {
        self.config = config
        self.loader = loader ?? session
        self.decoder = JSONDecoder()
        self.urlComponentsFactory = urlComponentsFactory
    }

    // MARK: - Public API (read)

    /// Fetches the public record for an ORCID iD.
    /// - Parameter orcid: The ORCID iD.
    /// - Returns: A decoded `OrcidRecord`.
    public func fetchRecord(orcid: OrcidID) async throws -> OrcidRecord {
        let url = config.environment.apiBaseURL.appendingPathComponent(OrcidEndpoints.record(orcid: orcid))
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        applyCommonHeaders(&req)
        req.setValue("application/vnd.orcid+json", forHTTPHeaderField: "Accept")

        let resp = try await HTTP.perform(req, loader: loader)
        try validate(resp)

        do {
            return try decoder.decode(OrcidRecord.self, from: resp.data)
        } catch {
            throw OrcidError.decodingError(String(describing: error))
        }
    }

    /// Fetches the public works summary for an ORCID iD.
    /// - Parameter orcid: The ORCID iD.
    /// - Returns: A decoded `OrcidWorksResponse`.
    public func fetchWorks(orcid: OrcidID) async throws -> OrcidWorksResponse {
        let url = config.environment.apiBaseURL.appendingPathComponent(OrcidEndpoints.works(orcid: orcid))
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        applyCommonHeaders(&req)
        req.setValue("application/vnd.orcid+json", forHTTPHeaderField: "Accept")

        let resp = try await HTTP.perform(req, loader: loader)
        try validate(resp)

        do {
            return try decoder.decode(OrcidWorksResponse.self, from: resp.data)
        } catch {
            throw OrcidError.decodingError(String(describing: error))
        }
    }

    // MARK: - OAuth helpers (3-legged)

    /// Builds an ORCID authorization URL (3-legged OAuth).
    ///
    /// - Parameters:
    ///   - clientID: ORCID OAuth client ID.
    ///   - redirectURI: Redirect URI registered in ORCID.
    ///   - scopes: Requested scopes.
    ///   - state: Optional CSRF state value.
    ///   - showLogin: Optional ORCID-specific flag to force login.
    ///   - prompt: Optional prompt hint.
    public func makeAuthorizeURL(
        clientID: String,
        redirectURI: String,
        scopes: [OrcidOAuthScope],
        state: String? = nil,
        showLogin: Bool? = nil,
        prompt: String? = nil
    ) throws -> URL {
        let base = config.environment.oauthBaseURL.appendingPathComponent(OrcidEndpoints.oauthAuthorizePath)

        guard var comps = urlComponentsFactory(base) else {
            throw OrcidError.invalidURL
        }

        var q: [URLQueryItem] = [
            .init(name: "client_id", value: clientID),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: scopes.map(\.rawValue).joined(separator: " ")),
            .init(name: "redirect_uri", value: redirectURI)
        ]

        if let state { q.append(.init(name: "state", value: state)) }
        if let showLogin { q.append(.init(name: "show_login", value: showLogin ? "true" : "false")) }
        if let prompt { q.append(.init(name: "prompt", value: prompt)) }

        comps.queryItems = q
        guard let url = comps.url else { throw OrcidError.invalidURL }
        return url
    }

    /// Exchanges an OAuth authorization code for an access token.
    public func exchangeCodeForToken(
        clientID: String,
        clientSecret: String,
        code: String,
        redirectURI: String
    ) async throws -> OrcidOAuthToken {
        let url = config.environment.oauthBaseURL.appendingPathComponent(OrcidEndpoints.oauthTokenPath)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        applyCommonHeaders(&req)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = FormURLEncoder.encode([
            "client_id": clientID,
            "client_secret": clientSecret,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI
        ])
        req.httpBody = body

        let resp = try await HTTP.perform(req, loader: loader)
        try validate(resp)

        do {
            return try decoder.decode(OrcidOAuthToken.self, from: resp.data)
        } catch {
            throw OrcidError.decodingError(String(describing: error))
        }
    }

    // MARK: - Helpers

    private func applyCommonHeaders(_ req: inout URLRequest) {
        req.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
    }

    private func validate(_ resp: HTTPResponse) throws {
        guard (200...299).contains(resp.statusCode) else {
            throw OrcidError.httpError(status: resp.statusCode, body: HTTP.bodyString(resp.data))
        }
    }
}
