import Foundation

/// How risky a profile is, inferred from hyphen/underscore/dot-separated name tokens.
/// Drives the menu grouping and symbols and whether a switch needs confirmation.
public enum EnvironmentTier: Int, CaseIterable, Sendable, Comparable {
    case production, preProduction, shared

    public var title: String {
        switch self {
        case .production: "Production"
        case .preProduction: "Pre-production"
        case .shared: "Shared"
        }
    }

    public var requiresConfirmation: Bool { self == .production }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Everything below production that isn't shared tooling: staging, test and dev alike.
    static let preProductionTokens: Set = ["staging", "stage", "stg", "uat", "preprod",
                                           "dev", "development", "test", "qa", "sandbox", "sbx"]
    static let productionTokens: Set = ["prod", "production", "prd"]

    public static func classify(_ profileName: String) -> EnvironmentTier {
        let tokens = profileName.lowercased()
            .split(whereSeparator: { "-_.".contains($0) })
            .map(String.init)

        for (index, token) in tokens.enumerated() {
            // "pre-production" / "pre-prod" is two tokens; the "pre" demotes it.
            if productionTokens.contains(token) {
                return index > 0 && tokens[index - 1] == "pre" ? .preProduction : .production
            }
        }
        if tokens.contains(where: preProductionTokens.contains) { return .preProduction }
        return .shared
    }
}
