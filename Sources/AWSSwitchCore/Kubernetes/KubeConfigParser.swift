import Foundation

/// Parses `kubectl config view -o json` (which redacts credential data by default).
public enum KubeConfigParser {
    private struct Root: Decodable {
        let contexts: [Entry]?
        let currentContext: String?

        enum CodingKeys: String, CodingKey {
            case contexts
            case currentContext = "current-context"
        }
    }

    private struct Entry: Decodable {
        let name: String
        let context: Detail?
    }

    private struct Detail: Decodable {
        let cluster: String?
    }

    public static func parse(_ json: Data) throws -> KubeConfigSnapshot {
        let root = try JSONDecoder().decode(Root.self, from: json)
        let contexts = (root.contexts ?? [])
            .map { KubeContext(name: $0.name, cluster: $0.context?.cluster ?? "") }
            .sorted { $0.name < $1.name }
        let current = root.currentContext.flatMap { $0.isEmpty ? nil : $0 }
        return KubeConfigSnapshot(contexts: contexts, current: current)
    }
}
