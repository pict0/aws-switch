import Foundation

/// Reads small files defensively. Refuses anything that isn't a regular file (a FIFO would
/// block the main thread forever) or is implausibly large for an AWS config or cache file.
public enum SafeFile {
    public static let maxBytes = 1_048_576

    public static func read(_ url: URL) -> Data? {
        let resolved = url.resolvingSymlinksInPath()
        guard let values = try? resolved.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
              values.isRegularFile == true,
              (values.fileSize ?? 0) <= maxBytes
        else { return nil }
        return try? Data(contentsOf: resolved)
    }

    public static func readString(_ url: URL) -> String? {
        read(url).flatMap { String(data: $0, encoding: .utf8) }
    }
}
