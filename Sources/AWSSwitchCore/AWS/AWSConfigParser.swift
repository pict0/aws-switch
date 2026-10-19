import Foundation

/// Minimal INI parser for the AWS shared config file.
public enum AWSConfigParser {
    public static func parse(_ text: String) -> [AWSProfile] {
        var sections: [(header: String, values: [String: String])] = []

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix(";") { continue }

            if line.hasPrefix("["), line.hasSuffix("]") {
                let header = String(line.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
                sections.append((header, [:]))
                continue
            }

            guard !sections.isEmpty, let eq = line.firstIndex(of: "=") else { continue }
            let key = line[..<eq].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: eq)...].trimmingCharacters(in: .whitespaces)
            sections[sections.count - 1].values[key] = value
        }

        var ssoSessions: [String: [String: String]] = [:]
        for section in sections {
            if let name = sectionName(section.header, prefix: "sso-session") {
                ssoSessions[name] = section.values
            }
        }

        return sections.compactMap { section in
            let name: String
            if section.header == "default" {
                name = "default"
            } else if let profileName = sectionName(section.header, prefix: "profile") {
                name = profileName
            } else {
                return nil
            }

            let v = section.values
            let startURL = v["sso_start_url"] ?? v["sso_session"].flatMap { ssoSessions[$0]?["sso_start_url"] }
            return AWSProfile(
                name: name,
                accountId: v["sso_account_id"],
                roleName: v["sso_role_name"],
                region: v["region"],
                ssoStartURL: startURL
            )
        }
        .filter { $0.name != "default" || $0.ssoStartURL != nil } // skip an empty [default]
        .sorted { $0.name < $1.name }
    }

    private static func sectionName(_ header: String, prefix: String) -> String? {
        guard header.hasPrefix(prefix + " ") else { return nil }
        let name = header.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }
}
