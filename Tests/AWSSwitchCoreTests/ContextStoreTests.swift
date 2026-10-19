import Foundation
import Testing
@testable import AWSSwitchCore

@Suite struct ContextStoreTests {
    @Test func roundTripsAndRestrictsPermissions() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let store = ContextStore(fileURL: url)

        #expect(store.read() == nil)
        try store.write("shared-services")
        #expect(store.read() == "shared-services")

        let perms = try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int
        #expect(perms == 0o600)
    }

    @Test(arguments: ["", "a b", "x;rm -rf ~", "$(whoami)", "a\nb", "`id`"])
    func rejectsUnsafeNames(_ name: String) {
        #expect(!ContextStore.isValidProfileName(name))
    }

    @Test func ignoresNonRegularFiles() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(mkfifo(url.path, 0o600) == 0)
        #expect(ContextStore(fileURL: url).read() == nil) // would block forever without the check
    }

    @Test func ignoresTamperedFileContents() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("$(curl evil)".utf8).write(to: url)
        #expect(ContextStore(fileURL: url).read() == nil)
    }
}
