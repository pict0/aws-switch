import Foundation
import Testing
@testable import AWSSwitchCore

@Suite struct SSOSessionStatusTests {
    @Test func readsOnlyExpiryAndKeepsLatestPerStartURL() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        try Data(#"{"startUrl":"https://x/start","expiresAt":"2026-01-01T00:00:00Z","accessToken":"secret"}"#.utf8)
            .write(to: dir.appendingPathComponent("a.json"))
        try Data(#"{"startUrl":"https://x/start/","expiresAt":"2026-06-01T00:00:00UTC"}"#.utf8)
            .write(to: dir.appendingPathComponent("b.json"))
        try Data(#"{"clientId":"c","expiresAt":"2026-01-01T00:00:00Z"}"#.utf8) // client registration, no startUrl
            .write(to: dir.appendingPathComponent("c.json"))

        let expiries = SSOSessionStatus.expiries(in: dir)
        #expect(expiries.count == 1)
        #expect(expiries["https://x/start"] == SSOSessionStatus.parseDate("2026-06-01T00:00:00Z"))
    }
}
