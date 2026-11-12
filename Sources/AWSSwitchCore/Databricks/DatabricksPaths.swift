import Foundation

/// Locations of the Databricks CLI file the app reads and the context file it writes.
public enum DatabricksPaths {
    /// Honours `DATABRICKS_CONFIG_FILE`, as the Databricks CLI and SDKs do.
    public static var configFile: URL {
        if let override = ProcessInfo.processInfo.environment["DATABRICKS_CONFIG_FILE"] {
            return URL(filePath: (override as NSString).expandingTildeInPath)
        }
        return URL.homeDirectory.appending(path: ".databrickscfg")
    }
    /// Beside the AWS context file, so the app never has to create a directory.
    public static var contextFile: URL { AWSPaths.awsDir.appending(path: "current-databricks-context") }
}
