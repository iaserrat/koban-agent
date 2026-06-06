import Foundation

/// The app's marketing version, read from the bundle's Info.plist. Surfaced on the home dashboard
/// beside the "Check for Updates" control. `nil` when the bundle carries no version string (e.g. a
/// unit-test host), so the view can simply omit it rather than print a placeholder.
enum AppVersion {
    static var current: String? {
        Bundle.main.object(forInfoDictionaryKey: BundleKeys.shortVersionString) as? String
    }
}
