import AWSSwitchCore
import Foundation

/// Thin wrapper over the kubectl binary. Switching goes through `kubectl config use-context`
/// so the app never edits kubeconfig YAML itself.
enum Kubectl {
    /// GUI apps don't inherit the shell PATH, so look in the usual install locations.
    static let path: URL? = ["/opt/homebrew/bin/kubectl", "/usr/local/bin/kubectl", "/usr/bin/kubectl"]
        .first { FileManager.default.isExecutableFile(atPath: $0) }
        .map { URL(filePath: $0) }

    static var configFile: URL {
        URL.homeDirectory.appending(path: ".kube/config")
    }

    static var configModified: Date? {
        try? configFile.resolvingSymlinksInPath()
            .resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    /// `kubectl config view` redacts certificate and token data unless `--raw` is passed.
    static func snapshot() async throws -> KubeConfigSnapshot {
        try KubeConfigParser.parse(try await run(["config", "view", "-o", "json"]))
    }

    static func useContext(_ name: String) async throws {
        _ = try await run(["config", "use-context", name])
    }

    private static func run(_ arguments: [String]) async throws -> Data {
        guard let path else { throw KubectlError.notFound }
        let result = try await ProcessRunner.run(path, arguments, captureOutput: true)
        guard result.status == 0 else {
            throw KubectlError.failed(arguments.joined(separator: " "), result.status)
        }
        return result.output
    }
}
