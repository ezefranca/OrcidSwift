import Foundation

/// A normalized ORCID iD in the canonical `0000-0000-0000-0000` form.
public struct OrcidID: Sendable, Hashable, Equatable {
    /// Canonical ORCID iD string.
    public let value: String

    /// Creates an ORCID iD from either a raw iD or a full `https://orcid.org/...` URL.
    /// - Throws: `OrcidError.invalidOrcidID` when the string cannot be normalized/validated.
    public init(_ raw: String) throws {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = OrcidID.normalize(trimmed)

        guard OrcidID.isValidFormat(normalized) else {
            throw OrcidError.invalidOrcidID(raw)
        }
        self.value = normalized
    }

    /// Normalizes an ORCID string by extracting the last path component when a URL is provided.
    ///
    /// Accepts: `0000-0002-1825-0097` or `https://orcid.org/0000-0002-1825-0097`.
    public static func normalize(_ raw: String) -> String {
        var s = raw
        if let url = URL(string: raw), let host = url.host, host.contains("orcid.org") {
            let comps = url.pathComponents.filter { $0 != "/" }
            if let last = comps.last { s = last }
        }
        return s
    }

    /// Validates the canonical ORCID format (including optional `X` check digit).
    public static func isValidFormat(_ s: String) -> Bool {
        let pattern = #"^\d{4}-\d{4}-\d{4}-\d{3}[\dX]$"#
        return s.range(of: pattern, options: .regularExpression) != nil
    }
}
