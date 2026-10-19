import Foundation

/// Reports SSO session expiry by start URL.
///
/// Security: this decodes *only* `startUrl` and `expiresAt`. Tokens and client secrets in the
/// cache files are never mapped into a Swift value, stored, logged or sent anywhere.
public enum SSOSessionStatus {
    private struct CacheEntry: Decodable {
        let startUrl: String
        let expiresAt: String
    }

    /// Latest expiry per start URL found in the cache directory.
    public static func expiries(in directory: URL = AWSPaths.ssoCacheDir) -> [String: Date] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil)) ?? []

        var result: [String: Date] = [:]
        for file in files where file.pathExtension == "json" {
            guard let data = SafeFile.read(file),
                  let entry = try? JSONDecoder().decode(CacheEntry.self, from: data),
                  let expiry = parseDate(entry.expiresAt)
            else { continue }
            let key = normalise(entry.startUrl)
            if let existing = result[key], existing >= expiry { continue }
            result[key] = expiry
        }
        return result
    }

    public static func expiry(for profile: AWSProfile, in expiries: [String: Date]) -> Date? {
        profile.ssoStartURL.flatMap { expiries[normalise($0)] }
    }

    static func parseDate(_ text: String) -> Date? {
        // The CLI writes "…Z", sometimes with fractional seconds, and sometimes "…UTC".
        let normalised = text.hasSuffix("UTC") ? text.replacing("UTC", with: "Z") : text
        return (try? Date(normalised, strategy: .iso8601))
            ?? (try? Date(normalised, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
    }

    static func normalise(_ url: String) -> String {
        url.hasSuffix("/") ? String(url.dropLast()) : url
    }
}
