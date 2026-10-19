import Foundation
import Testing
@testable import AWSSwitchCore

@Suite struct EnvironmentTierTests {
    @Test(arguments: [
        ("data-platform-prod", EnvironmentTier.production),
        ("acme-production", .production),
        ("finance-prod", .production),
        ("acme-pre-production", .preProduction),
        ("data-platform-staging", .preProduction),
        ("data-platform-dev", .preProduction),
        ("payments-api-test", .preProduction),
        ("sandbox", .preProduction),
        ("product-catalogue", .shared), // "product" is not the token "prod"
        ("transit", .shared),
        ("example-group-ltd", .shared),
    ])
    func classifiesByWholeTokens(_ name: String, _ tier: EnvironmentTier) {
        #expect(EnvironmentTier.classify(name) == tier)
    }
}
