import Foundation

enum OrcidEndpoints {
    static func record(orcid: OrcidID) -> String { "\(orcid.value)/record" }
    static func works(orcid: OrcidID) -> String { "\(orcid.value)/works" }

    static let oauthAuthorizePath = "oauth/authorize"
    static let oauthTokenPath = "oauth/token"
}
