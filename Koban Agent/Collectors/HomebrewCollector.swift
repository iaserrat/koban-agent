import Foundation

/// Builds the Homebrew inventory by reading the Cellar (formulae) and Caskroom (casks) under
/// each prefix, plus Homebrew's `INSTALL_RECEIPT.json` files for provenance. Pure filesystem
/// reads - `/opt/homebrew` is world-readable, so no entitlement or Full Disk Access is needed.
struct HomebrewCollector: SurfaceCollector {
    let surface = MonitoredSurface.homebrew
    let prefixes: [URL]
    let receiptValidator: HomebrewReceiptFileValidator

    init(
        prefixes: [URL],
        receiptValidator: HomebrewReceiptFileValidator = HomebrewReceiptFileValidator()
    ) {
        self.prefixes = prefixes
        self.receiptValidator = receiptValidator
    }

    var watchPaths: [String] {
        prefixes.flatMap { [cellar(in: $0).path, caskroom(in: $0).path] }
    }

    func snapshot() async throws -> [InventoryItem] {
        try await collect().items
    }

    func collect() async throws -> CollectorSnapshot {
        try prefixes.reduce(into: CollectorSnapshot(items: [])) { result, prefix in
            let formulae = try collect(in: cellar(in: prefix), using: formulaItem)
            let casks = try collect(in: caskroom(in: prefix), using: caskItem)
            result.items.append(contentsOf: formulae.items + casks.items)
            result.issues.append(contentsOf: formulae.issues + casks.issues)
        }
    }

    private func cellar(in prefix: URL) -> URL {
        prefix.appending(component: KnownPaths.homebrewCellarComponent, directoryHint: .isDirectory)
    }

    private func caskroom(in prefix: URL) -> URL {
        prefix.appending(component: KnownPaths.homebrewCaskroomComponent, directoryHint: .isDirectory)
    }

    /// Maps each immediate subdirectory (one per installed name) through `transform`.
    private func collect(
        in root: URL,
        using transform: (URL) throws -> (item: InventoryItem?, issues: [CollectorIssue])
    ) throws -> (items: [InventoryItem], issues: [CollectorIssue]) {
        let listing = try FileSystem.subdirectoryListing(of: root)
        return try listing.subdirectories.reduce(
            into: (items: [InventoryItem](), issues: listing.issues)
        ) { result, url in
            let transformed = try transform(url)
            if let item = transformed.item {
                result.items.append(item)
            }
            result.issues.append(contentsOf: transformed.issues)
        }
    }

    private func formulaItem(rack: URL) throws -> (item: InventoryItem?, issues: [CollectorIssue]) {
        let listing = try FileSystem.subdirectoryListing(of: rack)
        let kegs = listing.subdirectories
        guard kegs.isEmpty == false else { return (nil, listing.issues) }
        let receiptResult = try kegs.last.map {
            try InstallReceipt.read(inKeg: $0, validator: receiptValidator)
        }
        let receipt = receiptResult?.receipt
        let tap = receipt?.source?.tap ?? HomebrewLabels.unknownTap
        let item = InventoryItem(
            surface: surface,
            name: rack.lastPathComponent,
            version: versionString(from: kegs),
            path: rack.path,
            provenance: Provenance(origin: tap, installedOnRequest: receipt?.installedOnRequest)
        )
        return (item, listing.issues + [receiptResult?.issue].compactMap(\.self))
    }

    private func caskItem(nameDir: URL) throws -> (item: InventoryItem?, issues: [CollectorIssue]) {
        let listing = try FileSystem.subdirectoryListing(of: nameDir)
        let versions = listing.subdirectories
        guard versions.isEmpty == false else { return (nil, listing.issues) }
        let receiptResult = try InstallReceipt.read(
            inCaskMetadata: nameDir,
            validator: receiptValidator
        )
        let receipt = receiptResult.receipt
        let tap = receipt?.source?.tap ?? HomebrewLabels.unknownTap
        let item = InventoryItem(
            surface: surface,
            name: nameDir.lastPathComponent,
            version: versionString(from: versions),
            path: nameDir.path,
            provenance: Provenance(origin: tap, installedOnRequest: receipt?.installedOnRequest)
        )
        return (item, listing.issues + [receiptResult.issue].compactMap(\.self))
    }

    private func versionString(from directories: [URL]) -> String {
        directories.map(\.lastPathComponent).sorted().joined(separator: HomebrewLabels.versionSeparator)
    }
}
