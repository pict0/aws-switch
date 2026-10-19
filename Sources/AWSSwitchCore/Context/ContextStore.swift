import Foundation

/// Reads and writes the shared "current context" file that every shell's precmd hook follows.
public struct ContextStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL = AWSPaths.contextFile) {
        self.fileURL = fileURL
    }

    private static let allowedCharacters = CharacterSet(charactersIn:
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")

    /// Profile names are restricted to this set so the file can never carry anything
    /// a shell might interpret. The zsh hook enforces the same rule.
    public static func isValidProfileName(_ name: String) -> Bool {
        !name.isEmpty && name.count <= 128
            && name.unicodeScalars.allSatisfy { Self.allowedCharacters.contains($0) }
    }

    public func read() -> String? {
        guard let text = SafeFile.readString(fileURL) else { return nil }
        let name = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return Self.isValidProfileName(name) ? name : nil
    }

    public func write(_ profile: String) throws {
        guard Self.isValidProfileName(profile) else { throw ContextError.invalidProfileName(profile) }
        // Atomic write: readers see the old or new value, never a partial file.
        try Data((profile + "\n").utf8).write(to: fileURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
}
