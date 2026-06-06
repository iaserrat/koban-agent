import Foundation

/// XCTest host-process markers. The app uses this only to keep unit tests from starting the
/// live agent side effects when Xcode launches the app as a test host.
enum TestEnvironment {
    static let configurationFileVariable = "XCTestConfigurationFilePath"

    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment[configurationFileVariable] != nil
    }
}
