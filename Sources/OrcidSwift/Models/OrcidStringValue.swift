import Foundation

/// ORCID API wrapper for a string value.
public struct OrcidStringValue: Decodable, Sendable, Equatable {
    public let value: String?
}

/// External identifier entry.
public struct OrcidExternalID: Decodable, Sendable, Equatable {
    public let externalIdType: String?
    public let externalIdValue: String?

    enum CodingKeys: String, CodingKey {
        case externalIdType = "external-id-type"
        case externalIdValue = "external-id-value"
    }
}

/// Container for external identifiers.
public struct OrcidExternalIDs: Decodable, Sendable, Equatable {
    public let externalIDs: [OrcidExternalID]?

    enum CodingKeys: String, CodingKey {
        case externalIDs = "external-id"
    }
}
