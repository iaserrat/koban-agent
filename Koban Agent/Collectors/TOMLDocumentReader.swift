import Foundation
import TOMLDecoder

/// Reads TOML documents through a typed decoder.
struct TOMLDocumentReader {
    func decode<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let text = try read(url)
        try Task.checkCancellation()
        return try decode(type, from: text)
    }

    func decode<T: Decodable>(_ type: T.Type, from text: String) throws -> T {
        try Task.checkCancellation()
        return try TOMLDecoder().decode(type, from: text)
    }

    func read(_ url: URL) throws -> String {
        try Task.checkCancellation()
        let text = try String(contentsOf: url, encoding: .utf8)
        try Task.checkCancellation()
        return text
    }
}
