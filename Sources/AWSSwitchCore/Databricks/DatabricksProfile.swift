import Foundation

/// A profile from `~/.databrickscfg`. Name and host only: tokens and secrets are never read.
public struct DatabricksProfile: Hashable, Sendable, Identifiable {
    public let name: String
    public let host: String?

    public var id: String { name }

    public init(name: String, host: String?) {
        self.name = name
        self.host = host
    }
}
