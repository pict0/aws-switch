// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AWSSwitch",
    platforms: [.macOS(.v14)],
    targets: [
        // Pure logic: config parsing, context file, SSO expiry. No AppKit, fully testable.
        .target(name: "AWSSwitchCore"),
        // Menu bar UI.
        .executableTarget(name: "AWSSwitch", dependencies: ["AWSSwitchCore"]),
        .testTarget(name: "AWSSwitchCoreTests", dependencies: ["AWSSwitchCore"]),
    ]
)
