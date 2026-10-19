import Foundation
import Testing
@testable import AWSSwitchCore

@Suite struct KubeConfigTests {
    static let json = Data("""
        {"contexts":[
          {"name":"production","context":{"cluster":"arn:aws:eks:eu-west-2:222222222222:cluster/prod-eks","user":"u"}},
          {"name":"preprod","context":{"cluster":"arn:aws:eks:eu-west-2:111111111111:cluster/pre-eks"}},
          {"name":"microk8s","context":{"cluster":"microk8s-cluster"}},
          {"name":"a","context":{"cluster":"arn:aws:eks:eu-west-2:333333333333:cluster/one"}},
          {"name":"b","context":{"cluster":"arn:aws:eks:eu-west-2:333333333333:cluster/two"}}
        ],"current-context":"preprod","users":[{"name":"u","user":{"token":"REDACTED"}}]}
        """.utf8)

    static func profile(_ name: String, _ account: String?) -> AWSProfile {
        AWSProfile(name: name, accountId: account, roleName: nil, region: nil, ssoStartURL: nil)
    }

    @Test func parsesContextsAndCurrent() throws {
        let snapshot = try KubeConfigParser.parse(Self.json)
        #expect(snapshot.current == "preprod")
        #expect(snapshot.contexts.map(\.name) == ["a", "b", "microk8s", "preprod", "production"])
        #expect(snapshot.contexts.first { $0.name == "production" }?.awsAccountId == "222222222222")
        #expect(snapshot.contexts.first { $0.name == "microk8s" }?.awsAccountId == nil)
    }

    @Test func mapsProfileToItsSingleEKSContext() throws {
        let snapshot = try KubeConfigParser.parse(Self.json)
        #expect(snapshot.context(for: Self.profile("acme-production", "222222222222"))?.name == "production")
        #expect(snapshot.context(for: Self.profile("data-dev", "999999999999")) == nil) // no cluster
        #expect(snapshot.context(for: Self.profile("multi", "333333333333")) == nil)    // ambiguous
        #expect(snapshot.context(for: Self.profile("legacy", nil)) == nil)
    }

    @Test func mapsContextBackToProfile() throws {
        let snapshot = try KubeConfigParser.parse(Self.json)
        let profiles = [Self.profile("acme-pre-production", "111111111111")]
        let preprod = try #require(snapshot.contexts.first { $0.name == "preprod" })
        #expect(snapshot.profile(for: preprod, in: profiles)?.name == "acme-pre-production")
    }

    @Test(arguments: ["", "arn:aws:eks:eu-west-2:123:cluster/x", "arn:aws:iam::222222222222:role/x",
                      "arn:aws:eks:eu-west-2:222222222222:nodegroup/x"])
    func rejectsNonEKSClusterARNs(_ cluster: String) {
        #expect(KubeContext(name: "x", cluster: cluster).awsAccountId == nil)
    }
}
