import Foundation

/// Public ORCID record response from `GET /{orcid}/record`.
public struct OrcidRecord: Decodable, Sendable, Equatable {
    public let orcidIdentifier: OrcidIdentifier?
    public let person: OrcidPerson?
    public let activitiesSummary: OrcidActivitiesSummary?

    enum CodingKeys: String, CodingKey {
        case orcidIdentifier = "orcid-identifier"
        case person
        case activitiesSummary = "activities-summary"
    }
}

/// ORCID identifier block.
public struct OrcidIdentifier: Decodable, Sendable, Equatable {
    public let uri: String?
    public let path: String?
    public let host: String?
}

/// Person section of the ORCID record.
public struct OrcidPerson: Decodable, Sendable, Equatable {
    public let name: OrcidName?
    public let biography: OrcidBiography?
}

/// Name section of the person record.
public struct OrcidName: Decodable, Sendable, Equatable {
    public let givenNames: OrcidStringValue?
    public let familyName: OrcidStringValue?
    public let creditName: OrcidStringValue?

    enum CodingKeys: String, CodingKey {
        case givenNames = "given-names"
        case familyName = "family-name"
        case creditName = "credit-name"
    }
}

/// Biography section of the person record.
public struct OrcidBiography: Decodable, Sendable, Equatable {
    public let content: String?
}

/// Activities summary section.
public struct OrcidActivitiesSummary: Decodable, Sendable, Equatable {
    public let works: OrcidWorksGroupContainer?
}
