import Foundation

/// Local, append-only record of switches: ~/Library/Logs/AWSSwitch/switch.log
struct SwitchLog {
    static let url: URL = {
        let dir = URL.homeDirectory.appending(path: "Library/Logs/AWSSwitch")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "switch.log")
    }()

    func record(from old: String?, to new: String, kind: String = "aws") {
        let line = "\(Date.now.formatted(.iso8601)) \(kind): \(old ?? "-") -> \(new)\n"
        let url = Self.url
        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: Data(line.utf8))
        } else {
            try? Data(line.utf8).write(to: url)
        }
    }
}
