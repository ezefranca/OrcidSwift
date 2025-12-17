import XCTest
@testable import OrcidSwift

final class OrcidSwiftTests: XCTestCase {

    func testOrcidIDNormalization() throws {
        let a = try OrcidID("0000-0002-1825-0097")
        XCTAssertEqual(a.value, "0000-0002-1825-0097")

        let b = try OrcidID("https://orcid.org/0000-0002-1825-0097")
        XCTAssertEqual(b.value, "0000-0002-1825-0097")
    }

    func testOrcidIDInvalid() {
        XCTAssertThrowsError(try OrcidID("not-an-orcid"))
    }

    func testDecodeRecordFixture() throws {
        let data = try loadFixture("record.json")
        let record = try JSONDecoder().decode(OrcidRecord.self, from: data)
        XCTAssertEqual(record.orcidIdentifier?.path, "0000-0002-1825-0097")
        XCTAssertEqual(record.person?.name?.givenNames?.value, "Test")
    }

    func testDecodeWorksFixture() throws {
        let data = try loadFixture("works.json")
        let works = try JSONDecoder().decode(OrcidWorksResponse.self, from: data)
        XCTAssertEqual(works.group?.count, 1)
        XCTAssertEqual(works.group?.first?.workSummary?.first?.title?.title?.value, "Example Work")
    }

    func testHTTPBodyStringNil() {
        let data = Data([0xFF, 0xFE, 0xFD])
        XCTAssertNil(HTTP.bodyString(data))
    }

    func testMakeAuthorizeURL() throws {
        let url = try OrcidClient().makeAuthorizeURL(
            clientID: "client",
            redirectURI: "myapp://callback",
            scopes: [.authenticate, .readLimited],
            state: "state",
            showLogin: true,
            prompt: "login"
        )
        let comps = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = comps.queryItems ?? []
        func value(_ name: String) -> String? { items.first(where: { $0.name == name })?.value }

        XCTAssertEqual(value("client_id"), "client")
        XCTAssertEqual(value("response_type"), "code")
        XCTAssertEqual(value("redirect_uri"), "myapp://callback")
        XCTAssertEqual(value("state"), "state")
        XCTAssertEqual(value("show_login"), "true")
        XCTAssertEqual(value("prompt"), "login")
        XCTAssertEqual(value("scope"), "/authenticate /read-limited")
    }

    private func loadFixture(_ name: String) throws -> Data {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: nil))
        return try Data(contentsOf: url)
    }
}
