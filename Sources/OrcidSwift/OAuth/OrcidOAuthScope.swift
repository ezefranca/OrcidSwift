import Foundation

/// ORCID OAuth scopes.
public enum OrcidOAuthScope: String, Sendable {
    /// `/authenticate`
    case authenticate = "/authenticate"
    /// `/read-limited`
    case readLimited = "/read-limited"
    /// `/activities/update`
    case activitiesUpdate = "/activities/update"
    /// `/person/update`
    case personUpdate = "/person/update"
}
