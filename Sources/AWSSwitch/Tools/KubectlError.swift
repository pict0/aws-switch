import Foundation

enum KubectlError: LocalizedError {
    case notFound
    case failed(String, Int32)

    var errorDescription: String? {
        switch self {
        case .notFound: "kubectl not found"
        case let .failed(command, status): "kubectl \(command) failed (exit \(status))"
        }
    }
}
