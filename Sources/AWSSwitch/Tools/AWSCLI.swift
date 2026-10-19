import Foundation

/// Locates the AWS CLI binary.
enum AWSCLI {
    /// GUI apps don't inherit the shell PATH, so look in the usual install locations.
    static let path: URL? = ["/opt/homebrew/bin/aws", "/usr/local/bin/aws", "/usr/bin/aws"]
        .first { FileManager.default.isExecutableFile(atPath: $0) }
        .map { URL(filePath: $0) }
}
