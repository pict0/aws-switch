import Foundation

/// The contexts in kubeconfig and which one is current.
public struct KubeConfigSnapshot: Equatable, Sendable {
    public let contexts: [KubeContext]
    public let current: String?

    public init(contexts: [KubeContext], current: String?) {
        self.contexts = contexts
        self.current = current
    }

    public static let empty = KubeConfigSnapshot(contexts: [], current: nil)

    /// The single EKS context in the profile's account. Nil when there are none or
    /// several, since picking one of several would be a guess.
    public func context(for profile: AWSProfile) -> KubeContext? {
        guard let account = profile.accountId else { return nil }
        let matches = contexts.filter { $0.awsAccountId == account }
        return matches.count == 1 ? matches[0] : nil
    }

    /// The AWS profile whose account owns this context's EKS cluster, if exactly one does.
    public func profile(for context: KubeContext, in profiles: [AWSProfile]) -> AWSProfile? {
        guard let account = context.awsAccountId else { return nil }
        let matches = profiles.filter { $0.accountId == account }
        return matches.count == 1 ? matches[0] : nil
    }
}
