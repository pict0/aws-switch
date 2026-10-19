import Foundation

/// A profile from `~/.aws/config`. Only the fields the app needs.
public struct AWSProfile: Hashable, Sendable, Identifiable {
    public let name: String
    public let accountId: String?
    public let roleName: String?
    public let region: String?
    /// Resolved SSO start URL — either inline (`sso_start_url`) or via an `[sso-session]` block.
    public let ssoStartURL: String?

    public var id: String { name }
}
