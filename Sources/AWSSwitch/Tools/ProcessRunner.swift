import Foundation

/// Runs a command without a shell and without blocking a thread: output is read as async
/// bytes and the exit status arrives through the termination handler.
enum ProcessRunner {
    struct Result: Sendable {
        let status: Int32
        let output: Data
    }

    static func run(_ executable: URL, _ arguments: [String], captureOutput: Bool = false) async throws -> Result {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.standardError = FileHandle.nullDevice

        let output = Pipe()
        process.standardOutput = captureOutput ? output : FileHandle.nullDevice

        // Installed before run() so an instant exit can't be missed.
        let (exits, exited) = AsyncStream.makeStream(of: Int32.self)
        process.terminationHandler = { process in
            exited.yield(process.terminationStatus)
            exited.finish()
        }
        try process.run()

        var data = Data()
        if captureOutput {
            // Draining until EOF also stops a full pipe buffer from stalling the child.
            for try await byte in output.fileHandleForReading.bytes {
                data.append(byte)
            }
        }

        var status: Int32 = -1
        for await code in exits { status = code }
        return Result(status: status, output: data)
    }
}
