import Darwin
import Foundation
import os

// MARK: - FileDescriptorLimit

/// Raises the process open-file limit at launch. A GUI-launched macOS app inherits a soft
/// `RLIMIT_NOFILE` of 256, which a single FSEvents stream over many watched roots plus the
/// SQLite pool can exhaust (the watcher then fails to open paths and the database fails to
/// open). Raising the soft limit to the kernel's per-process ceiling removes that contention.
enum FileDescriptorLimit {
    /// The "no limit" sentinel for a resource limit, mirroring the C `RLIM_INFINITY` macro
    /// (`(((__uint64_t)1 << 63) - 1)`), which Swift cannot import because it is a cast macro.
    /// A hard limit equal to this means the only real ceiling is the kernel per-process maximum.
    static let noLimit: rlim_t = (rlim_t(1) << 63) - 1
    /// The soft `RLIMIT_NOFILE` value Koban should request, or `nil` when the current soft
    /// limit already meets the ceiling so no `setrlimit` call is needed. The ceiling is the
    /// hard limit clamped to the kernel maximum (an unlimited hard limit cannot actually be
    /// set, so it resolves to the kernel maximum). The soft limit is only ever raised, never
    /// lowered.
    static func raisedSoftLimit(soft: rlim_t, hard: rlim_t, systemMaximum: rlim_t) -> rlim_t? {
        let ceiling = hard == noLimit ? systemMaximum : min(hard, systemMaximum)
        return soft < ceiling ? ceiling : nil
    }

    /// Reads the current limits, computes the target, and applies it. Failures are logged and
    /// otherwise ignored: an unraised limit degrades coverage but must never wedge launch.
    static func raiseSoftLimitToSystemMaximum() {
        var limits = rlimit()
        guard getrlimit(RLIMIT_NOFILE, &limits) == 0 else {
            Log.app.error("getrlimit(RLIMIT_NOFILE) failed: \(errnoDescription, privacy: .public)")
            return
        }
        guard let target = raisedSoftLimit(
            soft: limits.rlim_cur,
            hard: limits.rlim_max,
            systemMaximum: systemFileDescriptorMaximum()
        ) else { return }

        limits.rlim_cur = target
        guard setrlimit(RLIMIT_NOFILE, &limits) == 0 else {
            Log.app.error("setrlimit(RLIMIT_NOFILE, \(target)) failed: \(errnoDescription, privacy: .public)")
            return
        }
        Log.app.info("Raised open-file limit to \(target).")
    }

    /// The kernel per-process open-file ceiling, falling back to the POSIX `OPEN_MAX` when the
    /// `sysctl` lookup is unavailable.
    private static func systemFileDescriptorMaximum() -> rlim_t {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname(ProcessLimitNames.maxFilesPerProcessKey, &value, &size, nil, 0) == 0,
              value > 0
        else { return rlim_t(OPEN_MAX) }
        return rlim_t(value)
    }

    private static var errnoDescription: String {
        String(cString: strerror(errno))
    }
}
