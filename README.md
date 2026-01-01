# OrcidSwift <img width="60" height="60" alt="orcid_swift" src="https://github.com/user-attachments/assets/c209c86d-7106-4d9c-a18d-4e5fd0c51a34" />

A lightweight async Swift client for the public [ORCID API](https://info.orcid.org/what-is-orcid/services/public-api/), plus small helper types for OAuth URL construction and token exchange.

## Requirements

- SwiftPM
- Xcode 16.4+

## Installation

Add to your `Package.swift`:

```swift
.package(url: "https://github.com/ezefranca/OrcidSwift.git", from: "1.0.0"),
```

Then add `OrcidSwift` as a dependency of your target.

## Usage

### Fetch a public record

```swift
import OrcidSwift

let client = OrcidClient()
let record = try await client.fetchRecord(orcid: try OrcidID("0000-0002-1825-0097"))
print(record.orcidIdentifier?.uri ?? "")
```

### Fetch works

```swift
import OrcidSwift

let client = OrcidClient()
let works = try await client.fetchWorks(orcid: try OrcidID("0000-0002-1825-0097"))
print(works.group?.count ?? 0)
```

### Build an OAuth authorize URL

```swift
import OrcidSwift

let client = OrcidClient(config: .init(environment: .production))
let url = try client.makeAuthorizeURL(
  clientID: "YOUR_CLIENT_ID",
  redirectURI: "yourapp://callback",
  scopes: [.authenticate],
  state: "csrf-state"
)
print(url)
```

### Exchange code for token

```swift
import OrcidSwift

let client = OrcidClient(config: .init(environment: .production))
let token = try await client.exchangeCodeForToken(
  clientID: "YOUR_CLIENT_ID",
  clientSecret: "YOUR_CLIENT_SECRET",
  code: "AUTH_CODE",
  redirectURI: "yourapp://callback"
)
print(token.accessToken)
```

## Tests

### Unit tests

```sh
swift test
```

### Integration tests (real internet)

Integration tests are present but skipped unless explicitly enabled:

```sh
ORCIDSWIFT_RUN_INTEGRATION_TESTS=1 swift test
```

## License

MIT License. See [LICENSE](LICENSE) for details.
