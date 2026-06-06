import CryptoKit
import Foundation

/// Computes stable file content hashes for file-backed inventory items.
enum FileHash {
    static func sha256(_ url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var hasher = SHA256()
        while true {
            guard let data = try handle.read(upToCount: ConfigurationDefaults.fileHashReadChunkBytes),
                  data.isEmpty == false
            else { break }
            hasher.update(data: data)
        }
        return hasher.finalize()
            .map { String(format: FileHashNames.hexByteFormat, $0) }
            .joined()
    }
}
