import Foundation

/// Locations of the AWS CLI files the app reads and writes.
public enum AWSPaths {
    public static var awsDir: URL {
        URL.homeDirectory.appending(path: ".aws")
    }
    public static var configFile: URL {
        if let override = ProcessInfo.processInfo.environment["AWS_CONFIG_FILE"] {
            return URL(filePath: (override as NSString).expandingTildeInPath)
        }
        return awsDir.appending(path: "config")
    }
    public static var contextFile: URL { awsDir.appending(path: "current-context") }
    public static var ssoCacheDir: URL { awsDir.appending(path: "sso/cache") }
}
