import Foundation

struct EnrollmentStateStore {
    private let fileURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let fileManager: FileManager

    init(
        fileURL: URL = Self.defaultFileURL(),
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.decoder = decoder
        self.encoder = encoder
        self.fileManager = fileManager
    }

    func load() throws -> EnrollmentState? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(EnrollmentState.self, from: data)
    }

    func save(_ state: EnrollmentState) throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(state)
        try data.write(to: fileURL, options: .atomic)
    }

    func delete() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }

    private static func defaultFileURL() -> URL {
        let directory = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return (directory ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appending(component: StorageNames.directory, directoryHint: .isDirectory)
            .appending(component: SensorProtocolConstants.enrollmentStateFileName)
    }
}
