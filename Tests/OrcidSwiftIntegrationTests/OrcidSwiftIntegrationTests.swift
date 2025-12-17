import XCTest
@testable import OrcidSwift

final class OrcidSwiftIntegrationTests: XCTestCase {

    // MARK: - Config

    /// Run with: ORCIDSWIFT_RUN_INTEGRATION_TESTS=1 swift test
    private var shouldRun: Bool {
        ProcessInfo.processInfo.environment["ORCIDSWIFT_RUN_INTEGRATION_TESTS"] == "1"
    }

    /// Avoid flaky CI: only run when explicitly enabled.
    override func setUp() {
        super.setUp()
        guard shouldRun else { return }
    }

    // MARK: - Known public profiles (stable-ish)
    private let orcidExample = "0000-0002-1825-0097"
    private let famousProfiles: [String] = [
        "0000-0002-1825-0097"
    ]

    // MARK: - Helpers

    private func makeClient() -> OrcidClient {
        OrcidClient(config: .init(environment: .production, userAgent: "OrcidSwiftIntegrationTests/1.0"))
    }

    private func requireRun() throws {
        try XCTSkipUnless(shouldRun, "Set ORCIDSWIFT_RUN_INTEGRATION_TESTS=1 to run integration tests.")
    }

    private func assertRecordLooksValid(_ record: OrcidRecord, expectedOrcid: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(record.orcidIdentifier?.path, expectedOrcid, file: file, line: line)
        XCTAssertEqual(record.orcidIdentifier?.host?.lowercased(), "orcid.org", file: file, line: line)

        // Minimal sanity checks that should hold for public records
        let given = record.person?.name?.givenNames?.value
        let family = record.person?.name?.familyName?.value
        XCTAssertTrue((given?.isEmpty == false) || (family?.isEmpty == false), "Expected at least one name field", file: file, line: line)
    }

    private func assertWorksLooksValid(_ works: OrcidWorksResponse, file: StaticString = #filePath, line: UInt = #line) {
        // group may be empty (valid). But it must decode.
        XCTAssertNotNil(works.group, file: file, line: line)
    }

    // MARK: - Happy path

    func testFetchRecordForKnownPublicProfile() async throws {
        try requireRun()

        let client = makeClient()
        let id = try OrcidID(orcidExample)

        let record = try await client.fetchRecord(orcid: id)
        assertRecordLooksValid(record, expectedOrcid: orcidExample)
    }

    func testFetchWorksForKnownPublicProfile() async throws {
        try requireRun()

        let client = makeClient()
        let id = try OrcidID(orcidExample)

        let works = try await client.fetchWorks(orcid: id)
        assertWorksLooksValid(works)

        // If works exist, validate shape.
        if let firstGroup = works.group?.first, let firstSummary = firstGroup.workSummary?.first {
            // put-code present for summaries (often)
            // title can be nil depending on record visibility; if present, should not be empty.
            if let title = firstSummary.title?.title?.value {
                XCTAssertFalse(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    func testFetchRecordAcrossMultipleProfiles() async throws {
        try requireRun()

        let client = makeClient()

        for raw in famousProfiles {
            let id = try OrcidID(raw)
            let record = try await client.fetchRecord(orcid: id)
            assertRecordLooksValid(record, expectedOrcid: raw)
        }
    }

    // MARK: - Error scenarios via a raw request (integration-level)

    func testHTTP404RecordNotFound() async throws {
        try requireRun()

        // Valid ORCID format but extremely unlikely to exist.
        let missing = try OrcidID("0000-0000-0000-0000")

        do {
            _ = try await makeClient().fetchRecord(orcid: missing)
            XCTFail("Expected httpError for missing record")
        } catch let err as OrcidError {
            guard case let .httpError(status, body) = err else {
                XCTFail("Unexpected error type: \(err)")
                return
            }
            XCTAssertEqual(status, 404)
            // Body may be HTML, JSON, or empty depending on infra.
            // Just assert it’s either nil or non-empty.
            if let body { XCTAssertFalse(body.isEmpty) }
        }
    }

    func testHTTP404WorksNotFound() async throws {
        try requireRun()

        let missing = try OrcidID("0000-0000-0000-0000")

        do {
            _ = try await makeClient().fetchWorks(orcid: missing)
            XCTFail("Expected httpError for missing works")
        } catch let err as OrcidError {
            guard case let .httpError(status, body) = err else {
                XCTFail("Unexpected error type: \(err)")
                return
            }
            XCTAssertEqual(status, 404)
            if let body { XCTAssertFalse(body.isEmpty) }
        }
    }

    func testHTTP406WhenAcceptHeaderIsMissingOrWrong() async throws {
        try requireRun()

        // This test validates ORCID content negotiation behavior at the HTTP level.
        // We intentionally do NOT use OrcidClient here because it always sets Accept.

        let env = OrcidEnvironment.production
        let url = env.apiBaseURL.appendingPathComponent("\(orcidExample)/record")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("OrcidSwiftIntegrationTests/1.0", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept") // often not acceptable for ORCID v3

        let loader: any HTTPDataLoading = URLSession.shared
        let resp = try await HTTP.perform(req, loader: loader)

        // ORCID typically expects "application/vnd.orcid+json". If it still returns 200, accept it.
        if resp.statusCode == 200 {
            // Still ensure it’s decodable into OrcidRecord.
            _ = try JSONDecoder().decode(OrcidRecord.self, from: resp.data)
        } else {
            XCTAssertTrue([406, 415, 400].contains(resp.statusCode), "Expected content-negotiation related error, got \(resp.statusCode)")
        }
    }

    func testRateLimitHeadersIfPresent() async throws {
        try requireRun()

        // ORCID may include rate limit headers. If present, validate they are parseable ints.
        let env = OrcidEnvironment.production
        let url = env.apiBaseURL.appendingPathComponent("\(orcidExample)/record")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("OrcidSwiftIntegrationTests/1.0", forHTTPHeaderField: "User-Agent")
        req.setValue("application/vnd.orcid+json", forHTTPHeaderField: "Accept")

        let resp = try await HTTP.perform(req, loader: URLSession.shared)
        XCTAssertTrue((200...299).contains(resp.statusCode))

        func headerInt(_ key: String) -> Int? {
            for (k, v) in resp.headers {
                if String(describing: k).lowercased() == key.lowercased() {
                    if let s = v as? String { return Int(s) }
                    if let n = v as? NSNumber { return n.intValue }
                }
            }
            return nil
        }

        // Common patterns seen in APIs; ORCID may or may not include them.
        if let remaining = headerInt("X-Rate-Limit-Remaining") {
            XCTAssertGreaterThanOrEqual(remaining, 0)
        }
        if let limit = headerInt("X-Rate-Limit-Limit") {
            XCTAssertGreaterThan(limit, 0)
        }
        if let reset = headerInt("X-Rate-Limit-Reset") {
            XCTAssertGreaterThan(reset, 0)
        }
    }

    // MARK: - Deeper data checks (non-brittle)

    func testRecordDecodingHasConsistentIdentifier() async throws {
        try requireRun()

        let client = makeClient()
        let id = try OrcidID(orcidExample)

        let record = try await client.fetchRecord(orcid: id)

        // path should match ORCID iD, uri should contain it (if present)
        XCTAssertEqual(record.orcidIdentifier?.path, orcidExample)
        if let uri = record.orcidIdentifier?.uri {
            XCTAssertTrue(uri.contains(orcidExample))
        }
    }

    func testWorksPutCodesAreUniqueWithinResponse() async throws {
        try requireRun()

        let client = makeClient()
        let id = try OrcidID(orcidExample)

        let works = try await client.fetchWorks(orcid: id)
        guard let groups = works.group else {
            XCTFail("Expected group array")
            return
        }

        var seen = Set<Int>()
        for g in groups {
            for s in g.workSummary ?? [] {
                if let pc = s.putCode {
                    XCTAssertFalse(seen.contains(pc), "Duplicate put-code \(pc)")
                    seen.insert(pc)
                }
            }
        }
        // It's okay if empty, but if there are put-codes, the uniqueness check above holds.
    }

    func testWorksTitlesIfPresentAreNotEmpty() async throws {
        try requireRun()

        let client = makeClient()
        let id = try OrcidID(orcidExample)

        let works = try await client.fetchWorks(orcid: id)
        for g in works.group ?? [] {
            for s in g.workSummary ?? [] {
                if let title = s.title?.title?.value {
                    XCTAssertFalse(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
