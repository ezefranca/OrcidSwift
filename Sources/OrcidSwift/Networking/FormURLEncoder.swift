import Foundation

/// Encodes a dictionary as `application/x-www-form-urlencoded`.
enum FormURLEncoder {
    /// Encodes items as UTF-8 bytes.
    static func encode(_ items: [String: String]) -> Data {
        // Stable output for tests/logging
        let parts = items
            .map { (k, v) in "\(escape(k))=\(escape(v))" }
            .sorted()
            .joined(separator: "&")
        return Data(parts.utf8)
    }

    private static func escape(_ string: String) -> String {
        // RFC 3986-ish for form bodies; spaces become '+'.
        // Allowed: ALPHA / DIGIT / "-" / "." / "_" / "*"
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._*"))
        let encoded = string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
        return encoded.replacingOccurrences(of: "%20", with: "+")
    }
}
