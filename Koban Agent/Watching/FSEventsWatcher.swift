import CoreServices
import Foundation
import OSLog

// MARK: - FSEventsWatcher

/// Watches a set of directory trees and invokes `onChange` whenever anything beneath them
/// changes. A thin wrapper over the FSEvents C API - Koban's event source of choice because
/// it needs no entitlement and no Full Disk Access (see CLAUDE.md). It reports only *that*
/// something changed, never *what* or *who*; the engine rescans the surface to find out.
///
/// `@unchecked Sendable` is justified: the only mutable state is `stream`, mutated solely in
/// `start()`/`stop()` (serialised by the owning actor); the C callback reads only the
/// immutable `onChange`.
final class FSEventsWatcher: @unchecked Sendable {
    private let paths: [String]
    private let latency: TimeInterval
    private let onChange: @Sendable ([FSEventsEvent]) -> Void
    private let queue: DispatchQueue
    private var stream: FSEventStreamRef?

    init(paths: [String], latency: TimeInterval, onChange: @escaping @Sendable ([FSEventsEvent]) -> Void) {
        self.paths = paths
        self.latency = latency
        self.onChange = onChange
        queue = DispatchQueue(label: "com.kobanhq.Koban-Agent.fsevents", qos: .utility)
    }

    @discardableResult
    func start() -> Bool {
        // Bound to a local so the logging autoclosures below capture a value, not `self`.
        let watched = paths
        guard stream == nil else { return true }
        guard watched.isEmpty == false else { return false }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: eventContextRetain,
            release: eventContextRelease,
            copyDescription: nil
        )

        // `UseCFTypes` makes FSEvents deliver `eventPaths` as a `CFArrayRef` of `CFStringRef`,
        // which the callback below bridges to `[String]`. Without it FSEvents passes a C
        // `char **`, and reinterpreting that as an `NSArray` crashes (EXC_BAD_ACCESS).
        let flags = UInt32(
            kFSEventStreamCreateFlagFileEvents
                | kFSEventStreamCreateFlagNoDefer
                | kFSEventStreamCreateFlagWatchRoot
                | kFSEventStreamCreateFlagUseCFTypes
        )

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            eventCallback,
            &context,
            watched as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            latency,
            flags
        ) else {
            Log.watching.error("Failed to create FSEventStream for \(watched, privacy: .public)")
            return false
        }

        FSEventStreamSetDispatchQueue(stream, queue)
        guard FSEventStreamStart(stream) else {
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            Log.watching.error("Failed to start FSEventStream for \(watched, privacy: .public)")
            return false
        }
        self.stream = stream
        Log.watching.info("Watching \(watched.count) path(s).")
        return true
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    /// Invoked by the C callback below (same file, hence `fileprivate`).
    fileprivate func forwardChange(_ events: [FSEventsEvent]) {
        onChange(events)
    }
}

/// The C callback. It captures nothing (so it bridges to a C function pointer) and recovers
/// the watcher from the context `info` pointer to forward the change notification.
private let eventCallback: FSEventStreamCallback = { _, info, eventCount, eventPaths, eventFlags, eventIds in
    guard let info else { return }
    let watcher = Unmanaged<FSEventsWatcher>.fromOpaque(info).takeUnretainedValue()
    let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] ?? []
    let events = (0 ..< eventCount).compactMap { index -> FSEventsEvent? in
        guard index < paths.count else { return nil }
        return FSEventsEvent(path: paths[index], flags: eventFlags[index], identifier: eventIds[index])
    }
    watcher.forwardChange(events)
}

private let eventContextRetain: CFAllocatorRetainCallBack = { info in
    guard let info else { return nil }
    return UnsafeRawPointer(Unmanaged<FSEventsWatcher>.fromOpaque(info).retain().toOpaque())
}

private let eventContextRelease: CFAllocatorReleaseCallBack = { info in
    guard let info else { return }
    Unmanaged<FSEventsWatcher>.fromOpaque(info).release()
}
