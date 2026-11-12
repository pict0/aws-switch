import Foundation

/// Minimal INI parser for `~/.databrickscfg`. Keeps section names and `host`; every other
/// key (`token`, `client_secret`, …) is skipped without being stored.
public enum DatabricksConfigParser {
    public static func parse(_ text: String) -> [DatabricksProfile] {
        var names: Set<String> = []
        var hosts: [String: String] = [:]
        var current: String?

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix(";") { continue }

            if line.hasPrefix("["), line.hasSuffix("]") {
                let name = String(line.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
                // Names that fail the allow-list are dropped: they could never be written to the context file.
                current = ContextStore.isValidProfileName(name) ? name : nil
                if let current { names.insert(current) }
                continue
            }

            guard let current, let eq = line.firstIndex(of: "="),
                  line[..<eq].trimmingCharacters(in: .whitespaces) == "host"
            else { continue }
            hosts[current] = line[line.index(after: eq)...].trimmingCharacters(in: .whitespaces)
        }

        return names.map { DatabricksProfile(name: $0, host: hosts[$0]) }
            .sorted { $0.name < $1.name }
    }
}
