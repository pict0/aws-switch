import Foundation
import Testing
@testable import AWSSwitchCore

@Suite struct DatabricksConfigTests {
    static let sample = """
        [DEFAULT]
        host = https://dbc-default.cloud.databricks.com
        token = dapi-SECRET-1

        # a comment
        [production]
        host = https://dbc-prod.cloud.databricks.com
        client_id = abc
        client_secret = SECRET-2

        [development]
        token = dapi-SECRET-3

        [bad name;rm -rf ~]
        host = https://evil.example.com

        [$(whoami)]
        host = https://evil.example.com
        """

    @Test func readsSectionNamesAndHostsOnly() {
        let profiles = DatabricksConfigParser.parse(Self.sample)
        #expect(profiles.map(\.name) == ["DEFAULT", "development", "production"])
        #expect(profiles.map(\.host) == ["https://dbc-default.cloud.databricks.com", nil,
                                         "https://dbc-prod.cloud.databricks.com"])
    }

    @Test func neverCarriesCredentials() {
        let dump = String(describing: DatabricksConfigParser.parse(Self.sample))
        #expect(!dump.contains("SECRET"))
    }

    @Test func dropsNamesFailingTheAllowList() {
        let names = DatabricksConfigParser.parse(Self.sample).map(\.name)
        #expect(names.allSatisfy(ContextStore.isValidProfileName))
    }

    @Test func ignoresKeysBeforeAnySection() {
        #expect(DatabricksConfigParser.parse("host = https://x\n").isEmpty)
    }

    @Test(arguments: [
        ("production", EnvironmentTier.production),
        ("prod-eu", .production),
        ("DEFAULT", .shared),
        ("development", .preProduction),
        ("staging", .preProduction),
        ("pre-production", .preProduction),
    ])
    func infersTier(_ name: String, _ tier: EnvironmentTier) {
        #expect(EnvironmentTier.classify(name) == tier)
    }

    @Test func contextFileRoundTripsDatabricksNames() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let store = ContextStore(fileURL: url)
        try store.write("DEFAULT")
        #expect(store.read() == "DEFAULT")
        #expect(throws: ContextError.self) { try store.write("a b") }
    }
}
