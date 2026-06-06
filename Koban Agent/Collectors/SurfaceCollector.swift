import Foundation

// MARK: - SurfaceCollector

/// Produces a fresh inventory snapshot for one surface by reading the relevant on-disk state.
/// Collectors are the only place that performs surface-specific IO; everything downstream
/// (diffing, heuristics) works on the `InventoryItem`s they return.
protocol SurfaceCollector: Sendable {
    var surface: MonitoredSurface { get }

    /// The directory trees whose changes should trigger a rescan of this surface.
    var watchPaths: [String] { get }

    /// Reads the current state of the surface. Throws only on unexpected IO/parse failure;
    /// an absent surface (e.g. Homebrew not installed) yields an empty snapshot, not an error.
    func snapshot() async throws -> [InventoryItem]

    /// Reads current state plus partial collection issues that do not invalidate all inventory.
    func collect() async throws -> CollectorSnapshot
}

extension SurfaceCollector {
    func collect() async throws -> CollectorSnapshot {
        try await CollectorSnapshot(items: snapshot())
    }
}
