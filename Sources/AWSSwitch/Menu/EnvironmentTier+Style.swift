import AppKit
import AWSSwitchCore

/// How each tier is shown. Tiers are told apart by shape; colour is reserved for production,
/// so red always means "this is prod" rather than decoration.
extension EnvironmentTier {
    /// Fill rises with risk: empty for shared, half for pre-production.
    var symbol: String {
        switch self {
        case .production: "exclamationmark.triangle.fill"
        case .preProduction: "circle.bottomhalf.filled"
        case .shared: "circle"
        }
    }

    var isProduction: Bool { self == .production }
}
