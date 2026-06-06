import Foundation

// MARK: - ProcessLimitNames

/// Named identifiers for the process resource limits Koban adjusts at launch.
enum ProcessLimitNames {
    /// `sysctl` key for the kernel's per-process open-file ceiling (`kern.maxfilesperproc`).
    /// Setting a soft `RLIMIT_NOFILE` above this value fails, so it is the upper bound Koban
    /// requests.
    static let maxFilesPerProcessKey = "kern.maxfilesperproc"
}
