import Foundation

/// A kubectl context. Only names are read; credentials never leave kubectl.
public struct KubeContext: Hashable, Sendable, Identifiable {
    public let name: String
    public let cluster: String

    public var id: String { name }

    public init(name: String, cluster: String) {
        self.name = name
        self.cluster = cluster
    }

    /// The AWS account ID when the cluster is an EKS ARN
    /// (`arn:aws:eks:<region>:<account>:cluster/<name>`), otherwise nil.
    public var awsAccountId: String? {
        let parts = cluster.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 6, parts[0] == "arn", parts[2] == "eks",
              parts[5].hasPrefix("cluster/"), parts[4].count == 12, parts[4].allSatisfy(\.isNumber)
        else { return nil }
        return String(parts[4])
    }
}
