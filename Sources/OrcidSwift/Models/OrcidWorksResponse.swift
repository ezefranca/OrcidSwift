import Foundation

/// Public ORCID works response from `GET /{orcid}/works`.
public struct OrcidWorksResponse: Decodable, Sendable, Equatable {
    public let lastModifiedDate: OrcidLastModifiedDate?
    public let group: [OrcidWorkGroup]?

    enum CodingKeys: String, CodingKey {
        case lastModifiedDate = "last-modified-date"
        case group
    }
}

/// Last-modified wrapper.
public struct OrcidLastModifiedDate: Decodable, Sendable, Equatable {
    public let value: Int64?
}

/// Group of works.
public struct OrcidWorkGroup: Decodable, Sendable, Equatable {
    public let workSummary: [OrcidWorkSummary]?

    enum CodingKeys: String, CodingKey {
        case workSummary = "work-summary"
    }
}

/// Work summary entry.
public struct OrcidWorkSummary: Decodable, Sendable, Equatable {
    public let putCode: Int?
    public let title: OrcidWorkTitle?
    public let publicationDate: OrcidPublicationDate?
    public let externalIDs: OrcidExternalIDs?

    enum CodingKeys: String, CodingKey {
        case putCode = "put-code"
        case title
        case publicationDate = "publication-date"
        case externalIDs = "external-ids"
    }
}

/// Title section of a work.
public struct OrcidWorkTitle: Decodable, Sendable, Equatable {
    public let title: OrcidStringValue?
    public let subtitle: OrcidStringValue?
}

/// Publication date section of a work.
public struct OrcidPublicationDate: Decodable, Sendable, Equatable {
    public let year: OrcidStringValue?
    public let month: OrcidStringValue?
    public let day: OrcidStringValue?
}

/// Container used inside record activities.
public struct OrcidWorksGroupContainer: Decodable, Sendable, Equatable {
    public let group: [OrcidWorkGroup]?
}
